namespace BlockOdyssey.Data
{
    /// <summary>
    /// 5 Màu thú cưng đồ chơi 3D đặc trưng trong game
    /// </summary>
    public enum PetColor
    {
        Red = 0,     // 🐶 Corgi Đỏ
        Yellow = 1,  // 🐱 Mèo Vàng
        Blue = 2,    // 🦆 Vịt Xanh Dương
        Green = 3,   // 🐰 Thỏ Xanh Lá
        Orange = 4,  // 🦊 Cáo Cam
        Rainbow = 5  // 🌈 Xe buýt Cầu Vồng (Chấp nhận mọi màu)
    }

    /// <summary>
    /// Các loại chướng ngại vật trên bàn cờ 8x8
    /// </summary>
    public enum HazardType
    {
        None = 0,
        Stone = 1,  // Đá tảng: Chỉ phá được bằng Búa Rèn Lửa
        Ice = 2,    // Băng tuyết: Cần 2 lần nổ dòng để giải phóng thú cưng (hoặc 1 hit ở Chapter 10)
        Bomb = 3,   // Bom hẹn giờ: Đếm lùi sau mỗi lượt thả khối, nổ thua cuộc khi về 0
        Vine = 4    // Dây leo gai: Khóa thú cưng cho đến khi dòng liền kề được giải phóng
    }

    /// <summary>
    /// 4 Bộ giao diện mỹ thuật (Skin Themes)
    /// </summary>
    public enum GameSkinTheme
    {
        KawaiiPets = 0,    // Thú cưng Kawaii Cổ Điển
        JellyCandy = 1,    // Thạch Rau Câu Jelly núng nính
        RgbMechanical = 2, // Bàn phím cơ RGB phát sáng
        JadeMahjong = 3    // Mạt Chược Ngọc Bích truyền thống
    }
}
