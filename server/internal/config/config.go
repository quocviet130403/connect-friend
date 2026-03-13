package config

import (
	"os"
	"strconv"
	"time"

	"github.com/joho/godotenv"
)

type Config struct {
	Port    string
	GinMode string

	// MongoDB
	MongoURI string
	MongoDB  string

	// Redis
	RedisAddr     string
	RedisPassword string
	RedisDB       int

	// JWT
	JWTSecret        string
	JWTExpiry        time.Duration
	JWTRefreshExpiry time.Duration

	// Limits
	MaxAccountsPerDevice    int
	MaxClubsPerUser         int
	ClubWarnInactiveDays    int
	ClubArchiveInactiveDays int
	ClubDeleteAfterArchive  int
	MaxInvitesPerMeetup     int
}

func Load() *Config {
	_ = godotenv.Load()

	return &Config{
		Port:    getEnv("PORT", "8080"),
		GinMode: getEnv("GIN_MODE", "debug"),

		MongoURI: getEnv("MONGO_URI", "mongodb://localhost:27017"),
		MongoDB:  getEnv("MONGO_DB", "connect"),

		RedisAddr:     getEnv("REDIS_ADDR", "localhost:6379"),
		RedisPassword: getEnv("REDIS_PASSWORD", ""),
		RedisDB:       getEnvInt("REDIS_DB", 0),

		JWTSecret:        getEnv("JWT_SECRET", "dev-secret"),
		JWTExpiry:        getEnvDuration("JWT_EXPIRY", 24*time.Hour),
		JWTRefreshExpiry: getEnvDuration("JWT_REFRESH_EXPIRY", 720*time.Hour),

		MaxAccountsPerDevice:    getEnvInt("MAX_ACCOUNTS_PER_DEVICE", 2),
		MaxClubsPerUser:         getEnvInt("MAX_CLUBS_PER_USER", 3),
		ClubWarnInactiveDays:    getEnvInt("CLUB_WARN_INACTIVE_DAYS", 60),
		ClubArchiveInactiveDays: getEnvInt("CLUB_ARCHIVE_INACTIVE_DAYS", 90),
		ClubDeleteAfterArchive:  getEnvInt("CLUB_DELETE_AFTER_ARCHIVE_DAYS", 30),
		MaxInvitesPerMeetup:     getEnvInt("MAX_INVITES_PER_MEETUP", 10),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if v := os.Getenv(key); v != "" {
		if i, err := strconv.Atoi(v); err == nil {
			return i
		}
	}
	return fallback
}

func getEnvDuration(key string, fallback time.Duration) time.Duration {
	if v := os.Getenv(key); v != "" {
		if d, err := time.ParseDuration(v); err == nil {
			return d
		}
	}
	return fallback
}
