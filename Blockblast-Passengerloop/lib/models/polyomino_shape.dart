import 'dart:math' as math;
import 'enums.dart';

/// Ô thành phần trong khối gạch Polyomino
class ShapeTile {
  final int r; // Chỉ số hàng tương đối
  final int c; // Chỉ số cột tương đối
  final PetColor petColor;
  final HazardType? hazard;

  const ShapeTile({
    required this.r,
    required this.c,
    required this.petColor,
    this.hazard,
  });

  ShapeTile copyWith({
    int? r,
    int? c,
    PetColor? petColor,
    HazardType? hazard,
  }) {
    return ShapeTile(
      r: r ?? this.r,
      c: c ?? this.c,
      petColor: petColor ?? this.petColor,
      hazard: hazard ?? this.hazard,
    );
  }
}

/// Khối gạch Polyomino với các ô thú cưng
class PolyominoShape {
  final String id;
  final String name;
  final List<ShapeTile> tiles;
  final int width;
  final int height;
  final int rotation; // 0, 90, 180, 270

  PolyominoShape({
    required this.id,
    required this.name,
    required this.tiles,
    required this.width,
    required this.height,
    this.rotation = 0,
  });

  /// Hàm xoay 90 độ chiều kim đồng hồ: (r, c) -> (c, -r) rồi chuẩn hóa về gốc (0, 0)
  PolyominoShape rotateClockwise() {
    // 1. Áp dụng ma trận xoay 90 độ theo chiều kim đồng hồ
    final rawRotated = tiles.map((tile) {
      return ShapeTile(
        r: tile.c,
        c: -tile.r,
        petColor: tile.petColor,
        hazard: tile.hazard,
      );
    }).toList();

    // 2. Tìm giá trị minR và minC để dịch về gốc (0, 0)
    int minR = rawRotated.map((t) => t.r).reduce(math.min);
    int minC = rawRotated.map((t) => t.c).reduce(math.min);

    final normalizedTiles = rawRotated.map((tile) {
      return ShapeTile(
        r: tile.r - minR,
        c: tile.c - minC,
        petColor: tile.petColor,
        hazard: tile.hazard,
      );
    }).toList();

    int maxR = normalizedTiles.map((t) => t.r).reduce(math.max);
    int maxC = normalizedTiles.map((t) => t.c).reduce(math.max);

    return PolyominoShape(
      id: id,
      name: name,
      tiles: normalizedTiles,
      width: maxC + 1,
      height: maxR + 1,
      rotation: (rotation + 90) % 360,
    );
  }

  PolyominoShape clone() {
    return PolyominoShape(
      id: id,
      name: name,
      tiles: List<ShapeTile>.from(tiles),
      width: width,
      height: height,
      rotation: rotation,
    );
  }
}

/// Các khuôn mẫu hình dạng khối gạch Polyomino cơ bản
class ShapeTemplate {
  final String name;
  final List<PointInt> offsets;

  const ShapeTemplate({required this.name, required this.offsets});
}

class PointInt {
  final int r;
  final int c;
  const PointInt(this.r, this.c);
}

const List<ShapeTemplate> kPolyominoTemplates = [
  // 1-cell (Dot)
  ShapeTemplate(name: 'Dot1x1', offsets: [PointInt(0, 0)]),

  // 2-cell (Domino)
  ShapeTemplate(name: 'Line2_H', offsets: [PointInt(0, 0), PointInt(0, 1)]),
  ShapeTemplate(name: 'Line2_V', offsets: [PointInt(0, 0), PointInt(1, 0)]),

  // 3-cell (Tromino)
  ShapeTemplate(name: 'Line3_H', offsets: [PointInt(0, 0), PointInt(0, 1), PointInt(0, 2)]),
  ShapeTemplate(name: 'Line3_V', offsets: [PointInt(0, 0), PointInt(1, 0), PointInt(2, 0)]),
  ShapeTemplate(name: 'Corner3_TL', offsets: [PointInt(0, 0), PointInt(0, 1), PointInt(1, 0)]),
  ShapeTemplate(name: 'Corner3_BR', offsets: [PointInt(0, 1), PointInt(1, 0), PointInt(1, 1)]),

  // 4-cell (Tetromino)
  ShapeTemplate(name: 'Square2x2', offsets: [PointInt(0, 0), PointInt(0, 1), PointInt(1, 0), PointInt(1, 1)]),
  ShapeTemplate(name: 'Line4_H', offsets: [PointInt(0, 0), PointInt(0, 1), PointInt(0, 2), PointInt(0, 3)]),
  ShapeTemplate(name: 'Line4_V', offsets: [PointInt(0, 0), PointInt(1, 0), PointInt(2, 0), PointInt(3, 0)]),
  ShapeTemplate(name: 'L_Shape_4', offsets: [PointInt(0, 0), PointInt(1, 0), PointInt(2, 0), PointInt(2, 1)]),
  ShapeTemplate(name: 'T_Shape_4', offsets: [PointInt(0, 0), PointInt(0, 1), PointInt(0, 2), PointInt(1, 1)]),

  // 5-cell (Pentamino)
  ShapeTemplate(name: 'Cross5', offsets: [PointInt(0, 1), PointInt(1, 0), PointInt(1, 1), PointInt(1, 2), PointInt(2, 1)]),
];

