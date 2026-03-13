package handler

import (
	"context"
	"fmt"
	"time"

	"github.com/connect-app/server/internal/config"
	"github.com/connect-app/server/internal/middleware"
	"github.com/connect-app/server/internal/model"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type MeetupHandler struct {
	meetups      *mongo.Collection
	participants *mongo.Collection
	invites      *mongo.Collection
	clubs        *mongo.Collection
	clubMembers  *mongo.Collection
	chatRooms    *mongo.Collection
	cfg          *config.Config
}

func NewMeetupHandler(db *mongo.Database, cfg *config.Config) *MeetupHandler {
	return &MeetupHandler{
		meetups:      db.Collection("meetup_posts"),
		participants: db.Collection("meetup_participants"),
		invites:      db.Collection("meetup_invites"),
		clubs:        db.Collection("clubs"),
		clubMembers:  db.Collection("club_members"),
		chatRooms:    db.Collection("chat_rooms"),
		cfg:          cfg,
	}
}

// GET /api/v1/meetups
func (h *MeetupHandler) ListMeetups(c *gin.Context) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	filter := bson.M{"status": bson.M{"$in": []string{"open", "ongoing"}}}

	clubID := c.Query("club_id")
	if clubID != "" {
		objID, err := primitive.ObjectIDFromHex(clubID)
		if err == nil {
			filter["club_id"] = objID
		}
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "start_time", Value: 1}}).
		SetLimit(50)

	cursor, err := h.meetups.Find(ctx, filter, opts)
	if err != nil {
		InternalError(c, "Database error")
		return
	}
	defer cursor.Close(ctx)

	var meetups []model.MeetupPost
	if err := cursor.All(ctx, &meetups); err != nil {
		InternalError(c, "Failed to read meetups")
		return
	}
	if meetups == nil {
		meetups = []model.MeetupPost{}
	}

	OK(c, meetups)
}

// POST /api/v1/meetups
func (h *MeetupHandler) CreateMeetup(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	var req model.CreateMeetupRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "Invalid request: "+err.Error())
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	startTime, err := time.Parse(time.RFC3339, req.StartTime)
	if err != nil {
		BadRequest(c, "Invalid start_time format (use RFC3339)")
		return
	}

	now := time.Now()
	meetup := model.MeetupPost{
		CreatorID: userObjID,
		Title:     req.Title,
		Description: req.Description,
		PlaceName:    req.PlaceName,
		PlaceAddress: req.PlaceAddress,
		Location: model.GeoJSON{
			Type:        "Point",
			Coordinates: []float64{req.Longitude, req.Latitude},
		},
		StartTime:    startTime,
		MaxMembers:   req.MaxMembers,
		CurrentCount: 1, // Creator
		Status:       "open",
		Tags:         req.Tags,
		CreatedAt:    now,
		UpdatedAt:    now,
	}

	if req.EndTime != "" {
		endTime, err := time.Parse(time.RFC3339, req.EndTime)
		if err == nil {
			meetup.EndTime = &endTime
		}
	}

	// Link to club if specified
	if req.ClubID != "" {
		clubObjID, err := primitive.ObjectIDFromHex(req.ClubID)
		if err == nil {
			meetup.ClubID = &clubObjID
			// Update club's last activity
			_, _ = h.clubs.UpdateOne(ctx, bson.M{"_id": clubObjID}, bson.M{
				"$set": bson.M{"last_activity_at": now},
			})
		}
	}

	// Create chat room
	chatRoom := model.ChatRoom{
		CreatedAt: now,
	}
	chatResult, _ := h.chatRooms.InsertOne(ctx, chatRoom)
	chatRoomID := chatResult.InsertedID.(primitive.ObjectID)
	meetup.ChatRoomID = &chatRoomID

	// Insert meetup
	result, err := h.meetups.InsertOne(ctx, meetup)
	if err != nil {
		InternalError(c, "Failed to create meetup")
		return
	}
	meetup.ID = result.InsertedID.(primitive.ObjectID)

	// Update chat room with meetup ID
	_, _ = h.chatRooms.UpdateOne(ctx, bson.M{"_id": chatRoomID}, bson.M{
		"$set": bson.M{"meetup_id": meetup.ID},
	})

	// Add creator as first participant
	participant := model.MeetupParticipant{
		MeetupID: meetup.ID,
		UserID:   userObjID,
		Status:   "joined",
		JoinedAt: now,
	}
	_, _ = h.participants.InsertOne(ctx, participant)

	Created(c, meetup)
}

