# Connect App

> Nền tảng tạo cuộc hẹn gặp mặt trực tiếp

## Tech Stack

- **Backend:** Golang (Gin) + WebSocket
- **Database:** MongoDB 7 + Redis 7
- **Mobile:** Flutter (coming soon)
- **Containerization:** Docker + Docker Compose

## Quick Start

```bash
# Start everything (MongoDB + Redis + Server)
docker compose up -d --build

# Check health
curl http://localhost:8080/health

# View logs
docker compose logs -f server

# Stop
docker compose down
```

## Services

| Service | URL | Description |
|---------|-----|-------------|
| **API Server** | http://localhost:8080 | Golang backend |
| **MongoDB** | localhost:27017 | Database |
| **Redis** | localhost:6379 | Cache + Pub/Sub |
| **Mongo Express** | http://localhost:8081 | DB admin panel |

## API Endpoints

### Auth (Public)
- `POST /api/v1/auth/register` — Đăng ký
- `POST /api/v1/auth/login` — Đăng nhập
- `POST /api/v1/auth/refresh` — Refresh token

### Profile (Requires JWT)
- `GET /api/v1/profile` — Profile của mình
- `PUT /api/v1/profile` — Cập nhật profile
- `GET /api/v1/profile/:id` — Xem profile người khác
- `PUT /api/v1/profile/location` — Cập nhật vị trí

### Clubs
- `GET /api/v1/clubs` — Danh sách CLB
- `POST /api/v1/clubs` — Tạo CLB (max 3)
- `GET /api/v1/clubs/:id` — Chi tiết CLB
- `POST /api/v1/clubs/:id/join` — Tham gia
- `DELETE /api/v1/clubs/:id/leave` — Rời CLB
- `GET /api/v1/clubs/:id/members` — Danh sách thành viên

### Meetups
- `GET /api/v1/meetups` — Danh sách meetup
- `POST /api/v1/meetups` — Tạo meetup
- `GET /api/v1/meetups/nearby` — Meetup gần
- `GET /api/v1/meetups/:id` — Chi tiết
- `POST /api/v1/meetups/:id/join` — Tham gia
- `DELETE /api/v1/meetups/:id/leave` — Rời
- `POST /api/v1/meetups/:id/invite` — Mời bạn (max 10)
- `GET /api/v1/meetups/:id/invites` — Xem lời mời (host)

### Invites
- `GET /api/v1/invites/pending` — Lời mời đang chờ
- `PUT /api/v1/invites/:id/accept` — Chấp nhận
- `PUT /api/v1/invites/:id/decline` — Từ chối

### Chat
- `GET /api/v1/chat/:roomId/messages` — Lịch sử chat
- `POST /api/v1/chat/:roomId/messages` — Gửi tin nhắn (REST)
- `WS /ws` — WebSocket real-time chat

### Notifications
- `GET /api/v1/notifications` — Danh sách thông báo
- `PUT /api/v1/notifications/:id/read` — Đánh dấu đã đọc
- `PUT /api/v1/notifications/read-all` — Đọc tất cả

## Project Structure

```
connect/
├── server/
│   ├── cmd/api/main.go          # Entry point
│   ├── internal/
│   │   ├── config/              # App config
│   │   ├── database/            # MongoDB + Redis
│   │   ├── middleware/          # JWT, CORS, Rate limit
│   │   ├── model/               # Models + DTOs
│   │   ├── handler/             # API handlers
│   │   ├── ws/                  # WebSocket hub
│   │   └── cron/                # Background jobs
│   ├── migrations/              # DB init scripts
│   ├── Dockerfile
│   └── .env
├── docker-compose.yml
├── Makefile
└── docs/
```
