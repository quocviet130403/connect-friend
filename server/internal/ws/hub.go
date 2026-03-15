package ws

import (
	"context"
	"encoding/json"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/connect-app/server/internal/model"
	"github.com/gorilla/websocket"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins in dev
	},
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

// Client represents a single WebSocket connection
type Client struct {
	hub    *Hub
	conn   *websocket.Conn
	send   chan []byte
	userID string
	rooms  map[string]bool // roomID -> joined
}

// Hub manages all WebSocket connections
type Hub struct {
	clients    map[*Client]bool
	rooms      map[string]map[*Client]bool // roomID -> clients
	register   chan *Client
	unregister chan *Client
	broadcast  chan *RoomMessage
	mu         sync.RWMutex
	messages   *mongo.Collection
}

type RoomMessage struct {
	RoomID  string          `json:"room_id"`
	Message json.RawMessage `json:"message"`
}

type WSMessage struct {
	Type    string          `json:"type"` // join_room, leave_room, send_message
	RoomID  string          `json:"room_id"`
	Payload json.RawMessage `json:"payload,omitempty"`
}

type ChatMessagePayload struct {
	Content     string `json:"content"`
	MessageType string `json:"message_type"`
}

type BroadcastMessage struct {
	Type      string      `json:"type"` // new_message, user_joined, user_left
	RoomID    string      `json:"room_id"`
	SenderID  string      `json:"sender_id"`
	Content   string      `json:"content"`
	Timestamp time.Time   `json:"timestamp"`
	Data      interface{} `json:"data,omitempty"`
}

func NewHub(db *mongo.Database) *Hub {
	return &Hub{
		clients:    make(map[*Client]bool),
		rooms:      make(map[string]map[*Client]bool),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		broadcast:  make(chan *RoomMessage, 256),
		messages:   db.Collection("chat_messages"),
	}
}

func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			h.mu.Unlock()
			log.Printf("Client connected: %s", client.userID)

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
				// Remove from all rooms
				for roomID := range client.rooms {
					if room, ok := h.rooms[roomID]; ok {
						delete(room, client)
						if len(room) == 0 {
							delete(h.rooms, roomID)
						}
					}
				}
			}
			h.mu.Unlock()
			log.Printf("Client disconnected: %s", client.userID)

		case msg := <-h.broadcast:
			h.mu.RLock()
			if room, ok := h.rooms[msg.RoomID]; ok {
				for client := range room {
					select {
					case client.send <- msg.Message:
					default:
						close(client.send)
						delete(room, client)
					}
				}
			}
			h.mu.RUnlock()
		}
	}
}

func (h *Hub) HandleWebSocket(w http.ResponseWriter, r *http.Request, userID string) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	client := &Client{
		hub:    h,
		conn:   conn,
		send:   make(chan []byte, 256),
		userID: userID,
		rooms:  make(map[string]bool),
	}

	h.register <- client

	go client.writePump()
	go client.readPump()
}

func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()

	c.conn.SetReadLimit(4096)
	c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	c.conn.SetPongHandler(func(string) error {
		c.conn.SetReadDeadline(time.Now().Add(60 * time.Second))
		return nil
	})

	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			break
		}

		var wsMsg WSMessage
		if err := json.Unmarshal(message, &wsMsg); err != nil {
			continue
		}

		switch wsMsg.Type {
		case "join_room":
			c.hub.mu.Lock()
			if _, ok := c.hub.rooms[wsMsg.RoomID]; !ok {
				c.hub.rooms[wsMsg.RoomID] = make(map[*Client]bool)
			}
			c.hub.rooms[wsMsg.RoomID][c] = true
			c.rooms[wsMsg.RoomID] = true
			c.hub.mu.Unlock()

		case "leave_room":
			c.hub.mu.Lock()
			if room, ok := c.hub.rooms[wsMsg.RoomID]; ok {
				delete(room, c)
			}
			delete(c.rooms, wsMsg.RoomID)
			c.hub.mu.Unlock()

		case "send_message":
			var payload ChatMessagePayload
			if err := json.Unmarshal(wsMsg.Payload, &payload); err != nil {
				continue
			}

			msgType := payload.MessageType
			if msgType == "" {
				msgType = "text"
			}

			// Save to MongoDB
			senderObjID, _ := primitive.ObjectIDFromHex(c.userID)
			roomObjID, _ := primitive.ObjectIDFromHex(wsMsg.RoomID)

			chatMsg := model.ChatMessage{
				RoomID:      roomObjID,
				SenderID:    senderObjID,
				Content:     payload.Content,
				MessageType: msgType,
				CreatedAt:   time.Now(),
			}

			ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
			result, _ := c.hub.messages.InsertOne(ctx, chatMsg)
			cancel()

			if result != nil {
				chatMsg.ID = result.InsertedID.(primitive.ObjectID)
			}

			// Broadcast to room
			broadcastMsg := BroadcastMessage{
				Type:      "new_message",
				RoomID:    wsMsg.RoomID,
				SenderID:  c.userID,
				Content:   payload.Content,
				Timestamp: chatMsg.CreatedAt,
				Data:      chatMsg,
			}
			msgBytes, _ := json.Marshal(broadcastMsg)
			c.hub.broadcast <- &RoomMessage{
				RoomID:  wsMsg.RoomID,
				Message: msgBytes,
			}

		case "mark_read":
			userObjID, _ := primitive.ObjectIDFromHex(c.userID)
			roomObjID, _ := primitive.ObjectIDFromHex(wsMsg.RoomID)
			now := time.Now()

			// Mark all unread messages in this room as read by this user
			ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
			c.hub.messages.UpdateMany(ctx, map[string]interface{}{
				"room_id": roomObjID,
				"read_by.user_id": map[string]interface{}{
					"$ne": userObjID,
				},
			}, map[string]interface{}{
				"$addToSet": map[string]interface{}{
					"read_by": model.ReadReceipt{
						UserID: userObjID,
						ReadAt: now,
					},
				},
			})
			cancel()

			// Broadcast read_update to room
			readUpdate := BroadcastMessage{
				Type:      "read_update",
				RoomID:    wsMsg.RoomID,
				SenderID:  c.userID,
				Timestamp: now,
			}
			readBytes, _ := json.Marshal(readUpdate)
			c.hub.broadcast <- &RoomMessage{
				RoomID:  wsMsg.RoomID,
				Message: readBytes,
			}
		}
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(30 * time.Second)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()

	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			c.conn.WriteMessage(websocket.TextMessage, message)

		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(10 * time.Second))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}
