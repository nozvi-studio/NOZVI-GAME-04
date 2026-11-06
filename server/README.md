# 🎱 Bida WebSocket Server (Realtime 8-Ball Multiplayer)

Máy chủ WebSocket thời gian thực cho trò chơi Bida 8 Bóng (8-Ball Billiards). Hỗ trợ ghép trận tự động 1v1 (Matchmaking), tạo phòng riêng với mã PIN 6 số, và chuyển tiếp gói tin (Relay packets) độ trễ thấp (<30ms).

---

## 🚀 Cách Chạy Server

Bạn có thể chạy server bằng **Node.js** hoặc bằng chính **Dart** có sẵn trong máy!

### Cách 1: Chạy bằng Node.js (Khuyên dùng khi deploy Cloud)
1. Mở terminal tại thư mục này:
   ```bash
   cd server
   npm install
   npm start
   ```
2. Server sẽ lắng nghe tại:
   - WebSocket: `ws://localhost:8080`
   - Healthcheck: `http://localhost:8080/health`

### Cách 2: Chạy trực tiếp bằng Dart (Không cần cài Node.js)
```bash
dart run server/server.dart
```

---

## 🌐 Triển Khai Miễn Phí Lên Internet (Cloud Deploy)

Để bạn bè ở bất kỳ đâu (dùng 4G/5G/WiFi khác nhau) cũng có thể đấu online với bạn:

1. **Deploy lên Render (Render.com) - Hoàn toàn miễn phí**:
   - Đẩy thư mục code lên GitHub.
   - Truy cập [render.com](https://render.com), chọn **New Web Service**.
   - Chọn repository của bạn, cấu hình:
     - **Root Directory**: `server`
     - **Build Command**: `npm install`
     - **Start Command**: `node server.js`
   - Nhận địa chỉ dạng: `wss://bida-game-server.onrender.com`.

2. **Dán địa chỉ server vào game**:
   - Trong game, chọn **ĐẤU ONLINE TOÀN CẦU**.
   - Nhập URL máy chủ (VD: `wss://bida-game-server.onrender.com` hoặc `ws://192.168.1.X:8080` khi test máy thật trong nhà).
