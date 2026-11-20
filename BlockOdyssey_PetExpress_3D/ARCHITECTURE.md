# 🎮 Block Odyssey: Pet Express (Unity 6 URP) - Architecture & Game Design

Dự án tái cấu trúc hoàn chỉnh từ nguyên mẫu Flutter sang nền tảng **Unity 6 (URP)** chuẩn **3D Stylized Toy Diorama**, tối ưu hóa cho màn hình dọc di động **9:16 (1080 x 1920)**.

---

## 🏗️ 1. Cấu Trúc Dự Án (Clean ScriptableObject Architecture)

```
BlockOdyssey_PetExpress_3D/
├── Assets/
│   ├── Scripts/
│   │   ├── Data/
│   │   │   ├── PetEnums.cs              # 5 màu thú (Corgi, Mèo, Vịt, Thỏ, Cáo), Chướng ngại vật & Skin
│   │   │   ├── PetColorDataSO.cs        # SO dữ liệu màu, prefab 3D, âm thanh tiếng kêu, hạt sáng
│   │   │   ├── PolyominoShapeSO.cs      # SO khối gạch Polyomino (1x1 đến 5-omino) + thuật toán xoay 90°
│   │   │   ├── LevelDataSO.cs           # SO cấu hình bàn cờ 8x8, xe buýt, chướng ngại vật & khóa ghế
│   │   │   └── GameSkinSO.cs            # SO 4 chủ đề skin (Kawaii, Jelly, RGB, Mahjong)
│   │   ├── Events/
│   │   │   ├── GameEventSO.cs           # Kênh truyền tin phát sự kiện Decoupled
│   │   │   ├── GameEventListener.cs     # Component lắng nghe sự kiện trên GameObject
│   │   │   └── GameEvents.cs            # Định nghĩa payload dữ liệu nổ hàng, đón xe, tràn ghế
│   │   ├── Core/
│   │   │   ├── GridBoardController.cs   # Quản lý lưới 8x8, nổ hàng/cột, giải phóng khách, va chạm
│   │   │   ├── BusStationController.cs  # Trạm xe buýt, Holding Dock 5 ghế, tự động đón khách từ ghế chờ
│   │   │   ├── SmartSpawner.cs          # Sinh 3 khối gạch ngẫu nhiên + Mercy Rule (>92% winnability)
│   │   │   ├── RelicManager.cs          # 3 Cổ vật: Búa Rèn Lửa 3x3, La Bàn Gió 90°, Lăng Kính Từ
│   │   │   ├── ActionQueue.cs           # Vòng lặp 7 bước tất định (Deterministic 7-Step Pipeline)
│   │   │   └── PlayerEconomyManager.cs  # Quản lý Xu Vàng, Ngọc, Chuỗi thắng x3, Cài đặt âm thanh
│   │   ├── Visuals/
│   │   │   ├── ParabolicJumper.cs       # Nhảy đường cong Parabol Bezier + Squash & Stretch + TrailRenderer
│   │   │   ├── BusVehicleVisual.cs      # Xe buýt 3D nhún gầm lò xo (Spring Bounce) + tai ve vẩy
│   │   │   ├── PetBlockVisual.cs        # Khối thú cưng thở bồng bềnh + chớp mắt Kawaii
│   │   │   └── ToyDioramaLighting.cs    # Ánh sáng Key Light mặt trời ấm + Rim Light xanh ngọc
│   │   └── UI/
│   │       ├── GamePlayUIController.cs  # HUD màn 1: Level, Streak x3, Tiền vàng, Xe buýt, Khay Next
│   │       ├── SagaMapUIController.cs   # Bản đồ màn 2: Đảo bay 3D diorama + Nút PLAY vàng 3D cực đại
│   │       ├── SanctuaryUIController.cs # Đảo thú màn 3: Cat Cafe, Duck Pool, Rương thu hoạch Idle
│   │       └── ShopUIController.cs      # Cửa hàng màn 4: Đài xoay đèn Spotlight + Khay Skin Jelly/RGB
│   └── Shaders/
│       └── ToonToyShader.shader         # Shader URP Ramp Toon 2-tone, Specular Gloss bóng bẩy, Rim Light & Outline
├── Packages/
│   └── manifest.json                    # Cấu hình URP 17.1.0, InputSystem, TextMeshPro, uGUI
└── ProjectSettings/
    └── ProjectSettings.asset            # Tên game "Block Odyssey: Pet Express", Orientation: Portrait 9:16
```

---

## 🎲 2. Luật Chơi & Vòng Lặp Trò Chơi (Core Loop)

1. **Khay Next Tray**: Cung cấp 3 khối gạch. Thuật toán `SmartSpawner` ưu tiên sinh màu của xe buýt đang chờ và luôn áp dụng **Mercy Rule** (đảm bảo ít nhất 1 khối đặt vừa bàn cờ).
2. **Kéo thả & Nổ dòng**: Thả khối vào bàn cờ 8x8. Khi hoàn thành bất kỳ hàng ngang hoặc cột dọc nào, hàng đó nổ hiệu ứng ánh sao và dấu chân thú `🐾`.
3. **Phân Luồng Đón Khách (Passenger Extraction)**:
   - Thú cưng **CÙNG MÀU** với Active Bus: Nhảy parabol vào lòng xe buýt.
   - Thú cưng **KHÁC MÀU**: Chuyển vào ngồi tại **Băng Ghế Chờ (Holding Dock - 5 chỗ)**.
4. **Tự Động Đón Khách Từ Ghế Chờ**: Khi xe buýt đầy khách, xe xuất bến theo đường cua chữ U. Khi xe tiếp theo vào trạm, xe lập tức **quét ghế chờ và hút toàn bộ khách cùng màu lên xe**, giải phóng ghế chờ!
5. **Điều kiện Thua**: Ghế chờ kín 5 chỗ mà có thú khác màu bị đẩy xuống (Dock Overflow), hoặc không còn chỗ đặt khối nào trong khay (Gridlock).
6. **Điều kiện Thắng**: Hoàn thành toàn bộ số lượng xe buýt yêu cầu của màn chơi.
