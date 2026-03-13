// MongoDB initialization script - creates indexes on first run
// This runs automatically when MongoDB container starts for the first time

db = db.getSiblingDB('connect');

// ========== Users ==========
db.users.createIndex({ phone: 1 }, { unique: true });
db.users.createIndex({ device_id: 1 });

// ========== Profiles ==========
db.profiles.createIndex({ user_id: 1 }, { unique: true });
db.profiles.createIndex({ location: "2dsphere" });
db.profiles.createIndex({ "city.slug": 1 });

// ========== Clubs ==========
db.clubs.createIndex({ "city.slug": 1, category: 1 });
db.clubs.createIndex({ creator_id: 1 });
db.clubs.createIndex({ last_activity_at: 1, status: 1 });
db.clubs.createIndex({ status: 1 });

// ========== Club Members ==========
db.club_members.createIndex({ club_id: 1, user_id: 1 }, { unique: true });
db.club_members.createIndex({ user_id: 1 });

// ========== Meetup Posts ==========
db.meetup_posts.createIndex({ location: "2dsphere" });
db.meetup_posts.createIndex({ club_id: 1, status: 1, start_time: -1 });
db.meetup_posts.createIndex({ creator_id: 1 });
db.meetup_posts.createIndex({ status: 1, start_time: 1 });

// ========== Meetup Participants ==========
db.meetup_participants.createIndex({ meetup_id: 1, user_id: 1 }, { unique: true });

// ========== Meetup Invites ==========
db.meetup_invites.createIndex({ meetup_id: 1, invitee_id: 1 }, { unique: true });
db.meetup_invites.createIndex({ invitee_id: 1, status: 1 });

// ========== Chat Messages ==========
db.chat_messages.createIndex({ room_id: 1, created_at: -1 });

// ========== Chat Rooms ==========
db.chat_rooms.createIndex({ meetup_id: 1 }, { unique: true });

// ========== Notifications ==========
db.notifications.createIndex({ user_id: 1, is_read: 1, created_at: -1 });

print('✅ All indexes created successfully for connect database');
