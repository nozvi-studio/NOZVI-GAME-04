import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import '../main.dart';
import '../models/table_skin_model.dart';
import '../services/progression_service.dart';

/// Component đồ họa hiển thị Skin Bàn Bida tùy chỉnh độc quyền theo concept Anime
/// Thiết kế chi tiết cao (High-Definition Vector Art), phân cấp độ lộng lẫy theo độ quý hiếm của bàn.
class TableSkinComponent extends Component with HasGameReference<BilliardGame> {
  TableSkinComponent() {
    priority = -1; // Nằm trên pool_table.png (-2) và nằm dưới bi / VFX (1 và 2)
  }

  @override
  void render(Canvas canvas) {
    final table = ProgressionService.instance.equippedTable;
    final size = game.size;
    if (size.x <= 0 || size.y <= 0) return;

    final pTopLeft = game.playAreaTopLeft;
    final pBottomRight = game.playAreaBottomRight;
    if (pTopLeft.x >= pBottomRight.x || pTopLeft.y >= pBottomRight.y) return;

    final playRect = Rect.fromLTRB(pTopLeft.x, pTopLeft.y, pBottomRight.x, pBottomRight.y);

    // Khi người chơi trang bị skin bàn khác (khác classic_green gốc):
    if (table.id != 'classic_green') {
      final fullRect = Rect.fromLTWH(0, 0, size.x, size.y);

      // 1. Phủ màu Thành Băng & Viền Bàn (Outer Rails) với vân gỗ bóng bẩy 3D
      final railPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            table.railColor,
            Color.lerp(table.railColor, Colors.black, 0.35) ?? table.railColor,
            Color.lerp(table.railColor, Colors.white, 0.12) ?? table.railColor,
            Color.lerp(table.railColor, Colors.black, 0.45) ?? table.railColor,
          ],
          stops: const [0.0, 0.40, 0.70, 1.0],
        ).createShader(fullRect);

      final outerPath = Path()..addRect(fullRect);
      final innerPath = Path()..addRRect(RRect.fromRectAndRadius(playRect, const Radius.circular(8)));
      final railPath = Path.combine(PathOperation.difference, outerPath, innerPath);
      canvas.drawPath(railPath, railPaint);

      // 2. Trang trí thành băng & 4 nẹp góc kim loại theo concept Anime độc đáo
      AnimeTablePatternRenderer.renderAnimeRailDeco(
        canvas: canvas,
        fullRect: fullRect,
        playRect: playRect,
        table: table,
      );

      // 3. Viền nẹp kim loại / hoa văn dát vàng quanh mép thành băng - PHÂN CẤP THEO PHẨM CẤP BÀN
      final isMythic = table.rarity == TableRarity.mythic;
      final isLegendary = table.rarity == TableRarity.legendary || isMythic;
      final isEpic = table.rarity == TableRarity.epic || isLegendary;

      final trimPaint = Paint()
        ..color = table.railAccentColor.withValues(alpha: isMythic ? 0.95 : (isLegendary ? 0.85 : (isEpic ? 0.70 : 0.50)))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMythic ? 2.6 : (isLegendary ? 2.2 : (isEpic ? 1.8 : 1.4));
      canvas.drawRRect(RRect.fromRectAndRadius(playRect, const Radius.circular(8)), trimPaint);
      canvas.drawRect(Rect.fromLTWH(2.5, 2.5, size.x - 5, size.y - 5), trimPaint..strokeWidth = 1.0);

      // Cho bàn Legendary và Mythic: Thêm đường chỉ dát vàng song song chạy dọc mép trong thành băng
      if (isLegendary) {
        final innerGild = Paint()
          ..color = (isMythic ? const Color(0xFFFFD700) : table.railAccentColor).withValues(alpha: isMythic ? 0.85 : 0.65)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        final insetRect = Rect.fromLTRB(playRect.left - 3.5, playRect.top - 3.5, playRect.right + 3.5, playRect.bottom + 3.5);
        canvas.drawRRect(RRect.fromRectAndRadius(insetRect, const Radius.circular(9)), innerGild);
      }

      // 4. Các Điểm Ngắm Kim Cương (Diamond Sights) độc quyền theo Concept Anime & Phẩm Cấp
      _renderDiamondSights(canvas, size, playRect, table);

