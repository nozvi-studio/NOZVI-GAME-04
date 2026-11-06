import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../models/cue_model.dart';
import '../services/progression_service.dart';
import '../services/online_multiplayer_service.dart';
import '../services/local_multiplayer_service.dart';
import '../services/language_service.dart';

/// Widget Thanh Chỉnh Cơ Kéo Xuống Dạng Con Nhộng (Capsule Cue Slider)
/// Thiết kế chuẩn phong cách 8 Ball Pool kinh điển:
/// - Chữ số % màu vàng kim đậm nét phía trên đỉnh
/// - Rãnh trượt con nhộng kim loại bo tròn 2 đầu (Capsule Pill)
/// - Cây cơ gỗ 3D chân thực với đầu cơ xanh phấn (Chalk-blue tip) và phíp trắng
/// - Kéo cơ xuống để chỉnh lực, thả tay bắn ngay tức thì (chuẩn 8 Ball Pool)
/// - Nút tròn trắng viền kim loại với biểu tượng đỏ ở góc dưới
class CuePowerSliderControl extends StatefulWidget {
  final BilliardGame game;
  final bool compact;
  final bool ultraCompact;

  const CuePowerSliderControl({
    super.key,
    required this.game,
    this.compact = false,
    this.ultraCompact = false,
  });

  @override
  State<CuePowerSliderControl> createState() => _CuePowerSliderControlState();
}

class _CuePowerSliderControlState extends State<CuePowerSliderControl> {
  bool _isDragging = false;
  bool _powerLocked = false; // Khi khóa lực thì thả tay không bắn, cần bấm nút để xuất chiêu
  int _lastHapticMilestone = 0;

  void _triggerHapticForPower(double power) {
    final milestone = (power * 4).floor();
    if (milestone != _lastHapticMilestone) {
      _lastHapticMilestone = milestone;
      HapticFeedback.selectionClick();
    }
  }

  void _handleTouch(Offset localPos, double trackHeight) {
    if (!widget.game.canUserControl) return;
    if (!_isDragging) {
      setState(() => _isDragging = true);
    }

    final clampedY = localPos.dy.clamp(0.0, trackHeight);
    final ratio = (clampedY / trackHeight).clamp(0.0, 1.0);

    // Vùng đỉnh 0% - 4% là vùng nghỉ / hủy cú đánh
    if (ratio <= 0.04) {
      widget.game.setShotPower(0.05);
    } else {
      final power = (0.05 + ratio * 0.95).clamp(0.05, 1.0);
      widget.game.setShotPower(power);
      _triggerHapticForPower(power);
    }
  }

  void _handleRelease() {
    setState(() => _isDragging = false);
    if (!widget.game.canUserControl) return;

    // Nếu không khóa lực: Thả tay bắn ngay lập tức (khi lực > 0.05)
    if (!_powerLocked) {
      final currentPower = widget.game.shotPower.value;
      if (currentPower > 0.05) {
        HapticFeedback.heavyImpact();
        widget.game.shootWithPower();
      }
    }
  }

  void _togglePowerLock() {
    setState(() => _powerLocked = !_powerLocked);
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _powerLocked
              ? 'power_locked_toast'.tr
              : 'power_unlocked_toast'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ultraCompact = widget.ultraCompact;
    final compact = widget.compact;
    final controlWidth = ultraCompact ? 34.0 : (compact ? 40.0 : 46.0);
    final capsuleWidth = ultraCompact ? 22.0 : (compact ? 26.0 : 30.0);
    final bottomButtonSize = ultraCompact ? 28.0 : (compact ? 34.0 : 38.0);

    return SizedBox(
      width: controlWidth,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          widget.game.shotPower,
          widget.game.currentTurn,
          ProgressionService.instance,
          OnlineMultiplayerService.instance,
          LocalMultiplayerService.instance,
        ]),
        builder: (context, _) {
          final power = widget.game.shotPower.value;
          final ratio = ((power - 0.05) / 0.95).clamp(0.0, 1.0);
          final displayPercent = ratio <= 0.04 ? 0 : (ratio * 100).round();

          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 1. Chữ số % màu vàng kim rực rỡ phía trên rãnh cơ
              _buildYellowPercentageHeader(displayPercent, ultraCompact, compact),
              SizedBox(height: ultraCompact ? 3.0 : 5.0),

              // 2. Rãnh con nhộng kim loại (Capsule Slider) chứa cây cơ gỗ 3D
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final trackHeight = constraints.maxHeight;
                    final maxTravel = trackHeight * 0.72;
                    final pullOffset = ratio * maxTravel;

                    return GestureDetector(
                      key: const ValueKey('cue_power_track_gesture'),
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (d) => _handleTouch(d.localPosition, trackHeight),
                      onPanUpdate: (d) => _handleTouch(d.localPosition, trackHeight),
                      onPanEnd: (_) => _handleRelease(),
                      onPanCancel: () => _handleRelease(),
                      onTapDown: (d) => _handleTouch(d.localPosition, trackHeight),
                      onTapUp: (_) => _handleRelease(),
                      child: Center(
                        child: Container(
                          width: capsuleWidth,
                          height: trackHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(capsuleWidth / 2),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xFF1E2228),
                                Color(0xFF323842),
                                Color(0xFF15181D),
                              ],
                            ),
                            border: Border.all(
                              color: _isDragging
                                  ? const Color(0xFFFFD700)
                                  : const Color(0xFF4A5260),
                              width: _isDragging ? 2.0 : 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.7),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                              if (_isDragging)
                                BoxShadow(
                                  color: const Color(0xFFFFD700).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(capsuleWidth / 2 - 1.5),
                            child: Stack(
                              children: [
                                // A. Lòng rãnh tối màu với vạch chia độ rãnh
                                Positioned.fill(
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          Color(0xFF080A0D),
                                          Color(0xFF101419),
                                          Color(0xFF080A0D),
                                        ],
                                      ),
                                    ),
                                    child: _buildTrackTickMarks(trackHeight),
                                  ),
                                ),

