import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../main.dart';

/// Thanh Trượt Thước Đo Vi Chỉnh Góc Bắn (Aim Ruler Slider Control)
/// Chuẩn phong cách 8 Ball Pool theo hình ảnh mẫu tham khảo:
/// - Phía trên: Chữ số độ màu vàng kim rực rỡ (0°, 15°, 45°...)
/// - Ở giữa: Rãnh con nhộng kim loại 3D với thước vạch chia độ và con trỏ tam giác đỏ (►)
/// - Phía dưới: Nút tròn bi cái màu trắng với chấm đỏ xoáy (Cue Spin Button)
class AimRulerSliderControl extends StatefulWidget {
  final BilliardGame game;
  final bool compact;
  final bool ultraCompact;
  final double upscaleFactor;
  final VoidCallback? onOpenSpinDialog;

  const AimRulerSliderControl({
    super.key,
    required this.game,
    this.compact = false,
    this.ultraCompact = false,
    this.upscaleFactor = 1.0,
    this.onOpenSpinDialog,
  });

  @override
  State<AimRulerSliderControl> createState() => _AimRulerSliderControlState();
}

class _AimRulerSliderControlState extends State<AimRulerSliderControl> with WidgetsBindingObserver {
  double? _lastPanY;
  bool _isDragging = false;
  int _lastHapticStep = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      if (_isDragging || _lastPanY != null) {
        setState(() {
          _isDragging = false;
          _lastPanY = null;
        });
      }
    }
  }

  void _triggerHaptic(double angle) {
    final step = (angle * 180 / math.pi).floor();
    if (step != _lastHapticStep) {
      _lastHapticStep = step;
      HapticFeedback.selectionClick();
    }
  }

  void _nudge(double delta) {
    if (!widget.game.canUserControl) return;
    widget.game.rotateAim(delta);
    _triggerHaptic(widget.game.aimAngle);
  }

  @override
  Widget build(BuildContext context) {
    final ultraCompact = widget.ultraCompact;
    final compact = widget.compact;
    final scale = widget.upscaleFactor;
    final controlWidth = (ultraCompact ? 34.0 : (compact ? 40.0 : 46.0)) * scale;
    final capsuleWidth = (ultraCompact ? 22.0 : (compact ? 26.0 : 30.0)) * scale;
    final bottomButtonSize = (ultraCompact ? 28.0 : (compact ? 34.0 : 38.0)) * scale;

    return SizedBox(
      width: controlWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Chữ số góc độ màu vàng kim rực rỡ phía trên thước (ví dụ 0°)
          _buildYellowDegreeHeader(ultraCompact, compact),
          SizedBox(height: (ultraCompact ? 3.0 : 5.0) * scale),

          // 2. Rãnh con nhộng kim loại 3D chứa thước ngắm vạch chia độ và mũi tên đỏ
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final trackHeight = constraints.maxHeight;

                return GestureDetector(
                  key: const ValueKey('aim_ruler_track_gesture'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (details) {
                    if (!widget.game.canUserControl) return;
                    setState(() => _isDragging = true);
                    _lastPanY = details.localPosition.dy;
                    HapticFeedback.selectionClick();
                  },
                  onPanUpdate: (details) {
                    if (!widget.game.canUserControl) return;
                    final currentY = details.localPosition.dy;
                    final dy = currentY - (_lastPanY ?? currentY);
                    _lastPanY = currentY;

                    // Vuốt xuống -> quay theo chiều kim đồng hồ (+delta)
                    // Vuốt lên -> quay ngược chiều kim đồng hồ (-delta)
                    // Tỉ lệ 0.0040 rad / pixel cho độ nhạy vi chỉnh milimet siêu mượt
                    final deltaAngle = dy * 0.0040;
                    if (deltaAngle.abs() > 0.00005) {
                      widget.game.rotateAim(deltaAngle);
                      _triggerHaptic(widget.game.aimAngle);
                    }
                  },
                  onPanEnd: (_) {
                    setState(() => _isDragging = false);
                    _lastPanY = null;
                  },
                  onPanCancel: () {
                    setState(() => _isDragging = false);
                    _lastPanY = null;
                  },
                  onTapDown: (details) {
                    // Chạm nửa trên: nhích lên 1mm (-0.0045 rad)
                    // Chạm nửa dưới: nhích xuống 1mm (+0.0045 rad)
                    final centerY = trackHeight / 2;
                    if (details.localPosition.dy < centerY) {
                      _nudge(-0.0045);
                    } else {
                      _nudge(0.0045);
                    }
                  },
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
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          (capsuleWidth - 3) / 2,
                        ),
                        child: Stack(
                          children: [
                            // Nền dải kim loại trụ 3D sâu trong lòng rãnh
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF161616),
                                      Color(0xFF383838),
                                      Color(0xFF6E6E6E),
                                      Color(0xFF383838),
                                      Color(0xFF161616),
                                    ],
                                    stops: [0.0, 0.25, 0.50, 0.75, 1.0],
                                  ),
                                ),
                              ),
                            ),

                            // Bóng trụ ánh sáng chiều ngang
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.6),
                                      Colors.white.withValues(alpha: 0.15),
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.5),
                                    ],
                                    stops: const [0.0, 0.2, 0.7, 1.0],
                                  ),
                                ),
                              ),
                            ),

                            // Các vạch khắc thước đo vi chỉnh cuộn mượt theo góc ngắm
                            Positioned.fill(
                              child: ValueListenableBuilder<double>(
                                valueListenable: widget.game.aimAngleNotifier,
                                builder: (context, angle, _) {
                                  return CustomPaint(
                                    painter: AimRulerPainter(
                                      angle: angle,
                                      isDragging: _isDragging,
                                    ),
                                  );
                                },
                              ),
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
          SizedBox(height: ultraCompact ? 2.0 : 4.0),

          // 2.5. Hiển thị Telemetry áp-phê chính xác (dx, dy) khi người chơi chỉnh xoáy
          ValueListenableBuilder<Offset>(
            valueListenable: widget.game.cueSpin,
            builder: (context, spin, _) {
              if (spin.distance < 0.04) return const SizedBox.shrink();
              final dxStr = '${spin.dx >= 0 ? '+' : ''}${spin.dx.toStringAsFixed(1)}';
              final dyStr = '${spin.dy >= 0 ? '+' : ''}${spin.dy.toStringAsFixed(1)}';
              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF101418),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 0.6),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '$dxStr,$dyStr',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: ultraCompact ? 6.5 : 8.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. Nút tròn màu trắng bi cái có chấm đỏ xoáy (Spin Button) ở góc dưới bên phải
          _buildBottomSpinButton(bottomButtonSize, ultraCompact),
        ],
      ),
    );
  }

  /// Tiêu đề góc độ (ví dụ 0°) màu vàng kim rực rỡ có viền đổ bóng nổi bật
  Widget _buildYellowDegreeHeader(bool ultraCompact, bool compact) {
    return ValueListenableBuilder<double>(
      valueListenable: widget.game.aimAngleNotifier,
      builder: (context, angle, _) {
        int deg = ((angle * 180 / math.pi).round() % 360 + 360) % 360;

        return Text(
          '$deg°',
          style: TextStyle(
            color: const Color(0xFFFFDE00), // Vàng kim rực rỡ chuẩn ảnh mẫu
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
      },
    );
  }

  /// Nút tròn màu trắng bi cái có chấm đỏ xoáy (Cue Spin Button) ở chân thước
  Widget _buildBottomSpinButton(double buttonSize, bool ultraCompact) {
    return GestureDetector(
      onTap: () {
        if (!widget.game.canUserControl) return;
        HapticFeedback.lightImpact();
        widget.onOpenSpinDialog?.call();
      },
      onPanUpdate: (details) {
        if (!widget.game.canUserControl) return;
        final center = Offset(buttonSize / 2, buttonSize / 2);
        final delta = details.localPosition - center;
        final maxRadius = buttonSize / 2;
        final normalized = Offset(
          (delta.dx / maxRadius).clamp(-1.0, 1.0),
          (delta.dy / maxRadius).clamp(-1.0, 1.0),
        );
        widget.game.setCueSpin(normalized);
      },
      onPanEnd: (_) => widget.game.commitCueSpin(),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF141414),
          border: Border.all(
            color: const Color(0xFF2E2E2E),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: Alignment(-0.35, -0.35),
              radius: 0.85,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFEDEDED),
                Color(0xFFB0B0B0),
              ],
              stops: [0.0, 0.65, 1.0],
            ),
          ),
          child: Center(
            child: ValueListenableBuilder<Offset>(
              valueListenable: widget.game.cueSpin,
              builder: (context, spin, _) {
                final maxOffset = (buttonSize - 12) * 0.36;
                return Transform.translate(
                  offset: Offset(spin.dx * maxOffset, spin.dy * maxOffset),
                  child: Container(
                    width: ultraCompact ? 4.5 : 5.5,
                    height: ultraCompact ? 4.5 : 5.5,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 1.5,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter vẽ các vạch thước đo chia độ và con trỏ tam giác màu đỏ
class AimRulerPainter extends CustomPainter {
  final double angle;
  final bool isDragging;

  AimRulerPainter({
    required this.angle,
    required this.isDragging,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // Khoảng cách giữa các vạch chia độ trên rãnh
    const tickSpacing = 16.0;
    // Tỉ lệ cuộn: 1 rad tương ứng ~250 pixel
    const pixelsPerRadian = 250.0;
    final scrollOffset = angle * pixelsPerRadian;
    final tickOffset = (scrollOffset % tickSpacing);

    final linePaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..strokeWidth = 1.2;

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..strokeWidth = 1.0;

    // Vẽ các vạch ngang chạy dọc thân thước
    for (double y = -tickSpacing + tickOffset; y <= height + tickSpacing; y += tickSpacing) {
      if (y < 4 || y > height - 4) continue;

      final tickIndex = ((scrollOffset - y) / tickSpacing).round();
      final isMajor = tickIndex % 4 == 0;

      final startX = isMajor ? 5.0 : 9.0;
      final endX = width - 4.0;

      // Vạch phản chiếu sáng phía dưới tạo rãnh khắc kim loại chìm 3D
      canvas.drawLine(
        Offset(startX, y + 1),
        Offset(endX, y + 1),
        highlightPaint,
      );

      // Vạch khắc chính
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        isMajor
            ? (Paint()
              ..color = const Color(0xFF0D0D0D)
              ..strokeWidth = 1.6)
            : linePaint,
      );
    }

    // Vẽ con trỏ hình tam giác màu đỏ (►) ở mép trái chỉ vào vạch giữa thước
    const pointerW = 9.5;
    const pointerH = 13.0;

    final pointerPath = Path()
      ..moveTo(0, centerY - pointerH / 2)
      ..lineTo(pointerW, centerY)
      ..lineTo(0, centerY + pointerH / 2)
      ..close();

    // Bóng đổ của mũi tên đỏ
    canvas.drawPath(
      pointerPath.shift(const Offset(0.8, 1.2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );

    // Thân con trỏ tam giác đỏ
    final pointerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFF3D00), Color(0xFFD50000)],
      ).createShader(Rect.fromLTWH(0, centerY - pointerH / 2, pointerW, pointerH));

    canvas.drawPath(pointerPath, pointerPaint);

    // Viền đậm cho con trỏ đỏ
    canvas.drawPath(
      pointerPath,
      Paint()
        ..color = const Color(0xFF6B0000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant AimRulerPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.isDragging != isDragging;
  }
}
