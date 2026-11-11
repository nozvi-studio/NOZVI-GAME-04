import 'package:flutter/material.dart';

/// Enum đại diện cho 5 loài thú cưng và màu sắc chủ đạo
enum PetColor {
  red,
  yellow,
  blue,
  green,
  orange;

  String get displayName {
    switch (this) {
      case PetColor.red:
        return 'Corgi';
      case PetColor.yellow:
        return 'Cat';
      case PetColor.blue:
        return 'Duck';
      case PetColor.green:
        return 'Rabbit';
      case PetColor.orange:
        return 'Fox';
    }
  }

  String get vietnameseName {
    switch (this) {
      case PetColor.red:
        return 'Corgi Đỏ';
      case PetColor.yellow:
        return 'Mèo Vàng';
      case PetColor.blue:
        return 'Vịt Xanh Dương';
      case PetColor.green:
        return 'Thỏ Xanh Lá';
      case PetColor.orange:
        return 'Cáo Cam';
    }
  }

  String get animalName {
    switch (this) {
      case PetColor.red:
        return 'Corgi';
      case PetColor.yellow:
        return 'Mèo';
      case PetColor.blue:
        return 'Vịt';
      case PetColor.green:
        return 'Thỏ';
      case PetColor.orange:
        return 'Cáo';
    }
  }

  String get emoji {
    switch (this) {
      case PetColor.red:
        return '🐶';
      case PetColor.yellow:
        return '🐱';
      case PetColor.blue:
        return '🦆';
      case PetColor.green:
        return '🐰';
      case PetColor.orange:
        return '🦊';
    }
  }

  /// Màu đỉnh Gradient của khối gạch Toy 2.5D
  Color get topGradientStart {
    switch (this) {
      case PetColor.red:
        return const Color(0xFFFF6B5B);
      case PetColor.yellow:
        return const Color(0xFFFFD84D);
      case PetColor.blue:
        return const Color(0xFF4FC3F7);
      case PetColor.green:
        return const Color(0xFF81E659);
      case PetColor.orange:
        return const Color(0xFFFF9D42);
    }
  }

  /// Màu đáy Gradient của khối gạch Toy 2.5D
  Color get topGradientEnd {
    switch (this) {
      case PetColor.red:
        return const Color(0xFFE84538);
      case PetColor.yellow:
        return const Color(0xFFF5B727);
      case PetColor.blue:
        return const Color(0xFF1E90FF);
      case PetColor.green:
        return const Color(0xFF4BC226);
      case PetColor.orange:
        return const Color(0xFFE86F17);
    }
  }

  /// Màu mặt trên đại diện của khối gạch
  Color get primaryColor => topGradientEnd;

  /// Màu phần đế 3D (Extrusion Lip) tối màu hơn mặt trên
  Color get darkColor {
    switch (this) {
      case PetColor.red:
        return const Color(0xFFA82419);
      case PetColor.yellow:
        return const Color(0xFFB87D0E);
      case PetColor.blue:
        return const Color(0xFF0D5CA8);
      case PetColor.green:
        return const Color(0xFF2D8512);
      case PetColor.orange:
        return const Color(0xFF9E4105);
    }
  }

  /// Màu má hồng / chi tiết phụ trên khuôn mặt thú cưng
  Color get cheekColor {
    switch (this) {
      case PetColor.red:
        return const Color(0xFFFF9E99);
      case PetColor.yellow:
        return const Color(0xFFFF8A80);
      case PetColor.blue:
        return const Color(0xFFFF8A80);
      case PetColor.green:
        return const Color(0xFFFFB2C1);
      case PetColor.orange:
        return const Color(0xFFFFF5EB);
    }
  }

  /// Màu chi tiết nổi bật (mỏ vịt, tai trong thỏ, má cáo...)
  Color get accentColor {
    switch (this) {
      case PetColor.red:
        return const Color(0xFFFF9E99);
      case PetColor.yellow:
        return const Color(0xFFFF8A80);
      case PetColor.blue:
        return const Color(0xFFFF9800); // Mỏ vịt
      case PetColor.green:
        return const Color(0xFFFFB2C1); // Tai trong thỏ
      case PetColor.orange:
        return const Color(0xFFFFF5EB); // Má trắng cáo
    }
  }

