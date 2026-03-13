# Connect — Mô Tả Chức Năng & User Flow

> **Connect** là nền tảng tạo cuộc hẹn gặp mặt trực tiếp.
> Không phải mạng xã hội — không post status, không đăng hình.
> Mục tiêu duy nhất: **giúp mọi người gặp nhau ngoài đời thật.**

---

## 📋 Tổng Quan Chức Năng

| # | Chức năng | Mô tả ngắn |
|---|-----------|-------------|
| 1 | Đăng ký & Đăng nhập | SĐT + OTP, max 2 account/thiết bị |
| 2 | Tạo Profile | Tên, avatar, bio, sở thích, chọn thành phố |
| 3 | Câu lạc bộ (Clubs) | Tạo (max 3)/tham gia CLB, auto-cancel nếu không hoạt động |
| 4 | Tạo cuộc hẹn (Meetup) | Post cuộc hẹn: địa điểm + thời gian + mô tả |
| 5 | **Mời bạn tham gia (Invite)** | **Host mời tối đa 10 members CLB vào cuộc hẹn** |
| 6 | Tham gia cuộc hẹn | Bấm tham gia → tự động vào group chat |
| 7 | Group Chat | Chat nhóm chỉ cho người tham gia cuộc hẹn |
| 8 | Thông báo (Push) | Noti khi có cuộc hẹn gần, có người tham gia, tin nhắn mới |
| 9 | Khám phá (Explore) | Tìm CLB, cuộc hẹn gần đây trên bản đồ |
| 10 | An toàn (Safety) | Xác thực danh tính, báo cáo, chặn, SOS |
| 11 | Đánh giá sau hẹn | Rating & review sau mỗi cuộc hẹn |

---

## 🔄 User Flows Chi Tiết

### Flow 1: Onboarding (Lần đầu mở app)

```
┌─────────────┐     ┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│ Màn hình    │     │ Nhập SĐT     │     │ Xác thực OTP     │     │ Tạo Profile  │
│ Welcome     │────▶│ Đăng ký      │────▶│ (6 số)           │────▶│              │
│ (3 slides)  │     │              │     │                  │     │              │
└─────────────┘     └──────────────┘     └──────────────────┘     └──────┬───────┘
                                                                         │
                                                                         ▼
                                                                  ┌──────────────┐
                                                                  │ Chọn thành   │
                                                                  │ phố & sở     │
                                                                  │ thích        │
                                                                  └──────┬───────┘
                                                                         │
                                                                         ▼
                                                                  ┌──────────────┐
                                                                  │ Gợi ý CLB    │
                                                                  │ phù hợp      │
                                                                  │ → Tham gia   │
                                                                  └──────┬───────┘
                                                                         │
                                                                         ▼
                                                                  ┌──────────────┐
                                                                  │  Home Feed   │
                                                                  │  (Sẵn sàng!) │
                                                                  └──────────────┘
```

**Chi tiết từng bước:**

1. **Welcome screens (3 slides):**
   - Slide 1: "Kết nối bạn bè cùng sở thích"
   - Slide 2: "Tạo cuộc hẹn, gặp nhau ngoài đời"
   - Slide 3: "An toàn & tin cậy" → Nút [Bắt đầu]

2. **Đăng ký:**
   - Nhập số điện thoại
   - Nhận OTP qua SMS → Nhập mã 6 số
   - Tạo mật khẩu (backup login)

3. **Tạo Profile:**
   - Tên hiển thị (bắt buộc)
   - Avatar (bắt buộc — chụp hoặc chọn từ gallery)
   - Bio ngắn (tùy chọn, max 200 ký tự)
   - Ngày sinh + Giới tính

4. **Chọn thành phố & sở thích:**
   - Chọn thành phố đang sống (VD: Hồ Chí Minh, Hà Nội, Đà Nẵng...)
   - Chọn ít nhất 3 sở thích từ danh sách: ☕ Cafe, 📸 Chụp hình, 🏃 Thể thao, 🎮 Gaming, 🎨 Nghệ thuật, 🎵 Âm nhạc, 🍜 Ăn uống, ✈️ Du lịch, 📚 Đọc sách, 🎬 Phim...

