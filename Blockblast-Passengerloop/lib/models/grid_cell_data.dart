import 'enums.dart';

/// Dữ liệu của một ô trên bàn cờ 8x8
class GridCellData {
  final int row;
  final int col;
  PetColor? petColor;
  HazardType? hazard;
  int iceLayer; // 0: không có băng, 1: băng nứt, 2: băng nguyên
  int bombTurns; // Số lượt đếm ngược của bom
  bool isLocked; // Bị khóa không thể đặt gạch (do bom nổ hoặc dị hình)
  double animScale;
  double animOffsetY;

  GridCellData({
    required this.row,
    required this.col,
    this.petColor,
    this.hazard,
    this.iceLayer = 0,
    this.bombTurns = 0,
    this.isLocked = false,
    this.animScale = 1.0,
    this.animOffsetY = 0.0,
  });

  /// Kiểm tra ô có trống để đặt khối gạch vào không
  bool get isEmpty =>
      !isLocked &&
      petColor == null &&
      hazard != HazardType.stone;

  /// Kiểm tra ô có đang chứa vật thể (để tính toán đầy hàng)
  bool get hasContent =>
      petColor != null || hazard == HazardType.stone;

  /// Sao chép dữ liệu ô
  GridCellData clone() {
    return GridCellData(
      row: row,
      col: col,
      petColor: petColor,
      hazard: hazard,
      iceLayer: iceLayer,
      bombTurns: bombTurns,
      isLocked: isLocked,
      animScale: animScale,
      animOffsetY: animOffsetY,
    );
  }

  void reset() {
    petColor = null;
    hazard = null;
    iceLayer = 0;
    bombTurns = 0;
    isLocked = false;
    animScale = 1.0;
    animOffsetY = 0.0;
  }
}

