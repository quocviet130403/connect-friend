# Connect App - Task Tracker

## Phase 0: Planning & Design
- [x] Create comprehensive app plan & architecture document
- [x] Design database schema (MongoDB)
- [x] Design API endpoints
- [x] Create features & flows document

## Phase 1: Server Setup & Foundation
- [x] Initialize Go project structure
- [x] Docker setup (MongoDB + Redis + Go server)
- [x] Core config (env, database connections)
- [x] Middleware (JWT auth, CORS, rate limit)
- [x] Database models & indexes
- [x] Build verification ✅

## Phase 2: Core Backend APIs
- [x] Auth APIs (register, login, refresh, device limit)
- [x] Profile APIs (CRUD, location update)
- [x] Club APIs (CRUD, join/leave, creation limit)
- [x] Club auto-cancel cron job
- [x] Meetup APIs (CRUD, join/leave, nearby geo query)
- [x] Meetup invite system (max 10, hidden decline)
- [x] Chat APIs (REST + message history with pagination)
- [x] Notification APIs (list, mark read, mark all read)

## Phase 3: Real-time Features
- [x] WebSocket hub for chat
- [x] Chat message handlers (join room, send message, broadcast)
- [ ] Redis Pub/Sub integration (for multi-instance)
- [ ] Online status tracking via Redis

## Phase 4: Flutter Client ✅
- [x] Initialize Flutter project
- [x] Premium dark theme (purple/teal palette, Inter font)
- [x] API service (full endpoint coverage + token management)
- [x] WebSocket chat service (auto-reconnect)
- [x] Auth provider (state management)
- [x] GoRouter (auth guard, bottom nav shell, nested routes)
- [x] Auth screens (Login + Register with animations)
- [x] Explore screen (meetup feed with cards)
- [x] Clubs screen (grid + category filter + create dialog)
- [x] Meetups screen (pending invites + meetup list)
- [x] Profile screen (avatar, bio, interests, edit, logout)
- [x] Club detail screen (info + join + members)
- [x] Meetup detail screen (info + join + chat)
- [x] Create meetup screen (form with date/time/slider)
- [x] Chat screen (real-time WebSocket + message bubbles)
- [x] flutter pub get ✅
- [x] flutter analyze (minor warnings only) ✅

## Next Steps
- [ ] Tích hợp Firebase Cloud Messaging cho push notifications
- [ ] Add Google Maps cho chọn địa điểm
- [ ] Thêm search/filter trên bản đồ
- [ ] Profile verification (CCCD/CMND)