  /// Màu viền sáng nổi bật
  Color get lightColor {
    switch (this) {
      case PetColor.red:
        return const Color(0xFFFF9E99);
      case PetColor.yellow:
        return const Color(0xFFFFE082);
      case PetColor.blue:
        return const Color(0xFF81D4FA);
      case PetColor.green:
        return const Color(0xFFB9F6CA);
      case PetColor.orange:
        return const Color(0xFFFFCC80);
    }
  }
}

/// Các ô chướng ngại vật đặc biệt trên bàn cờ
enum HazardType {
  /// Đá tảng xám không thể nổ bằng hàng/cột thường
  stone,

  /// Lớp băng bao bọc thú cưng (cần 2 lần nổ hàng mới giải phóng)
  ice,

  /// Bom hẹn giờ, đếm ngược lượt; nếu về 0 sẽ nổ khóa vùng 3x3
  bomb,

  /// Dây leo xanh lan sang ô trống cạnh bên nếu 2 lượt liên tiếp không nổ hàng
  vine;

  String get displayName {
    switch (this) {
      case HazardType.stone:
        return 'Đá Tảng';
      case HazardType.ice:
        return 'Băng Giá';
      case HazardType.bomb:
        return 'Bom Hẹn Giờ';
      case HazardType.vine:
        return 'Dây Leo';
    }
  }
}

/// Hai cổ vật kỹ năng ở đáy màn hình
enum RelicType {
  /// Búa Rèn Lửa: Sạc bằng phá 3 hàng, phá hủy vùng 3x3 và giải cứu thú cưng
  hammer,

  /// La Bàn Gió: Sạc khi đón đủ 2 chuyến xe, xoay 90 độ cả 3 khối trong khay Next
  compass;

  String get vietnameseName {
    switch (this) {
      case RelicType.hammer:
        return 'Búa Rèn Lửa';
      case RelicType.compass:
        return 'La Bàn Gió';
    }
  }
}

/// Trạng thái tương tác của người chơi
enum GamePhase {
  idle,
  draggingBlock,
  targetingHammer,
  executingActionQueue,
  levelWon,
  levelLost,
}

/// Tên 7 bước trong chuỗi thực thi ActionQueue
enum ActionStepName {
  placeBlock,
  evaluateLines,
  extractPassengers,
  boardAndDock,
  updateHazards,
  checkRelics,
  checkGameState,
}

/// 4 Bộ Skin thương mại cho khối gạch 2.5D
enum GameSkinTheme {
  kawaiiPets,
  jellyCandy,
  rgbMechanical,
  jadeMahjong;

  String get title {
    switch (this) {
      case GameSkinTheme.kawaiiPets:
        return 'Thú Cưng Kawaii';
      case GameSkinTheme.jellyCandy:
        return 'Thạch Rau Câu Jelly';
      case GameSkinTheme.rgbMechanical:
        return 'Bàn Phím Cơ RGB';
      case GameSkinTheme.jadeMahjong:
        return 'Mạt Chược Ngọc';
    }
  }

  String get description {
    switch (this) {
      case GameSkinTheme.kawaiiPets:
        return 'Bộ đồ chơi thú cưng 2.5D nguyên bản siêu đáng yêu.';
      case GameSkinTheme.jellyCandy:
        return 'Thạch hoa quả núng nính trong suốt ánh đường ngọt ngào.';
      case GameSkinTheme.rgbMechanical:
        return 'Keycap PBT chuẩn eSports kèm đèn nền RGB chuyển sắc.';
      case GameSkinTheme.jadeMahjong:
        return 'Quân bài ngọc bích cổ điển chạm khắc ánh vàng sang trọng.';
    }
  }

  String get badgeEmoji {
    switch (this) {
      case GameSkinTheme.kawaiiPets:
        return '🐶';
      case GameSkinTheme.jellyCandy:
        return '🍮';
      case GameSkinTheme.rgbMechanical:
        return '⌨️';
      case GameSkinTheme.jadeMahjong:
        return '🀄';
    }
  }

  int get priceCoins {
    switch (this) {
      case GameSkinTheme.kawaiiPets:
        return 0;
      case GameSkinTheme.jellyCandy:
        return 300;
      case GameSkinTheme.rgbMechanical:
        return 600;
      case GameSkinTheme.jadeMahjong:
        return 1000;
    }
  }

  int get priceGems {
    switch (this) {
      case GameSkinTheme.kawaiiPets:
        return 0;
      case GameSkinTheme.jellyCandy:
        return 20;
      case GameSkinTheme.rgbMechanical:
        return 40;
      case GameSkinTheme.jadeMahjong:
        return 60;
    }
  }
}


