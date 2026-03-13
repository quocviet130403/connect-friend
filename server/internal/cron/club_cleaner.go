package cron

import (
	"context"
	"log"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

type ClubCleaner struct {
	clubs              *mongo.Collection
	clubMembers        *mongo.Collection
	warnInactiveDays   int
	archiveInactiveDays int
	deleteAfterDays    int
}

func NewClubCleaner(db *mongo.Database, warnDays, archiveDays, deleteDays int) *ClubCleaner {
	return &ClubCleaner{
		clubs:              db.Collection("clubs"),
		clubMembers:        db.Collection("club_members"),
		warnInactiveDays:   warnDays,
		archiveInactiveDays: archiveDays,
		deleteAfterDays:    deleteDays,
	}
}

// Start runs the club cleanup cron job
func (c *ClubCleaner) Start() {
	go func() {
		// Run immediately on start, then every 24 hours
		c.run()
		ticker := time.NewTicker(24 * time.Hour)
		defer ticker.Stop()
		for range ticker.C {
			c.run()
		}
	}()
	log.Println("🕐 Club auto-cancel cron started")
}

func (c *ClubCleaner) run() {
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	now := time.Now()
	warnCutoff := now.AddDate(0, 0, -c.warnInactiveDays)
	archiveCutoff := now.AddDate(0, 0, -c.archiveInactiveDays)
	deleteCutoff := now.AddDate(0, 0, -c.deleteAfterDays)

	// Step 1: Warn inactive clubs (2 months no activity)
	warnResult, err := c.clubs.UpdateMany(ctx,
		bson.M{
			"status":           "active",
			"last_activity_at": bson.M{"$lt": warnCutoff},
		},
		bson.M{
			"$set": bson.M{
				"status":    "warned",
				"warned_at": now,
			},
		},
	)
	if err == nil && warnResult.ModifiedCount > 0 {
		log.Printf("⚠️  Warned %d inactive clubs", warnResult.ModifiedCount)
		// TODO: Send notifications to club admins
	}

	// Step 2: Archive warned clubs (3 months no activity)
	archiveResult, err := c.clubs.UpdateMany(ctx,
		bson.M{
			"status":           "warned",
			"last_activity_at": bson.M{"$lt": archiveCutoff},
		},
		bson.M{
			"$set": bson.M{
				"status": "archived",
			},
		},
	)
	if err == nil && archiveResult.ModifiedCount > 0 {
		log.Printf("📦 Archived %d inactive clubs", archiveResult.ModifiedCount)
	}

	// Step 3: Hard delete archived clubs (1 month after archive)
	deleteCursor, err := c.clubs.Find(ctx,
		bson.M{
			"status":    "archived",
			"warned_at": bson.M{"$lt": deleteCutoff},
		},
	)
	if err != nil {
		return
	}
	defer deleteCursor.Close(ctx)

	var deletedCount int
	for deleteCursor.Next(ctx) {
		var club struct {
			ID primitive.ObjectID `bson:"_id"`
		}
		if err := deleteCursor.Decode(&club); err != nil {
			continue
		}

		// Delete club members first
		_, _ = c.clubMembers.DeleteMany(ctx, bson.M{"club_id": club.ID})
		// Delete club
		_, err := c.clubs.DeleteOne(ctx, bson.M{"_id": club.ID})
		if err == nil {
			deletedCount++
		}
	}
	if deletedCount > 0 {
		log.Printf("❌ Permanently deleted %d archived clubs", deletedCount)
	}
}
