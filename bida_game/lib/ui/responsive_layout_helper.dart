import 'dart:math' as math;
import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState;
import 'package:flutter/material.dart';

/// Bộ công cụ điều phối thích ứng linh hoạt (Flexfi Upscale Helper)
/// Tự động nhận diện và tính toán tỷ lệ hiển thị hoàn hảo trên:
/// - Samsung Galaxy Z Fold (Màn hình trong vuông 6:5, màn hình phụ 23:9, chế độ Flex Mode gập 90°)
/// - Microsoft Surface Duo / Duo 2 (Chế độ trải rộng 2 màn hình có bản lề ở giữa, màn hình đơn 4:3)
/// - Máy tính bảng iPad / Android Tablets (Tỷ lệ 4:3, 16:10, 3:2)
/// - Mọi loại điện thoại thông thường (16:9, 18:9, 19.5:9, 20:9, 21:9)
/// - Thiết bị màn hình nhỏ / siêu dài
class ResponsiveLayoutHelper {
  final double screenWidth;
  final double screenHeight;
  final double aspectRatio;
  final bool hasHinge;
  final bool isVerticalHinge;
  final bool isHorizontalHinge;
  final bool isFlexMode;
  final Rect? hingeBounds;
  final bool isSquareOrFoldable;
  final bool isUltraWide;
  final bool isCompact;
  final bool isUltraCompact;
  final bool isTablet;
  final double upscaleFactor;

  const ResponsiveLayoutHelper._({
    required this.screenWidth,
    required this.screenHeight,
    required this.aspectRatio,
    required this.hasHinge,
    required this.isVerticalHinge,
    required this.isHorizontalHinge,
    required this.isFlexMode,
    required this.hingeBounds,
    required this.isSquareOrFoldable,
    required this.isUltraWide,
    required this.isCompact,
    required this.isUltraCompact,
    required this.isTablet,
    required this.upscaleFactor,
  });

  factory ResponsiveLayoutHelper.of(BuildContext context, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final ratio = height > 0 ? (width / height) : 1.77;

    // 1. Nhận diện Bản lề gập & Màn hình kép qua MediaQuery.displayFeatures
    final mediaQuery = MediaQuery.of(context);
    DisplayFeature? hingeFeature;
    try {
      for (final f in mediaQuery.displayFeatures) {
        if (f.type == DisplayFeatureType.hinge || f.type == DisplayFeatureType.fold) {
          hingeFeature = f;
          break;
        }
      }
    } catch (_) {}

    final bool hasHinge = hingeFeature != null;
    final bool isFlexMode = hingeFeature?.state == DisplayFeatureState.postureHalfOpened;
    final Rect? hingeBounds = hingeFeature?.bounds;

    final bool isVerticalHinge = hasHinge &&
        hingeBounds != null &&
        hingeBounds.height > hingeBounds.width &&
        hingeBounds.width > 0;

    final bool isHorizontalHinge = hasHinge &&
        hingeBounds != null &&
        hingeBounds.width >= hingeBounds.height;

    // 2. Phân loại kiểu màn hình:
    // Z Fold màn gập trong / Surface Duo đơn màn / iPad: tỉ lệ < 1.52
    final bool isSquareOrFoldable = ratio < 1.52;
    // Z Fold màn phụ bìa ngoài gập lại (23:9, 22:9) hoặc ultra-wide: tỉ lệ > 2.18
    final bool isUltraWide = ratio > 2.18;
    // Màn hình nhỏ (điện thoại nhỏ, độ phân giải thấp)
    final bool isUltraCompact = height < 365 || width < 680;
    final bool isCompact = height < 460 || width < 820;
    // Máy tính bảng hoặc màn hình lớn cao cấp
    final bool isTablet = (width >= 750 && height >= 580) || (width >= 960 && height >= 560);

    // 3. Hệ số Upscale thông minh (Flexfi Upscale Factor):
    // Giúp chữ, icon, thanh lực, thanh ngắm và các thành phần giao diện
    // phóng to vừa vặn, sang trọng, không bị teo nhỏ trên Z Fold / iPad
    // và không bao giờ bị tràn/vỡ trên điện thoại màn hình nhỏ.
    double upscale = 1.0;
    if (isTablet || (isSquareOrFoldable && width >= 720)) {
      // Upscale 1.12x -> 1.28x trên tablet & Z Fold mở rộng
      final baseDim = math.min(width, height);
      upscale = (baseDim / 540.0).clamp(1.10, 1.28);
    } else if (isUltraCompact) {
      upscale = 0.90;
    } else if (isCompact) {
      upscale = 0.96;
    } else {
      upscale = 1.0;
    }

    return ResponsiveLayoutHelper._(
      screenWidth: width,
      screenHeight: height,
      aspectRatio: ratio,
      hasHinge: hasHinge,
      isVerticalHinge: isVerticalHinge,
      isHorizontalHinge: isHorizontalHinge,
      isFlexMode: isFlexMode,
      hingeBounds: hingeBounds,
      isSquareOrFoldable: isSquareOrFoldable,
      isUltraWide: isUltraWide,
      isCompact: isCompact,
      isUltraCompact: isUltraCompact,
      isTablet: isTablet,
      upscaleFactor: upscale,
    );
  }

