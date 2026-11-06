# 🎱 BẢN THIẾT KẾ TRÒ CHƠI (GAME DESIGN DOCUMENT - GDD)
## TỰA GAME: 8-BALL BILLIARDS 2D (BIDA 8 BÓNG ĐỈNH CAO)

> **Tài Liệu Thiết Kế Trò Chơi Chính Thức (Official Game Design Document)**  
> **Phiên bản tài liệu:** 2.5 (Production Ready & Live-Ops)  
> **Nền tảng mục tiêu:** Mobile First (Android / iOS Xoay Ngang - Landscape 16:9), Mở rộng Web (HTML5/Canvas) & Desktop  
> **Công nghệ lõi:** Flutter Framework • Flame Game Engine • Forge2D (Box2D Physics) • Node.js WebSocket Server • Firebase Cloud  
> **Hệ thống ngôn ngữ:** 5 Ngôn ngữ phản ứng thời gian thực (**Tiếng Việt, English, 中文, 日本語, 한국어**)

---

## 📑 MỤC LỤC TỔNG QUAN

1. [Định Vị Sản Phẩm & Tầm Nhìn Thiết Kế (Vision & Pillars)](#1-định-vị-sản-phẩm--tầm-nhìn-thiết-kế)
2. [Vòng Lặp Trò Chơi (Core & Meta Loops)](#2-vòng-lặp-trò-chơi)
3. [Cơ Chế Vật Lý & Điều Khiển Bắn Bi (Core Mechanics & Physics UX)](#3-cơ-chế-vật-lý--điều-khiển-bắn-bi)
4. [Quy Tắc Luật Chơi Chuẩn Quốc Tế (Ruleset Specifications)](#4-quy-tắc-luật-chơi-chuẩn-quốc-tế)
5. [Hệ Sinh Thái 8 Chế Độ Chơi (Game Modes Specification)](#5-hệ-sinh-thái-8-chế-độ-chơi)
6. [Kho Tàng 112 Thế Đánh Huyền Thoại (14 Danh Thủ Thế Giới)](#6-kho-tàng-112-thế-đánh-huyền-thoại)
7. [Kiến Trúc Đấu Mạng Kép (Local WiFi P2P & Online WebSocket Server)](#7-kiến-trúc-đấu-mạng-kép)
8. [Hệ Thống RPG Gậy Cơ, Thành Tựu & Tiến Trình (Progression & RPG Systems)](#8-hệ-thống-rpg-gậy-cơ-thành-tựu--tiến-trình)
9. [Kinh Tế Trong Game (In-Game Economy: Sources & Sinks)](#9-kinh-tế-trong-game)
10. [Hệ Thống Bản Địa Hóa Đa Ngôn Ngữ Phản Ứng (Localization Engine)](#10-hệ-thống-bản-địa-hóa-đa-ngôn-ngữ-phản-ứng)
11. [Thiết Kế Giao Diện Người Dùng & Trải Nghiệm Cảm Ứng (UI/UX Design System)](#11-thiết-kế-giao-diện-người-dùng--trải-nghiệm-cảm-ứng)
12. [Lộ Trình Sản Phẩm & Kế Hoạch Vận Hành (Roadmap & Live-Ops)](#12-lộ-trình-sản-phẩm--kế-hoạch-vận-hành)

---

## 1. ĐỊNH VỊ SẢN PHẨM & TẦM NHÌN THIẾT KẾ

### 1.1. Tuyên Ngôn Dự Án
**8-Ball Billiards 2D** là tựa game thể thao bida mô phỏng vật lý chân thực kết hợp yếu tố tiến trình RPG nhẹ nhàng, hướng đến việc mang lại cảm giác chạm-bắn chân thực, chuẩn xác từng milimet cho game thủ di động toàn cầu. Game dung hòa hoàn hảo giữa tính giải trí thư giãn (casual) và chiều sâu chiến thuật hình học đối kháng đỉnh cao (mid-core esports).

### 1.2. Trụ Cột Thiết Kế Cốt Lõi (Core Pillars)
1. **Vật Lý Chuẩn Xác & Cảm Giác Cơ Chân Thực**:
   - Sử dụng động cơ vật lý Box2D (Forge2D) mô phỏng chính xác va chạm đàn hồi, ma sát nỉ, độ nảy góc băng và hiệu ứng xoáy áp-phê 2D (Cu-lê, Trô bóng, Áp-phê ngang).
2. **Hạ Tầng Đấu Mạng Kép Đột Phá**:
   - Không chỉ hỗ trợ Đấu mạng Online WebSocket toàn cầu (Auto-Matchmaking & Mã PIN 6 số), game tích hợp sẵn Đấu mạng Local WiFi P2P tự động dò phòng siêu tốc độ trễ <15ms mà không cần kết nối Internet.
3. **Bộ Sưu Tập Di Sản 112 Thế Đánh Huyền Thoại**:
   - Tái hiện trọn vẹn 112 đường cơ kinh điển của 14 danh thủ bida lẫy lừng thế giới, kết hợp hướng dẫn kỹ thuật chi tiết và mô tả lịch sử thực tế.
4. **Trải Nghiệm Cảm Ứng Công Thái Học Chống Lỗi (Ergonomic Touch UX)**:
   - Hệ thống thanh kéo lực kết hợp chế độ Khóa lực (Power Lock), thước ngắm vi chỉnh $0.1^\circ$ và bánh răng 1mm triệt tiêu hoàn toàn nhược điểm rung tay hoặc che khuất tầm nhìn trên màn hình cảm ứng.
5. **Khả Năng Tiếp Cận Toàn Cầu 100% (5 Ngôn Ngữ)**:
   - Bản địa hóa đồng bộ từ HUD, thông điệp luật chơi, 112 thế đánh, 10 ải bot cho đến lỗi Firebase sang 5 ngôn ngữ lớn (**Tiếng Việt, English, 中文, 日本語, 한국어**) với khả năng đổi ngôn ngữ tức thì trong tích tắc.

---

## 2. VÒNG LẶP TRÒ CHƠI

Kiến trúc trò chơi vận hành theo 3 tầng vòng lặp lồng ghép chặt chẽ, tối ưu hóa tỷ lệ giữ chân người chơi (Retention) từ phiên chơi ngắn trong ngày đến mục tiêu dài hạn hàng tháng:

```
+---------------------------------------------------------------------------------------------------+
|                                  RETENTION LOOP (Tuần / Tháng)                                    |
|  - Bảng Xếp Hạng Toàn Cầu 3 Bảng (Level, Coins, Wins)   - Sưu tập 10 Huy Chương Danh Dự (Medals)   |
|  - Chinh phục 112 Thế Đánh Huyền Thoại                  - Vô địch Tournament 5 Brackets Knockout   |
+---------------------------------------------------------------------------------------------------+
                                                  ^
                                                  | (Tích lũy XP, Cúp Vàng, Huy Chương, Kim Cương)
+---------------------------------------------------------------------------------------------------+
|                                    META GAME LOOP (Hàng Ngày)                                     |
|  [Đấu Online / Local Cược Vàng] ---> [Cày Cấp Độ Mở Shop] ---> [Nâng Cấp Gậy Lv.1-10]             |
|                ^                                                                 |                |
|                |------------ [Chiến Dịch 10 Ải Bot] <----------------------------+                |
|                |                                                                 |                |
|                +------------ [Giải Đố Thế Bi Hàng Ngày] <------------------------+                |
+---------------------------------------------------------------------------------------------------+
                                                  ^
                                                  | (Vàng, XP, Kim Cương, Nâng cấp chỉ số)
+---------------------------------------------------------------------------------------------------+
|                                    CORE GAME LOOP (Trong Ván)                                     |
|  [Vào Bàn] -> [Đọc Thế Bi] -> [Căn Áp-phê / Lực / Thước 1mm] -> [Bắn Cơ] -> [VFX & Phân Định]     |
+---------------------------------------------------------------------------------------------------+
```

- **Core Loop (3 - 5 phút/ván)**: Đọc vị trí bi trên bàn $\to$ Tinh chỉnh hướng bắn & áp-phê $\to$ Kéo lực cơ $\to$ Bi va chạm & rơi vào lỗ $\to$ Nhận thưởng tức thì.
- **Meta Loop (Hàng ngày)**: Thi đấu PvP cược tiền $\to$ Thu thập Vàng & Kim Cương $\to$ Mở khóa và nâng cấp gậy cơ Lv.1 - 10 $\to$ Vượt Ải Bot & Giải Đố thế bi.
- **Retention Loop (Hàng tuần / tháng)**: Chinh phục trọn bộ 112 thế đánh huyền thoại $\to$ Săn 14 thành tựu & 10 huy chương $\to$ Leo Top Bảng xếp hạng thế giới.

---

## 3. CƠ CHẾ VẬT LÝ & ĐIỀU KHIỂN BẮN BI

### 3.1. Mô Phỏng Vật Lý Box2D (Forge2D Engine)
- **Hệ quy chiếu & Tỷ lệ chuẩn hóa**: Mặt bàn bida tỷ lệ thực tế $2:1$, độ co giãn thích ứng theo màn hình 16:9.
- **Hệ số va chạm đàn hồi (Restitution)**: Đạt mức $0.98$ giữa bi với bi, tạo độ truyền lực bi nổ dứt khoát.
- **Ma sát nỉ (Linear & Angular Damping)**: Giảm tốc tuyến tính tự nhiên mô phỏng lực cản lăn của thảm nỉ len cao cấp.
- **Hệ số nảy băng cao su (Cushion Rebound)**: Đảm bảo góc phản xạ ăn khớp góc tới, biến đổi linh hoạt theo lực ép và độ xoáy ngang.

### 3.2. Động Học Xoáy Bi Cái 2D (Cue Ball Spin Dynamics)
Người chơi chạm vào nút bi cái ở góc phải màn hình để định vị điểm tiếp xúc đầu cơ $(dx, dy)$ trên mặt bi:
- **Tâm Bi (Center Shot - $dx=0, dy=0$)**: Lực truyền thẳng tâm, bi cái dừng chết (Stun) khi va chạm trực diện.
- **Cu-lê (Topspin Follow - $dy < 0$)**: Bi cái xoay cuộn tới trước, phóng vụt lên theo đà sau khi va chạm với bi mục tiêu.
- **Trô Bóng (Backspin Draw - $dy > 0$)**: Bi cái xoay giật lùi, hãm phanh và lùi ngược về sau ngoạn mục.
- **Áp-phê Ngang (English Side Spin - $dx \neq 0$)**: Đổi góc nảy khi bi cái đập vào thành băng, mở rộng hoặc thu hẹp góc phản xạ.

### 3.3. Bộ Điều Khiển Công Thái Học Đa Chiều (Ergonomic Controls)
- **Thanh lực bắn (Left Power Slider)**: Bố trí bên trái màn hình cho ngón cái tay trái, kéo lún cơ mượt mà, chuyển dải màu neon từ Xanh $\to$ Vàng $\to$ Đỏ rực.
- **Chế độ Khóa Lực (Power Lock Mode)**: Chạm nút tròn ở đáy thanh lực để khóa chết mức lực; người chơi có thể thoải mái nhấc tay ngắm lại góc mà không sợ bị trượt bắn nhầm, chạm lại nút tròn để kích hoạt bắn.
- **Thước ngắm vi chỉnh (Right Aim Ruler)**: Bố trí bên phải cho ngón cái tay phải, tinh chỉnh góc quay từng $0.1^\circ$.
- **Cặp nút bánh răng 1mm (Fine Tune Gear)**: Nhích nhẹ cây cơ sang trái/phải 1mm, giải quyết triệt để lỗi rung ngón tay trên màn hình cảm ứng.

---

## 4. QUY TẮC LUẬT CHƠI CHUẨN QUỐC TẾ

Trò chơi áp dụng chuẩn luật thi đấu **World Pool-Billiard Association (WPA 8-Ball)**:

### 4.1. Phân Chia Nhóm Bi
- Bàn đấu gồm 1 Bi Cái (Trắng) và 15 bi mục tiêu chia làm 2 nhóm:
  - **Nhóm Bi Trơn (Solids)**: Số từ **1 đến 7** (màu đơn sắc).
  - **Nhóm Bi Sọc (Stripes)**: Số từ **9 đến 15** (sọc trắng ở giữa).
  - **Bi Đen Số 8**: Bi quyết định số phận ván đấu.
- Nhóm bi của mỗi cơ thủ chỉ được ấn định sau cú đánh hợp lệ đầu tiên đưa bi vào lỗ sau lượt khai cuộc.

### 4.2. Trình Tự Đánh & Lượt Đánh
- Cơ thủ phải đánh bi cái chạm nhóm bi của mình đầu tiên.
- Đưa hợp lệ ít nhất một bi nhóm mình vào lỗ $\to$ **Được tiếp tục đánh**.
- Không ăn bi hoặc phạm lỗi $\to$ **Chuyển lượt cho đối thủ**.

### 4.3. Các Lỗi Phạm Luật (Foul)
Người chơi bị xử phạt lỗi nếu:
1. Đánh bi cái rơi vào lỗ (Scratch).
2. Bi cái không chạm vào bất kỳ quả bi nào trên bàn.
3. Bi cái chạm bi đối thủ hoặc chạm bi số 8 đầu tiên (khi chưa dọn sạch nhóm của mình).
4. Bi cái và bi mục tiêu sau va chạm không có quả nào chạm thành băng hoặc rơi vào lỗ.

### 4.4. Quyền Đặt Bi Tự Do (Ball-in-Hand)
- Khi đối phương phạm lỗi, người chơi nhận quyền **Ball-in-Hand**: được tự do nhấc và đặt bi cái ở bất kỳ vị trí nào trên mặt bàn. Trong chế độ Đấu mạng, tọa độ đặt bi được đồng bộ hóa tức thì sang máy đối thủ.

### 4.5. Phân Định Thắng / Thua Tuyệt Đối
- **THẮNG VÁN ĐẤU**: Dọn sạch 7 bi thuộc nhóm của mình và sau đó đánh bi số 8 vào lỗ một cách hợp lệ.
- **XỬ THUA NGAY LẬP TỨC (Instant Loss)**:
  - Đánh rơi bi số 8 vào lỗ khi chưa dọn sạch nhóm bi của mình.
  - Đánh rơi bi số 8 đồng thời làm rơi bi cái vào lỗ.
  - Làm bi số 8 văng ra khỏi bàn thi đấu.

---

## 5. HỆ SINH THÁI 8 CHẾ ĐỘ CHƠI

| STT | Chế Độ Chơi | Cơ Chế & Mục Tiêu | Yếu Tố Kích Thích | Cơ Chế Phần Thưởng | Trạng Thái |
| :---: | :--- | :--- | :--- | :--- | :---: |
| **1** | **Chơi 2 Người (Pass & Play)** | 2 người chơi luân phiên trên 1 màn hình | So tài offline cùng bạn bè gia đình | Ghi nhận tỷ số, rèn luyện kỹ năng | ✅ **Hoàn thành** |
| **2** | **Đấu Với Máy (Vs CPU)** | Luyện tập với Bot Dễ / Khó | Rèn luyện góc ngắm, thử nghiệm áp-phê | Thưởng EXP cơ bản | ✅ **Hoàn thành** |
| **3** | **Chiến Dịch Vượt Ải Bot (10 Ải)** | 10 Ải AI phân cấp qua 4 Tầng Hạng (Tiers) | Đối đầu AI biết áp-phê & giấu bi an toàn | Thưởng lớn Vàng, Kim Cương & EXP | ✅ **Hoàn thành** |
| **4** | **112 Thế Đánh Huyền Thoại** | Tái hiện 112 đường cơ của 14 danh thủ | Chinh phục các cú đánh lịch sử thế giới | Vàng, Kim Cương, Danh hiệu Danh thủ | ✅ **Hoàn thành** |
| **5** | **Thế Bi Hàng Ngày (Daily Puzzle)** | Giải đố dọn bàn giới hạn số lượt cơ | Thử thách tư duy logic hình học mỗi ngày | Thưởng Kim Cương và Vàng hàng ngày | ✅ **Hoàn thành** |
| **6** | **Giải Đấu Cúp 5 Vòng (Tournament)** | Đấu loại trực tiếp 5 vòng (R16 $\to$ Chung kết) | Áp lực thi đấu cúp chuyên nghiệp đỉnh cao | 🏆 Cúp Vàng Danh Dự, Vàng lớn & EXP | ✅ **Hoàn thành** |
| **7** | **Đấu Mạng Local WiFi (P2P)** | Kết nối 2 máy qua cùng WiFi / Hotspot | Đua tài trực tiếp độ trễ <15ms không cần net | Thắng +500 Vàng, Thua -500 Vàng | ✅ **Hoàn thành** |
| **8** | **Đấu Mạng Online Trực Tuyến 1v1** | Ghép trận tự động hoặc tạo phòng mã PIN | Tranh tài toàn cầu qua Internet | Cược Vàng, Tích lũy Trận thắng (Wins) | ✅ **Hoàn thành** |

---

## 6. KHO TÀNG 112 THẾ ĐÁNH HUYỀN THOẠI

Hệ thống gồm **112 đường cơ đỉnh cao** chia đều cho **14 danh thủ bida huyền thoại thế giới** (mỗi danh thủ sở hữu 8 thế đánh đặc trưng):

```
                                [112 THẾ ĐÁNH HUYỀN THOẠI - 14 DANH THỦ]
                                                   │
  ├── 1. Efren "Bata" Reyes (Phù Thủy Bida): Cú Z-bank, Kick giải snooker, Mỏng mép băng, Trô kẹp băng, Color of Money...
  ├── 2. Ronnie O'Sullivan (Tên Lửa): Cu-lê 2 băng mở góc, Thuận tay trái tia chớp, Xuyên bàn 3.5m, 147 nhanh nhất 5m08s...
  ├── 3. Shane Van Boening (Cậu Bé Nam Dakota): Siêu trô xuyên bàn 1.5m, Phá uy lực ăn bi 1, Nhảy bi Mosconi, Cắt góc chết...
  ├── 4. Florian "Venom" Kohler (Vua Trickshot): Massé bẻ cong quanh bi, Vòng cung cầu vồng 3 bi, Xuyên hầm, Vô cực khép kín...
  ├── 5. Dương Quốc Hoàng (Hoàng Sao Hỏa): Cắt mỏng cân não World 9-Ball, Đánh bại SVB, Rung chuông lỗ góc, Vô địch Scottish Open...
  ├── 6. Earl Strickland (Hạt Ngọc Quý): Combo xuyên khe cửa lỗ, Bắn nhảy cực cự ly ngắn, Cắt dọc băng tốc độ, Cú nhảy vô địch lần 9...
  ├── 7. Francisco Bustamante (Django): Áp-phê ngược bẻ băng, Trô bi dội băng ngược, Cú đánh lòng dũng cảm, Phong vương Django...
  ├── 8. Jayson Shaw (Mắt Đại Bàng): Cắt mỏng 85 độ xé gió, Tấn công trực diện góc chết, Nhảy bi siêu hạn định, Đăng quang Mosconi...
  ├── 9. Fedor Gorst (Bóng Ma): Cắt tỉa cự ly xa chuẩn như dao, Điều bi hình học số học, Trô dọc băng sai lệch 0mm, Song vô địch...
  ├── 10. Torbjörn Blomdahl (Vua 3 Băng Thụy Điển): 3 Băng chữ U, Zigzag 4 băng, Dội băng ngược chiều xoáy, Kiệt tác 44 cúp thế giới...
  ├── 11. Semih Saygıner (Phù Thủy Thổ Nhĩ Kỳ): Cánh cung ma thuật, Slalom qua 2 khe hẹp, Massé giật lùi 180 độ, Vương giả tái xuất...
  ├── 12. Raymond Ceulemans (Mr. 100 Huyền Thoại): Hệ thống nút số kim cương chuẩn mực, Dẫn bi xuyên tâm, Di sản 35 lần vô địch...
  ├── 13. Mike Massey (Bậc Thầy Biểu Diễn): Vòng sau lưng lỗ kép, Búng tay qua hàng bi, Nhảy bi vượt chướng ngại, Cú đánh thế kỷ...
  └── 14. Jeanette Lee (Góa Phụ Đen): Đòn tấn công sát thủ, Cắt băng sắc lạnh như dao, Nhảy bi dứt khoát, Tuyệt chiêu danh vọng...
```

- **100% Bản Địa Hóa**: Cả 112 thế đánh đều sở hữu bản dịch đặc thù cho **Tiêu đề**, **Mô tả lịch sử** và **Hướng dẫn thông số kỹ thuật cơ** trên toàn bộ 5 ngôn ngữ (`vi`, `en`, `zh`, `ja`, `ko`).

---

## 7. KIẾN TRÚC ĐẤU MẠNG KÉP

Hệ thống hạ tầng mạng được xây dựng theo mô hình **Đấu Mạng Kép (Dual Networking Architecture)**, đáp ứng xuất sắc mọi môi trường kết nối:

```
                              [KIẾN TRÚC ĐẤU MẠNG KÉP - DUAL NETWORKING]
                                                   │
             ┌─────────────────────────────────────┴─────────────────────────────────────┐
             ▼                                                                           ▼
   [NHÁNH 1: LOCAL WIFI P2P]                                                   [NHÁNH 2: ONLINE WEBSOCKET]
(UDP Broadcast 8889 + TCP 8888)                                                (Node.js ws Server - Cổng 8080)
             │                                                                           │
├── Tự động dò tìm phòng trong LAN/Hotspot                                  ├── Auto Matchmaking Queue (Ghép tự động)
├── Kết nối P2P trực tiếp độ trễ <15ms                                      ├── Private PIN Room (Chia sẻ mã PIN 6 số)
└── Không phụ thuộc đường truyền Internet                                   └── Reconnect Session (Phục hồi ván dở dang)
             │                                                                           │
             └─────────────────────────────────────┬─────────────────────────────────────┘
                                                   ▼
                                  [GIAO THỨC ĐỒNG BỘ 60 FPS CHUNG]
                                  ├── Đồng bộ góc xoay ngọn cơ & độ kéo lực
                                  ├── Đồng bộ vector áp-phê xoáy 2D (dx, dy)
                                  ├── Đồng bộ tọa độ nhấc/đặt bi cái (Ball-in-Hand)
                                  ├── Khóa quyền thao tác theo lượt (Authority Lock)
                                  └── Phân định thắng/thua & Thanh toán cược tự động
```

### Quy Tắc Phòng Chống Gian Lận & An Toàn Phiên Đấu
1. **Khóa quyền hành động theo lượt (Authority Lock)**: Khi chưa tới lượt của mình (`!isMyTurn`), toàn bộ bàn chơi và thanh điều khiển của đối phương bị khóa cứng (`IgnorePointer`) kèm độ mờ `opacity: 0.35` và banner đỏ trực quan.
2. **Cơ chế Reconnect Session thông minh**: Khi client rớt mạng đột ngột và mở lại game, hệ thống tự động nhận diện ID phòng cũ và cho phép bấm "Quay lại trận đấu ngay" để tiếp tục ván đấu mà không bị xử thua.
3. **Cơ chế Phạt Thoát Trận (Forfeit Penalty)**: Người chơi chủ động đầu hàng hoặc ngắt kết nối quá thời gian quy định sẽ bị xử thua ngay lập tức và bị trừ tiền cược chuyển cho đối thủ.

---

## 8. HỆ THỐNG RPG GẬY CƠ, THÀNH TỰU & TIẾN TRÌNH

### 8.1. Cửa Hàng & Nâng Cấp Gậy Cơ (7 Mẫu Gậy Độc Quyền)
Mỗi cây gậy sở hữu 4 thuộc tính cơ bản tăng tiến từ **Cấp 1 đến Cấp 10**: **Lực (Force)**, **Ngắm (Aim)**, **Xoáy (Spin)**, và **Thời gian (Time)**:

| Tên Gậy Cơ | Phẩm Cấp | Cấp Mở Khóa | Giá Mua Shop | Chỉ Số Lv.1<br>`[L/N/X/G]` | Chỉ Số Lv.10<br>`[L/N/X/G]` | Kỹ Năng / Nội Tại Đặc Quyền |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Gậy Gỗ Tân Thủ** *(Standard)* | ⚪ Common | **Lv. 1** | *Miễn phí* | `2 / 2 / 1 / 1` | `4 / 4 / 3 / 2` | Gậy khởi đầu cân bằng cho tân thủ |
| **Cơ Titan Thép** *(Titan Striker)* | ⚪ Common | **Lv. 5** | 3,000 Vàng | `4 / 3 / 2 / 2` | `7 / 5 / 4 / 4` | **Heavy Break**: Tăng +15% xung lực phá bi khai cuộc |
| **Cơ Băng Phong** *(Frostbite)* | 🔵 Rare | **Lv. 12** | 18,000 Vàng | `5 / 5 / 4 / 3` | `8 / 8 / 7 / 6` | **Ice Aim**: Giảm 20% độ rung lắc khi kéo cơ ngắm |
| **Cơ Kim Ngưu** *(Golden Bull)* | 🔵 Rare | **Lv. 22** | 50,000 Vàng | `6 / 5 / 5 / 4` | `9 / 8 / 8 / 6` | **Jackpot Touch**: Thưởng thêm +10% Vàng khi chiến thắng |
| **Cơ Cyberpunk Neo** *(Neon Vector)*| 🟣 Epic | **Lv. 35** | 150,000 Vàng | `7 / 7 / 6 / 5` | `11 / 11 / 10 / 8` | **Laser Line**: Tia ngắm laser sáng gấp đôi và dài hơn |
| **Cơ Hỏa Phụng** *(Phoenix Flame)* | 🟣 Epic | **Lv. 48** | 450 Kim Cương | `8 / 8 / 8 / 6` | `12 / 12 / 12 / 9` | **Inferno Spin**: Độ xoáy trô giật lùi bóng tăng thêm +25% |
| **Cơ Đế Vương Rồng Vàng** *(Dragon)*| 🟡 Legendary| **Lv. 60** | 1,500 Kim Cương| `10 / 10 / 9 / 8` | `15 / 15 / 15 / 12` | **Dragon Heart**: Bảo hiểm hoàn lại 50% tiền cược khi thua |

### 8.2. Hệ Thống 14 Thành Tựu (Achievements) & 10 Huy Chương Danh Dự (Medals)
- **14 Thành Tựu**: Thưởng lượng lớn EXP giúp thăng cấp tài khoản (Tân thủ nhập môn, Khai cuộc hoàn hảo, Bậc thầy áp-phê, Dọn bàn thần tốc, Vượt ải chiến dịch, Chiến thần đấu mạng, Quán quân Tournament...).
- **10 Huy Chương Ghim Profile Bar**: Người chơi được ghim tối đa **5 huy chương danh giá** lên thanh hồ sơ cá nhân để biểu dương đẳng cấp trước đối thủ khi thi đấu PvP.

### 8.3. Bảng Xếp Hạng Trực Tuyến 3 Bảng (Leaderboards)
- **Top Cấp Độ (Level)**: Tôn vinh cơ thủ cày cuốc kinh nghiệm cao nhất.
- **Top Đại Gia Vàng (Coins)**: Xếp hạng khối lượng tài sản tích lũy.
- **Top Trận Thắng (Total Wins)**: Bảng vàng thành tích đối kháng thực tế.

---

## 9. KINH TẾ TRONG GAME

Hệ sinh thái kinh tế 2 đơn vị tiền tệ (**Vàng** & **Kim Cương**) duy trì cân bằng hoàn hảo giữa nguồn tạo (Sources) và nguồn tiêu (Sinks), triệt tiêu hoàn toàn lạm phát:

```
[NGUỒN THU CỦA NGƯỜI CHƠI (SOURCES)]
├── Thắng trận Đấu Mạng Local / Online (+500 Vàng + Bonus Gậy Kim Ngưu)
├── Quán quân Giải Đấu Tournament 5 Vòng (+5,000 Vàng & Cúp Vàng)
├── Vượt 10 Ải Chiến Dịch Bot (Thưởng Vàng & Kim Cương mỗi ải)
├── Chinh phục 112 Thế Đánh Huyền Thoại (Thưởng Vàng & EXP danh thủ)
├── Hoàn thành Thế Bi Hàng Ngày (Thưởng Kim Cương & Vàng mỗi ngày)
├── Nhận thưởng 14 Thành Tựu (+EXP thăng cấp tài khoản)
└── Thăng Cấp Level Up (Thưởng gói quà Vàng + Kim Cương)
                 │
                 ▼
       [HỆ THỐNG TIỀN TỆ TRONG GAME]
       ├── Vàng (Gold Coins): Cược trận đấu, mua gậy Shop, nâng cấp gậy Lv.1 - Lv.10
       └── Kim Cương (Diamonds): Mua gậy phẩm cấp cao (Epic, Legendary), hồi lượt
                 │
                 ▼
[CƠ CHẾ TIÊU THỤ & CHỐNG LẠM PHÁT (SINKS)]
├── Thua cược trận Đấu Mạng Local / Online (-500 Vàng)
├── Chi phí mua gậy cơ mới trong Cửa Hàng
├── Chi phí vàng tăng lũy tiến khi nâng cấp gậy lên Cấp 2 ➔ Cấp 10
└── Phí tham gia các giải đấu cúp đặc biệt
```

---

## 10. HỆ THỐNG BẢN ĐỊA HÓA ĐA NGÔN NGỮ PHẢN ỨNG

Hệ thống bản địa hóa thời gian thực hỗ trợ **5 ngôn ngữ chính thức**:
1. 🇻🇳 **Tiếng Việt (`vi`)**: Bản địa hóa nguyên bản phong phú.
2. 🇬🇧 **English (`en`)**: Tiêu chuẩn quốc tế chuẩn hóa thuật ngữ bida.
3. 🇨🇳 **中文 (`zh`)**: Tiếng Trung giản thể chuẩn xác cho thị trường châu Á.
4. 🇯🇵 **日本語 (`ja`)**: Tiếng Nhật tinh tế cho cộng đồng game thủ Nhật Bản.
5. 🇰🇷 **한국어 (`ko`)**: Tiếng Hàn hiện đại, chuẩn thể thao chuyên nghiệp.

### Kiến Trúc 3 Tầng Bảo Vệ Dự Phòng (Triple-Layer Fallback Architecture)
```
[Yêu cầu hiển thị chuỗi]
       │
       ├── (1) Tra cứu theo ID chính xác trong Từ Điển Bản Địa Hóa
       │            ├── Tìm thấy ➔ Trả về chuỗi dịch theo ngôn ngữ đích (en/zh/ja/ko)
       │            └── Không tìm thấy ➔ Chuyển tiếp sang tầng 2
       │
       ├── (2) Tra cứu ngược theo Chuỗi Tiếng Việt Gốc (titlesByVietnamese, descriptionsByVietnamese, hintsByVietnamese)
       │            ├── Tìm thấy ➔ Trả về chuỗi dịch tương ứng
       │            └── Không tìm thấy ➔ Chuyển tiếp sang tầng 3
       │
       └── (3) Fallback an toàn sang Tiếng Anh chuẩn (en) hoặc Chuỗi mặc định (defaultText)
```

- **Cơ chế cập nhật UI tức thì**: Toàn bộ widget gốc được quản lý qua `LanguageService.instance` kết hợp `ListenableBuilder`. Nút chuyển đổi 5 ngôn ngữ được bố trí độc quyền tại **Main Menu** với huy hiệu quốc kỳ và tên bản địa rõ nét; trong trận đấu được tinh giản hoàn toàn nút ngôn ngữ để giữ sự tập trung tối đa và tối ưu không gian cho màn hình cảm ứng di động.

---

## 11. THIẾT KẾ GIAO DIỆN NGƯỜI DÙNG & TRẢI NGHIỆM CẢM ỨNG

```
+---------------------------------------------------------------------------------------------------+
|  [P1: Avatar - Lv.5 - Nam (Bạn) - 15,200 $]          [Âm thanh] [Cài đặt]    [P2: Quang Huy - Lv.8] |
+---------------------------------------------------------------------------------------------------+
| [LỰC] |                                                                                   | [THƯỚC] |
|       |                                  BÀN BIDA 16:9                                    |         |
| [100%]|             (Mặt nỉ xanh ngọc lục bảo - Viền gỗ bo góc kim loại)                  | [ÁP-PHÊ]|
|   |   |                                                                                   |   |     |
|  CƠ   |               [🔒 LƯỢT CỦA QUANG HUY (ĐANG CHỜ...)] (Khi đấu mạng)                | [⚙️ 1mm] |
|  KÉO  |                                                                                   | VI CHỈNH|
|  LÚN  |                  (Combo Banner: 🔥 COMBO X2 - TUYỆT VỜI!)                         | GÓC     |
|   |   |                                                                                   | NGẮM    |
| [🔒/⚡]|                     [Tia laser ngắm bắn & Quả bi lăn 3D]                          |   |     |
+---------------------------------------------------------------------------------------------------+
```

### 11.1. Bàn Đấu Bida Responsive Chuẩn 16:9
- **Mặt bàn nỉ cao cấp**: Tông màu xanh ngọc lục bảo (Emerald Green) kết hợp viền gỗ mun và ốp kim loại vàng đồng sang trọng ở 6 miệng lỗ.
- **Tự động co giãn thích ứng (Adaptive Layout)**: 3 cấp độ giao diện (**Standard**, **Compact**, **Ultra-Compact**) đảm bảo bàn chơi hiển thị trọn vẹn trên các thiết bị màn hình ngắn (chiều cao < 360px) mà không bao giờ bị lỗi tràn viền (RenderFlex Overflow).

### 11.2. Hiệu Ứng Trực Quan Động Học & GPU VFX
- **Hiệu ứng Bi Lăn Vào Lỗ 3D (3D Pocket Roll-in Animation)**: Bi tự động xoay tròn, thu nhỏ tỷ lệ từ $1.0$ về $0.35$ và mờ dần trong 240ms khi rơi vào lỗ.
- **Hệ thống hạt GPU (BilliardVfxComponent)**: Tối ưu hóa bộ nhớ và vòng đời hạt (Sparks va chạm, Pocket Dust miệng lỗ, Combo Flash neon, Victory Confetti ăn mừng).

---

## 12. LỘ TRÌNH SẢN PHẨM & KẾ HOẠCH VẬN HÀNH

```
[Giai Đoạn 1: Core Engine]  ===>  [Giai Đoạn 2: Meta & RPG]  ===>  [Giai Đoạn 3: Local WiFi P2P]
      (HOÀN THIỆN 100%)                (HOÀN THIỆN 100%)                 (HOÀN THIỆN 100%)
  - Vật lý Box2D chuẩn xác        - Hệ thống Gậy Cơ & Stats           - UDP Discovery tự động dò
  - Áp-phê, Cu-lê, Trô bóng       - Nâng cấp Gậy Lv. 1-10             - Socket TCP P2P thời gian thực
  - Bot AI Dễ & Khó               - Chiến Dịch 10 Ải Bot (4 Tiers)    - Khóa quyền hành động theo lượt
  - Responsive Mọi Màn Hình       - 112 Thế Đánh Huyền Thoại          - Đồng bộ ngắm/lực/xoáy/ball-in-hand
  - Thước vi chỉnh & Nút 1mm      - Thế Bi Hàng Ngày (Daily Puzzle)   - Cược tiền thắng/thua trực tiếp
  - Hiệu ứng Lăn Lỗ 3D            - 14 Thành Tựu & 10 Huy Chương      - Hiển thị Nickname & Level thật

                                        ||
                                        \/
[Giai Đoạn 5: Esports & Đa Nền Tảng] <=== [Giai Đoạn 4: Online Server & Đa Ngôn Ngữ]
            (QUÝ 1/2027)                                (HOÀN THIỆN 100%)
  - Chế độ 9-Ball & Bida 3 Băng         - WebSocket Server Matchmaking 1v1 qua Internet
  - Pro Mode (Tắt hoàn toàn tia ngắm)   - Tạo phòng thi đấu riêng chia sẻ Mã PIN 6 số
  - Xuất bản bản build Web & Desktop    - Khôi phục ván đấu dở dang (Reconnect Session)
  - Giải Đấu Cúp 8 Người Knockout       - Bản địa hóa 100% 5 Ngôn Ngữ (VI, EN, ZH, JA, KO)
                                        - Tournament 5 Brackets Knockout với Cúp Vàng
```

### Kế Hoạch Tiếp Theo (Giai Đoạn 5):
- [ ] Bổ sung thể thức thi đấu mới: **9-Ball Pool** và **Bida Carom / 3 Băng**.
- [ ] Chế độ Thi Đấu Chuyên Nghiệp (Pro Mode: Tắt toàn bộ tia hỗ trợ ngắm).
- [ ] Xuất bản bản build tối ưu cho Trình duyệt Web (Canvas Kit) và Desktop (Windows/macOS).
- [ ] Bida Pass Mùa Giải (Battle Pass 30 ngày) và Hệ thống Bang Hội / Club Wars.

# NOZVI-GAME-04