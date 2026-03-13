package model

// ========== Auth DTOs ==========

type RegisterRequest struct {
	Phone    string `json:"phone" binding:"required,min=9,max=15"`
	Password string `json:"password" binding:"required,min=6"`
	DeviceID string `json:"device_id" binding:"required"`
}

type LoginRequest struct {
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required"`
}

type RefreshRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type AuthResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	User         User   `json:"user"`
}

// ========== Profile DTOs ==========

type UpdateProfileRequest struct {
	DisplayName string   `json:"display_name" binding:"omitempty,min=2,max=50"`
	AvatarURL   string   `json:"avatar_url"`
	Bio         string   `json:"bio" binding:"omitempty,max=200"`
	DateOfBirth string   `json:"date_of_birth"`
	Gender      string   `json:"gender" binding:"omitempty,oneof=male female other"`
	CityName    string   `json:"city_name"`
	CitySlug    string   `json:"city_slug"`
	Interests   []string `json:"interests"`
	Vibes       []string `json:"vibes"`
}

type UpdateLocationRequest struct {
	Longitude float64 `json:"longitude" binding:"required"`
	Latitude  float64 `json:"latitude" binding:"required"`
}

// ========== Club DTOs ==========

type CreateClubRequest struct {
	Name        string `json:"name" binding:"required,min=3,max=100"`
	Description string `json:"description" binding:"max=500"`
	CoverURL    string `json:"cover_url"`
	IconEmoji   string `json:"icon_emoji"`
	Category    string `json:"category" binding:"required"`
	CityName    string `json:"city_name" binding:"required"`
	CitySlug    string `json:"city_slug" binding:"required"`
	IsPublic    bool   `json:"is_public"`
}

// ========== Meetup DTOs ==========

type CreateMeetupRequest struct {
	ClubID       string   `json:"club_id"`
	Title        string   `json:"title" binding:"required,min=3,max=100"`
	Description  string   `json:"description" binding:"max=500"`
	PlaceName    string   `json:"place_name" binding:"required"`
	PlaceAddress string   `json:"place_address" binding:"required"`
	Longitude    float64  `json:"longitude" binding:"required"`
	Latitude     float64  `json:"latitude" binding:"required"`
	StartTime    string   `json:"start_time" binding:"required"`
	EndTime      string   `json:"end_time"`
	MaxMembers   int      `json:"max_members" binding:"required,min=2,max=50"`
	Tags         []string `json:"tags"`
}

type InviteRequest struct {
	UserIDs []string `json:"user_ids" binding:"required,min=1,max=10"`
}

// ========== Chat DTOs ==========

type SendMessageRequest struct {
	Content     string `json:"content" binding:"required,max=1000"`
	MessageType string `json:"message_type" binding:"omitempty,oneof=text location"`
}

// ========== Common ==========

type PaginationQuery struct {
	Page  int `form:"page,default=1"`
	Limit int `form:"limit,default=20"`
}

type NearbyQuery struct {
	Longitude float64 `form:"longitude" binding:"required"`
	Latitude  float64 `form:"latitude" binding:"required"`
	RadiusKm  float64 `form:"radius_km,default=5"`
	Category  string  `form:"category"`
}