                                // B. Vệt sáng năng lượng rọi theo độ kéo cơ
                                if (ratio > 0.02)
                                  Positioned(
                                    top: 0,
                                    left: 2,
                                    right: 2,
                                    height: (pullOffset + capsuleWidth * 0.4).clamp(0.0, trackHeight),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(capsuleWidth / 2),
                                          bottom: const Radius.circular(3),
                                        ),
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            const Color(0xFF00E676).withValues(alpha: 0.15),
                                            (ratio > 0.75
                                                    ? const Color(0xFFFF2A4B)
                                                    : ratio > 0.4
                                                        ? const Color(0xFFFFB300)
                                                        : const Color(0xFF00E676))
                                                .withValues(alpha: 0.45),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                // C. Cây gậy cơ gỗ 3D trượt xuống từ đỉnh con nhộng
                                Positioned(
                                  top: pullOffset,
                                  left: 0,
                                  right: 0,
                                  bottom: -pullOffset,
                                  child: _buildCapsuleCueStick(capsuleWidth, trackHeight),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: ultraCompact ? 4.0 : 8.0),

              // 3. Nút tròn màu trắng có biểu tượng đỏ ở góc dưới bên trái
              _buildBottomCircularButton(bottomButtonSize, ultraCompact),
            ],
          );
        },
      ),
    );
  }

  /// Tiêu đề % màu vàng kim rực rỡ có viền đổ bóng nổi bật như ảnh mẫu
  Widget _buildYellowPercentageHeader(int percent, bool ultraCompact, bool compact) {
    return Text(
      '$percent%',
      style: TextStyle(
        color: const Color(0xFFFFDE00), // Vàng kim rực rỡ như ảnh mẫu
        fontSize: ultraCompact ? 13.0 : (compact ? 15.0 : 17.5),
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
        shadows: const [
          Shadow(
            color: Colors.black,
            offset: Offset(0, 1.8),
            blurRadius: 3.5,
          ),
          Shadow(
            color: Colors.black,
            offset: Offset(1.2, 0),
            blurRadius: 2.0,
          ),
          Shadow(
            color: Colors.black,
            offset: Offset(-1.2, 0),
            blurRadius: 2.0,
          ),
        ],
      ),
    );
  }

  /// Vẽ các vạch khắc chia độ mờ bên trong rãnh con nhộng
  Widget _buildTrackTickMarks(double height) {
    return Stack(
      children: [
        for (final pct in [0.25, 0.50, 0.75])
          Positioned(
            top: height * pct,
            left: 2,
            right: 2,
            child: Container(
              height: 1.0,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
      ],
    );
  }

  /// Widget vẽ Cây Gậy Cơ 3D chân thực: Đầu lơ xanh vòm cong, phíp trắng, thân gỗ phong vàng óng
  Widget _buildCapsuleCueStick(double capsuleWidth, double trackHeight) {
    final (cue, level) = widget.game.getActivePlayerCue();

    return CustomPaint(
      size: Size(capsuleWidth, trackHeight),
      painter: _RealisticCapsuleCuePainter(
        capsuleWidth: capsuleWidth,
        cue: cue,
        level: level,
      ),
    );
  }

  /// Nút bấm tròn màu trắng bạc với biểu tượng đỏ góc dưới bên trái
  Widget _buildBottomCircularButton(double size, bool ultraCompact) {
    return GestureDetector(
      key: const ValueKey('cue_slider_bottom_button'),
      onTap: () {
        if (!widget.game.canUserControl) return;
        if (_powerLocked && widget.game.shotPower.value > 0.05) {
          // Nếu đang khóa lực và có lực kéo: chạm nút tròn sẽ bắn ngay
          HapticFeedback.heavyImpact();
          widget.game.shootWithPower();
        } else {
          // Chuyển đổi trạng thái khóa lực / mở lực
          _togglePowerLock();
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            center: Alignment(-0.2, -0.3),
            radius: 0.85,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFEDEDED),
              Color(0xFFCCCCCC),
              Color(0xFF9E9E9E),
            ],
            stops: [0.0, 0.45, 0.82, 1.0],
          ),
          border: Border.all(
            color: const Color(0xFF2C3238),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: CustomPaint(
            size: Size(size * 0.50, size * 0.50),
            painter: _RedAngleSymbolPainter(),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter vẽ biểu tượng góc ngắm màu đỏ bên trong nút tròn trắng (chuẩn ảnh mẫu)
class _RedAngleSymbolPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD32F2F) // Đỏ tươi nổi bật
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Vẽ góc nhọn nghiêng (Angle symbol ∠)
    final path = Path()
      ..moveTo(w * 0.82, h * 0.82)
      ..lineTo(w * 0.22, h * 0.82)
      ..lineTo(w * 0.72, h * 0.18);

    canvas.drawPath(path, paint);

    // Điểm chấm đỏ tâm góc
    final dotPaint = Paint()
      ..color = const Color(0xFFD32F2F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.42, h * 0.62), 1.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// CustomPainter vẽ cây gậy cơ 3D dáng con nhộng chân thực:
/// - Đỉnh vòm bo tròn màu xanh phấn (Chalk-blue tip)
/// - Vòng đệm phíp cơ trắng (White ferrule)
/// - Thân cơ gỗ phong vàng ấm áp (Maple wood cylinder với ánh sáng 3D)
/// - Tích hợp hoa văn và màu sắc từ gậy cơ đang trang bị trong Shop
class _RealisticCapsuleCuePainter extends CustomPainter {
  final double capsuleWidth;
  final CueModel cue;
  final int level;

  _RealisticCapsuleCuePainter({
    required this.capsuleWidth,
    required this.cue,
    required this.level,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final centerX = w / 2;

    // Chiều rộng gậy cơ ôm khít bên trong rãnh con nhộng (cách mép 1.5px)
    final stickWidth = (w - 3.0).clamp(16.0, 26.0);
    final halfStick = stickWidth / 2;
    final stickLeft = centerX - halfStick;
    final stickRight = centerX + halfStick;

    // 1. Thân cơ 3D chia 2 phần: Ngọn cơ (Shaft) phía trên và Chuôi cơ (Handle) phía dưới
    final ferruleHeight = 9.0;
    final shaftStartY = 6.0 + ferruleHeight;
    final ringY = h * 0.48;

    // Ngọn cơ (Shaft)
    final shaftRect = Rect.fromLTRB(stickLeft, shaftStartY, stickRight, ringY);
    final baseShaftColors = cue.shaftColors.isNotEmpty ? cue.shaftColors : const [Color(0xFFDF9E52), Color(0xFFC78438)];
    final shaftGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        baseShaftColors[0],
        baseShaftColors.length > 1 ? baseShaftColors[1] : baseShaftColors[0],
        Colors.white.withValues(alpha: 0.65), // Vệt bóng sáng trắng phản chiếu
        baseShaftColors.last,
        const Color(0xFF3E2723),
      ],
      stops: const [0.0, 0.28, 0.50, 0.78, 1.0],
    );
    canvas.drawRect(shaftRect, Paint()..shader = shaftGradient.createShader(shaftRect));

    // Họa tiết Concept Anime trên ngọn cơ trong Slider
    switch (cue.animeConcept) {
      case CueAnimeConcept.katanaSamurai:
        final hamonPaint = Paint()
          ..color = const Color(0xFFFF1744).withValues(alpha: level >= 6 ? 0.95 : 0.80)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        final hamonPath = Path()..moveTo(centerX, shaftStartY + 2);
        for (double hy = shaftStartY + 2; hy < ringY - 4; hy += 10) {
          hamonPath.quadraticBezierTo(centerX - 1.5, hy + 2.5, centerX, hy + 5);
          hamonPath.quadraticBezierTo(centerX + 1.5, hy + 7.5, centerX, hy + 10);
        }
        canvas.drawPath(hamonPath, hamonPaint);
        if (level >= 5) {
          // Habaki mạ vàng
          canvas.drawRect(Rect.fromLTWH(stickLeft, ringY - 6, stickWidth, 6), Paint()..color = const Color(0xFFFFD54F));
        }
        break;

      case CueAnimeConcept.cyberNeo:
        final beamPaint = Paint()
          ..color = const Color(0xFF00E5FF).withValues(alpha: 0.90)
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(centerX, shaftStartY), Offset(centerX, ringY), beamPaint);
        break;

      case CueAnimeConcept.dragonFlame:
        final flamePaint = Paint()
          ..color = const Color(0xFFFF6D00).withValues(alpha: 0.85)
          ..strokeWidth = 1.2;
        canvas.drawLine(Offset(centerX, shaftStartY), Offset(centerX, ringY), flamePaint);
        break;

      default:
        break;
    }

    // Chuôi cơ (Handle)
    final handleRect = Rect.fromLTRB(stickLeft, ringY + 4, stickRight, h - 8);
    final baseHandleColors = cue.handleColors.isNotEmpty ? cue.handleColors : const [Color(0xFF263238), Color(0xFF1B0000)];
    final handleGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        baseHandleColors[0],
        baseHandleColors.length > 1 ? baseHandleColors[1] : baseHandleColors[0],
        Colors.white.withValues(alpha: 0.55),
        baseHandleColors.last,
        Colors.black87,
      ],
      stops: const [0.0, 0.28, 0.50, 0.78, 1.0],
    );

    final handleBodyPath = Path()
      ..moveTo(stickLeft, ringY + 4)
      ..lineTo(stickLeft, h - 8)
      ..arcToPoint(
        Offset(stickRight, h - 8),
        radius: Radius.circular(halfStick),
        clockwise: false,
      )
      ..lineTo(stickRight, ringY + 4)
      ..close();
    canvas.drawPath(handleBodyPath, Paint()..shader = handleGradient.createShader(handleRect));

    // Họa tiết Anime trên chuôi cơ
    switch (cue.animeConcept) {
      case CueAnimeConcept.katanaSamurai:
        final tsukaPaint = Paint()
          ..color = const Color(0xFFFFD54F).withValues(alpha: level >= 6 ? 0.90 : 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        for (double ty = ringY + 10; ty < h - 16; ty += 12) {
          final p = Path()
            ..moveTo(centerX, ty)
            ..lineTo(centerX - 3.5, ty + 4)
            ..lineTo(centerX, ty + 8)
            ..lineTo(centerX + 3.5, ty + 4)
            ..close();
          canvas.drawPath(p, tsukaPaint);
        }
        break;

      case CueAnimeConcept.mechaGundam:
        final hazardP = Paint()
          ..color = const Color(0xFFFF6D00).withValues(alpha: 0.85)
          ..strokeWidth = 2.0;
        for (double hy = ringY + 12; hy < h - 16; hy += 14) {
          canvas.drawLine(Offset(stickLeft + 2, hy), Offset(stickRight - 2, hy + 5), hazardP);
        }
        break;

      default:
        break;
    }

    // 2. Vòng đệm ren kim loại hoặc Vành Tsuba tại ringY
    if (cue.animeConcept == CueAnimeConcept.katanaSamurai) {
      // Tsuba kiếm Nhật Bản
      final tsubaRect = Rect.fromLTWH(stickLeft - 2.5, ringY - 1.5, stickWidth + 5.0, 5.0);
      canvas.drawRRect(RRect.fromRectAndRadius(tsubaRect, const Radius.circular(2)), Paint()..color = const Color(0xFFFFD54F));
      canvas.drawRRect(RRect.fromRectAndRadius(tsubaRect, const Radius.circular(2)), Paint()..color = Colors.black87..style = PaintingStyle.stroke..strokeWidth = 0.8);
    } else {
      final ringPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: level >= 5
              ? const [Color(0xFFFFD54F), Color(0xFFFFF9C4), Color(0xFFB8860B)]
              : const [Color(0xFF8A7320), Color(0xFFFFE082), Color(0xFF6B5510)],
        ).createShader(Rect.fromLTWH(stickLeft, ringY, stickWidth, 4.5));
      canvas.drawRect(Rect.fromLTWH(stickLeft, ringY, stickWidth, 4.0), ringPaint);
    }

    // 3. Phíp cơ trắng (Ferrule)
    final ferruleRect = Rect.fromLTWH(stickLeft, 6.0, stickWidth, ferruleHeight);
    final ferrulePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFCCCCCC),
          Color(0xFFFFFFFF),
          Color(0xFFF0F0F0),
          Color(0xFFB0B0B0),
        ],
        stops: [0.0, 0.35, 0.65, 1.0],
      ).createShader(ferruleRect);
    canvas.drawRect(ferruleRect, ferrulePaint);

    // Viền vàng nẹp chân phíp nếu Lv >= 5
    canvas.drawLine(
      Offset(stickLeft, 6.0 + ferruleHeight),
      Offset(stickRight, 6.0 + ferruleHeight),
      Paint()
        ..color = level >= 5 ? const Color(0xFFFFD54F) : const Color(0xFF424242)
        ..strokeWidth = level >= 5 ? 1.0 : 0.8,
    );

    // 4. Đầu lơ (Tip) dạng vòm cong ở đỉnh
    final tipPath = Path()
      ..moveTo(stickLeft, 6.0)
      ..lineTo(stickRight, 6.0)
      ..arcToPoint(
        Offset(stickLeft, 6.0),
        radius: Radius.circular(halfStick),
        clockwise: false,
      )
      ..close();

    final tipPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.3),
        radius: 0.9,
        colors: [
          Color.lerp(cue.tipColor, Colors.white, 0.4) ?? cue.tipColor,
          cue.tipColor,
          Color.lerp(cue.tipColor, Colors.black, 0.3) ?? cue.tipColor,
        ],
      ).createShader(Rect.fromLTWH(stickLeft, 0, stickWidth, halfStick * 2));
    canvas.drawPath(tipPath, tipPaint);

    // 5. Đệm cao su & VIÊN NGỌC KHẢM ĐUÔI CHUÔI CƠ (Butt Gemstone Bezel)
    final bumperPath = Path()
      ..moveTo(stickLeft, h - 8)
      ..arcToPoint(
        Offset(stickRight, h - 8),
        radius: Radius.circular(halfStick),
        clockwise: false,
      )
      ..close();
    canvas.drawPath(bumperPath, Paint()..color = const Color(0xFF141414));

    // Lv >= 5: Khảm đá quý ở đế gậy slider
    if (level >= 5) {
      final gemColor = switch (cue.animeConcept) {
        CueAnimeConcept.katanaSamurai => const Color(0xFFFF1744),
        CueAnimeConcept.cyberNeo => const Color(0xFF00E5FF),
        CueAnimeConcept.dragonFlame => const Color(0xFFFF6D00),
        CueAnimeConcept.arcaneMagic => const Color(0xFFB388FF),
        CueAnimeConcept.shadowVoid => const Color(0xFF7C4DFF),
        CueAnimeConcept.mechaGundam => const Color(0xFF76FF03),
        CueAnimeConcept.sakuraZen => const Color(0xFFFF80AB),
        CueAnimeConcept.frostCryo => const Color(0xFF80D8FF),
        CueAnimeConcept.classic => const Color(0xFFFFD54F),
      };

      // Đĩa vàng và ngọc
      canvas.drawCircle(Offset(centerX, h - 5.5), 3.2, Paint()..color = const Color(0xFFFFD54F));
      canvas.drawCircle(Offset(centerX, h - 5.5), 2.2, Paint()..color = gemColor);
      canvas.drawCircle(Offset(centerX - 0.6, h - 6.2), 0.8, Paint()..color = Colors.white);
    }

    // 6. Hào quang tỏa sáng hai bên gậy (Level >= 6)
    if (level >= 6) {
      final isMax = level == 10;
      final auraPaint = Paint()
        ..color = cue.auraColor.withValues(alpha: isMax ? 0.60 : 0.40)
        ..strokeWidth = isMax ? 3.0 : 2.0
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isMax ? 4 : 2.5);
      canvas.drawLine(Offset(stickLeft - 1, 10), Offset(stickLeft - 1, h - 10), auraPaint);
      canvas.drawLine(Offset(stickRight + 1, 10), Offset(stickRight + 1, h - 10), auraPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticCapsuleCuePainter oldDelegate) {
    return oldDelegate.capsuleWidth != capsuleWidth ||
        oldDelegate.cue != cue ||
        oldDelegate.level != level;
  }
}