  /// Tính toán kích thước tối ưu tuyệt đối cho Bàn Bida (tỷ lệ 2:1)
  /// và các cụm điều khiển hai bên (Cơ kéo lực bên trái, Thước ngắm bên phải).
  ///
  /// Đảm bảo trên mọi hệ máy:
  /// - Bàn bida luôn to nhất có thể mà không bị cắt xén
  /// - Thanh lực & Thước ngắm có chiều cao đồng nhất với bàn bida (không bị kéo dài lê thê gấp đôi trên Z Fold)
  /// - Không bao giờ bị lệch tâm hay đè lên bản lề Surface Duo
  OptimalTableMetrics computeTableMetrics({
    required double availableWidth,
    required double availableHeight,
  }) {
    // Chiều rộng các cụm điều khiển đã được nhân hệ số upscale
    final powerWidth = (isUltraCompact ? 36.0 : (isCompact ? 44.0 : 52.0)) * upscaleFactor;
    final aimWidth = (isUltraCompact ? 34.0 : (isCompact ? 40.0 : 46.0)) * upscaleFactor;
    final sideSpacing = (isUltraCompact ? 4.0 : (isCompact ? 6.0 : 8.0)) * upscaleFactor;
    final totalControlsWidth = powerWidth + aimWidth + (sideSpacing * 2);

    // Bàn bida có tỉ lệ vật lý 2:1 -> tableWidth = 2 * tableHeight
    // tableWidth + totalControlsWidth <= availableWidth -> tableHeight <= (availableWidth - totalControlsWidth) / 2
    // tableHeight <= availableHeight
    final maxHByWidth = math.max(100.0, (availableWidth - totalControlsWidth) / 2.0);
    final tableHeight = math.min(availableHeight, maxHByWidth);
    final tableWidth = tableHeight * 2.0;

    return OptimalTableMetrics(
      tableWidth: tableWidth,
      tableHeight: tableHeight,
      powerControlWidth: powerWidth,
      aimControlWidth: aimWidth,
      sideSpacing: sideSpacing,
      stationWidth: tableWidth + totalControlsWidth,
      stationHeight: tableHeight,
      upscaleFactor: upscaleFactor,
    );
  }
}

/// Chứa các thông số kích thước đã được upscale và căn chỉnh hoàn hảo
class OptimalTableMetrics {
  final double tableWidth;
  final double tableHeight;
  final double powerControlWidth;
  final double aimControlWidth;
  final double sideSpacing;
  final double stationWidth;
  final double stationHeight;
  final double upscaleFactor;

  const OptimalTableMetrics({
    required this.tableWidth,
    required this.tableHeight,
    required this.powerControlWidth,
    required this.aimControlWidth,
    required this.sideSpacing,
    required this.stationWidth,
    required this.stationHeight,
    required this.upscaleFactor,
  });
}

