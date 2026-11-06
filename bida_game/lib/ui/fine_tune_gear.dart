import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';
import '../services/language_service.dart';

/// Widget Bánh Răng Xoay Vi Chỉnh Hướng Bắn (Fine-Tune Aim Gear Wheel)
/// Cho phép người chơi điều chỉnh góc ngắm gậy cơ từng milimet siêu chuẩn xác
/// hệt như cơ chế Rotary Aim Wheel trong 8 Ball Pool gốc.
class FineTuneGearControl extends StatefulWidget {
  final BilliardGame game;
  final bool compact;
  final bool ultraCompact;

  const FineTuneGearControl({
    super.key,
    required this.game,
    this.compact = false,
    this.ultraCompact = false,
  });

  @override
  State<FineTuneGearControl> createState() => _FineTuneGearControlState();
}

class _FineTuneGearControlState extends State<FineTuneGearControl> {
  Offset? _lastPanPos;
  Timer? _holdTimer;
  int _lastToothStep = 0;
  bool _isDragging = false;

  static const int _teethCount = 18;
  static const double _microStepRad = 0.0045; // ~0.25 độ (khoảng 1mm lệch bi)

  void _triggerHapticTick(double currentAngle) {
    final step = (currentAngle / (2 * math.pi / _teethCount)).floor();
    if (step != _lastToothStep) {
      _lastToothStep = step;
      HapticFeedback.selectionClick();
    }
  }

  void _nudge(double delta) {
    if (!widget.game.canUserControl) return;
    widget.game.rotateAim(delta);
    _triggerHapticTick(widget.game.aimAngle);
  }