// GET /api/v1/meetups/:id
func (h *MeetupHandler) GetMeetup(c *gin.Context) {
	id := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		BadRequest(c, "Invalid meetup ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var meetup model.MeetupPost
	err = h.meetups.FindOne(ctx, bson.M{"_id": objID}).Decode(&meetup)
	if err == mongo.ErrNoDocuments {
		NotFound(c, "Meetup not found")
		return
	}
	if err != nil {
		InternalError(c, "Database error")
		return
	}

	OK(c, meetup)
}

// POST /api/v1/meetups/:id/join
func (h *MeetupHandler) JoinMeetup(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	meetupID := c.Param("id")
	meetupObjID, err := primitive.ObjectIDFromHex(meetupID)
	if err != nil {
		BadRequest(c, "Invalid meetup ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Check meetup exists and is open
	var meetup model.MeetupPost
	err = h.meetups.FindOne(ctx, bson.M{"_id": meetupObjID}).Decode(&meetup)
	if err != nil {
		NotFound(c, "Meetup not found")
		return
	}
	if meetup.Status != "open" {
		BadRequest(c, "Meetup is not open for joining")
		return
	}
	if meetup.CurrentCount >= meetup.MaxMembers {
		BadRequest(c, "Meetup is full")
		return
	}

	// Check not already joined
	count, _ := h.participants.CountDocuments(ctx, bson.M{
		"meetup_id": meetupObjID,
		"user_id":   userObjID,
		"status":    "joined",
	})
	if count > 0 {
		Conflict(c, "Already joined this meetup")
		return
	}

	// Add participant
	participant := model.MeetupParticipant{
		MeetupID: meetupObjID,
		UserID:   userObjID,
		Status:   "joined",
		JoinedAt: time.Now(),
	}
	_, err = h.participants.InsertOne(ctx, participant)
	if err != nil {
		InternalError(c, "Failed to join meetup")
		return
	}

	// Increment count and check if full
	newCount := meetup.CurrentCount + 1
	updateFields := bson.M{"current_count": newCount, "updated_at": time.Now()}
	if newCount >= meetup.MaxMembers {
		updateFields["status"] = "full"
	}
	_, _ = h.meetups.UpdateOne(ctx, bson.M{"_id": meetupObjID}, bson.M{"$set": updateFields})

	OK(c, gin.H{
		"message":      "Joined meetup successfully",
		"chat_room_id": meetup.ChatRoomID,
	})
}

// DELETE /api/v1/meetups/:id/leave
func (h *MeetupHandler) LeaveMeetup(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	meetupID := c.Param("id")
	meetupObjID, err := primitive.ObjectIDFromHex(meetupID)
	if err != nil {
		BadRequest(c, "Invalid meetup ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Check meetup - can't leave if you're the creator
	var meetup model.MeetupPost
	err = h.meetups.FindOne(ctx, bson.M{"_id": meetupObjID}).Decode(&meetup)
	if err != nil {
		NotFound(c, "Meetup not found")
		return
	}
	if meetup.CreatorID == userObjID {
		BadRequest(c, "Creator cannot leave. Cancel the meetup instead.")
		return
	}

	// Update participant status
	result, _ := h.participants.UpdateOne(ctx,
		bson.M{"meetup_id": meetupObjID, "user_id": userObjID, "status": "joined"},
		bson.M{"$set": bson.M{"status": "left"}},
	)
	if result.MatchedCount == 0 {
		NotFound(c, "Not a participant of this meetup")
		return
	}

	// Decrement count, reopen if was full
	updateFields := bson.M{"updated_at": time.Now()}
	_, _ = h.meetups.UpdateOne(ctx, bson.M{"_id": meetupObjID}, bson.M{
		"$inc": bson.M{"current_count": -1},
		"$set": updateFields,
	})
	// Reopen if was full
	if meetup.Status == "full" {
		_, _ = h.meetups.UpdateOne(ctx, bson.M{"_id": meetupObjID}, bson.M{
			"$set": bson.M{"status": "open"},
		})
	}

	OK(c, gin.H{"message": "Left meetup successfully"})
}

// GET /api/v1/meetups/nearby
func (h *MeetupHandler) NearbyMeetups(c *gin.Context) {
	var query model.NearbyQuery
	if err := c.ShouldBindQuery(&query); err != nil {
		BadRequest(c, "Invalid query: "+err.Error())
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	filter := bson.M{
		"status": bson.M{"$in": []string{"open", "ongoing"}},
		"location": bson.M{
			"$near": bson.M{
				"$geometry": bson.M{
					"type":        "Point",
					"coordinates": []float64{query.Longitude, query.Latitude},
				},
				"$maxDistance": query.RadiusKm * 1000, // Convert km to meters
			},
		},
	}

	if query.Category != "" {
		filter["tags"] = query.Category
	}

	opts := options.Find().SetLimit(30)
	cursor, err := h.meetups.Find(ctx, filter, opts)
	if err != nil {
		InternalError(c, "Database error")
		return
	}
	defer cursor.Close(ctx)

	var meetups []model.MeetupPost
	if err := cursor.All(ctx, &meetups); err != nil {
		InternalError(c, "Failed to read meetups")
		return
	}
	if meetups == nil {
		meetups = []model.MeetupPost{}
	}

	OK(c, meetups)
}

// POST /api/v1/meetups/:id/invite
func (h *MeetupHandler) InviteMembers(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	meetupID := c.Param("id")
	meetupObjID, err := primitive.ObjectIDFromHex(meetupID)
	if err != nil {
		BadRequest(c, "Invalid meetup ID")
		return
	}

	var req model.InviteRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "Invalid request: "+err.Error())
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Verify user is the meetup creator
	var meetup model.MeetupPost
	err = h.meetups.FindOne(ctx, bson.M{"_id": meetupObjID}).Decode(&meetup)
	if err != nil {
		NotFound(c, "Meetup not found")
		return
	}
	if meetup.CreatorID != userObjID {
		Forbidden(c, "Only the meetup host can send invites")
		return
	}

	// Check existing invite count
	existingCount, _ := h.invites.CountDocuments(ctx, bson.M{"meetup_id": meetupObjID})
	if int(existingCount)+len(req.UserIDs) > h.cfg.MaxInvitesPerMeetup {
		TooMany(c, fmt.Sprintf("Maximum %d invites per meetup", h.cfg.MaxInvitesPerMeetup))
		return
	}

	now := time.Now()
	invited := 0
	for _, uid := range req.UserIDs {
		inviteeObjID, err := primitive.ObjectIDFromHex(uid)
		if err != nil {
			continue
		}

		// Check invitee is a club member (if meetup belongs to a club)
		if meetup.ClubID != nil {
			count, _ := h.clubMembers.CountDocuments(ctx, bson.M{
				"club_id": meetup.ClubID,
				"user_id": inviteeObjID,
			})
			if count == 0 {
				continue // Skip non-members
			}
		}

		invite := model.MeetupInvite{
			MeetupID:  meetupObjID,
			InviterID: userObjID,
			InviteeID: inviteeObjID,
			Status:    "pending",
			CreatedAt: now,
		}
		_, err = h.invites.InsertOne(ctx, invite)
		if err == nil {
			invited++
		}
		// Ignore duplicate key errors (already invited)
	}

	OK(c, gin.H{
		"message": fmt.Sprintf("Sent %d invites", invited),
		"invited": invited,
	})
}

// GET /api/v1/meetups/:id/invites
func (h *MeetupHandler) GetInvites(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	meetupID := c.Param("id")
	meetupObjID, err := primitive.ObjectIDFromHex(meetupID)
	if err != nil {
		BadRequest(c, "Invalid meetup ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Verify user is the meetup creator
	var meetup model.MeetupPost
	err = h.meetups.FindOne(ctx, bson.M{"_id": meetupObjID}).Decode(&meetup)
	if err != nil || meetup.CreatorID != userObjID {
		Forbidden(c, "Only the meetup host can view invites")
		return
	}

	cursor, err := h.invites.Find(ctx, bson.M{"meetup_id": meetupObjID})
	if err != nil {
		InternalError(c, "Database error")
		return
	}
	defer cursor.Close(ctx)

	var invites []model.MeetupInvite
	if err := cursor.All(ctx, &invites); err != nil {
		InternalError(c, "Failed to read invites")
		return
	}
	if invites == nil {
		invites = []model.MeetupInvite{}
	}

	// Hide declined status from host
	for i := range invites {
		if invites[i].Status == "declined" {
			invites[i].Status = "pending" // Host doesn't know who declined
		}
	}

	OK(c, invites)
}

// PUT /api/v1/invites/:id/accept
func (h *MeetupHandler) AcceptInvite(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	inviteID := c.Param("id")
	inviteObjID, err := primitive.ObjectIDFromHex(inviteID)
	if err != nil {
		BadRequest(c, "Invalid invite ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Find and validate invite
	var invite model.MeetupInvite
	err = h.invites.FindOne(ctx, bson.M{"_id": inviteObjID, "invitee_id": userObjID}).Decode(&invite)
	if err != nil {
		NotFound(c, "Invite not found")
		return
	}
	if invite.Status != "pending" {
		BadRequest(c, "Invite already responded to or expired")
		return
	}

	// Check meetup is still open
	var meetup model.MeetupPost
	err = h.meetups.FindOne(ctx, bson.M{"_id": invite.MeetupID}).Decode(&meetup)
	if err != nil || (meetup.Status != "open") {
		BadRequest(c, "Meetup is no longer open")
		return
	}

	now := time.Now()

	// Update invite status
	_, _ = h.invites.UpdateOne(ctx, bson.M{"_id": inviteObjID}, bson.M{
		"$set": bson.M{"status": "accepted", "responded_at": now},
	})

	// Auto-join meetup
	participant := model.MeetupParticipant{
		MeetupID: invite.MeetupID,
		UserID:   userObjID,
		Status:   "joined",
		JoinedAt: now,
	}
	_, _ = h.participants.InsertOne(ctx, participant)

	// Update meetup count
	newCount := meetup.CurrentCount + 1
	updateFields := bson.M{"current_count": newCount, "updated_at": now}
	if newCount >= meetup.MaxMembers {
		updateFields["status"] = "full"
	}
	_, _ = h.meetups.UpdateOne(ctx, bson.M{"_id": invite.MeetupID}, bson.M{"$set": updateFields})

	OK(c, gin.H{
		"message":      "Invite accepted, you joined the meetup!",
		"chat_room_id": meetup.ChatRoomID,
	})
}

// PUT /api/v1/invites/:id/decline
func (h *MeetupHandler) DeclineInvite(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	inviteID := c.Param("id")
	inviteObjID, err := primitive.ObjectIDFromHex(inviteID)
	if err != nil {
		BadRequest(c, "Invalid invite ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	now := time.Now()
	result, _ := h.invites.UpdateOne(ctx,
		bson.M{"_id": inviteObjID, "invitee_id": userObjID, "status": "pending"},
		bson.M{"$set": bson.M{"status": "declined", "responded_at": now}},
	)
	if result.MatchedCount == 0 {
		NotFound(c, "Invite not found or already responded")
		return
	}

	OK(c, gin.H{"message": "Invite declined"})
}

// GET /api/v1/invites/pending
func (h *MeetupHandler) PendingInvites(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := h.invites.Find(ctx, bson.M{"invitee_id": userObjID, "status": "pending"})
	if err != nil {
		InternalError(c, "Database error")
		return
	}
	defer cursor.Close(ctx)

	var invites []model.MeetupInvite
	if err := cursor.All(ctx, &invites); err != nil {
		InternalError(c, "Failed to read invites")
		return
	}
	if invites == nil {
		invites = []model.MeetupInvite{}
	}

	OK(c, invites)
}