5. **Gợi ý CLB:**
   - Dựa trên sở thích đã chọn → Hiện danh sách CLB phù hợp
   - Cho phép skip hoặc tham gia ngay

---

### Flow 2: Khám Phá & Tham Gia Câu Lạc Bộ

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│ Tab Explore  │     │ Danh sách    │     │ Chi tiết CLB     │
│              │────▶│ CLB (filter  │────▶│ - Mô tả          │
│              │     │ by category) │     │ - Số thành viên   │
└──────────────┘     └──────────────┘     │ - Meetups gần đây │
                                          └────────┬─────────┘
                                                   │
                                          Bấm [Tham gia]
                                                   │
                                                   ▼
                                          ┌──────────────────┐
                                          │ ✅ Đã tham gia    │
                                          │ Nhận noti meetup  │
                                          │ mới từ CLB này    │
                                          └──────────────────┘
```

**Chức năng CLB:**
- **Xem CLB:** Tên, mô tả, emoji icon, số thành viên, ảnh bìa
- **Filter:** Theo category (Cafe, Sport, Gaming...) hoặc tìm kiếm tên
- **Tham gia:** Bấm 1 nút → Vào danh sách member → Nhận noti meetup
- **Rời CLB:** Settings → Rời khỏi CLB
- **Tạo CLB mới:** Nếu không tìm thấy CLB phù hợp → Tạo mới

**Tạo CLB mới:**
- Tên CLB
- Mô tả
- Chọn category
- Chọn emoji icon
- Upload ảnh bìa (tùy chọn)
- Public / Private (cần invite code)
- ⚠️ **Giới hạn:** Mỗi user chỉ được tạo tối đa **3 CLB**

**🚨 Auto-Cancel CLB không hoạt động:**

| Thời gian không có meetup | Hành động |
|---------------------------|----------|
| 2 tháng | ⚠️ Cảnh báo admin CLB: "CLB sẽ bị hủy sau 1 tháng nếu không có meetup" |
| 3 tháng | 📦 Tự động ẩn khỏi explore (archived) |
| 4 tháng | ❌ Xóa vĩnh viễn |

> Admin CLB có thể **hồi sinh** bằng cách tạo meetup mới khi CLB còn trong giai đoạn cảnh báo hoặc archived.

---

### Flow 3: Tạo Cuộc Hẹn (Core Feature ⭐)

```
┌──────────────┐     ┌──────────────────────────────────┐
│ Bấm nút     │     │ Form tạo cuộc hẹn               │
│ [+] Tạo hẹn │────▶│                                  │
│ (FAB button) │     │ 1. Chọn CLB (hoặc public)       │
└──────────────┘     │ 2. Tiêu đề cuộc hẹn             │
                     │ 3. Mô tả ngắn                   │
                     │ 4. Chọn địa điểm (Google Maps)   │
                     │ 5. Chọn ngày + giờ              │
                     │ 6. Số người tối đa              │
                     │ 7. Tags (#cafe #chill #sport)    │
                     └───────────────┬──────────────────┘
                                     │
                              Bấm [Đăng]
                                     │
                                     ▼
                     ┌──────────────────────────────────┐
                     │ ✅ Cuộc hẹn đã tạo!              │
                     │                                  │
                     │ → Noti gửi đến members CLB      │
                     │   + users gần vị trí meetup     │
                     │                                  │
                     │ → Auto tạo group chat room      │
                     │   (host là participant đầu tiên) │
                     │                                  │
                     │ → Hiện popup: "Mời bạn trong    │
                     │   CLB tham gia?" [Mời] [Bỏ qua] │
                     └──────────────────────────────────┘
```

**Ví dụ cuộc hẹn:**
```
┌────────────────────────────────────────┐
│ ☕ Cafe & Chụp hình chiều nay          │
│                                        │
│ 📍 Cộng Cà Phê, 26 Lý Tự Trọng, Q.1  │
│ ⏰ Hôm nay, 15:00 - 17:00             │
│ 👥 3/6 người                           │
│                                        │
│ "Ai rảnh chiều nay ra Cộng chụp        │
│  hình không? Mang máy ảnh nha 📸"      │
│                                        │
│ 🏷️ #cafe #photography #chill           │
│                                        │
│ ┌────────────┐ ┌──────────┐ ┌───────┐  │
│ │ Tham gia ▶ │ │ ✉️ Mời   │ │💬 (3) │  │
│ └────────────┘ └──────────┘ └───────┘  │
│                                        │
│ Tạo bởi: Loan ✅  •  còn 2 giờ nữa    │
└────────────────────────────────────────┘
```
> Nút **✉️ Mời** chỉ hiển thị cho **Host** của cuộc hẹn.

**Templates nhanh (Quick Create):**
- ☕ **Cafe:** Pre-fill category + tags
- 🍜 **Ăn uống:** Pre-fill category + tags
- 🏃 **Thể thao:** Pre-fill category + tags
- 🎮 **Gaming:** Pre-fill category + tags
- 🎬 **Xem phim:** Pre-fill category + tags
- ✏️ **Tùy chỉnh:** Tự điền từ đầu

---

### Flow 3.5: Mời Bạn Trong CLB Tham Gia Cuộc Hẹn (Invite) ⭐

```
┌──────────────────┐     ┌──────────────────────────────────┐
│ Host bấm nút     │     │ Danh sách members CLB            │
│ [✉️ Mời] trên    │────▶│                                  │
│ meetup card      │     │ ┌────────────────────────────┐   │
│                  │     │ │ 🔍 Tìm tên...              │   │
│ HOẶC             │     │ └────────────────────────────┘   │
│                  │     │                                  │
│ Popup sau khi    │     │ ☐ 👤 Minh          Online 🟢    │
│ tạo meetup       │     │ ☑ 👤 Hương         Online 🟢    │
└──────────────────┘     │ ☑ 👤 Tuấn          2h trước     │
                         │ ☐ 👤 Linh          5h trước     │
                         │ ☑ 👤 Khoa          Online 🟢    │
                         │ ☐ 👤 Mai           1 ngày       │
                         │ ...                              │
                         │                                  │
                         │ Đã chọn: 3/10                    │
                         │                                  │
                         │ ┌──────────────────────────────┐ │
                         │ │   Gửi lời mời (3 người) ▶   │ │
                         │ └──────────────────────────────┘ │
                         └────────────────┬─────────────────┘
                                          │
                                   Bấm [Gửi]
                                          │
                                          ▼
                         ┌──────────────────────────────────┐
                         │ ✅ Đã gửi lời mời!               │
                         │                                  │
                         │ → 3 người nhận push noti:       │
                         │   "Loan mời bạn: Cafe & Chụp    │
                         │    hình tại Cộng lúc 15:00"     │
                         │                                  │
                         │ → Noti có 2 nút:                │
                         │   [Tham gia ngay] [Từ chối]     │
                         └──────────────────────────────────┘
```

**Quy tắc mời:**
- Chỉ **Host** (người tạo meetup) mới được mời
- Chỉ mời được **members trong cùng CLB** của meetup
- Tối đa **10 lời mời** mỗi meetup (tránh spam)
- Mỗi user chỉ nhận **1 lời mời** cho 1 meetup (không spam lại)
- Người được mời có thể: **Tham gia** hoặc **Từ chối**
- Từ chối = host không biết ai từ chối (tránh awkward)
- Lời mời **hết hạn** khi meetup bắt đầu hoặc đầy người
- Host có thể xem trạng thái: Đã mời (⏳) / Đã tham gia (✅) / Hết hạn (⌛)

**Trạng thái lời mời:**
```
  Gửi mời         Người nhận hành động        Meetup đầy/bắt đầu
     │                    │                          │
     ▼                    ▼                          ▼
 ┌────────┐    ┌───────────────────┐          ┌───────────┐
 │PENDING │───▶│ ACCEPTED (auto    │          │ EXPIRED   │
 │  ⏳     │    │ join meetup+chat) │          │   ⌛      │
 └────────┘    └───────────────────┘          └───────────┘
     │
     ▼
 ┌────────┐
 │DECLINED│
 │  (ẩn)  │
 └────────┘
```

---

### Flow 4: Tham Gia Cuộc Hẹn & Vào Group Chat

```
┌──────────────┐     ┌──────────────┐     ┌──────────────────┐
│ Nhận Noti    │     │ Xem chi tiết │     │ Bấm [Tham gia]  │
│ "Có meetup   │────▶│ cuộc hẹn     │────▶│                  │
│  gần bạn!"   │     │              │     │                  │
└──────────────┘     └──────────────┘     └────────┬─────────┘
                                                    │
                                                    ▼
                                          ┌──────────────────┐
                                          │ ✅ Đã tham gia    │
                                          │                  │
                                          │ → Vào group chat │
                                          │ → System msg:    │
                                          │   "Minh đã       │
                                          │    tham gia"     │
                                          │ → Host nhận noti │
                                          └────────┬─────────┘
                                                   │
                                                   ▼
                                          ┌──────────────────┐
                                          │ 💬 Group Chat     │
                                          │                  │
                                          │ Chỉ participants │
                                          │ mới vào được     │
                                          │                  │
                                          │ Chat realtime    │
                                          │ + Chia sẻ vị trí │
                                          └──────────────────┘
```

**Quy tắc tham gia:**
- Chỉ được tham gia nếu cuộc hẹn chưa đầy (current < max)
- Chỉ được tham gia nếu cuộc hẹn chưa diễn ra
- Host có thể kick participant
- Participant có thể rời bất cứ lúc nào
- ❌ **KHÔNG THỂ** xem chat nếu chưa tham gia

---

### Flow 5: Group Chat

```
┌──────────────────────────────────────────────┐
│ 💬 Cafe & Chụp hình chiều nay  (4 người)    │
├──────────────────────────────────────────────┤
│                                              │
│ 🤖 System: Loan đã tạo cuộc hẹn             │
│ 🤖 System: Minh đã tham gia                 │
│ 🤖 System: Hương đã tham gia                │
│                                              │
│ 👤 Loan: Chào mọi người! Mang máy ảnh nha   │
│                                              │
│ 👤 Minh: Okk mình sẽ đến sớm 15p            │
│                                              │
│ 👤 Hương: Mình đang ở gần đó, tí tới 😄     │
│                                              │
│ 🤖 System: Cuộc hẹn bắt đầu lúc 15:00!     │
│                                              │
│ 👤 Loan: 📍 Tôi ở đây [Chia sẻ vị trí]      │
│                                              │
├──────────────────────────────────────────────┤
│ [📍 Vị trí]  [Nhập tin nhắn...    ] [Gửi ▶] │
└──────────────────────────────────────────────┘
```

**Tính năng chat:**
- Tin nhắn text realtime
- Chia sẻ vị trí (pin trên map) — giúp tìm nhau dễ hơn
- System messages (tham gia, rời nhóm, meetup bắt đầu/kết thúc)
- Chat **vẫn giữ** sau meetup kết thúc (để mọi người liên lạc tiếp nếu muốn)
- Không cho gửi hình/video (giữ app đơn giản, tránh nội dung xấu)

---

### Flow 6: Sau Cuộc Hẹn (Post-Meetup)

```
┌──────────────┐     ┌──────────────────┐     ┌──────────────┐
│ Cuộc hẹn     │     │ Pop-up đánh giá  │     │ Gợi ý hành  │
│ kết thúc     │────▶│                  │────▶│ động tiếp    │
│ (auto)       │     │ "Buổi hẹn thế   │     │ theo         │
└──────────────┘     │  nào?"           │     └──────┬───────┘
                     │                  │            │
                     │ ⭐⭐⭐⭐⭐          │     ┌──────▼───────┐
                     │                  │     │ • Kết bạn?   │
                     │ [Bình luận ngắn] │     │ • Tạo hẹn    │
                     │                  │     │   tiếp?      │
                     │ [Gửi đánh giá]   │     │ • Báo cáo?   │
                     └──────────────────┘     └──────────────┘
```

**Chi tiết:**
1. Khi `end_time` đến → Meetup tự chuyển status "Completed"
2. Mỗi participant nhận pop-up đánh giá (sau 30 phút kết thúc)
3. Rating 1-5 sao cho trải nghiệm tổng thể
4. Tùy chọn: Gửi lời kết bạn cho từng participant

---

### Flow 7: Thông Báo (Notifications)

**Các loại thông báo:**

| Trigger | Nội dung noti | Ai nhận |
|---------|--------------|---------|
| Meetup mới trong CLB | "☕ Meetup mới: Cafe tại Cộng lúc 15:00" | Members CLB + users gần đó |
| **Lời mời tham gia** | **"Loan mời bạn: Cafe & Chụp hình tại Cộng 15:00" [Tham gia] [Từ chối]** | **Members CLB được mời (max 10)** |
| **Chấp nhận lời mời** | **"Minh đã chấp nhận lời mời cuộc hẹn của bạn"** | **Host** |
| Có người tham gia | "Minh đã tham gia cuộc hẹn của bạn" | Host |
| Tin nhắn mới | "Loan: Mang máy ảnh nha 📸" | Tất cả participants |
| Meetup sắp bắt đầu | "⏰ Cuộc hẹn bắt đầu sau 30 phút!" | Tất cả participants |
| Meetup đầy | "Cuộc hẹn đã đủ người!" | Host |
| Có người rời | "Hương đã rời cuộc hẹn" | Host |
| Lời mời kết bạn | "Loan muốn kết bạn với bạn" | User được mời |

**Cài đặt thông báo:**
- Bật/tắt từng loại noti
- Chỉnh bán kính nhận noti (1km - 20km)
- Giờ im lặng (VD: 22:00 - 07:00)

---

### Flow 8: Home Feed

```
┌──────────────────────────────────────────────┐
│ 📍 Hồ Chí Minh           [🔔] [👤]          │
├──────────────────────────────────────────────┤
│                                              │
│ ┌──── Filter Bar ─────────────────────────┐  │
│ │ [Tất cả] [☕Cafe] [🏃Sport] [🎮Game] ▶  │  │
│ └─────────────────────────────────────────┘  │
│                                              │
│ ┌── Đang diễn ra ────────────────────────┐  │
│ │ 🟢 Cafe tại Highlands    2.3km         │  │
│ │    ⏰ Bắt đầu 10 phút trước            │  │
│ │    👥 4/6 người                         │  │
│ └────────────────────────────────────────┘  │
│                                              │
│ ┌── Sắp tới ─────────────────────────────┐  │
│ │ ☕ Cafe & Chụp hình       1.5km         │  │
│ │    📍 Cộng Cà Phê, Q.1                 │  │
│ │    ⏰ Hôm nay 15:00 • còn 2 giờ        │  │
│ │    👥 3/6 người                         │  │
│ │    Bởi: Loan ✅                         │  │
│ └────────────────────────────────────────┘  │
│                                              │
│ ┌──────────────────────────────────────────┐ │
│ │ 🏃 Chạy bộ Landmark 81     3.1km       │ │
│ │    📍 Công viên Vinhomes               │ │
│ │    ⏰ Ngày mai 06:00                    │ │
│ │    👥 5/10 người                        │ │
│ └──────────────────────────────────────────┘ │
│                                              │
├──────────────────────────────────────────────┤
│                                              │
│     [🏠]    [🗺️]    [➕]    [💬]    [👤]     │
│     Home    Map    Tạo    Chat   Profile    │
│                                              │
└──────────────────────────────────────────────┘
```

---

### Flow 9: Map View (Bản đồ)

```
┌──────────────────────────────────────────────┐
│ [🔍 Tìm khu vực...]            [📋 List]    │
├──────────────────────────────────────────────┤
│                                              │
│      🗺️ Google Maps                         │
│                                              │
│         ☕(3)                                │
│                  🏃(1)                       │
│     📍(bạn)                                  │
│                        🎮(2)                 │
│              🍜(1)                           │
│                                              │
│  ┌─── Tap vào pin ──────────────────────┐    │
│  │ ☕ Cafe & Chụp hình    │  [Xem ▶]   │    │
│  │ Cộng Q.1 • 15:00      │             │    │
│  │ 👥 3/6 • ⭐ 4.5        │             │    │
│  └───────────────────────────────────────┘   │
│                                              │
├──────────────────────────────────────────────┤
│     [🏠]    [🗺️]    [➕]    [💬]    [👤]     │
└──────────────────────────────────────────────┘
```

---

## 🔒 Safety Features

### Xác thực danh tính
- Upload CCCD/CMND → Admin duyệt → Badge ✅
- Meetup từ user verified → Hiện badge rõ ràng
- Filter: Chỉ xem meetup từ user verified

### Báo cáo & Chặn
- Mỗi profile/meetup có nút "..." → Báo cáo / Chặn
- Lý do báo cáo: Hành vi xấu, Thông tin giả, Spam, Khác
- Admin review → Cảnh cáo / Khóa tài khoản

### Emergency SOS
- Cài đặt → Chọn "Liên hệ khẩn cấp" (SĐT người thân)
- Khi đang trong meetup → Nút SOS
- Bấm giữ 3 giây → Gửi SMS vị trí hiện tại cho người thân

---

## 📱 Navigation Structure (Bottom Tabs)

| Tab | Icon | Chức năng |
|-----|------|-----------|
| **Home** | 🏠 | Feed cuộc hẹn gần đây + từ CLB đã join |
| **Map** | 🗺️ | Bản đồ meetup xung quanh |
| **Create** | ➕ | Tạo cuộc hẹn mới (FAB button nổi bật) |
| **Chat** | 💬 | Danh sách group chat (meetup đã tham gia) |
| **Profile** | 👤 | Profile, CLB đã join, settings |

---

## 📊 Trạng Thái Cuộc Hẹn (Meetup Status)

```
    Tạo mới          Có người join       Đến giờ           Hết giờ
       │                  │                │                 │
       ▼                  ▼                ▼                 ▼
   ┌────────┐      ┌───────────┐    ┌───────────┐    ┌───────────┐
   │  OPEN  │─────▶│   OPEN    │───▶│  ONGOING  │───▶│ COMPLETED │
   │        │      │ (3/6)     │    │           │    │           │
   └────────┘      └───────────┘    └───────────┘    └───────────┘
       │                │                                   │
       ▼                ▼                                   ▼
   ┌────────┐      ┌───────────┐                    ┌───────────┐
   │CANCELLED│     │   FULL    │                    │  RATING   │
   │(by host)│     │  (6/6)    │                    │  PHASE    │
   └────────┘      └───────────┘                    └───────────┘
```

---

## 🚀 MVP Scope (Đề xuất phiên bản đầu tiên)

### ✅ Có trong MVP
1. Đăng ký / Đăng nhập (SĐT + OTP)
2. Tạo & chỉnh sửa profile
3. Chọn thành phố
4. Duyệt & tham gia CLB
5. Tạo cuộc hẹn (trong CLB hoặc public)
6. **Mời members CLB tham gia cuộc hẹn (max 10 người)**
7. Tham gia cuộc hẹn
8. Group chat (text only)
9. Push notifications (meetup mới, lời mời, tin nhắn)
10. Report & Block cơ bản

### ❌ Chưa có trong MVP (Phase 2+)
- Map view
- Kết bạn (Friend list) & chat 1-1
- Xác thực CCCD
- Đánh giá sau meetup
- Recurring meetups
- Emergency SOS
- AI matching / gợi ý
- Quick create templates
