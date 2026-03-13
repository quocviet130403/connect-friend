package handler

import (
	"context"
	"time"

	"github.com/connect-app/server/internal/middleware"
	"github.com/connect-app/server/internal/model"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type ChatHandler struct {
	messages     *mongo.Collection
	chatRooms    *mongo.Collection
	participants *mongo.Collection
}

func NewChatHandler(db *mongo.Database) *ChatHandler {
	return &ChatHandler{
		messages:     db.Collection("chat_messages"),
		chatRooms:    db.Collection("chat_rooms"),
		participants: db.Collection("meetup_participants"),
	}
}

// GET /api/v1/chat/:roomId/messages
func (h *ChatHandler) GetMessages(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	roomID := c.Param("roomId")
	roomObjID, err := primitive.ObjectIDFromHex(roomID)
	if err != nil {
		BadRequest(c, "Invalid room ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Verify user is a participant of the meetup linked to this chat room
	var chatRoom model.ChatRoom
	err = h.chatRooms.FindOne(ctx, bson.M{"_id": roomObjID}).Decode(&chatRoom)
	if err != nil {
		NotFound(c, "Chat room not found")
		return
	}

	count, _ := h.participants.CountDocuments(ctx, bson.M{
		"meetup_id": chatRoom.MeetupID,
		"user_id":   userObjID,
		"status":    "joined",
	})
	if count == 0 {
		Forbidden(c, "Only meetup participants can view chat")
		return
	}

	// Pagination
	var pq model.PaginationQuery
	if err := c.ShouldBindQuery(&pq); err != nil {
		pq.Page = 1
		pq.Limit = 50
	}
	if pq.Limit > 100 {
		pq.Limit = 100
	}
	skip := int64((pq.Page - 1) * pq.Limit)

	opts := options.Find().
		SetSort(bson.D{{Key: "created_at", Value: -1}}).
		SetSkip(skip).
		SetLimit(int64(pq.Limit))

	cursor, err := h.messages.Find(ctx, bson.M{"room_id": roomObjID}, opts)
	if err != nil {
		InternalError(c, "Database error")
		return
	}
	defer cursor.Close(ctx)

	var messages []model.ChatMessage
	if err := cursor.All(ctx, &messages); err != nil {
		InternalError(c, "Failed to read messages")
		return
	}
	if messages == nil {
		messages = []model.ChatMessage{}
	}

	total, _ := h.messages.CountDocuments(ctx, bson.M{"room_id": roomObjID})

	totalPages := int(total) / pq.Limit
	if int(total)%pq.Limit > 0 {
		totalPages++
	}

	OKWithMeta(c, messages, &Meta{
		Page:       pq.Page,
		Limit:      pq.Limit,
		Total:      total,
		TotalPages: totalPages,
	})
}

// POST /api/v1/chat/:roomId/messages (REST fallback, primary is WebSocket)
func (h *ChatHandler) SendMessage(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	roomID := c.Param("roomId")
	roomObjID, err := primitive.ObjectIDFromHex(roomID)
	if err != nil {
		BadRequest(c, "Invalid room ID")
		return
	}

	var req model.SendMessageRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "Invalid request: "+err.Error())
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Verify user is a participant
	var chatRoom model.ChatRoom
	err = h.chatRooms.FindOne(ctx, bson.M{"_id": roomObjID}).Decode(&chatRoom)
	if err != nil {
		NotFound(c, "Chat room not found")
		return
	}
	count, _ := h.participants.CountDocuments(ctx, bson.M{
		"meetup_id": chatRoom.MeetupID,
		"user_id":   userObjID,
		"status":    "joined",
	})
	if count == 0 {
		Forbidden(c, "Only meetup participants can send messages")
		return
	}

	msgType := req.MessageType
	if msgType == "" {
		msgType = "text"
	}

	msg := model.ChatMessage{
		RoomID:      roomObjID,
		SenderID:    userObjID,
		Content:     req.Content,
		MessageType: msgType,
		CreatedAt:   time.Now(),
	}

	result, err := h.messages.InsertOne(ctx, msg)
	if err != nil {
		InternalError(c, "Failed to send message")
		return
	}
	msg.ID = result.InsertedID.(primitive.ObjectID)

	Created(c, msg)
}
