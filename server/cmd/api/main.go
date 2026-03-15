package main

import (
	"log"
	"net/http"

	"github.com/connect-app/server/internal/config"
	"github.com/connect-app/server/internal/cron"
	"github.com/connect-app/server/internal/database"
	"github.com/connect-app/server/internal/handler"
	mw "github.com/connect-app/server/internal/middleware"
	"github.com/connect-app/server/internal/ws"
	"github.com/gin-gonic/gin"
)

func main() {
	// Load config
	cfg := config.Load()

	// Set Gin mode
	gin.SetMode(cfg.GinMode)

	// Connect to MongoDB
	db, err := database.ConnectMongo(cfg.MongoURI, cfg.MongoDB)
	if err != nil {
		log.Fatalf("MongoDB connection failed: %v", err)
	}
	defer database.DisconnectMongo(db)

	// Connect to Redis
	rdb, err := database.ConnectRedis(cfg.RedisAddr, cfg.RedisPassword, cfg.RedisDB)
	if err != nil {
		log.Fatalf("Redis connection failed: %v", err)
	}
	defer rdb.Close()
	_ = rdb // Will be used later for caching

	// Initialize WebSocket hub
	hub := ws.NewHub(db)
	go hub.Run()

	// Start cron jobs
	clubCleaner := cron.NewClubCleaner(db,
		cfg.ClubWarnInactiveDays,
		cfg.ClubArchiveInactiveDays,
		cfg.ClubDeleteAfterArchive,
	)
	clubCleaner.Start()

	// Initialize handlers
	authHandler := handler.NewAuthHandler(db, cfg)
	profileHandler := handler.NewProfileHandler(db)
	clubHandler := handler.NewClubHandler(db, cfg)
	meetupHandler := handler.NewMeetupHandler(db, cfg)
	chatHandler := handler.NewChatHandler(db)
	notifHandler := handler.NewNotificationHandler(db)

	// Setup router
	r := gin.Default()
	r.Use(mw.CORS())
	r.Use(mw.RateLimiter(100, 60_000_000_000)) // 100 requests per minute

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":  "ok",
			"service": "connect-api",
		})
	})

	// API v1
	v1 := r.Group("/api/v1")

	// ========== Auth (public) ==========
	auth := v1.Group("/auth")
	{
		auth.POST("/register", authHandler.Register)
		auth.POST("/login", authHandler.Login)
		auth.POST("/refresh", authHandler.Refresh)
	}

	// ========== Protected routes ==========
	protected := v1.Group("")
	protected.Use(mw.AuthMiddleware(cfg.JWTSecret))

	// Profile
	profile := protected.Group("/profile")
	{
		profile.GET("", profileHandler.GetMyProfile)
		profile.PUT("", profileHandler.UpdateProfile)
		profile.GET("/:id", profileHandler.GetProfile)
		profile.PUT("/location", profileHandler.UpdateLocation)
	}

	// Clubs
	clubs := protected.Group("/clubs")
	{
		clubs.GET("", clubHandler.ListClubs)
		clubs.POST("", clubHandler.CreateClub)
		clubs.GET("/:id", clubHandler.GetClub)
		clubs.POST("/:id/join", clubHandler.JoinClub)
		clubs.DELETE("/:id/leave", clubHandler.LeaveClub)
		clubs.GET("/:id/members", clubHandler.GetMembers)
	}

	// Meetups
	meetups := protected.Group("/meetups")
	{
		meetups.GET("", meetupHandler.ListMeetups)
		meetups.POST("", meetupHandler.CreateMeetup)
		meetups.GET("/nearby", meetupHandler.NearbyMeetups)
		meetups.GET("/:id", meetupHandler.GetMeetup)
		meetups.POST("/:id/join", meetupHandler.JoinMeetup)
		meetups.DELETE("/:id/leave", meetupHandler.LeaveMeetup)
		meetups.POST("/:id/invite", meetupHandler.InviteMembers)
		meetups.GET("/:id/invites", meetupHandler.GetInvites)
	}

	// Invites
	invites := protected.Group("/invites")
	{
		invites.GET("/pending", meetupHandler.PendingInvites)
		invites.PUT("/:id/accept", meetupHandler.AcceptInvite)
		invites.PUT("/:id/decline", meetupHandler.DeclineInvite)
	}

	// Chat (REST)
	chat := protected.Group("/chat")
	{
		chat.GET("/:roomId/messages", chatHandler.GetMessages)
		chat.POST("/:roomId/messages", chatHandler.SendMessage)
		chat.PUT("/:roomId/read", chatHandler.MarkRead)
	}

	// Notifications
	notifs := protected.Group("/notifications")
	{
		notifs.GET("", notifHandler.GetNotifications)
		notifs.PUT("/:id/read", notifHandler.MarkRead)
		notifs.PUT("/read-all", notifHandler.MarkAllRead)
	}

	// WebSocket endpoint
	r.GET("/ws", mw.AuthMiddleware(cfg.JWTSecret), func(c *gin.Context) {
		userID := mw.GetUserID(c)
		hub.HandleWebSocket(c.Writer, c.Request, userID)
	})

	// Start server
	addr := ":" + cfg.Port
	log.Printf("🚀 Connect API server starting on %s", addr)
	if err := r.Run(addr); err != nil {
		log.Fatalf("Server failed: %v", err)
	}
}
