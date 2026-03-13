package handler

import (
	"context"
	"time"

	"github.com/connect-app/server/internal/config"
	"github.com/connect-app/server/internal/middleware"
	"github.com/connect-app/server/internal/model"
	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"golang.org/x/crypto/bcrypt"
)

type AuthHandler struct {
	users  *mongo.Collection
	cfg    *config.Config
}

func NewAuthHandler(db *mongo.Database, cfg *config.Config) *AuthHandler {
	return &AuthHandler{
		users: db.Collection("users"),
		cfg:   cfg,
	}
}

// POST /api/v1/auth/register
func (h *AuthHandler) Register(c *gin.Context) {
	var req model.RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "Invalid request: "+err.Error())
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Check device limit
	deviceCount, err := h.users.CountDocuments(ctx, bson.M{"device_id": req.DeviceID})
	if err != nil {
		InternalError(c, "Database error")
		return
	}
	if deviceCount >= int64(h.cfg.MaxAccountsPerDevice) {
		TooMany(c, "Maximum accounts per device reached")
		return
	}

	// Check if phone already exists
	var existing model.User
	err = h.users.FindOne(ctx, bson.M{"phone": req.Phone}).Decode(&existing)
	if err == nil {
		Conflict(c, "Phone number already registered")
		return
	}

	// Hash password
	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		InternalError(c, "Failed to hash password")
		return
	}

	// Create user
	now := time.Now()
	user := model.User{
		Phone:             req.Phone,
		PasswordHash:      string(hash),
		DeviceID:          req.DeviceID,
		ClubsCreatedCount: 0,
		MaxClubsAllowed:   h.cfg.MaxClubsPerUser,
		CreatedAt:         now,
		UpdatedAt:         now,
	}

	result, err := h.users.InsertOne(ctx, user)
	if err != nil {
		InternalError(c, "Failed to create user")
		return
	}

	user.ID = result.InsertedID.(primitive.ObjectID)

	// Generate tokens
	tokens, err := h.generateTokens(user.ID.Hex())
	if err != nil {
		InternalError(c, "Failed to generate tokens")
		return
	}

	Created(c, model.AuthResponse{
		AccessToken:  tokens.AccessToken,
		RefreshToken: tokens.RefreshToken,
		User:         user,
	})
}

// POST /api/v1/auth/login
func (h *AuthHandler) Login(c *gin.Context) {
	var req model.LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "Invalid request: "+err.Error())
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Find user by phone
	var user model.User
	err := h.users.FindOne(ctx, bson.M{"phone": req.Phone}).Decode(&user)
	if err != nil {
		Unauthorized(c, "Invalid phone or password")
		return
	}

	// Check password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		Unauthorized(c, "Invalid phone or password")
		return
	}

	// Generate tokens
	tokens, err := h.generateTokens(user.ID.Hex())
	if err != nil {
		InternalError(c, "Failed to generate tokens")
		return
	}

	OK(c, model.AuthResponse{
		AccessToken:  tokens.AccessToken,
		RefreshToken: tokens.RefreshToken,
		User:         user,
	})
}

// POST /api/v1/auth/refresh
func (h *AuthHandler) Refresh(c *gin.Context) {
	var req model.RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		BadRequest(c, "Invalid request")
		return
	}

	// Parse refresh token
	claims := &middleware.Claims{}
	token, err := jwt.ParseWithClaims(req.RefreshToken, claims, func(t *jwt.Token) (interface{}, error) {
		return []byte(h.cfg.JWTSecret), nil
	})
	if err != nil || !token.Valid {
		Unauthorized(c, "Invalid or expired refresh token")
		return
	}

	// Generate new tokens
	tokens, err := h.generateTokens(claims.UserID)
	if err != nil {
		InternalError(c, "Failed to generate tokens")
		return
	}

	OK(c, gin.H{
		"access_token":  tokens.AccessToken,
		"refresh_token": tokens.RefreshToken,
	})
}

type tokenPair struct {
	AccessToken  string
	RefreshToken string
}

func (h *AuthHandler) generateTokens(userID string) (*tokenPair, error) {
	now := time.Now()

	// Access token
	accessClaims := middleware.Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(h.cfg.JWTExpiry)),
			IssuedAt:  jwt.NewNumericDate(now),
		},
	}
	accessToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, accessClaims).SignedString([]byte(h.cfg.JWTSecret))
	if err != nil {
		return nil, err
	}

	// Refresh token
	refreshClaims := middleware.Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(now.Add(h.cfg.JWTRefreshExpiry)),
			IssuedAt:  jwt.NewNumericDate(now),
		},
	}
	refreshToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, refreshClaims).SignedString([]byte(h.cfg.JWTSecret))
	if err != nil {
		return nil, err
	}

	return &tokenPair{AccessToken: accessToken, RefreshToken: refreshToken}, nil
}
