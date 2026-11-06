# 🎱 Game Bida 8 Bóng 2D (Billiard 8-Ball)

Game Bida 8 Bóng (8-Ball Pool) phong cách hiện đại, trực quan, hỗ trợ chơi 2 người trên cùng thiết bị, so tài với máy (CPU Bot), vượt ải chiến dịch, giải thế bi hàng ngày và **Đấu mạng Local WiFi thời gian thực (P2P)**. Trò chơi được xây dựng trên nền tảng **Flutter + Flame + Forge2D**, tối ưu hóa giao diện xoay ngang, tự động thích ứng hoàn hảo trên mọi thiết bị di động (Mobile Responsive).

---

## 📑 Mục Lục
1. [🛠️ Công Nghệ Sử Dụng](#️-công-nghệ-sử-dụng)
2. [🌟 Tính Năng Kỹ Thuật Đã Triển Khai](#-tính-năng-kỹ-thuật-đã-triển-khai)
3. [🎨 Thiết Kế Giao Diện & Trải Nghiệm Người Dùng (UI/UX Showcase)](#-thiết-kế-giao-diện--trải-nghiệm-người-dùng-uiux-showcase)
   - [3.1. Bàn Đấu Bida Responsive Chuẩn 16:9](#31-bàn-đấu-bida-responsive-chuẩn-169)
   - [3.2. Thanh Điều Khiển Người Chơi (Player Status Bar)](#32-thanh-điều-khiển-người-chơi-player-status-bar)
   - [3.3. Bộ Điều Khiển Kỹ Năng Bắn Đa Chiều](#33-bộ-điều-khiển-kỹ-năng-bắn-đa-chiều)
   - [3.4. Đồ Họa Động Học & Hiệu Ứng Trực Quan (VFX)](#34-đồ-họa-động-học--hiệu-ứng-trực-quan-vfx)
   - [3.5. Hệ Thống Dialogs & Menu Chức Năng](#35-hệ-thống-dialogs--menu-chức-năng)
4. [📖 Luật Chơi Chi Tiết (Chuẩn 8-Ball)](#-luật-chơi-chi-tiết-chuẩn-8-ball)
5. [🎮 Hướng Dẫn Thao Tác](#-hướng-dẫn-thao-tác)
6. [📘 Bản Thiết Kế Trò Chơi (Game Design Document - GDD)](#-bản-thiết-kế-trò-chơi-game-design-document---gdd)
   - [6.1. Định Vị & Tầm Nhìn Dự Án](#61-định-vị--tầm-nhìn-dự-án)
   - [6.2. Kiến Trúc Vòng Lặp Game (Game Loops)](#62-kiến-trúc-vòng-lặp-game-game-loops)
   - [6.3. Hệ Thống Chế Độ Chơi (6 Chế Độ Đa Tầng)](#63-hệ-thống-chế-độ-chơi-tạo-tính-chơi-lại-cao-replayability)
   - [6.4. Kiến Trúc Đấu Mạng Local WiFi (Peer-to-Peer Realtime)](#64-kiến-trúc-đấu-mạng-local-wifi-peer-to-peer-realtime)
   - [6.5. Tính Năng & Hoạt Động Giữ Chân Người Chơi (Retention & Live-Ops)](#65-tính-năng--hoạt-động-giữ-chân-người-chơi-retention--live-ops)
   - [6.6. Hệ Thống Shop Cửa Hàng & Nâng Cấp Gậy Cơ (Cue Mastery & Shop RPG)](#66-hệ-thống-shop-cửa-hàng--nâng-cấp-gậy-cơ-cue-mastery--shop-rpg)
   - [6.7. Kinh Tế Trong Game (In-Game Economy)](#67-kinh-tế-trong-game-in-game-economy)
7. [🗺️ Lộ Trình Phát Triển (Product Roadmap)](#-lộ-trình-phát-triển-product-roadmap)

---

## 🛠️ Công Nghệ Sử Dụng

Dự án được xây dựng trên nền tảng công nghệ đa nền tảng hiện đại, đảm bảo hiệu năng cao và chuyển động 60 FPS mượt mà:

- **Flutter**: Bộ công cụ phát triển giao diện người dùng đa nền tảng hàng đầu của Google, giúp game chạy mượt trên Android, iOS, Web và Desktop.
- **Flame Game Engine**: Engine game 2D chuyên dụng cho Flutter, quản lý vòng lặp game (game loop), thời gian thực và kết xuất hình ảnh ổn định.
- **Forge2D (Box2D Physics Engine)**: Động cơ vật lý tiêu chuẩn quốc tế mô phỏng chân thực va chạm cơ học, góc nảy băng, ma sát lăn mặt nỉ và lực quán tính của bi.
- **Đồ họa Vector Thuần (CustomPaint)**: Cây cơ trên thanh lực, hệ thống tia ngắm laser và bóng đổ 3D được vẽ trực tiếp bằng vector, đảm bảo độ nét tuyệt đối trên mọi độ phân giải màn hình.
- **Hạ tầng Mạng Nội Bộ (Socket TCP / UDP)**: Giao thức mạng P2P tốc độ cao kết nối hai thiết bị trực tiếp qua cùng mạng WiFi hoặc Điểm phát sóng di động (Hotspot) với độ trễ cực thấp (<15ms).
- **Firebase Authentication & Cloud Firestore**: Quản lý tài khoản người chơi (Email, Mật khẩu, Khách), đồng bộ hóa tiến trình, gậy cơ sở hữu và Bảng xếp hạng trực tuyến (Leaderboard Realtime).
- **Audioplayers Engine**: Tích hợp âm thanh đa kênh xử lý tiếng va chạm bi động (Dynamic Impulse Hit Sound), hiệu ứng lọt lỗ và nhạc nền thư giãn (BGM).

---

## 🌟 Tính Năng Kỹ Thuật Đã Triển Khai

- 📶 **Đấu Mạng Local WiFi (P2P Realtime Multiplayer)**:
  - Tự động dò phòng qua **UDP Broadcast** (cổng 8889), kết nối phòng siêu tốc qua **TCP Socket** (cổng 8888).
  - Đồng bộ hóa 60 FPS góc xoay cơ, mức kéo lực, điểm chạm áp-phê xoáy và tọa độ nhấc/đặt bi (Ball-in-Hand).
  - **Khóa quyền hành động thông minh**: Khi tới lượt đối thủ, bàn chơi và các nút kéo lực / thước ngắm / áp-phê tự động vô hiệu hóa (`IgnorePointer`) và làm mờ (`opacity: 0.35`), kèm banner chờ trực quan.
  - Hiển thị Nickname thật, Cấp độ (Lv.X) và Số dư Vàng của cả hai bên theo thời gian thực.
  - **Kinh tế cược ván đấu**: Người thắng nhận +500 Vàng (+ thưởng gậy) và XP; Người thua bị trừ -500 Vàng trực tiếp từ tài khoản.
- 🤖 **Chế độ chơi đa dạng**:
  - **Chơi 2 Người (PvP)**: Thi đấu lần lượt với bạn bè trên cùng màn hình.
  - **Đấu với Máy (Vs CPU)**: Tùy chọn 2 cấp độ: **Bot Dễ** (dành cho người mới tập chơi) và **Bot Khó** (AI phân tích hình học thông minh, ngắm bóng và căn lực chính xác, biết tự né phạm lỗi).
  - **Chiến Dịch Vượt Ải Bot (Campaign 7 Ải)**: Chuỗi ải Boss AI tăng dần độ khó với tiền thưởng và kinh nghiệm lớn.
  - **Thế Bi Hàng Ngày (Daily Trickshot Puzzle)**: Thử thách kỹ năng dọn bàn với số cơ giới hạn, trao thưởng Kim Cương và Vàng mỗi ngày.
- 🌪️ **Vật lý xoáy bi thực tế**:
  - Tùy chỉnh điểm chạm đầu cơ trên bi cái để tạo hiệu ứng: **Cu-lê** (tiến tới sau va chạm), **Trô bóng** (giật lùi lại) và **Áp-phê Trái / Phải** (đổi góc nảy khi đập băng).
  - Tự động hoàn trả vị trí tâm bi sau mỗi cú đánh.
- ⚡ **Thanh lực tương tác & Thước vi chỉnh góc ngắm**:
  - Cây cơ trên thanh đo tự động **lún sâu xuống** theo mức kéo lực của ngón tay (kèm vệt hào quang năng lượng đổi màu Xanh $\to$ Vàng $\to$ Đỏ).
  - **Thước trượt vi chỉnh góc bắn (Aim Ruler Slider)**: Tinh chỉnh góc ngắm chuẩn xác từng góc nhỏ, triệt tiêu hoàn toàn hiện tượng rung tay trên màn hình cảm ứng di động.
- 🎱 **Hiệu ứng lăn 3D vào lỗ (3D Ball Pocket Roll-in Animation)**:
  - Bi khi rơi vào lỗ sẽ tự động co nhỏ dần, xoay tròn theo trục lăn và biến mất chìm sâu vào lòng hộc bàn bida theo phối cảnh 3D chân thực thay vì biến mất đột ngột.
- 🔊 **Hệ thống Âm thanh Bida sống động**:
  - Tiếng va chạm bi "cạch" giòn tan được tính toán âm lượng và cường độ linh hoạt dựa trên **xung lực va chạm thực tế (Box2D Contact Impulse)**.
  - Tiếng bi rơi lọt vào lòng lỗ hốc bàn bida trầm ấm.
  - Nhạc nền thư giãn BGM với công tắc chuyển đổi nhanh và thanh điều chỉnh âm lượng riêng biệt.
- 🔥 **Hiệu ứng Combo chuỗi ăn bi**:
  - Tự động nhận diện và tính combo khi người chơi ăn từ 2 bi cùng nhóm hợp lệ trở lên trong cùng 1 lượt đánh.
  - Banner Combo hiệu ứng phát sáng neon nổi bật giữa bàn đấu.
- 📱 **Giao diện tự co giãn (Mobile Responsive)**:
  - Tự động thích ứng hoàn hảo với mọi kích cỡ màn hình điện thoại (kể cả các dòng máy nhỏ như iPhone SE, Android phổ thông hay máy có tai thỏ / camera nốt ruồi), không bao giờ bị tràn viền hay che mất bàn chơi.
- 🎯 **Tia ngắm thông minh**: Hiển thị đường đi dự kiến của bi cái và hướng chuyển động của bi mục tiêu sau va chạm.
- 🛍️ **Cửa hàng Gậy Cơ (Cue Shop RPG)**: 7 mẫu gậy cơ độc đáo, phân chia theo phẩm cấp (Common, Rare, Epic, Legendary), mở khóa theo Level người chơi và nâng cấp 10 bậc chỉ số.

---

## 🎨 THIẾT KẾ GIAO DIỆN & TRẢI NGHIỆM NGƯỜI DÙNG (UI/UX SHOWCASE)

Giao diện (GD) của trò chơi được thiết kế theo ngôn ngữ hiện đại, sang trọng, lấy cảm hứng từ các tựa game bida hàng đầu thế giới (8 Ball Pool, Billiards City) nhưng tối ưu hóa hoàn toàn cho trải nghiệm chạm vuốt trên di động:

```
+---------------------------------------------------------------------------------------------------+
|  [P1: Avatar - Lv.5 - Nam (Bạn) - 15,200 $]      [Âm thanh] [Cài đặt]      [P2: Quang Huy - Lv.8 - 42,000 $] |
+---------------------------------------------------------------------------------------------------+
| [LỰC] |                                                                                   | [THƯỚC] |
|       |                                  BÀN BIDA 16:9                                    |         |
| [100%]|             (Mặt nỉ xanh ngọc lục bảo - Viền gỗ bo góc kim loại)                  | [ÁP-PHÊ]|
|   |   |                                                                                   |   |     |
|  CƠ   |               [🔒 LƯỢT CỦA QUANG HUY (ĐANG CHỜ...)] (Khi đấu WiFi)                |   |     |
|  KÉO  |                                                                                   | VI CHỈNH|
|  LÚN  |                  (Combo Banner: 🔥 COMBO X2 - TUYỆT VỜI!)                         | GÓC     |
|   |   |                                                                                   | NGẮM    |
|  [0%] |                     [Tia laser ngắm bắn & Quả bi lăn 3D]                          |   |     |
+---------------------------------------------------------------------------------------------------+
```

### 3.1. Bàn Đấu Bida Responsive Chuẩn 16:9
- **Mặt bàn nỉ cao cấp**: Tông màu xanh ngọc lục bảo (Emerald Green) kết hợp viền gỗ mun và ốp kim loại vàng đồng sang trọng ở 6 miệng lỗ.
- **Hệ thống đổ bóng động**: Các quả bi và thành băng đổ bóng mềm mượt (Soft Drop Shadow), tạo cảm giác nổi 2.5D chân thực.
- **Tự động co giãn (Adaptive Layout)**:
  - Tự động đo kích thước khung nhìn thực tế của màn hình thiết bị.
  - Phân tách 3 mức hiển thị: **Chuẩn (Standard)**, **Nhỏ gọn (Compact)** và **Siêu nhỏ gọn (Ultra-Compact)** cho các máy màn hình ngắn (chiều cao < 360px), đảm bảo bàn bida và các thanh điều khiển luôn nằm trọn vẹn trong màn hình mà không bao giờ phát sinh lỗi RenderFlex Overflow.

### 3.2. Thanh Điều Khiển Người Chơi (Player Status Bar)
Nằm ở cạnh trên cùng của màn hình, được bo tròn góc với hiệu ứng đổ bóng mờ nền tối:
- **Thẻ người chơi P1 & P2**:
  - **Huy hiệu Level**: Huy hiệu gradient cam - vàng nổi bật (ví dụ: `Lv.1`, `Lv.12`).
  - **Tên người chơi (Nickname)**: Hiển thị tên tài khoản thật kèm chỉ dẫn `(Bạn)` hoặc `(Chủ phòng)` / `(Khách)`.
  - **Số dư Vàng ($)**: Hiển thị số tiền hiện có kèm icon đồng tiền vàng lấp lánh.
  - **Đèn báo lượt (Turn Indicator)**: Khi đến lượt cơ thủ nào, thẻ của cơ thủ đó sẽ sáng viền xanh neon cùng mũi tên chỉ báo động học.
  - **Nhóm bi mục tiêu**: Hiển thị cụm bi mục tiêu thu nhỏ tương ứng (Nhóm Bi Trơn 1-7 hoặc Nhóm Bi Sọc 9-15) cùng trạng thái các bi đã vào lỗ hoặc còn trên bàn.
- **Cụm phím chức năng trung tâm**:
  - **Phím Âm thanh nhanh**: Biểu tượng loa bật/tắt tức thì âm thanh hoặc mở bảng chỉnh âm lượng.
  - **Phím Cài đặt**: Mở cửa sổ tùy chỉnh chế độ chơi, nhạc nền, SFX và thoát trận.

### 3.3. Bộ Điều Khiển Kỹ Năng Bắn Đa Chiều
Hệ thống điều khiển được phân bổ khoa học sang hai cạnh mép màn hình, phù hợp hoàn hảo với ngón tay cái của cả hai tay khi cầm máy xoay ngang:
- **Thanh lực bắn bên trái (Left Power Control)**:
  - Thiết kế cây cơ thẳng đứng đặt trong rãnh đo độ sâu.
  - Khi người chơi chạm và kéo ngón tay cái xuống, cây cơ sẽ lùi dần về phía sau theo độ sâu vật lý.
  - Cột đèn LED năng lượng neon hiển thị phần trăm lực từ `0%` đến `100%`, tự đổi màu từ **Xanh lá $\to$ Hổ phách $\to$ Đỏ rực**.
- **Thước ngắm vi chỉnh bên phải (Right Aim Ruler)**:
  - Thanh trượt chia vạch micromet giúp xoay cây cơ từng độ cực nhỏ ($0.1^\circ$).
  - Giải quyết triệt để vấn đề "ngón tay to che khuất góc bắn" trên màn hình di động.
- **Nút điều khiển Áp-phê xoáy (Cue Spin Button)**:
  - Nằm ngay dưới thước ngắm, hiển thị hình quả bi cái thu nhỏ cùng chấm đỏ đánh dấu điểm tiếp xúc đầu cơ.
  - Chạm vào nút sẽ mở ra hộp thoại căn chỉnh xoáy 2D phóng to, cho phép chọn nhanh các kỹ thuật đỉnh cao: **Tâm bi (Đánh thường)**, **Cu-lê (Đẩy tới)**, **Trô bóng (Giật lùi)**, **Áp-phê Trái / Phải**.

### 3.4. Đồ Họa Động Học & Hiệu Ứng Trực Quan (VFX)
- **Hiệu ứng Bi Lăn Vào Lỗ 3D (3D Pocket Roll-in Animation)**:
  - Khi quả bi lăn chạm miệng lỗ, nó không bị xóa tức thì mà kích hoạt chuỗi diễn hoạt 3D: Bi tự động xoay tròn quanh tâm, thu nhỏ tỷ lệ từ `1.0` xuống `0.35` và mờ dần trong 240ms, tạo cảm giác bi rơi thật sự xuống hộc dưới đáy bàn.
- **Banner Combo Ăn Bi**:
  - Xuất hiện rực rỡ với hiệu ứng hào quang neon tím - vàng giữa bàn khi ăn liên tiếp các bi cùng loại: `🔥 COMBO X2 - TUYỆT VỜI!` hoặc `⚡ COMBO X3 - BẬC THẦY!`.
- **Khóa lượt & Banner chờ trong Đấu Mạng Local WiFi**:
  - Khi chưa tới lượt của mình, toàn bộ bàn bida và các thanh điều khiển tự động giảm độ mờ xuống `0.35` và chặn mọi thao tác chạm (`IgnorePointer`).
  - Phía trên bàn xuất hiện banner đỏ cảnh báo sang trọng:  
    `🔒 LƯỢT CỦA [TÊN ĐỐI THỦ] (ĐANG CHỜ...)` kèm vòng tròn xoay chờ tín hiệu đồng bộ.
- **Bảng Tổng Kết Ván Đấu (Victory / Defeat Rack Overlay)**:
  - Khung thông báo gradient xanh thẫm viền vàng hổ phách nổi bật.
  - Biểu tượng Cúp vàng danh dự (`🎉 BẠN ĐÃ CHIẾN THẮNG!`) hoặc Biểu tượng chia buồn (`😢 [ĐỐI THỦ] ĐÃ CHIẾN THẮNG!`).
  - Huy hiệu cộng thưởng vàng màu vàng hổ phách (`+500 Vàng`) hoặc huy hiệu trừ tiền phạt màu đỏ cảnh báo (`-500 Vàng`).

### 3.5. Hệ Thống Dialogs & Menu Chức Năng
- **Cửa Sổ Đấu Mạng Local WiFi**:
  - Giao diện chia 2 tab: **Tạo Phòng (Host)** và **Tìm Phòng (Join)**.
  - Hiển thị địa chỉ IP nội bộ của máy chủ, danh sách các phòng đang mở trong cùng mạng WiFi được tự động phát hiện qua UDP Broadcast.
  - Ô nhập địa chỉ IP thủ công bàn phím ảo tùy biến, kết nối nhanh với 1 chạm.
- **Cửa Hàng Gậy Cơ (Cue Shop Dialog)**:
  - Hiển thị danh mục các mẫu gậy cơ theo thứ tự cấp độ mở khóa.
  - Thẻ gậy với hình ảnh vector sắc nét, nhãn phẩm cấp (Common, Rare, Epic, Legendary), thanh đo 4 chỉ số cơ bản (Lực, Ngắm, Xoáy, Thời gian) và nút Mua / Trang bị / Nâng cấp Lv.1 - Lv.10.
- **Bảng Xếp Hạng Trực Tuyến (Leaderboard Dialog)**:
  - Kết nối Cloud Firestore realtime, hiển thị danh sách Top cơ thủ toàn cầu với Avatar, Cúp, Level, Tỷ lệ thắng và Huy chương Top 1-2-3 (Vàng, Bạc, Đồng).
- **Hồ Sơ & Xác Thực Tài Khoản (Profile & Auth Dialog)**:
  - Cho phép người chơi đổi tên hiển thị (Nickname), đổi Avatar, cập nhật mật khẩu hoặc chuyển đổi linh hoạt giữa tài khoản Khách (Guest) và tài khoản Email đã đăng ký.

---

## 📖 Luật Chơi Chi Tiết (Chuẩn 8-Ball)

### 1. Phân chia nhóm bi
Bàn bida gồm 1 bi cái (bi trắng) và 15 bi mục tiêu được chia làm 2 nhóm:
- **Bi Trơn (Solids)**: Đánh số từ **1 đến 7** (màu đơn sắc).
- **Bi Sọc (Stripes)**: Đánh số từ **9 đến 15** (có dải sọc trắng ở giữa).
- **Bi Đen Số 8**: Bi quyết định ván đấu.

> *Nhóm bi của mỗi người chơi chỉ được xác định sau cú đánh khai cuộc khi có người đưa thành công quả bi đầu tiên vào lỗ một cách hợp lệ.*

### 2. Quy tắc đánh theo lượt
- Mỗi người chơi chỉ được ngắm và chạm cơ vào **nhóm bi của mình** đầu tiên.
- Nếu đưa được ít nhất một bi thuộc nhóm của mình vào lỗ hợp lệ, người chơi sẽ **được đánh tiếp**.
- Nếu không có bi nào vào lỗ hoặc phạm luật, lượt chơi sẽ **chuyển sang đối thủ**.

### 3. Các lỗi phạm luật (Foul)
Người chơi sẽ bị tính là phạm lỗi nếu:
1. Đánh bi cái rơi vào lỗ.
2. Đánh bi cái không chạm trúng bất kỳ quả bi nào trên bàn.
3. Đánh bi cái chạm bi của đối thủ hoặc chạm bi số 8 đầu tiên (khi chưa dọn hết nhóm của mình).
4. Bi cái và bi mục tiêu sau va chạm không có quả nào chạm băng hoặc rơi vào lỗ.

### 4. Quyền đặt bi tự do (Ball-in-Hand)
- Khi một bên phạm lỗi (Foul), người chơi kế tiếp sẽ nhận quyền **Ball-in-Hand**.
- Người chơi có quyền dùng tay chạm và đặt bi cái ở **bất kỳ vị trí nào** trên mặt bàn để thực hiện cú đánh tiếp theo. Trong chế độ Local WiFi, vị trí bi cái được đồng bộ hóa tức thì sang máy đối thủ.

### 5. Điều kiện Thắng / Thua
- **Chiến Thắng**: Người chơi dọn sạch toàn bộ các bi thuộc nhóm của mình và sau đó đánh bi số 8 vào lỗ một cách hợp lệ.
- **Thua Ngay Lập Tức**:
  - Đánh rơi bi số 8 vào lỗ khi chưa ăn hết nhóm bi của mình.
  - Đánh bi số 8 vào lỗ đồng thời làm bi cái rơi vào lỗ.
  - Làm bi số 8 văng ra khỏi bàn thi đấu.

---

## 🎮 Hướng Dẫn Thao Tác

1. **Ngắm hướng**: Chạm và rê ngón tay trên mặt bàn để xoay hướng ngắm của cây cơ. Dùng **Thước ngắm vi chỉnh bên phải** để tinh chỉnh góc bắn nhỏ.
2. **Chỉnh xoáy Áp-phê**: Bấm vào biểu tượng bi cái ở góc dưới bên phải để chọn điểm tiếp xúc cơ (Cu-lê, Trô bóng hoặc Áp-phê).
3. **Kéo lực & Bắn**:
   - Chạm vào thanh đo bên trái và vuốt ngón tay cái xuống dưới. Cây cơ sẽ lún dần theo tay bạn.
   - Thả tay ra để thực hiện cú đánh với lực tương ứng.
4. **Di chuyển bi cái (khi có Ball-in-Hand)**: Chạm giữ trực tiếp vào bi cái, kéo đến vị trí mong muốn trên bàn và thả tay.
5. **Đấu Mạng Local WiFi**:
   - Máy 1: Bấm icon Mạng $\to$ Chọn tab "Tạo phòng" $\to$ Bấm "Bắt đầu tạo phòng".
   - Máy 2: Cùng kết nối vào WiFi/Hotspot của máy 1 $\to$ Bấm icon Mạng $\to$ Bấm vào tên phòng máy 1 xuất hiện tự động để tham gia ngay!

---

## 📘 BẢN THIẾT KẾ TRÒ CHƠI (GAME DESIGN DOCUMENT - GDD)

### 6.1. Định Vị & Tầm Nhìn Dự Án

- **Thể loại**: Casual Sports / Mid-core Billiards Simulator kết hợp yếu tố RPG nhẹ (Gậy cơ, Thuộc tính, Cửa hàng, Đấu mạng Local WiFi).
- **Nền tảng mục tiêu**: Mobile (Android / iOS), mở rộng Web (HTML5/Canvas) & PC.
- **Target Audience**: 
  - Game thủ yêu thích thể thao bida, thi đấu kỹ năng logic hình học (16 - 45 tuổi).
  - Người chơi casual tìm kiếm game giải trí ngắn (vòng lặp 3 - 5 phút/ván).
  - Nhóm bạn bè, đồng nghiệp so tài trực tiếp cùng phòng qua mạng WiFi / Hotspot.
- **USP (Unique Selling Proposition)**:
  - Cảm giác vật lý bi lăn, áp-phê và nảy băng chân thực chuẩn Box2D kết hợp âm thanh va chạm sinh động.
  - Khả năng **Đấu mạng Local WiFi P2P thời gian thực mượt mà** không cần internet cáp quang hay server trung gian đắt đỏ.
  - Điều khiển cảm ứng trực quan, tích hợp thước ngắm vi chỉnh giải quyết triệt để nhược điểm màn hình cảm ứng di động.

---

### 6.2. Kiến Trúc Vòng Lặp Game (Game Loops)

```
+-------------------------------------------------------------------------------+
|                       RETENTION LOOP (Tuần / Tháng)                          |
|  - Bảng Xếp Hạng Tuần (Weekly Leagues)  - Sưu tập Gậy Huyền Thoại             |
|  - Chiến Dịch Ải Boss AI                - Hoạt Động Bang Hội & Giao Hữu       |
+-------------------------------------------------------------------------------+
                                        ^
                                        | (Tích lũy Điểm / Cup / Huy Chương)
+-------------------------------------------------------------------------------+
|                         META GAME LOOP (Hàng Ngày)                            |
|  [Đấu WiFi Cược Vàng] ---> [Cày Cấp Độ Mở Shop] ---> [Nâng Cấp Gậy Lv.1-10]   |
|          ^                                                   |                |
|          |----------- [Giải Đố Thế Bi Hàng Ngày] <-----------+                |
+-------------------------------------------------------------------------------+
                                        ^
                                        | (Vàng, XP, Kim Cương)
+-------------------------------------------------------------------------------+
|                         CORE GAME LOOP (Trong Ván)                            |
|  [Vào Bàn] -> [Đọc Thế Bi] -> [Căn Áp-phê / Lực / Thước] -> [Bắn] -> [Kết Quả] |
+-------------------------------------------------------------------------------+
```

---

### 6.3. Hệ Thống Chế Độ Chơi Tạo Tính Chơi Lại Cao (Replayability)

| Chế Độ Chơi | Mục Tiêu Chính | Yếu Tố Kích Thích Người Chơi | Cơ Chế Phần Thưởng | Trạng Thái |
| :--- | :--- | :--- | :--- | :---: |
| **1. Đấu Mạng Local WiFi (P2P)** | So tài trực tiếp 2 máy qua mạng WiFi/Hotspot | Cạnh tranh kỹ năng người với người, cược tiền kịch tính | Thắng +500 Vàng & XP, Thua trừ -500 Vàng | ✅ **Hoàn thành** |
| **2. Chơi 2 Người (Pass & Play)** | 2 người chơi lần lượt trên 1 màn hình | Giải trí nhanh cùng bạn bè người thân | Rèn luyện kỹ năng, tính điểm số | ✅ **Hoàn thành** |
| **3. Đấu Với Máy (Vs CPU)** | Tập luyện với Bot Dễ hoặc Bot Khó | Thử nghiệm các góc bắn hiểm hóc | Thưởng XP cơ bản | ✅ **Hoàn thành** |
| **4. Chiến Dịch Ải Bot (Campaign)** | Vượt 7 ải Boss AI với độ khó tăng dần | Chinh phục thử thách, hạ gục cao thủ máy | Thưởng lớn Vàng, Kim Cương & XP lần đầu | ✅ **Hoàn thành** |
| **5. Thế Bi Hàng Ngày (Daily Puzzle)**| Dọn sạch các bi mục tiêu với số cơ giới hạn | Kích thích tư duy logic, áp-phê trô giật bóng | Thưởng Kim Cương và Vàng mỗi ngày | ✅ **Hoàn thành** |
| **6. Đấu Xếp Hạng Online (Cloud Server)**| Đua top toàn cầu, ghép cặp tự động qua Server | Thăng hạng Elo, vinh danh Leaderboard | Cúp Danh Dự, Rương quà mùa giải | 🚀 *Giai đoạn tiếp theo* |

---

### 6.4. Kiến Trúc Đấu Mạng Local WiFi (Peer-to-Peer Realtime)

Chế độ Đấu Mạng Local WiFi cho phép hai thiết bị di động trong cùng mạng LAN/WLAN hoặc qua Điểm phát sóng di động (Hotspot) thi đấu đối kháng trực tiếp mà không cần cấu hình Router hay mở cổng mạng (Port Forwarding):

```
+-----------------------------------------------------------------------------------+
|               KIẾN TRÚC MẠNG ĐỐI KHÁNG LOCAL WIFI (SOCKET P2P)                     |
+-----------------------------------------------------------------------------------+
|                                                                                   |
|   [THIẾT BỊ 1: HOST (CHỦ PHÒNG)]             [THIẾT BỊ 2: CLIENT (KHÁCH)]        |
|   - Tự động dò IP LAN (192.168.x.x)          - Lắng nghe UDP Broadcast (Cổng 8889)|
|   - Mở Socket Server TCP (Cổng 8888)         - Tự động phát hiện Host xuất hiện   |
|   - Phát UDP Broadcast chu kỳ 1.2s    ===>   - Bấm tham gia phòng 1 chạm          |
|                                                                                   |
|                                  KẾT NỐI TCP THÀNH CÔNG                           |
|                                       <=========>                                 |
|                                                                                   |
|   [ĐỒNG BỘ DỮ LIỆU THỜI GIAN THỰC]:                                               |
|   1. Trao đổi thông tin: Nickname, Level, Số dư Vàng                              |
|   2. Đồng bộ góc ngắm (Aim Angle) & Lực kéo cơ (Shot Power) theo thời gian thực    |
|   3. Đồng bộ điểm áp-phê xoáy (Cue Spin dx, dy)                                   |
|   4. Đồng bộ nhấc / đặt bi cái (Ball-in-Hand) kèm cờ "placed: true"              |
|   5. Khóa quyền điều khiển khi đối thủ đang đánh (Turn-based Authority Lock)       |
|   6. Kết thúc ván: Phân định thắng/thua, cộng/trừ tiền cược ví tự động            |
|                                                                                   |
+-----------------------------------------------------------------------------------+
```

- **Quy tắc khóa quyền hành động (Turn-based Authority Lock)**:
  - Máy chủ (Host) luôn là Player 1 (đánh khai cuộc Break shot). Máy khách (Client) là Player 2.
  - Khi chưa tới lượt của mình (`!isMyTurn`), toàn bộ bàn đấu và bảng điều khiển bị phong tỏa bằng `IgnorePointer` và giảm độ mờ sang `0.35`. Chỉ thiết bị của người đang tới lượt mới có quyền thao tác.
  - Khi có Foul (phạm luật), quyền đặt bi tự do (Ball-in-Hand) được trao cho đối phương và tọa độ được truyền qua mạng để cả hai máy hiển thị bi di chuyển mượt mà.
- **Kinh tế cược ván đấu (Betting Match Economy)**:
  - Mức cược mặc định: **500 Vàng**.
  - Người chiến thắng: Nhận `+500 Vàng` cược (+10% nếu trang bị Gậy Kim Ngưu) cùng `+150 XP`.
  - Người thua cuộc: Bị trừ `-500 Vàng` từ tài khoản (giảm 50% tiền cược mất nếu trang bị Gậy Long Thần).

---

### 6.5. Tính Năng & Hoạt Động Giữ Chân Người Chơi (Retention & Live-Ops)

1. **Chuỗi Nhiệm Vụ Thế Bi Hàng Ngày (Daily Puzzle)**:
   - Mỗi ngày một bàn cờ thế bi mới với chướng ngại vật đòi hỏi kỹ thuật băng hoặc nhảy bi.
   - Thưởng nóng Kim Cương để tích lũy mua các gậy cơ cao cấp.
2. **Bảng Xếp Hạng Cơ Thủ (Realtime Leaderboards)**:
   - Cập nhật tự động qua Firebase Firestore.
   - Hiển thị danh hiệu Top 10 cơ thủ có Cúp cao nhất, Level cao nhất và tỷ lệ thắng tốt nhất.
3. **Hiệu Ứng Combo Tăng Động Lực**:
   - Thưởng Combo ăn liên tiếp tạo cảm giác thỏa mãn (Juiciness) trong từng đường cơ xuất sắc.

---

### 6.6. Hệ Thống Shop Cửa Hàng & Nâng Cấp Gậy Cơ (Cue Mastery & Shop RPG)

Gậy cơ trong game sở hữu 4 chỉ số cơ bản và tăng tiến sức mạnh vượt bậc khi nâng cấp từ **Cấp 1 lên Cấp 10**:

| Tên Gậy Cơ | Phẩm Cấp | Cấp Mở Khóa | Giá Mua Shop | Chỉ Số Ban Đầu (Lv.1)<br>`[Lực / Ngắm / Xoáy / Giờ]` | Chỉ Số Tối Đa (Lv.10)<br>`[Lực / Ngắm / Xoáy / Giờ]` | Kỹ Năng / Nội Tại Đặc Quyền |
| :--- | :---: | :---: | :---: | :---: | :---: | :--- |
| **Gậy Gỗ Tân Thủ** *(Standard)* | ⚪ Common | **Lv. 1** | *Miễn phí* | `2 / 2 / 1 / 1` | `4 / 4 / 3 / 2` | Dành cho người mới làm quen |
| **Cơ Titan Thép** *(Titan Striker)* | ⚪ Common | **Lv. 5** | 3,000 Vàng | `4 / 3 / 2 / 2` | `7 / 5 / 4 / 4` | **Heavy Break**: Tăng +15% lực phá bi khai cuộc |
| **Cơ Băng Phong** *(Frostbite)* | 🔵 Rare | **Lv. 12** | 18,000 Vàng | `5 / 5 / 4 / 3` | `8 / 8 / 7 / 6` | **Ice Aim**: Làm chậm 20% tốc độ dao động thanh đo lực |
| **Cơ Kim Ngưu** *(Golden Bull)* | 🔵 Rare | **Lv. 22** | 50,000 Vàng | `6 / 5 / 5 / 4` | `9 / 8 / 8 / 6` | **Jackpot Touch**: Thưởng thêm +10% Vàng khi thắng trận |
| **Cơ Cyberpunk Neo** *(Neon Vector)*| 🟣 Epic | **Lv. 35** | 150,000 Vàng | `7 / 7 / 6 / 5` | `11 / 11 / 10 / 8` | **Laser Line**: Tia ngắm bi cái và bi mục tiêu sáng gấp đôi |
| **Cơ Hỏa Phụng** *(Phoenix Flame)* | 🟣 Epic | **Lv. 48** | 450 Kim Cương | `8 / 8 / 8 / 6` | `12 / 12 / 12 / 9` | **Inferno Spin**: Độ giật trô bóng tăng vọt +25% khoảng cách |
| **Cơ Đế Vương Rồng Vàng** *(Dragon)*| 🟡 Legendary| **Lv. 60** | 1,500 Kim Cương| `10 / 10 / 9 / 8` | `15 / 15 / 15 / 12` | **Dragon Heart**: Hoàn lại 50% tiền cược nếu thua ván |

---

### 6.7. Kinh Tế Trong Game (In-Game Economy)

```
[NGUỒN THU CỦA NGƯỜI CHƠI (SOURCES)]
├── Thắng trận Đấu Mạng Local WiFi (+500 Vàng + Bonus Gậy)
├── Vượt Ải Chiến Dịch Bot (Vàng & Kim Cương lần đầu)
├── Hoàn thành Thế Bi Hàng Ngày (Kim Cương & Vàng)
└── Thăng Cấp Tài Khoản Level Up (Thưởng Vàng + Kim Cương)
                 │
                 ▼
       [HỆ THỐNG TIỀN TỆ]
       ├── Vàng (Gold Coins): Dùng để cược trận đấu, mua gậy Shop, nâng cấp gậy
       └── Kim Cương (Diamonds): Dùng để mua gậy cao cấp (Epic, Legendary)
                 │
                 ▼
[CƠ CHẾ TIÊU THỤ & CHỐNG LẠM PHÁT (SINKS)]
├── Mất tiền khi thua cược trận Đấu Mạng (-500 Vàng)
├── Chi phí mua gậy cơ mới trong Cửa Hàng
└── Chi phí nâng cấp gậy lên Lv. 2 ➔ Lv. 10
```

---

## 🗺️ LỘ TRÌNH PHÁT TRIỂN (PRODUCT ROADMAP)

Lộ trình phát triển được cập nhật theo tiến độ thực tế của dự án:

```
[Giai Đoạn 1: Core Engine]  ===>  [Giai Đoạn 2: Meta & RPG]  ===>  [Giai Đoạn 3: Local WiFi P2P]
      (HOÀN THIỆN 100%)                (HOÀN THIỆN 100%)                 (HOÀN THIỆN 100%)
  - Vật lý Box2D chuẩn xác        - Hệ thống Gậy Cơ & Stats           - UDP Discovery tự động dò
  - Áp-phê, Cu-lê, Trô bóng       - Nâng cấp Gậy Lv. 1-10             - Socket TCP P2P thời gian thực
  - Bot AI Dễ & Khó               - Chế độ Chiến Dịch Ải Bot          - Khóa quyền hành động theo lượt
  - Responsive Mọi Màn Hình       - Chế độ Thế Bi Hàng Ngày           - Đồng bộ ngắm/lực/xoáy/ball-in-hand
  - Thước vi chỉnh góc ngắm       - Âm thanh SFX & BGM chân thực      - Cược tiền thắng/thua trực tiếp
  - Hiệu ứng Lăn Lỗ 3D            - Firebase Auth & Leaderboard       - Hiển thị Nickname & Level thật

                                        ||
                                        \/
[Giai Đoạn 5: Esports & Đa Nền Tảng] <=== [Giai Đoạn 4: Online Global Server]
            (QUÝ 1/2027)                                (QUÝ 4/2026)
  - Chế độ 9-Ball & Bida 3 Băng         - Server Matchmaking tự động qua Cloud
  - Pro Mode (Tắt hoàn toàn tia ngắm)   - Bàn Cược theo Thành Phố (Hà Nội, Vegas)
  - Xuất bản bản build Web & Desktop    - Chat Emoji hoạt hình trong bàn đấu
  - Giải Đấu Cúp 8 Người Knockout       - Hệ thống Bang Hội / Club Wars
```

### Chi Tiết Kế Hoạch Từng Giai Đoạn:

#### 📍 Giai Đoạn 1: Nền Tảng Cốt Lõi (Core Engine & Polish) — *[Đã Hoàn Thành]*
- [x] Tích hợp engine vật lý Forge2D / Box2D: Va chạm bi - bi, bi - băng bàn chuẩn xác.
- [x] Cơ chế Áp-phê (Spin Control): Cu-lê đẩy tới, Trô giật lùi, xoáy nảy góc băng.
- [x] Hệ thống thanh kéo lực tương tác mượt mà, chuyển màu năng lượng neon.
- [x] Bộ luật 8-Ball hoàn chỉnh: Chia bi Trơn/Sọc, Foul, Quyền đặt bi tự do (Ball-in-Hand), Điều kiện thắng/thua với Bi số 8.
- [x] AI Bot 2 cấp độ: Dễ (giải trí) và Khó (tính toán hình học, tự né phạm lỗi).
- [x] UI Responsive tự động co giãn theo tỷ lệ màn hình điện thoại, chống tràn màn hình.
- [x] Thước vi chỉnh góc ngắm (Aim Ruler Slider) tinh chỉnh micromet.
- [x] Hiệu ứng lăn 3D vào lỗ (3D Ball Pocket Roll-in Animation).

#### 📍 Giai Đoạn 2: Meta-Game, Hệ Thống Gậy & Tiến Trình RPG — *[Đã Hoàn Thành]*
- [x] **Cửa Hàng Gậy Cơ Đa Phẩm Cấp**: 7 mẫu gậy từ Common đến Legendary, mở khóa theo Level người chơi.
- [x] **Hệ Thống Nâng Cấp Gậy (Level 1 $\to$ Level 10)**: Tăng tiến 4 chỉ số (Lực, Ngắm, Xoáy, Thời gian) và nội tại đặc quyền.
- [x] **Chế Độ Chiến Dịch Ải Bot (7 Ải Boss AI)**: Tăng dần độ khó với phần thưởng hấp dẫn.
- [x] **Chế Độ Thế Bi Hàng Ngày (Daily Trickshot Puzzle)**: Giới hạn lượt cơ, tích lũy Kim Cương và Vàng.
- [x] **Hệ Thống Âm Thanh Động**: Tiếng va chạm bi "cạch" chân thực theo xung lực Box2D, tiếng bi lọt lỗ và BGM.
- [x] **Hệ Thống Combo**: Banner vinh danh chuỗi ăn liên tiếp các bi cùng loại.
- [x] **Firebase Auth & Realtime Leaderboard**: Đăng nhập, lưu trữ đám mây và Bảng xếp hạng trực tuyến.

#### 📍 Giai Đoạn 3: Đấu Mạng Local WiFi P2P Thời Gian Thực — *[Đã Hoàn Thành]*
- [x] Dò tìm phòng tự động qua UDP Broadcast không cần cấu hình Router.
- [x] Kết nối P2P trực tiếp qua Socket TCP độ trễ cực thấp.
- [x] Đồng bộ thời gian thực 60 FPS: Hướng ngắm, mức kéo lực, áp-phê xoáy, nhấc và đặt bi cái.
- [x] Khóa toàn diện quyền hành động khi đang tới lượt của đối thủ (bàn đấu, thước ngắm, thanh lực, áp-phê).
- [x] Banner thông báo trạng thái lượt đối thủ trực quan kèm hiệu ứng chờ.
- [x] Hiển thị chính xác Nickname thật, Cấp độ và Số dư Vàng của cả hai bên.
- [x] Cơ chế kinh tế cược tiền ván đấu: Thắng nhận tiền (+500 Vàng), Thua mất tiền (-500 Vàng).

#### 📍 Giai Đoạn 4: Server Đấu Mạng Trực Tuyến Toàn Cầu (Cloud Matchmaking & Social) — *[Kế hoạch tiếp theo]*
- [ ] Xây dựng Server Matchmaking tự động ghép cặp 1v1 theo điểm kỹ năng Elo qua Internet.
- [ ] Hệ thống Bàn Cược theo Thành Phố (Hà Nội, Sài Gòn, Tokyo, Las Vegas...).
- [ ] Tích hợp hệ thống Chat nhanh, Emoji hoạt hình chọc tức đối thủ.
- [ ] Bida Pass Mùa Giải (Battle Pass 30 ngày).
- [ ] Giải đấu Cúp 8 Người Knockout trực tiếp.

#### 📍 Giai Đoạn 5: Đa Nền Tảng & Esports Mở Rộng
- [ ] Hỗ trợ thêm các thể thức thi đấu mới: **9-Ball Pool** và **Bida Carom / 3 Băng mini**.
- [ ] Xuất bản bản build tối ưu trên trình duyệt Web (HTML5 Canvas) và Windows/macOS.
- [ ] Chế độ Khán Giả (Spectator Mode) phục vụ livestream và các giải đấu eSports cộng đồng.
