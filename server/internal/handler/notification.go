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

type NotificationHandler struct {
	notifications *mongo.Collection
}

func NewNotificationHandler(db *mongo.Database) *NotificationHandler {
	return &NotificationHandler{
		notifications: db.Collection("notifications"),
	}
}

// GET /api/v1/notifications
func (h *NotificationHandler) GetNotifications(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var pq model.PaginationQuery
	if err := c.ShouldBindQuery(&pq); err != nil {
		pq.Page = 1
		pq.Limit = 20
	}
	skip := int64((pq.Page - 1) * pq.Limit)

	opts := options.Find().
		SetSort(bson.D{{Key: "created_at", Value: -1}}).
		SetSkip(skip).
		SetLimit(int64(pq.Limit))

	cursor, err := h.notifications.Find(ctx, bson.M{"user_id": userObjID}, opts)
	if err != nil {
		InternalError(c, "Database error")
		return
	}
	defer cursor.Close(ctx)

	var notifs []model.Notification
	if err := cursor.All(ctx, &notifs); err != nil {
		InternalError(c, "Failed to read notifications")
		return
	}
	if notifs == nil {
		notifs = []model.Notification{}
	}

	// Count unread
	unread, _ := h.notifications.CountDocuments(ctx, bson.M{
		"user_id": userObjID,
		"is_read": false,
	})

	OK(c, gin.H{
		"notifications": notifs,
		"unread_count":  unread,
	})
}

// PUT /api/v1/notifications/:id/read
func (h *NotificationHandler) MarkRead(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)
	notifID := c.Param("id")
	notifObjID, err := primitive.ObjectIDFromHex(notifID)
	if err != nil {
		BadRequest(c, "Invalid notification ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err = h.notifications.UpdateOne(ctx,
		bson.M{"_id": notifObjID, "user_id": userObjID},
		bson.M{"$set": bson.M{"is_read": true}},
	)
	if err != nil {
		InternalError(c, "Failed to mark notification as read")
		return
	}

	OK(c, gin.H{"message": "Notification marked as read"})
}

// PUT /api/v1/notifications/read-all
func (h *NotificationHandler) MarkAllRead(c *gin.Context) {
	userID := middleware.GetUserID(c)
	userObjID, _ := primitive.ObjectIDFromHex(userID)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	result, err := h.notifications.UpdateMany(ctx,
		bson.M{"user_id": userObjID, "is_read": false},
		bson.M{"$set": bson.M{"is_read": true}},
	)
	if err != nil {
		InternalError(c, "Failed to mark notifications as read")
		return
	}

	OK(c, gin.H{
		"message": "All notifications marked as read",
		"updated": result.ModifiedCount,
	})
}
