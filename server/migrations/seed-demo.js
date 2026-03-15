// Demo account seeder for connect-friend
// Run: make seed
// Password for all demo accounts: 123456
// bcrypt hash of "123456" with default cost (10)

const DEMO_PASSWORD_HASH = "$2b$10$3dRYlTbGlEkdxbsLV3/4NesB2fc8WkNSOKe/6bjfQtqBPp4./yy5S";

db = db.getSiblingDB('connect');

const now = new Date();

// ========== Demo Users ==========
const users = [
  {
    phone: "0901000001",
    password_hash: DEMO_PASSWORD_HASH,
    device_id: "demo-device-001",
    clubs_created_count: 0,
    max_clubs_allowed: 3,
    created_at: now,
    updated_at: now
  },
  {
    phone: "0901000002",
    password_hash: DEMO_PASSWORD_HASH,
    device_id: "demo-device-002",
    clubs_created_count: 0,
    max_clubs_allowed: 3,
    created_at: now,
    updated_at: now
  },
  {
    phone: "0901000003",
    password_hash: DEMO_PASSWORD_HASH,
    device_id: "demo-device-003",
    clubs_created_count: 0,
    max_clubs_allowed: 3,
    created_at: now,
    updated_at: now
  },
  {
    phone: "0901000004",
    password_hash: DEMO_PASSWORD_HASH,
    device_id: "demo-device-004",
    clubs_created_count: 0,
    max_clubs_allowed: 3,
    created_at: now,
    updated_at: now
  },
  {
    phone: "0901000005",
    password_hash: DEMO_PASSWORD_HASH,
    device_id: "demo-device-005",
    clubs_created_count: 0,
    max_clubs_allowed: 3,
    created_at: now,
    updated_at: now
  }
];

// Remove existing demo users (by phone) to allow re-seeding
const demoPhones = users.map(u => u.phone);
const existingUsers = db.users.find({ phone: { $in: demoPhones } }).toArray();
const existingUserIds = existingUsers.map(u => u._id);

if (existingUserIds.length > 0) {
  db.profiles.deleteMany({ user_id: { $in: existingUserIds } });
  db.users.deleteMany({ phone: { $in: demoPhones } });
  print("🗑️  Cleaned up existing demo data");
}

// Insert users
db.users.insertMany(users);
print("✅ Inserted " + users.length + " demo users");

// Get inserted user IDs
const insertedUsers = db.users.find({ phone: { $in: demoPhones } }).toArray();

// ========== Demo Profiles ==========
const profileData = [
  {
    display_name: "Minh Tú",
    bio: "Thích cà phê và chạy bộ buổi sáng ☕🏃",
    gender: "male",
    city: { name: "Hồ Chí Minh", slug: "ho-chi-minh" },
    location: { type: "Point", coordinates: [106.6297, 10.8231] },
    interests: ["coffee", "running", "photography"],
    vibes: ["chill", "active"],
    verified: false
  },
  {
    display_name: "Thanh Hà",
    bio: "Foodie 🍜 | Yêu du lịch và khám phá ẩm thực",
    gender: "female",
    city: { name: "Hồ Chí Minh", slug: "ho-chi-minh" },
    location: { type: "Point", coordinates: [106.7009, 10.7769] },
    interests: ["food", "travel", "cooking"],
    vibes: ["social", "adventurous"],
    verified: false
  },
  {
    display_name: "Đức Anh",
    bio: "Developer by day, gamer by night 🎮💻",
    gender: "male",
    city: { name: "Hà Nội", slug: "ha-noi" },
    location: { type: "Point", coordinates: [105.8342, 21.0278] },
    interests: ["gaming", "coding", "music"],
    vibes: ["chill", "nerdy"],
    verified: false
  },
  {
    display_name: "Mai Linh",
    bio: "Yoga & thiền 🧘‍♀️ Sống tích cực mỗi ngày",
    gender: "female",
    city: { name: "Đà Nẵng", slug: "da-nang" },
    location: { type: "Point", coordinates: [108.2022, 16.0544] },
    interests: ["yoga", "meditation", "reading"],
    vibes: ["peaceful", "mindful"],
    verified: false
  },
  {
    display_name: "Quốc Bảo",
    bio: "Bóng đá cuối tuần ⚽ | Cafe đen không đường",
    gender: "male",
    city: { name: "Hồ Chí Minh", slug: "ho-chi-minh" },
    location: { type: "Point", coordinates: [106.6602, 10.7626] },
    interests: ["football", "coffee", "movies"],
    vibes: ["active", "social"],
    verified: false
  }
];

const profiles = insertedUsers.map((user, i) => ({
  user_id: user._id,
  ...profileData[i],
  avatar_url: "",
  updated_at: now
}));

db.profiles.insertMany(profiles);
print("✅ Inserted " + profiles.length + " demo profiles");

// ========== Summary ==========
print("");
print("===========================================");
print("  📱 DEMO ACCOUNTS READY");
print("===========================================");
print("  Password for all accounts: 123456");
print("-------------------------------------------");
insertedUsers.forEach((u, i) => {
  print("  " + profileData[i].display_name + " | " + u.phone + " | " + profileData[i].city.name);
});
print("===========================================");
