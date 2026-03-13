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

type ProfileHandler struct {
	profiles *mongo.Collection
}

func NewProfileHandler(db *mongo.Database) *ProfileHandler {
	return &ProfileHandler{
		profiles: db.Collection("profiles"),
	}
}

// GET /api/v1/profile
func (h *ProfileHandler) GetMyProfile(c *gin.Context) {
	userID := middleware.GetUserID(c)
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		BadRequest(c, "Invalid user ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var profile model.Profile
	err = h.profiles.FindOne(ctx, bson.M{"user_id": objID}).Decode(&profile)
	if err == mongo.ErrNoDocuments {
		// Return empty profile if not created yet
		OK(c, gin.H{"profile": nil, "message": "Profile not created yet"})
		return
	}
	if err != nil {
		InternalError(c, "Database error")
		return
	}

	OK(c, profile)
}

// PUT /api/v1/profile
func (h *ProfileHandler) UpdateProfile(c *gin.Context) {
	userID := middleware.GetUserID(c)
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		BadRequest(c, "Invalid user ID")
		return
	}

	var req model.UpdateProfileRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "Invalid request: "+err.Error())
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	now := time.Now()
	update := bson.M{
		"$set": bson.M{
			"display_name": req.DisplayName,
			"avatar_url":   req.AvatarURL,
			"bio":          req.Bio,
			"gender":       req.Gender,
			"city": model.City{
				Name: req.CityName,
				Slug: req.CitySlug,
			},
			"interests":  req.Interests,
			"vibes":      req.Vibes,
			"updated_at": now,
		},
		"$setOnInsert": bson.M{
			"user_id":  objID,
			"verified": false,
		},
	}

	opts := options.Update().SetUpsert(true)
	_, err = h.profiles.UpdateOne(ctx, bson.M{"user_id": objID}, update, opts)
	if err != nil {
		InternalError(c, "Failed to update profile")
		return
	}

	// Return updated profile
	var profile model.Profile
	_ = h.profiles.FindOne(ctx, bson.M{"user_id": objID}).Decode(&profile)
	OK(c, profile)
}

// GET /api/v1/profile/:id
func (h *ProfileHandler) GetProfile(c *gin.Context) {
	id := c.Param("id")
	objID, err := primitive.ObjectIDFromHex(id)
	if err != nil {
		BadRequest(c, "Invalid profile ID")
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var profile model.Profile
	err = h.profiles.FindOne(ctx, bson.M{"user_id": objID}).Decode(&profile)
	if err == mongo.ErrNoDocuments {
		NotFound(c, "Profile not found")
		return
	}
	if err != nil {
		InternalError(c, "Database error")
		return
	}

	OK(c, profile)
}

// PUT /api/v1/profile/location
func (h *ProfileHandler) UpdateLocation(c *gin.Context) {
	userID := middleware.GetUserID(c)
	objID, err := primitive.ObjectIDFromHex(userID)
	if err != nil {
		BadRequest(c, "Invalid user ID")
		return
	}

	var req model.UpdateLocationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "Invalid request: "+err.Error())
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	update := bson.M{
		"$set": bson.M{
			"location": model.GeoJSON{
				Type:        "Point",
				Coordinates: []float64{req.Longitude, req.Latitude},
			},
			"updated_at": time.Now(),
		},
	}

	result, err := h.profiles.UpdateOne(ctx, bson.M{"user_id": objID}, update)
	if err != nil {
		InternalError(c, "Failed to update location")
		return
	}
	if result.MatchedCount == 0 {
		NotFound(c, "Profile not found, create profile first")
		return
	}

	OK(c, gin.H{"message": "Location updated"})
}
