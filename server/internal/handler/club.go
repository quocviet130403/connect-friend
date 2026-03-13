package handler

import (
	"context"
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

type ClubHandler struct {
	clubs       *mongo.Collection
	clubMembers *mongo.Collection
	users       *mongo.Collection
	cfg         *config.Config
}

func NewClubHandler(db *mongo.Database, cfg *config.Config) *ClubHandler {
	return &ClubHandler{
		clubs:       db.Collection("clubs"),
		clubMembers: db.Collection("club_members"),
		users:       db.Collection("users"),
		cfg:         cfg,
	}
}

// GET /api/v1/clubs
func (h *ClubHandler) ListClubs(c *gin.Context) {
	citySlug := c.Query("city")
	category := c.Query("category")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	filter := bson.M{"status": bson.M{"$ne": "archived"}}
	if citySlug != "" {
		filter["city.slug"] = citySlug
	}
	if category != "" {
		filter["category"] = category
	}

	opts := options.Find().
		SetSort(bson.D{{Key: "member_count", Value: -1}}).
		SetLimit(50)

	cursor, err := h.clubs.Find(ctx, filter, opts)
	if err != nil {
		InternalError(c, "Database error")
		return
	}
	defer cursor.Close(ctx)

	var clubs []model.Club
	if err := cursor.All(ctx, &clubs); err != nil {
		InternalError(c, "Failed to read clubs")
		return
	}

	if clubs == nil {
		clubs = []model.Club{}
	}

	OK(c, clubs)
}

// POST /api/v1/clubs
func (h *ClubHandler) CreateClub(c *gin.Context) {
	userID := middleware.GetUserID(c)
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		BadRequest(c, "Invalid user ID")
		return
	}

	var req model.CreateClubRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "Invalid request: "+err.Error())
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Check club creation limit
	var user model.User
	err = h.users.FindOne(ctx, bson.M{"_id": objID}).Decode(&user)
	if err != nil {
		InternalError(c, "User not found")
		return
	}
	if user.ClubsCreatedCount >= h.cfg.MaxClubsPerUser {
		TooMany(c, "Maximum clubs per user reached (limit: "+string(rune('0'+h.cfg.MaxClubsPerUser))+")")
		return
	}

	now := time.Now()
	club := model.Club{
		Name:           req.Name,
		Description:    req.Description,
		CoverURL:       req.CoverURL,
		IconEmoji:      req.IconEmoji,
		Category:       req.Category,
		City:           model.City{Name: req.CityName, Slug: req.CitySlug},
		CreatorID:      objID,
		MemberCount:    1, // Creator is first member
		IsPublic:       req.IsPublic,
		LastActivityAt: now,
		Status:         "active",
		CreatedAt:      now,
	}

	result, err := h.clubs.InsertOne(ctx, club)
	if err != nil {
		InternalError(c, "Failed to create club")
		return
	}

	club.ID = result.InsertedID.(primitive.ObjectID)

	// Add creator as admin member
	member := model.ClubMember{
		ClubID:   club.ID,
		UserID:   objID,
		Role:     "admin",
		JoinedAt: now,
	}
	_, _ = h.clubMembers.InsertOne(ctx, member)

	// Increment user's club count
	_, _ = h.users.UpdateOne(ctx, bson.M{"_id": objID}, bson.M{
		"$inc": bson.M{"clubs_created_count": 1},
	})

	Created(c, club)
}

// GET /api/v1/clubs/:id
func (h *ClubHandler) GetClub(c *gin.Context) {
	id := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		BadRequest(c, "Invalid club ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var club model.Club
	err = h.clubs.FindOne(ctx, bson.M{"_id": objID}).Decode(&club)
	if err == mongo.ErrNoDocuments {
		NotFound(c, "Club not found")
		return
	}
	if err != nil {
		InternalError(c, "Database error")
		return
	}

	OK(c, club)
}

// POST /api/v1/clubs/:id/join
func (h *ClubHandler) JoinClub(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	clubID := c.Param("id")
	clubObjID, err := primitive.ObjectIDFromHex(clubID)
	if err != nil {
		BadRequest(c, "Invalid club ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Check club exists and is active
	var club model.Club
	err = h.clubs.FindOne(ctx, bson.M{"_id": clubObjID, "status": "active"}).Decode(&club)
	if err != nil {
		NotFound(c, "Club not found or inactive")
		return
	}

	// Check if already a member
	count, _ := h.clubMembers.CountDocuments(ctx, bson.M{"club_id": clubObjID, "user_id": userObjID})
	if count > 0 {
		Conflict(c, "Already a member of this club")
		return
	}

	// Add member
	member := model.ClubMember{
		ClubID:   clubObjID,
		UserID:   userObjID,
		Role:     "member",
		JoinedAt: time.Now(),
	}
	_, err = h.clubMembers.InsertOne(ctx, member)
	if err != nil {
		InternalError(c, "Failed to join club")
		return
	}

	// Increment member count
	_, _ = h.clubs.UpdateOne(ctx, bson.M{"_id": clubObjID}, bson.M{
		"$inc": bson.M{"member_count": 1},
	})

	OK(c, gin.H{"message": "Joined club successfully"})
}

// DELETE /api/v1/clubs/:id/leave
func (h *ClubHandler) LeaveClub(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	clubID := c.Param("id")
	clubObjID, err := primitive.ObjectIDFromHex(clubID)
	if err != nil {
		BadRequest(c, "Invalid club ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	result, err := h.clubMembers.DeleteOne(ctx, bson.M{"club_id": clubObjID, "user_id": userObjID})
	if err != nil || result.DeletedCount == 0 {
		NotFound(c, "Not a member of this club")
		return
	}

	// Decrement member count
	_, _ = h.clubs.UpdateOne(ctx, bson.M{"_id": clubObjID}, bson.M{
		"$inc": bson.M{"member_count": -1},
	})

	OK(c, gin.H{"message": "Left club successfully"})
}

// GET /api/v1/clubs/:id/members
func (h *ClubHandler) GetMembers(c *gin.Context) {
	clubID := c.Param("id")
	clubObjID, err := primitive.ObjectIDFromHex(clubID)
	if err != nil {
		BadRequest(c, "Invalid club ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cursor, err := h.clubMembers.Find(ctx, bson.M{"club_id": clubObjID})
	if err != nil {
		InternalError(c, "Database error")
		return
	}
	defer cursor.Close(ctx)

	var members []model.ClubMember
	if err := cursor.All(ctx, &members); err != nil {
		InternalError(c, "Failed to read members")
		return
	}

	if members == nil {
		members = []model.ClubMember{}
	}

	OK(c, members)
}
