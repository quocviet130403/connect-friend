package model

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// ========== User ==========

type User struct {
	ID                primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Phone             string             `bson:"phone" json:"phone"`
	PasswordHash      string             `bson:"password_hash" json:"-"`
	DeviceID          string             `bson:"device_id" json:"-"`
	ClubsCreatedCount int                `bson:"clubs_created_count" json:"clubs_created_count"`
	MaxClubsAllowed   int                `bson:"max_clubs_allowed" json:"max_clubs_allowed"`
	CreatedAt         time.Time          `bson:"created_at" json:"created_at"`
	UpdatedAt         time.Time          `bson:"updated_at" json:"updated_at"`
}

// ========== Profile ==========

type GeoJSON struct {
	Type        string    `bson:"type" json:"type"`
	Coordinates []float64 `bson:"coordinates" json:"coordinates"` // [lng, lat]
}

type City struct {
	Name string `bson:"name" json:"name"`
	Slug string `bson:"slug" json:"slug"`
}

type Profile struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID      primitive.ObjectID `bson:"user_id" json:"user_id"`
	DisplayName string             `bson:"display_name" json:"display_name"`
	AvatarURL   string             `bson:"avatar_url" json:"avatar_url"`
	Bio         string             `bson:"bio" json:"bio"`
	DateOfBirth *time.Time         `bson:"date_of_birth,omitempty" json:"date_of_birth,omitempty"`
	Gender      string             `bson:"gender" json:"gender"`
	City        City               `bson:"city" json:"city"`
	Location    *GeoJSON           `bson:"location,omitempty" json:"location,omitempty"`
	Interests   []string           `bson:"interests" json:"interests"`
	Vibes       []string           `bson:"vibes" json:"vibes"`
	Verified    bool               `bson:"verified" json:"verified"`
	UpdatedAt   time.Time          `bson:"updated_at" json:"updated_at"`
}

// ========== Club ==========

type Club struct {
	ID             primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Name           string             `bson:"name" json:"name"`
	Description    string             `bson:"description" json:"description"`
	CoverURL       string             `bson:"cover_url" json:"cover_url"`
	IconEmoji      string             `bson:"icon_emoji" json:"icon_emoji"`
	Category       string             `bson:"category" json:"category"`
	City           City               `bson:"city" json:"city"`
	CreatorID      primitive.ObjectID `bson:"creator_id" json:"creator_id"`
	MemberCount    int                `bson:"member_count" json:"member_count"`
	IsPublic       bool               `bson:"is_public" json:"is_public"`
	LastActivityAt time.Time          `bson:"last_activity_at" json:"last_activity_at"`
	Status         string             `bson:"status" json:"status"` // active, warned, archived
	WarnedAt       *time.Time         `bson:"warned_at,omitempty" json:"warned_at,omitempty"`
	CreatedAt      time.Time          `bson:"created_at" json:"created_at"`
}

type ClubMember struct {
	ID       primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ClubID   primitive.ObjectID `bson:"club_id" json:"club_id"`
	UserID   primitive.ObjectID `bson:"user_id" json:"user_id"`
	Role     string             `bson:"role" json:"role"` // admin, moderator, member
	JoinedAt time.Time          `bson:"joined_at" json:"joined_at"`
}

// ========== Meetup ==========

type MeetupPost struct {
	ID           primitive.ObjectID  `bson:"_id,omitempty" json:"id"`
	CreatorID    primitive.ObjectID  `bson:"creator_id" json:"creator_id"`
	ClubID       *primitive.ObjectID `bson:"club_id,omitempty" json:"club_id,omitempty"`
	Title        string              `bson:"title" json:"title"`
	Description  string              `bson:"description" json:"description"`
	PlaceName    string              `bson:"place_name" json:"place_name"`
	PlaceAddress string              `bson:"place_address" json:"place_address"`
	Location     GeoJSON             `bson:"location" json:"location"`
	StartTime    time.Time           `bson:"start_time" json:"start_time"`
	EndTime      *time.Time          `bson:"end_time,omitempty" json:"end_time,omitempty"`
	MaxMembers   int                 `bson:"max_members" json:"max_members"`
	CurrentCount int                 `bson:"current_count" json:"current_count"`
	Status       string              `bson:"status" json:"status"` // open, full, ongoing, completed, cancelled
	Tags         []string            `bson:"tags" json:"tags"`
	ChatRoomID   *primitive.ObjectID `bson:"chat_room_id,omitempty" json:"chat_room_id,omitempty"`
	CreatedAt    time.Time           `bson:"created_at" json:"created_at"`
	UpdatedAt    time.Time           `bson:"updated_at" json:"updated_at"`
}

type MeetupParticipant struct {
	ID       primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	MeetupID primitive.ObjectID `bson:"meetup_id" json:"meetup_id"`
	UserID   primitive.ObjectID `bson:"user_id" json:"user_id"`
	Status   string             `bson:"status" json:"status"` // joined, left, removed
	JoinedAt time.Time          `bson:"joined_at" json:"joined_at"`
}

type MeetupInvite struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	MeetupID    primitive.ObjectID `bson:"meetup_id" json:"meetup_id"`
	InviterID   primitive.ObjectID `bson:"inviter_id" json:"inviter_id"`
	InviteeID   primitive.ObjectID `bson:"invitee_id" json:"invitee_id"`
	Status      string             `bson:"status" json:"status"` // pending, accepted, declined, expired
	CreatedAt   time.Time          `bson:"created_at" json:"created_at"`
	RespondedAt *time.Time         `bson:"responded_at,omitempty" json:"responded_at,omitempty"`
}

// ========== Chat ==========

type ChatRoom struct {
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	MeetupID  primitive.ObjectID `bson:"meetup_id" json:"meetup_id"`
	CreatedAt time.Time          `bson:"created_at" json:"created_at"`
}

type ChatMessage struct {
	ID          primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	RoomID      primitive.ObjectID `bson:"room_id" json:"room_id"`
	SenderID    primitive.ObjectID `bson:"sender_id" json:"sender_id"`
	Content     string             `bson:"content" json:"content"`
	MessageType string             `bson:"message_type" json:"message_type"` // text, location, system
	CreatedAt   time.Time          `bson:"created_at" json:"created_at"`
}

// ========== Notification ==========

type Notification struct {
	ID        primitive.ObjectID     `bson:"_id,omitempty" json:"id"`
	UserID    primitive.ObjectID     `bson:"user_id" json:"user_id"`
	Type      string                 `bson:"type" json:"type"`
	Title     string                 `bson:"title" json:"title"`
	Body      string                 `bson:"body" json:"body"`
	Data      map[string]interface{} `bson:"data" json:"data"`
	IsRead    bool                   `bson:"is_read" json:"is_read"`
	CreatedAt time.Time              `bson:"created_at" json:"created_at"`
}

type NotificationSettings struct {
	ID              primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	UserID          primitive.ObjectID `bson:"user_id" json:"user_id"`
	NearbyRadiusKm  int                `bson:"nearby_radius_km" json:"nearby_radius_km"`
	PushEnabled     bool               `bson:"push_enabled" json:"push_enabled"`
	QuietHoursStart string             `bson:"quiet_hours_start" json:"quiet_hours_start"`
	QuietHoursEnd   string             `bson:"quiet_hours_end" json:"quiet_hours_end"`
}