      // 5. Phủ Lòng Bàn Vải Nỉ (Cloth Felt Gradient)
      final feltPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [table.clothPrimary, table.clothSecondary],
        ).createShader(playRect);
      canvas.drawRRect(RRect.fromRectAndRadius(playRect, const Radius.circular(6)), feltPaint);

      // 6. HỌA TIẾT CONCEPT ANIME ĐỘC ĐÁO & CHI TIẾT CAO IN TRỰC TIẾP LÊN MẶT NỈ
      AnimeTablePatternRenderer.renderAnimePattern(
        canvas: canvas,
        playRect: playRect,
        table: table,
        scale: 1.0,
      );

      // 7. Bóng Đổ Chiều Sâu 3D Thành Băng (Ambient Cushion Drop Shadow)
      final shadowDepth = (size.y * 0.038).clamp(8.0, 18.0);
      final shadowTop = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [table.cushionShadowColor, Colors.transparent],
        ).createShader(Rect.fromLTWH(playRect.left, playRect.top, playRect.width, shadowDepth));
      canvas.drawRect(Rect.fromLTWH(playRect.left, playRect.top, playRect.width, shadowDepth), shadowTop);

      final shadowBottom = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [table.cushionShadowColor, Colors.transparent],
        ).createShader(Rect.fromLTWH(playRect.left, playRect.bottom - shadowDepth, playRect.width, shadowDepth));
      canvas.drawRect(Rect.fromLTWH(playRect.left, playRect.bottom - shadowDepth, playRect.width, shadowDepth), shadowBottom);

      // 8. Vạch Phát Bóng (Head String) & Điểm Đặt Bi (Head Spot / Foot Spot) mạ ánh kim
      final linePaint = Paint()
        ..color = table.railAccentColor.withValues(alpha: isLegendary ? 0.45 : 0.28)
        ..strokeWidth = isLegendary ? 1.2 : 1.0;
      final headX = playRect.left + playRect.width * 0.25;
      final footX = playRect.left + playRect.width * 0.75;
      final midY = playRect.top + playRect.height * 0.5;

      canvas.drawLine(Offset(headX, playRect.top), Offset(headX, playRect.bottom), linePaint);

      // Điểm đặt bi hình thoi kim cương phát sáng
      _drawSpotMarker(canvas, Offset(headX, midY), table.railAccentColor, isLegendary: isLegendary, isMythic: isMythic);
      _drawSpotMarker(canvas, Offset(footX, midY), table.railAccentColor, isLegendary: isLegendary, isMythic: isMythic);

      // 9. Lòng & Vành Miệng 6 Lỗ Bida mạ kim loại 3D tinh xảo (Metallic Beveled Pocket Rings)
      for (final p in game.pockets) {
        final pos = Offset(p.position.x, p.position.y);
        final r = p.radius;

        // Vành nẹp kim loại miệng lỗ (Pocket Bezel)
        final bezelPaint = Paint()
          ..shader = RadialGradient(
            colors: isMythic
                ? [const Color(0xFFFFD700), const Color(0xFFFF8F00), Colors.black87]
                : (isLegendary
                    ? [const Color(0xFFFFD54F), table.railAccentColor, Colors.black87]
                    : [table.railAccentColor.withValues(alpha: 0.85), Colors.black87]),
            stops: isMythic ? const [0.60, 0.85, 1.0] : const [0.75, 0.92, 1.0],
          ).createShader(Rect.fromCircle(center: pos, radius: r * 1.12));
        canvas.drawCircle(pos, r * (isLegendary ? 1.08 : 1.04), bezelPaint);

        // ĐỐI VỚI BÀN HUYỀN THOẠI & THẦN THOẠI: Khảm đá quý quanh vành miệng lỗ
        if (isLegendary) {
          final gemCount = isMythic ? 6 : 4;
          final gemColor = isMythic
              ? (table.id == 'dragon_emperor' ? const Color(0xFFFF1744) : const Color(0xFF00E5FF))
              : (table.id == 'jade_dynasty' ? const Color(0xFF69F0AE) : const Color(0xFFE040FB));
          for (int gi = 0; gi < gemCount; gi++) {
            final a = gi * (2 * math.pi / gemCount);
            final gx = pos.dx + math.cos(a) * (r * 0.98);
            final gy = pos.dy + math.sin(a) * (r * 0.98);
            canvas.drawCircle(Offset(gx, gy), 1.5, Paint()..color = const Color(0xFFFFD700));
            canvas.drawCircle(Offset(gx, gy), 1.0, Paint()..color = gemColor);
            canvas.drawCircle(Offset(gx - 0.3, gy - 0.3), 0.4, Paint()..color = Colors.white);
          }
        }

        // Lòng lỗ sâu thẳm
        final pocketPaint = Paint()..color = table.pocketColor;
        canvas.drawCircle(pos, r * 0.86, pocketPaint);

        // Vòng chỉ viền kim loại sáng bóng
        canvas.drawCircle(
          pos,
          r * 0.86,
          Paint()
            ..color = (isMythic ? const Color(0xFFFFD700) : table.railAccentColor).withValues(alpha: isLegendary ? 0.75 : 0.50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isLegendary ? 1.4 : 1.0,
        );
      }
    }
  }

  void _drawSpotMarker(Canvas canvas, Offset center, Color accent, {bool isLegendary = false, bool isMythic = false}) {
    final size = isMythic ? 4.5 : (isLegendary ? 3.8 : 3.2);
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..lineTo(center.dx + size, center.dy)
      ..lineTo(center.dx, center.dy + size)
      ..lineTo(center.dx - size, center.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = (isMythic ? const Color(0xFFFFD700) : accent).withValues(alpha: 0.85));
    if (isLegendary) {
      // Vòng tròn hào quang bao quanh điểm đặt bi
      canvas.drawCircle(
        center,
        size * 1.5,
        Paint()
          ..color = (isMythic ? const Color(0xFFFFD700) : accent).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
    canvas.drawCircle(center, isLegendary ? 1.5 : 1.2, Paint()..color = Colors.white.withValues(alpha: 0.95));
  }

  /// Vẽ 18 điểm ngắm chuẩn (Diamond Sights) độc quyền theo Concept Anime & Phẩm Cấp
  void _renderDiamondSights(Canvas canvas, Vector2 size, Rect playRect, TableSkinModel table) {
    final accent = table.railAccentColor;
    final concept = table.animeConcept;
    final rarity = table.rarity;

    // Băng dài trên và dưới (mỗi bên 6 điểm ngắm chia đều)
    final wStep = playRect.width / 8;
    for (int i = 1; i <= 7; i++) {
      if (i == 4) continue; // Bỏ qua vị trí lỗ giữa
      final x = playRect.left + wStep * i;
      final topY = playRect.top * 0.45;
      final botY = size.y - (size.y - playRect.bottom) * 0.45;
      _drawSingleAnimeSight(canvas, Offset(x, topY), accent, concept, rarity);
      _drawSingleAnimeSight(canvas, Offset(x, botY), accent, concept, rarity);
    }

    // Băng ngắn trái và phải (mỗi bên 3 điểm ngắm chia đều)
    final hStep = playRect.height / 4;
    for (int i = 1; i <= 3; i++) {
      final y = playRect.top + hStep * i;
      final leftX = playRect.left * 0.45;
      final rightX = size.x - (size.x - playRect.right) * 0.45;
      _drawSingleAnimeSight(canvas, Offset(leftX, y), accent, concept, rarity);
      _drawSingleAnimeSight(canvas, Offset(rightX, y), accent, concept, rarity);
    }
  }

  void _drawSingleAnimeSight(Canvas canvas, Offset pos, Color accent, TableAnimeConcept concept, TableRarity rarity) {
    final isMythic = rarity == TableRarity.mythic;
    final isLegendary = rarity == TableRarity.legendary || isMythic;

    // Đối với bàn Huyền Thoại & Thần Thoại: Vành giác vàng 24K quanh điểm ngắm
    if (isLegendary) {
      canvas.drawCircle(
        pos,
        isMythic ? 4.2 : 3.6,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: isMythic ? 0.90 : 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isMythic ? 1.4 : 1.0,
      );
    }

    switch (concept) {
      case TableAnimeConcept.sakuraZen:
        // Đóa hoa anh đào vàng kim 4 cánh
        final petalPaint = Paint()..color = isLegendary ? const Color(0xFFFFD700) : const Color(0xFFFFD54F);
        canvas.drawCircle(Offset(pos.dx, pos.dy - 1.3), 1.6, petalPaint);
        canvas.drawCircle(Offset(pos.dx + 1.3, pos.dy), 1.6, petalPaint);
        canvas.drawCircle(Offset(pos.dx, pos.dy + 1.3), 1.6, petalPaint);
        canvas.drawCircle(Offset(pos.dx - 1.3, pos.dy), 1.6, petalPaint);
        canvas.drawCircle(pos, 1.0, Paint()..color = const Color(0xFFFF4081));
        break;

      case TableAnimeConcept.cyberTokyo:
        // Điểm ngắm LED Cyber neon hình thoi sắc lẹm
        final r = isLegendary ? 3.6 : 3.0;
        final diamond = Path()
          ..moveTo(pos.dx, pos.dy - r)
          ..lineTo(pos.dx + r, pos.dy)
          ..lineTo(pos.dx, pos.dy + r)
          ..lineTo(pos.dx - r, pos.dy)
          ..close();
        canvas.drawPath(diamond, Paint()..color = const Color(0xFF00E5FF));
        canvas.drawCircle(pos, isLegendary ? 1.5 : 1.2, Paint()..color = Colors.white);
        break;

      case TableAnimeConcept.dragonLava:
        // Vảy rồng hỏa ngọc hình thoi nhọn
        final rx = isLegendary ? 2.8 : 2.4;
        final ry = isLegendary ? 4.4 : 3.8;
        final scale = Path()
          ..moveTo(pos.dx, pos.dy - ry)
          ..lineTo(pos.dx + rx, pos.dy)
          ..lineTo(pos.dx, pos.dy + ry)
          ..lineTo(pos.dx - rx, pos.dy)
          ..close();
        canvas.drawPath(scale, Paint()..color = isMythic ? const Color(0xFFFF1744) : const Color(0xFFFF6D00));
        canvas.drawCircle(pos, isLegendary ? 1.4 : 1.0, Paint()..color = const Color(0xFFFFD54F));
        break;

      case TableAnimeConcept.arcaneGrimoire:
        // Ngôi sao pha lê thạch anh tím 4 cánh
        final s = isLegendary ? 4.2 : 3.6;
        final star = Paint()
          ..color = isMythic ? const Color(0xFF00E5FF) : const Color(0xFFB388FF)
          ..strokeWidth = isLegendary ? 1.5 : 1.2;
        canvas.drawLine(Offset(pos.dx - s, pos.dy), Offset(pos.dx + s, pos.dy), star);
        canvas.drawLine(Offset(pos.dx, pos.dy - s), Offset(pos.dx, pos.dy + s), star);
        canvas.drawCircle(pos, isLegendary ? 1.5 : 1.2, Paint()..color = Colors.white);
        break;

      case TableAnimeConcept.mechaEva:
        // Ô lục giác tổ ong Neon Lime
        final hr = isLegendary ? 3.6 : 3.0;
        final hex = Path();
        for (int i = 0; i < 6; i++) {
          final a = i * math.pi / 3;
          final hx = pos.dx + math.cos(a) * hr;
          final hy = pos.dy + math.sin(a) * hr;
          if (i == 0) {
            hex.moveTo(hx, hy);
          } else {
            hex.lineTo(hx, hy);
          }
        }
        hex.close();
        canvas.drawPath(hex, Paint()..color = const Color(0xFF76FF03));
        canvas.drawCircle(pos, 1.0, Paint()..color = const Color(0xFFFF9100));
        break;

      case TableAnimeConcept.shadowVoid:
        // Viên ngọc hắc ám hình thoi tím đậm
        final r = isLegendary ? 3.6 : 3.0;
        final voidDiamond = Path()
          ..moveTo(pos.dx, pos.dy - r)
          ..lineTo(pos.dx + r, pos.dy)
          ..lineTo(pos.dx, pos.dy + r)
          ..lineTo(pos.dx - r, pos.dy)
          ..close();
        canvas.drawPath(voidDiamond, Paint()..color = const Color(0xFFBA68C8));
        canvas.drawCircle(pos, isLegendary ? 1.5 : 1.2, Paint()..color = const Color(0xFF212121));
        break;

      case TableAnimeConcept.classic:
        // Khảm xà cừ hình thoi chuẩn quốc tế (Mother-of-pearl rhombus)
        final rx = isLegendary ? 3.0 : 2.4;
        final ry = isLegendary ? 4.2 : 3.4;
        final p = Path()
          ..moveTo(pos.dx, pos.dy - ry)
          ..lineTo(pos.dx + rx, pos.dy)
          ..lineTo(pos.dx, pos.dy + ry)
          ..lineTo(pos.dx - rx, pos.dy)
          ..close();
        canvas.drawPath(p, Paint()..color = Colors.white.withValues(alpha: 0.90));
        canvas.drawPath(
          p,
          Paint()
            ..color = isLegendary ? const Color(0xFFFFD54F) : const Color(0xFFB0BEC5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isLegendary ? 1.0 : 0.6,
        );
        break;
    }
  }
}

/// Bộ dựng hình đồ họa Concept Anime cao cấp cho Bàn Đấu (Dùng chung cho cả In-Game & Shop Preview)
class AnimeTablePatternRenderer {
  /// Vẽ hoa văn Concept Anime sắc nét, đa tầng và độ phân giải cao lên mặt nỉ bàn
  static void renderAnimePattern({
    required Canvas canvas,
    required Rect playRect,
    required TableSkinModel table,
    required double scale,
  }) {
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(playRect, Radius.circular(6 * scale)));

    final center = playRect.center;
    final accent = table.railAccentColor;
    final isMythic = table.rarity == TableRarity.mythic;
    final isLegendary = table.rarity == TableRarity.legendary || isMythic;
    final isEpic = table.rarity == TableRarity.epic || isLegendary;

    // 0. KHUNG VIỀN HOA VĂN GẤM DÁT VÀNG (Brocade Border) CHO CÁC BÀN TỪ EPIC ĐẾN THẦN THOẠI
    _renderBrocadeBorder(canvas, playRect, table, scale, isEpic: isEpic, isLegendary: isLegendary, isMythic: isMythic);

    // 1. HOA VĂN CHÍNH THEO CONCEPT ANIME ĐỘC ĐÁO
    switch (table.animeConcept) {
      case TableAnimeConcept.sakuraZen:
        _renderSakuraPattern(canvas, playRect, center, accent, scale, isLegendary);
        break;
      case TableAnimeConcept.cyberTokyo:
        _renderCyberPattern(canvas, playRect, center, accent, scale, isLegendary);
        break;
      case TableAnimeConcept.dragonLava:
        _renderDragonPattern(canvas, playRect, center, accent, scale, isMythic, isLegendary);
        break;
      case TableAnimeConcept.arcaneGrimoire:
        _renderArcanePattern(canvas, playRect, center, accent, scale, isMythic, isLegendary);
        break;
      case TableAnimeConcept.shadowVoid:
        _renderShadowPattern(canvas, playRect, center, accent, scale, isLegendary);
        break;
      case TableAnimeConcept.mechaEva:
        _renderMechaPattern(canvas, playRect, center, accent, scale, isLegendary);
        break;
      case TableAnimeConcept.classic:
        _renderClassicPattern(canvas, playRect, center, accent, scale, isLegendary);
        break;
    }

    canvas.restore();
  }

  /// Khung viền chỉ vàng / gấm lụa hoàng gia chạy vòng quanh mặt nỉ bàn
  static void _renderBrocadeBorder(
    Canvas canvas,
    Rect rect,
    TableSkinModel table,
    double scale, {
    required bool isEpic,
    required bool isLegendary,
    required bool isMythic,
  }) {
    if (!isEpic) return;

    final inset = (isMythic ? 12.0 : (isLegendary ? 10.0 : 8.0)) * scale;
    final borderRect = Rect.fromLTRB(rect.left + inset, rect.top + inset, rect.right - inset, rect.bottom - inset);

    final borderPaint = Paint()
      ..color = (isMythic ? const Color(0xFFFFD700) : (isLegendary ? const Color(0xFFFFD54F) : table.railAccentColor))
          .withValues(alpha: isMythic ? 0.45 : (isLegendary ? 0.35 : 0.22))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isMythic ? 1.6 : (isLegendary ? 1.2 : 0.9)) * scale;

    canvas.drawRRect(RRect.fromRectAndRadius(borderRect, Radius.circular(4 * scale)), borderPaint);

    if (isLegendary) {
      // Đường viền kép thứ 2 và góc hoa văn quả trám hoàng gia
      final innerInset = inset + 4.5 * scale;
      final innerRect = Rect.fromLTRB(rect.left + innerInset, rect.top + innerInset, rect.right - innerInset, rect.bottom - innerInset);
      canvas.drawRRect(RRect.fromRectAndRadius(innerRect, Radius.circular(2 * scale)), borderPaint..strokeWidth = 0.6 * scale);

      // 4 Hạt ngọc quả trám mạ vàng ở 4 góc viền nỉ
      final cornerDist = innerInset + 6 * scale;
      final corners = [
        Offset(rect.left + cornerDist, rect.top + cornerDist),
        Offset(rect.right - cornerDist, rect.top + cornerDist),
        Offset(rect.left + cornerDist, rect.bottom - cornerDist),
        Offset(rect.right - cornerDist, rect.bottom - cornerDist),
      ];
      final diamondPaint = Paint()
        ..color = (isMythic ? const Color(0xFFFFD700) : const Color(0xFFFFD54F)).withValues(alpha: 0.55);
      for (final c in corners) {
        final dPath = Path()
          ..moveTo(c.dx, c.dy - 3 * scale)
          ..lineTo(c.dx + 3 * scale, c.dy)
          ..lineTo(c.dx, c.dy + 3 * scale)
          ..lineTo(c.dx - 3 * scale, c.dy)
          ..close();
        canvas.drawPath(dPath, diamondPaint);
      }
    }
  }

  /// 1. Concept Anime Sakura Zen / Kiếm Đạo Kimetsu - Đa tầng tinh xảo
  static void _renderSakuraPattern(Canvas canvas, Rect rect, Offset center, Color accent, double scale, bool isLegendary) {
    // Tầng 1: Vân sóng nước Seigaiha cổ truyền Nhật Bản chìm nhẹ dưới mặt nỉ
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8 * scale;
    final waveR = 24.0 * scale;
    for (double wx = rect.left + 15; wx < rect.right; wx += waveR * 1.6) {
      for (double wy = rect.top + 15; wy < rect.bottom; wy += waveR * 0.9) {
        canvas.drawArc(
          Rect.fromCircle(center: Offset(wx, wy), radius: waveR),
          math.pi,
          math.pi,
          false,
          wavePaint,
        );
      }
    }

    // Tầng 2: Vòng nguyệt quế hoa văn Kamon hoàng gia ở trung tâm
    final crestPaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: isLegendary ? 0.48 : 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isLegendary ? 2.4 : 2.0) * scale;

    final outerR = rect.height * 0.28;
    canvas.drawCircle(center, outerR, crestPaint);
    canvas.drawCircle(center, outerR * 0.92, crestPaint..strokeWidth = 1.0 * scale);
    canvas.drawCircle(center, outerR * 0.72, crestPaint..strokeWidth = 1.4 * scale);

    // 16 tia nhụy vàng tinh xảo
    final spokePaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.35)
      ..strokeWidth = 1.0 * scale;
    for (int i = 0; i < 16; i++) {
      final a = (i * 2 * math.pi) / 16;
      final p1 = Offset(center.dx + math.cos(a) * (outerR * 0.72), center.dy + math.sin(a) * (outerR * 0.72));
      final p2 = Offset(center.dx + math.cos(a) * (outerR * 0.92), center.dy + math.sin(a) * (outerR * 0.92));
      canvas.drawLine(p1, p2, spokePaint);
    }

    // 8 đóa hoa anh đào lớn nở rộ bên trong gia huy
    const petalCount = 8;
    for (int i = 0; i < petalCount; i++) {
      final angle = (i * 2 * math.pi) / petalCount;
      final px = center.dx + math.cos(angle) * (outerR * 0.45);
      final py = center.dy + math.sin(angle) * (outerR * 0.45);
      _drawSingleSakuraPetal(canvas, Offset(px, py), 9.0 * scale, angle, true);
    }
    // Tâm hoa anh đào trung tâm dát vàng
    canvas.drawCircle(center, outerR * 0.16, Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.40));
    canvas.drawCircle(center, outerR * 0.08, Paint()..color = Colors.white.withValues(alpha: 0.80));

    // Tầng 3: Các cụm hoa và cánh hoa anh đào bay lượn lả lướt khắp bàn
    final petalPoints = [
      Offset(rect.left + rect.width * 0.12, rect.top + rect.height * 0.22),
      Offset(rect.left + rect.width * 0.18, rect.top + rect.height * 0.75),
      Offset(rect.left + rect.width * 0.32, rect.top + rect.height * 0.38),
      Offset(rect.left + rect.width * 0.68, rect.top + rect.height * 0.65),
      Offset(rect.right - rect.width * 0.18, rect.top + rect.height * 0.28),
      Offset(rect.right - rect.width * 0.12, rect.top + rect.height * 0.78),
    ];

    for (int i = 0; i < petalPoints.length; i++) {
      _drawSingleSakuraPetal(canvas, petalPoints[i], (8.0 + (i % 3) * 3.5) * scale, i * 1.1, false);
    }

    // 4 góc hoa đào đại phong ấn dát vàng
    final cornerOffset = 36.0 * scale;
    final corners = [
      Offset(rect.left + cornerOffset, rect.top + cornerOffset),
      Offset(rect.right - cornerOffset, rect.top + cornerOffset),
      Offset(rect.left + cornerOffset, rect.bottom - cornerOffset),
      Offset(rect.right - cornerOffset, rect.bottom - cornerOffset),
    ];
    for (final c in corners) {
      canvas.drawCircle(c, 16.0 * scale, crestPaint..strokeWidth = 1.0 * scale);
      _drawSingleSakuraPetal(canvas, c, 7.0 * scale, 0, true);
    }
  }

  static void _drawSingleSakuraPetal(Canvas canvas, Offset pos, double size, double angle, bool goldEdge) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final path = Path()
      ..moveTo(0, -size)
      ..cubicTo(size * 0.75, -size * 0.45, size * 0.85, size * 0.45, 0, size)
      ..cubicTo(-size * 0.85, size * 0.45, -size * 0.75, -size * 0.45, 0, -size)
      ..close();

    final petalFill = Paint()
      ..color = const Color(0xFFFF4081).withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, petalFill);

    final petalBorder = Paint()
      ..color = (goldEdge ? const Color(0xFFFFD54F) : Colors.white).withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, petalBorder);

    // Gân cánh hoa tinh tế ở giữa
    canvas.drawLine(Offset(0, -size * 0.6), Offset(0, size * 0.5), petalBorder..strokeWidth = 0.6);

    canvas.restore();
  }

  /// 2. Concept Anime Cyberpunk Neo Tokyo 2077 - Đồ họa ma trận số sắc nét
  static void _renderCyberPattern(Canvas canvas, Rect rect, Offset center, Color accent, double scale, bool isLegendary) {
    // Tầng 1: Lưới vi mạch Cyberspace Grid có giao điểm phát sáng
    final gridPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.10)
      ..strokeWidth = 0.9 * scale;

    const cols = 14;
    const rows = 7;
    final dx = rect.width / cols;
    final dy = rect.height / rows;

    for (int i = 1; i < cols; i++) {
      final x = rect.left + i * dx;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), gridPaint);
    }
    for (int j = 1; j < rows; j++) {
      final y = rect.top + j * dy;
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), gridPaint);
    }

    // Giao điểm lưới phát quang (Solder points)
    final nodePaint = Paint()..color = const Color(0xFF00E5FF).withValues(alpha: 0.35);
    for (int i = 2; i < cols; i += 3) {
      for (int j = 2; j < rows; j += 2) {
        canvas.drawRect(Rect.fromCenter(center: Offset(rect.left + i * dx, rect.top + j * dy), width: 3 * scale, height: 3 * scale), nodePaint);
      }
    }

    // Tầng 2: Mạch bus dẫn truyền số Neon Cyan & Magenta
    final circuitPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: isLegendary ? 0.42 : 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isLegendary ? 2.0 : 1.6) * scale;

    final magentaCircuit = Paint()
      ..color = const Color(0xFFE040FB).withValues(alpha: isLegendary ? 0.45 : 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * scale;

    final corners = [
      Offset(rect.left + rect.width * 0.14, rect.top + rect.height * 0.20),
      Offset(rect.right - rect.width * 0.14, rect.top + rect.height * 0.20),
      Offset(rect.left + rect.width * 0.14, rect.bottom - rect.height * 0.20),
      Offset(rect.right - rect.width * 0.14, rect.bottom - rect.height * 0.20),
    ];

    for (final c in corners) {
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(center.dx + (c.dx - center.dx) * 0.5, center.dy)
        ..lineTo(center.dx + (c.dx - center.dx) * 0.5, c.dy)
        ..lineTo(c.dx, c.dy);
      canvas.drawPath(path, circuitPaint);

      // Chip vi xử lý ở 4 góc kết nối
      canvas.drawRect(Rect.fromCenter(center: c, width: 9 * scale, height: 9 * scale), magentaCircuit);
      canvas.drawCircle(c, 2.2 * scale, Paint()..color = Colors.white.withValues(alpha: 0.8));
    }

    // Tầng 3: CPU Holographic Core ở trung tâm
    final coreR = rect.height * 0.26;
    canvas.drawCircle(center, coreR, circuitPaint..strokeWidth = 2.0 * scale);
    canvas.drawCircle(center, coreR * 0.80, magentaCircuit..strokeWidth = 1.0 * scale);
    canvas.drawCircle(center, coreR * 0.52, circuitPaint..strokeWidth = 1.2 * scale);

    // Ký tự số & góc tọa độ công nghệ
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.50)
      ..strokeWidth = 1.0 * scale;
    canvas.drawLine(Offset(center.dx - coreR * 0.35, center.dy), Offset(center.dx + coreR * 0.35, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - coreR * 0.35), Offset(center.dx, center.dy + coreR * 0.35), crossPaint);
  }

  /// 3. Concept Anime Long Thần Dung Nham / Shonen Dragon - Rực lửa hào khí
  static void _renderDragonPattern(
    Canvas canvas,
    Rect rect,
    Offset center,
    Color accent,
    double scale,
    bool isMythic,
    bool isLegendary,
  ) {
    // Tầng 1: Các đường nứt nham thạch rực sáng (Magma Fissures)
    final fissurePaint = Paint()
      ..color = (isMythic ? const Color(0xFFFF1744) : const Color(0xFFFF3D00)).withValues(alpha: isMythic ? 0.38 : 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isMythic ? 3.0 : 2.4) * scale;

    final leftFissure = Path()
      ..moveTo(rect.left, center.dy)
      ..lineTo(rect.left + rect.width * 0.12, center.dy - 22 * scale)
      ..lineTo(rect.left + rect.width * 0.22, center.dy + 12 * scale)
      ..lineTo(center.dx - rect.height * 0.30, center.dy);
    canvas.drawPath(leftFissure, fissurePaint);

    final rightFissure = Path()
      ..moveTo(rect.right, center.dy)
      ..lineTo(rect.right - rect.width * 0.12, center.dy + 20 * scale)
      ..lineTo(rect.right - rect.width * 0.22, center.dy - 12 * scale)
      ..lineTo(center.dx + rect.height * 0.30, center.dy);
    canvas.drawPath(rightFissure, fissurePaint);

    // Tầng 2: CÁNH RỒNG THẦN THOẠI TRẢI DÀI TRÊN BÀN DRAGON EMPEROR
    if (isMythic) {
      final wingPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * scale;

      // Cánh rồng sải cánh bên trái
      final leftWing = Path()
        ..moveTo(center.dx - 30 * scale, center.dy - 10 * scale)
        ..quadraticBezierTo(center.dx - rect.width * 0.25, center.dy - rect.height * 0.40, center.dx - rect.width * 0.38, center.dy - 15 * scale)
        ..quadraticBezierTo(center.dx - rect.width * 0.28, center.dy + 10 * scale, center.dx - 20 * scale, center.dy + 15 * scale);
      canvas.drawPath(leftWing, wingPaint);

      // Cánh rồng sải cánh bên phải
      final rightWing = Path()
        ..moveTo(center.dx + 30 * scale, center.dy - 10 * scale)
        ..quadraticBezierTo(center.dx + rect.width * 0.25, center.dy - rect.height * 0.40, center.dx + rect.width * 0.38, center.dy - 15 * scale)
        ..quadraticBezierTo(center.dx + rect.width * 0.28, center.dy + 10 * scale, center.dx + 20 * scale, center.dy + 15 * scale);
      canvas.drawPath(rightWing, wingPaint);
    }

    // Tầng 3: Đại phong ấn Hỏa Long Bát Giác (Draconic Octagram Seal)
    final sealR = rect.height * 0.32;
    final sealPaint = Paint()
      ..color = (isMythic ? const Color(0xFFFFD700) : const Color(0xFFFF9100)).withValues(alpha: isMythic ? 0.52 : (isLegendary ? 0.42 : 0.30))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isMythic ? 2.5 : 2.0) * scale;

    canvas.drawCircle(center, sealR, sealPaint);
    canvas.drawCircle(center, sealR * 0.90, sealPaint..strokeWidth = 1.0 * scale);
    canvas.drawCircle(center, sealR * 0.65, sealPaint..strokeWidth = 1.4 * scale);

    // 2 tam giác lồng nhau tạo thành lục giác / bát giác triệu hồi
    for (int k = 0; k < 2; k++) {
      final star = Path();
      final rot = k * math.pi / 3;
      for (int i = 0; i < 3; i++) {
        final a = (i * 2 * math.pi) / 3 - math.pi / 2 + rot;
        final x = center.dx + math.cos(a) * (sealR * 0.88);
        final y = center.dy + math.sin(a) * (sealR * 0.88);
        if (i == 0) {
          star.moveTo(x, y);
        } else {
          star.lineTo(x, y);
        }
      }
      star.close();
      canvas.drawPath(star, sealPaint..strokeWidth = 1.2 * scale);
    }

    // Tâm phong ấn: Hạt ngọc Long Châu rực sáng
    canvas.drawCircle(center, sealR * 0.22, Paint()..color = const Color(0xFFFFD600).withValues(alpha: 0.40));
    canvas.drawCircle(center, sealR * 0.10, Paint()..color = Colors.white.withValues(alpha: 0.90));

    // Vảy rồng mạ vàng 8 hướng
    final scalePaint = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    for (int i = 0; i < 8; i++) {
      final a = (i * 2 * math.pi) / 8;
      final px = center.dx + math.cos(a) * (sealR * 0.78);
      final py = center.dy + math.sin(a) * (sealR * 0.78);
      canvas.drawCircle(Offset(px, py), 3.0 * scale, scalePaint);
    }
  }

  /// 4. Concept Anime Trận Đồ Ma Pháp / Arcane Grimoire / Celestial Olympus - Huyền bí thiên văn
  static void _renderArcanePattern(
    Canvas canvas,
    Rect rect,
    Offset center,
    Color accent,
    double scale,
    bool isMythic,
    bool isLegendary,
  ) {
    final magicR = rect.height * 0.34;
    final magicPaint = Paint()
      ..color = (isMythic ? const Color(0xFFFFD700) : const Color(0xFFB388FF)).withValues(alpha: isMythic ? 0.55 : (isLegendary ? 0.44 : 0.32))
      ..style = PaintingStyle.stroke
      ..strokeWidth = (isMythic ? 2.4 : 1.8) * scale;

    // Vòng tròn thiên văn ma pháp đồng tâm
    canvas.drawCircle(center, magicR, magicPaint);
    canvas.drawCircle(center, magicR * 0.90, magicPaint..strokeWidth = 0.9 * scale);
    canvas.drawCircle(center, magicR * 0.60, magicPaint..strokeWidth = 1.2 * scale);
    canvas.drawCircle(center, magicR * 0.35, magicPaint..strokeWidth = 1.0 * scale);

    // Ngôi sao bát giác ma thuật (8-Pointed Celestial Star)
    final starPath = Path();
    const starPoints = 8;
    for (int i = 0; i < starPoints; i++) {
      final a = (i * 2 * math.pi) / starPoints;
      final r = (i % 2 == 0) ? magicR * 0.88 : magicR * 0.50;
      final x = center.dx + math.cos(a) * r;
      final y = center.dy + math.sin(a) * r;
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(starPath, magicPaint..strokeWidth = 1.2 * scale);

    // Bàn Thần Thoại Olympus: Vòng nguyệt quế vàng 12 chòm sao
    if (isMythic) {
      final laurelPaint = Paint()
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * scale;
      for (int i = 0; i < 12; i++) {
        final a = i * (2 * math.pi / 12);
        final lx = center.dx + math.cos(a) * (magicR * 1.12);
        final ly = center.dy + math.sin(a) * (magicR * 1.12);
        canvas.drawCircle(Offset(lx, ly), 2.5 * scale, laurelPaint);
      }
    }

    // Ký hiệu ma pháp cổ tự và chòm sao đa chiều khắp mặt nỉ
    final starDots = [
      Offset(rect.left + rect.width * 0.16, rect.top + rect.height * 0.28),
      Offset(rect.left + rect.width * 0.24, rect.top + rect.height * 0.20),
      Offset(rect.left + rect.width * 0.28, rect.top + rect.height * 0.34),
      Offset(rect.right - rect.width * 0.16, rect.bottom - rect.height * 0.28),
      Offset(rect.right - rect.width * 0.24, rect.bottom - rect.height * 0.20),
      Offset(rect.right - rect.width * 0.28, rect.bottom - rect.height * 0.34),
    ];
    final lineConstellation = Paint()
      ..color = (isMythic ? const Color(0xFFFFD700) : const Color(0xFFE040FB)).withValues(alpha: 0.30)
      ..strokeWidth = 0.8 * scale;
    for (int i = 0; i < 2; i++) {
      canvas.drawLine(starDots[i], starDots[i + 1], lineConstellation);
      canvas.drawLine(starDots[i + 3], starDots[i + 4], lineConstellation);
    }
    for (final dot in starDots) {
      canvas.drawCircle(dot, 2.8 * scale, Paint()..color = Colors.white.withValues(alpha: 0.85));
    }
  }

  /// 5. Concept Anime Vực Sâu Bóng Tối / Solo Leveling Shadow Monarch
  static void _renderShadowPattern(Canvas canvas, Rect rect, Offset center, Color accent, double scale, bool isLegendary) {
    // Vòng xoáy hư vô hắc ám đa tầng ở trung tâm
    final voidR = rect.height * 0.30;
    for (int i = 1; i <= 5; i++) {
      final r = voidR * (i / 5.0);
      final alpha = (0.35 - i * 0.05).clamp(0.08, 0.45);
      final voidPaint = Paint()
        ..color = const Color(0xFF7C4DFF).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (2.4 - i * 0.3) * scale;
      canvas.drawCircle(center, r, voidPaint);
    }

    // 8 lưỡi liềm hắc ám xoáy hướng tâm
    const bladeCount = 8;
    for (int i = 0; i < bladeCount; i++) {
      final a = (i * 2 * math.pi) / bladeCount;
      final start = Offset(center.dx + math.cos(a) * voidR, center.dy + math.sin(a) * voidR);
      final end = Offset(center.dx + math.cos(a + 0.5) * (voidR * 0.25), center.dy + math.sin(a + 0.5) * (voidR * 0.25));
      final bladePath = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(center.dx + math.cos(a + 0.25) * (voidR * 0.75), center.dy + math.sin(a + 0.25) * (voidR * 0.75), end.dx, end.dy);
      canvas.drawPath(
        bladePath,
        Paint()
          ..color = const Color(0xFFBA68C8).withValues(alpha: 0.38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * scale,
      );
    }

    // Hạt nhân lỗ đen hắc ám trung tâm
    canvas.drawCircle(center, voidR * 0.18, Paint()..color = const Color(0xFF12002B).withValues(alpha: 0.80));
    canvas.drawCircle(center, voidR * 0.08, Paint()..color = const Color(0xFFE040FB).withValues(alpha: 0.90));
  }

  /// 6. Concept Anime Pháo Đài Biomecha / EVA Unit AT-Field - Mạng tổ ong tương lai
  static void _renderMechaPattern(Canvas canvas, Rect rect, Offset center, Color accent, double scale, bool isLegendary) {
    // Tầng 1: Lưới phòng ngự tổ ong AT-Field đa giác
    final hexPaint = Paint()
      ..color = const Color(0xFF76FF03).withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0 * scale;

    final hexR = 26.0 * scale;
    final hStep = hexR * 1.5;
    final vStep = hexR * math.sqrt(3);

    for (double x = rect.left + hexR; x < rect.right; x += hStep * 2) {
      for (double y = rect.top + hexR; y < rect.bottom; y += vStep) {
        _drawHexagon(canvas, Offset(x, y), hexR, hexPaint);
        _drawHexagon(canvas, Offset(x + hStep, y + vStep * 0.5), hexR, hexPaint);
      }
    }

    // Tầng 2: Hệ thống hồng tâm tác chiến (Combat HUD Crosshair)
    final headX = rect.left + rect.width * 0.25;
    final footX = rect.left + rect.width * 0.75;
    final midY = center.dy;

    final reticlePaint = Paint()
      ..color = const Color(0xFFFF9100).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * scale;

    for (final x in [headX, footX]) {
      canvas.drawCircle(Offset(x, midY), 16 * scale, reticlePaint);
      canvas.drawCircle(Offset(x, midY), 6 * scale, reticlePaint..strokeWidth = 0.8 * scale);
      canvas.drawLine(Offset(x - 22 * scale, midY), Offset(x + 22 * scale, midY), reticlePaint..strokeWidth = 1.2 * scale);
      canvas.drawLine(Offset(x, midY - 22 * scale), Offset(x, midY + 22 * scale), reticlePaint);
    }
  }

  static void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 2 * math.pi) / 6;
      final x = center.dx + math.cos(angle) * radius;
      final y = center.dy + math.sin(angle) * radius;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  /// 7. Concept Classic Chuẩn Thi Đấu
  static void _renderClassicPattern(Canvas canvas, Rect rect, Offset center, Color accent, double scale, bool isLegendary) {
    final centerCirclePaint = Paint()
      ..color = Colors.white.withValues(alpha: isLegendary ? 0.22 : 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2 * scale;
    canvas.drawCircle(center, rect.height * 0.22, centerCirclePaint);
    canvas.drawCircle(center, rect.height * 0.10, centerCirclePaint..strokeWidth = 0.8 * scale);
  }

  /// Trang trí thành băng & 4 góc nẹp kim loại theo concept Anime & Phẩm cấp
  static void renderAnimeRailDeco({
    required Canvas canvas,
    required Rect fullRect,
    required Rect playRect,
    required TableSkinModel table,
  }) {
    final accent = table.railAccentColor;
    final isMythic = table.rarity == TableRarity.mythic;
    final isLegendary = table.rarity == TableRarity.legendary || isMythic;

    // Đối với bàn Huyền Thoại & Thần Thoại: Nẹp góc mạ vàng 24K chạm khắc nổi
    if (isLegendary) {
      final goldBracketPaint = Paint()
        ..color = (isMythic ? const Color(0xFFFFD700) : const Color(0xFFFFD54F)).withValues(alpha: isMythic ? 0.95 : 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isMythic ? 3.0 : 2.4;

      final bSize = isMythic ? 34.0 : 28.0;
      _drawCornerBracket(canvas, 4, 4, bSize, goldBracketPaint);
      _drawCornerBracket(canvas, fullRect.width - 4, 4, bSize, goldBracketPaint, flipX: true);
      _drawCornerBracket(canvas, 4, fullRect.height - 4, bSize, goldBracketPaint, flipY: true);
      _drawCornerBracket(canvas, fullRect.width - 4, fullRect.height - 4, bSize, goldBracketPaint, flipX: true, flipY: true);

      // Điểm xuyết hạt ngọc vàng tại 4 góc
      final dotPaint = Paint()..color = isMythic ? const Color(0xFFFF1744) : const Color(0xFFFFD700);
      canvas.drawCircle(const Offset(8, 8), 2.0, dotPaint);
      canvas.drawCircle(Offset(fullRect.width - 8, 8), 2.0, dotPaint);
      canvas.drawCircle(Offset(8, fullRect.height - 8), 2.0, dotPaint);
      canvas.drawCircle(Offset(fullRect.width - 8, fullRect.height - 8), 2.0, dotPaint);
    }

    switch (table.animeConcept) {
      case TableAnimeConcept.sakuraZen:
        final goldPlate = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: 0.70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        const cSize = 26.0;
        _drawCornerBracket(canvas, 4, 4, cSize, goldPlate);
        _drawCornerBracket(canvas, fullRect.width - 4, 4, cSize, goldPlate, flipX: true);
        _drawCornerBracket(canvas, 4, fullRect.height - 4, cSize, goldPlate, flipY: true);
        _drawCornerBracket(canvas, fullRect.width - 4, fullRect.height - 4, cSize, goldPlate, flipX: true, flipY: true);
        break;

      case TableAnimeConcept.cyberTokyo:
        // Đèn vi mạch neon rực sáng ở 4 góc thành băng
        final cornerGlow = Paint()
          ..color = accent.withValues(alpha: 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2;
        canvas.drawRect(const Rect.fromLTWH(4, 4, 28, 28), cornerGlow);
        canvas.drawRect(Rect.fromLTWH(fullRect.width - 32, 4, 28, 28), cornerGlow);
        canvas.drawRect(Rect.fromLTWH(4, fullRect.height - 32, 28, 28), cornerGlow);
        canvas.drawRect(Rect.fromLTWH(fullRect.width - 32, fullRect.height - 32, 28, 28), cornerGlow);
        break;

      case TableAnimeConcept.mechaEva:
        // Vạch sọc cảnh báo nguy hiểm (Hazard Chevrons) trên mép thành băng
        final hazardPaint = Paint()
          ..color = const Color(0xFFFF9100).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        for (double x = 40; x < fullRect.width - 40; x += 32) {
          canvas.drawLine(Offset(x, 2), Offset(x + 12, 10), hazardPaint);
          canvas.drawLine(Offset(x, fullRect.height - 10), Offset(x + 12, fullRect.height - 2), hazardPaint);
        }
        break;

      case TableAnimeConcept.dragonLava:
        // Vảy rồng mạ kim loại sắc nhọn trên mép băng
        final scalePaint = Paint()
          ..color = (isMythic ? const Color(0xFFFFD700) : const Color(0xFFFF6D00)).withValues(alpha: 0.55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6;
        for (double x = 45; x < fullRect.width - 45; x += 22) {
          final p = Path()
            ..moveTo(x, 3)
            ..lineTo(x + 11, 10)
            ..lineTo(x + 22, 3);
          canvas.drawPath(p, scalePaint);
        }
        break;

      case TableAnimeConcept.arcaneGrimoire:
      case TableAnimeConcept.shadowVoid:
        final runeBorder = Paint()
          ..color = accent.withValues(alpha: 0.50)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawRect(Rect.fromLTWH(6, 6, fullRect.width - 12, fullRect.height - 12), runeBorder);
        break;

      case TableAnimeConcept.classic:
        break;
    }
  }

  static void _drawCornerBracket(Canvas canvas, double x, double y, double size, Paint paint, {bool flipX = false, bool flipY = false}) {
    final dx = flipX ? -size : size;
    final dy = flipY ? -size : size;
    final path = Path()
      ..moveTo(x, y + dy)
      ..lineTo(x, y)
      ..lineTo(x + dx, y);
    canvas.drawPath(path, paint);
  }
}