  void _startContinuousNudge(double delta) {
    _nudge(delta);
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      _nudge(delta);
    });
  }

  void _stopContinuousNudge() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.game.canUserControl) return;
    setState(() => _isDragging = true);
    _lastPanPos = details.localPosition;
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails details, Size gearSize) {
    if (!widget.game.canUserControl) return;
    final currentPos = details.localPosition;
    final lastPos = _lastPanPos ?? currentPos;
    _lastPanPos = currentPos;

    final center = Offset(gearSize.width / 2, gearSize.height / 2);
    final vLast = lastPos - center;
    final vCurr = currentPos - center;

    double deltaAngle;

    // Nếu người chơi xoay tròn quanh tâm bánh răng
    if (vLast.distance > 8.0 && vCurr.distance > 8.0) {
      var diff = math.atan2(vCurr.dy, vCurr.dx) - math.atan2(vLast.dy, vLast.dx);
      if (diff > math.pi) diff -= 2 * math.pi;
      if (diff < -math.pi) diff += 2 * math.pi;
      // Tỉ số truyền giảm tốc 1:3.2 để đạt độ mịn milimet
      deltaAngle = diff * 0.32;
    } else {
      // Vuốt dọc mép bánh răng: 1 pixel vuốt = 0.0035 radian
      deltaAngle = (currentPos.dy - lastPos.dy) * 0.0035;
    }

    if (deltaAngle.abs() > 0.0001) {
      widget.game.rotateAim(deltaAngle);
      _triggerHapticTick(widget.game.aimAngle);
    }
  }

  void _onPanEnd(DragEndDetails _) {
    setState(() => _isDragging = false);
    _lastPanPos = null;
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.ultraCompact
        ? 44.0
        : (widget.compact ? 52.0 : 60.0);
    final gearDiameter = widget.ultraCompact
        ? 34.0
        : (widget.compact ? 42.0 : 48.0);
    final iconSize = widget.ultraCompact
        ? 14.0
        : (widget.compact ? 17.0 : 20.0);

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: widget.ultraCompact ? 2.0 : 3.0,
        vertical: widget.ultraCompact ? 3.0 : 5.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(widget.ultraCompact ? 10 : 14),
        border: Border.all(
          color: _isDragging
              ? const Color(0xFF00E5FF)
              : Colors.white.withValues(alpha: 0.18),
          width: _isDragging ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDragging
                ? const Color(0x3300E5FF)
                : Colors.black.withValues(alpha: 0.5),
            blurRadius: _isDragging ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tiêu đề Vi Chỉnh
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.track_changes,
                  size: widget.ultraCompact ? 10 : 12,
                  color: const Color(0xFF00E5FF),
                ),
                const SizedBox(width: 2),
                Text(
                  'fine_tune'.tr,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: widget.ultraCompact ? 7.5 : 8.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),

            // Nút vi chỉnh Nhích Lên / Ngược chiều kim đồng hồ (▲)
            _buildNudgeButton(
              icon: Icons.arrow_drop_up,
              iconSize: iconSize,
              delta: -_microStepRad,
              tooltip: 'fine_tune_left'.tr,
            ),
            const SizedBox(height: 1),

            // Bánh Răng Cơ Khí Xoay (Fine-Tune Gear Wheel)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: _onPanStart,
              onPanUpdate: (d) => _onPanUpdate(d, Size(gearDiameter, gearDiameter)),
              onPanEnd: _onPanEnd,
              onPanCancel: () => setState(() {
                _isDragging = false;
                _lastPanPos = null;
              }),
              child: SizedBox(
                width: gearDiameter,
                height: gearDiameter,
                child: ValueListenableBuilder<double>(
                  valueListenable: widget.game.aimAngleNotifier,
                  builder: (context, aimAngle, _) {
                    return CustomPaint(
                      painter: FineTuneGearPainter(
                        angle: aimAngle,
                        teethCount: _teethCount,
                        isDragging: _isDragging,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 1),

            // Nút vi chỉnh Nhích Xuống / Thuận chiều kim đồng hồ (▼)
            _buildNudgeButton(
              icon: Icons.arrow_drop_down,
              iconSize: iconSize,
              delta: _microStepRad,
              tooltip: 'fine_tune_right'.tr,
            ),
            const SizedBox(height: 2),

            // Huy hiệu hiển thị góc bắn chi tiết từng 0.1 độ (Degree HUD)
            ValueListenableBuilder<double>(
              valueListenable: widget.game.aimAngleNotifier,
              builder: (context, aimAngle, _) {
                var deg = (aimAngle * 180 / math.pi) % 360;
                if (deg < 0) deg += 360;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
                      width: 0.7,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${deg.toStringAsFixed(1)}°',
                        style: const TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const Text(
                        '±1mm',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 7.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNudgeButton({
    required IconData icon,
    required double iconSize,
    required double delta,
    required String tooltip,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startContinuousNudge(delta),
      onTapUp: (_) => _stopContinuousNudge(),
      onTapCancel: _stopContinuousNudge,
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white12, width: 0.5),
          ),
          child: Icon(
            icon,
            size: iconSize,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter vẽ bánh răng xoay cơ khí với các răng cưa 3D, vạch chia milimet và trục định hướng
class FineTuneGearPainter extends CustomPainter {
  final double angle;
  final int teethCount;
  final bool isDragging;

  FineTuneGearPainter({
    required this.angle,
    this.teethCount = 18,
    this.isDragging = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final toothDepth = outerRadius * 0.16;
    final rootRadius = outerRadius - toothDepth;
    final innerDialRadius = rootRadius * 0.78;
    final hubRadius = innerDialRadius * 0.46;

    final cyanAccent = const Color(0xFF00E5FF);

    // 1. Vẽ bóng đổ bên ngoài bánh răng
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawCircle(center, outerRadius - 1, shadowPaint);

    // 2. Vẽ vành răng cưa cơ khí (Cog Teeth)
    final gearPath = Path();
    final halfToothAngle = (2 * math.pi / teethCount) * 0.28;
    final stepAngle = (2 * math.pi / teethCount);

    for (int i = 0; i < teethCount; i++) {
      final toothCenterAngle = angle + i * stepAngle;
      final a1 = toothCenterAngle - stepAngle * 0.5;
      final a2 = toothCenterAngle - halfToothAngle;
      final a3 = toothCenterAngle - halfToothAngle * 0.65;
      final a4 = toothCenterAngle + halfToothAngle * 0.65;
      final a5 = toothCenterAngle + halfToothAngle;

      final pRoot1 = center + Offset(math.cos(a1) * rootRadius, math.sin(a1) * rootRadius);
      final pRoot2 = center + Offset(math.cos(a2) * rootRadius, math.sin(a2) * rootRadius);
      final pTip1 = center + Offset(math.cos(a3) * outerRadius, math.sin(a3) * outerRadius);
      final pTip2 = center + Offset(math.cos(a4) * outerRadius, math.sin(a4) * outerRadius);
      final pRoot3 = center + Offset(math.cos(a5) * rootRadius, math.sin(a5) * rootRadius);

      if (i == 0) {
        gearPath.moveTo(pRoot1.dx, pRoot1.dy);
      } else {
        gearPath.lineTo(pRoot1.dx, pRoot1.dy);
      }
      gearPath.lineTo(pRoot2.dx, pRoot2.dy);
      gearPath.lineTo(pTip1.dx, pTip1.dy);
      gearPath.lineTo(pTip2.dx, pTip2.dy);
      gearPath.lineTo(pRoot3.dx, pRoot3.dy);
    }
    gearPath.close();

    // Tô màu kim loại thép nòng súng (Gunmetal gradient) cho thân bánh răng
    final gearGradient = RadialGradient(
      center: Alignment.topLeft,
      radius: 0.95,
      colors: isDragging
          ? const [Color(0xFF324755), Color(0xFF1E2830), Color(0xFF11171C)]
          : const [Color(0xFF2E353D), Color(0xFF1F242A), Color(0xFF121518)],
    );
    final gearPaint = Paint()
      ..shader = gearGradient.createShader(Rect.fromCircle(center: center, radius: outerRadius))
      ..style = PaintingStyle.fill;
    canvas.drawPath(gearPath, gearPaint);

    // Viền kim loại sáng bóng quanh mép bánh răng
    final gearBorderPaint = Paint()
      ..color = isDragging
          ? cyanAccent.withValues(alpha: 0.8)
          : Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(gearPath, gearBorderPaint);

    // 3. Vùng mặt đĩa đồng tâm có vạch chia độ vi chỉnh
    final innerDialPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF141920), const Color(0xFF0B0E12)],
      ).createShader(Rect.fromCircle(center: center, radius: innerDialRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerDialRadius, innerDialPaint);

    final innerDialBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, innerDialRadius, innerDialBorder);

    // Vạch chia milimet / độ hướng tâm
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.7;
    final cyanTickPaint = Paint()
      ..color = cyanAccent.withValues(alpha: 0.8)
      ..strokeWidth = 1.1;

    const totalTicks = 24;
    for (int t = 0; t < totalTicks; t++) {
      final tAngle = angle + (t * 2 * math.pi / totalTicks);
      final isMajor = (t % 6 == 0);
      final tickLen = isMajor ? 3.8 : 2.0;
      final rStart = innerDialRadius - 1.0;
      final rEnd = rStart - tickLen;

      final pStart = center + Offset(math.cos(tAngle) * rStart, math.sin(tAngle) * rStart);
      final pEnd = center + Offset(math.cos(tAngle) * rEnd, math.sin(tAngle) * rEnd);
      canvas.drawLine(pStart, pEnd, isMajor ? cyanTickPaint : tickPaint);
    }

    // 4. Trục xoay trung tâm (Mechanical Center Bearing Hub)
    final hubGradient = RadialGradient(
      colors: const [Color(0xFF4A5568), Color(0xFF2D3748), Color(0xFF1A202C)],
    );
    final hubPaint = Paint()
      ..shader = hubGradient.createShader(Rect.fromCircle(center: center, radius: hubRadius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, hubRadius, hubPaint);

    final hubBorder = Paint()
      ..color = isDragging ? cyanAccent : Colors.white54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, hubRadius, hubBorder);

    // 4 Ốc lục giác cơ khí
    final boltPaint = Paint()
      ..color = Colors.white70
      ..style = PaintingStyle.fill;
    final boltDist = hubRadius * 0.60;
    for (int b = 0; b < 4; b++) {
      final bAngle = angle + (b * math.pi / 2);
      final boltCenter = center + Offset(math.cos(bAngle) * boltDist, math.sin(bAngle) * boltDist);
      canvas.drawCircle(boltCenter, 1.0, boltPaint);
    }

    // 5. Mũi kim chỉ hướng vi chỉnh phát sáng (Precision Target Needle)
    final needlePaint = Paint()
      ..color = cyanAccent
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final needleTip = center + Offset(math.cos(angle) * (innerDialRadius - 1.0), math.sin(angle) * (innerDialRadius - 1.0));
    final needleTail = center + Offset(math.cos(angle) * (hubRadius * 0.8), math.sin(angle) * (hubRadius * 0.8));
    canvas.drawLine(needleTail, needleTip, needlePaint);

    // Chấm ngọc tâm phát sáng
    final centerDotPaint = Paint()
      ..color = cyanAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 1.8, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant FineTuneGearPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.teethCount != teethCount;
  }
}
