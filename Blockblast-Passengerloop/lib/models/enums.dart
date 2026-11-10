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

  /// Màu mặt trên của khối gạch
  Color get primaryColor {
    switch (this) {
      case PetColor.red:
        return const Color(0xFFFF4D4D);
      case PetColor.yellow:
        return const Color(0xFFFFB800);
      case PetColor.blue:
        return const Color(0xFF29B6F6);
      case PetColor.green:
        return const Color(0xFF66BB6A);
      case PetColor.orange:
        return const Color(0xFFFF7043);
    }
  }

  /// Màu phần đế 2.5D (dày 6px tối màu hơn mặt trên)
  Color get darkColor {
    switch (this) {
      case PetColor.red:
        return const Color(0xFFB31B1B);
      case PetColor.yellow:
        return const Color(0xFFB87E00);
      case PetColor.blue:
        return const Color(0xFF0277BD);
      case PetColor.green:
        return const Color(0xFF2E7D32);
      case PetColor.orange:
        return const Color(0xFFD84315);
    }
  }

  /// Màu viền sáng nổi bật
  Color get lightColor {
    switch (this) {
      case PetColor.red:
        return const Color(0xFFFFA4A4);
      case PetColor.yellow:
        return const Color(0xFFFFE082);
      case PetColor.blue:
        return const Color(0xFF81D4FA);
      case PetColor.green:
        return const Color(0xFFA5D6A7);
      case PetColor.orange:
        return const Color(0xFFFFAB91);
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

