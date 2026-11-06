import 'dart:async';
import 'package:flutter/material.dart';
import '../services/progression_service.dart';
import '../models/table_skin_model.dart';

class ComboEvent {
  final int count;
  final String title;
  final String subtitle;
  final int timestamp;

  const ComboEvent({
    required this.count,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });
}

/// Hiển thị chữ COMBO chuẩn phong cách Arcade 8-Ball Pool / ZingPlay:
/// Chữ số màu Vàng 3D + Chữ "COMBO" màu Xanh Dương 3D viền trắng nổi bật ngay trên mặt bàn.
class ComboBannerOverlay extends StatefulWidget {
  final ValueNotifier<ComboEvent?> comboNotifier;

  const ComboBannerOverlay({
    super.key,
    required this.comboNotifier,
  });

  @override
  State<ComboBannerOverlay> createState() => _ComboBannerOverlayState();
}

class _ComboBannerOverlayState extends State<ComboBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotateAnimation;
  late final Animation<double> _opacityAnimation;
  late final Animation<Offset> _slideAnimation;

  Timer? _dismissTimer;
  ComboEvent? _currentCombo;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Hiệu ứng phóng to bật nảy mạnh mẽ (Punch Pop-in)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.15, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.25, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 35,
      ),
    ]).animate(_controller);

    // Góc nghiêng nhẹ -4 độ phong cách hành động
    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.12, end: -0.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.06, end: -0.05)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.40, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ),
    );

    widget.comboNotifier.addListener(_onComboTriggered);
  }

  void _onComboTriggered() {
    final event = widget.comboNotifier.value;
    if (event == null || event.count < 2) return;

    _dismissTimer?.cancel();
    setState(() {
      _currentCombo = event;
    });

    _controller.forward(from: 0.0);

    // Giữ chữ combo trong 1.8 giây rồi thu nhỏ mờ dần
    _dismissTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) {
            setState(() {
              _currentCombo = null;
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    widget.comboNotifier.removeListener(_onComboTriggered);
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentCombo == null) return const SizedBox.shrink();

    final count = _currentCombo!.count;
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 750 || size.height < 450;
    final isUltraCompact = size.width < 550 || size.height < 360;

    final numSize = isUltraCompact ? 42.0 : (isCompact ? 54.0 : 68.0);
    final wordSize = isUltraCompact ? 32.0 : (isCompact ? 42.0 : 52.0);

    final concept = ProgressionService.instance.equippedTable.animeConcept;

    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: SlideTransition(
                position: _slideAnimation,
                child: Transform.rotate(
                  angle: _rotateAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (concept != TableAnimeConcept.classic) ...[
                          _buildAnimeConceptTag(concept, isUltraCompact ? 10.0 : 12.0),
                          const SizedBox(height: 2),
                        ],
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            _build3DNumber(count, numSize, concept),
                            SizedBox(width: isUltraCompact ? 4 : 8),
                            _build3DComboWord(wordSize, concept),
                          ],
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
    );
  }

  /// Huy hiệu Anime Concept của Combo
  Widget _buildAnimeConceptTag(TableAnimeConcept concept, double fontSize) {
    String tagText;
    Color tagColor;
    Color tagBg;

    switch (concept) {
      case TableAnimeConcept.cyberTokyo:
        tagText = '⚡ CYBER 連撃 BURST ⚡';
        tagColor = const Color(0xFF00E5FF);
        tagBg = const Color(0x3300E5FF);
        break;
      case TableAnimeConcept.sakuraZen:
        tagText = '🌸 華麗なる連撃 SAKURA 🌸';
        tagColor = const Color(0xFFFF80AB);
        tagBg = const Color(0x33FF80AB);
        break;
      case TableAnimeConcept.dragonLava:
        tagText = '🔥 爆炎連撃 DRAGON FLAME 🔥';
        tagColor = const Color(0xFFFF9100);
        tagBg = const Color(0x33FF9100);
        break;
      case TableAnimeConcept.arcaneGrimoire:
        tagText = '✨ 秘術詠唱 ARCANE ✨';
        tagColor = const Color(0xFFB388FF);
        tagBg = const Color(0x337C4DFF);
        break;
      case TableAnimeConcept.shadowVoid:
        tagText = '🌑 影の支配 SHADOW 🌑';
        tagColor = const Color(0xFFBA68C8);
        tagBg = const Color(0x336A1B9A);
        break;
      case TableAnimeConcept.mechaEva:
        tagText = '🛡️ 殲滅モード MECHA EVA 🛡️';
        tagColor = const Color(0xFF76FF03);
        tagBg = const Color(0x3376FF03);
        break;
      case TableAnimeConcept.classic:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: tagBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tagColor.withValues(alpha: 0.6), width: 1),
        boxShadow: [
          BoxShadow(color: tagColor.withValues(alpha: 0.3), blurRadius: 6),
        ],
      ),
      child: Text(
        tagText,
        style: TextStyle(
          color: tagColor,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  /// Số Combo (Màu Vàng - Cam 3D viền đậm, đổ bóng khối)
  Widget _build3DNumber(int count, double fontSize, TableAnimeConcept concept) {
    final text = '$count';
    const skew = -0.18; // Nghiêng phong cách arcade thể thao

    List<Color> numberGradient;
    switch (concept) {
      case TableAnimeConcept.cyberTokyo:
        numberGradient = const [
          Color(0xFFE0F7FA),
          Color(0xFF00E5FF),
          Color(0xFF00B0FF),
          Color(0xFF2979FF),
        ];
        break;
      case TableAnimeConcept.sakuraZen:
        numberGradient = const [
          Color(0xFFFFF0F5),
          Color(0xFFFF80AB),
          Color(0xFFF06292),
          Color(0xFFE91E63),
        ];
        break;
      case TableAnimeConcept.dragonLava:
        numberGradient = const [
          Color(0xFFFFF8E1),
          Color(0xFFFFD54F),
          Color(0xFFFF6D00),
          Color(0xFFDD2C00),
        ];
        break;
      case TableAnimeConcept.arcaneGrimoire:
        numberGradient = const [
          Color(0xFFEDE7F6),
          Color(0xFFB388FF),
          Color(0xFF7C4DFF),
          Color(0xFF512DA8),
        ];
        break;
      case TableAnimeConcept.shadowVoid:
        numberGradient = const [
          Color(0xFFF3E5F5),
          Color(0xFFCE93D8),
          Color(0xFFAB47BC),
          Color(0xFF6A1B9A),
        ];
        break;
      case TableAnimeConcept.mechaEva:
        numberGradient = const [
          Color(0xFFF1F8E9),
          Color(0xFFB2FF59),
          Color(0xFF76FF03),
          Color(0xFF64DD17),
        ];
        break;
      case TableAnimeConcept.classic:
        numberGradient = const [
          Color(0xFFFFF9C4),
          Color(0xFFFFEA00),
          Color(0xFFFFB300),
          Color(0xFFFF6D00),
        ];
        break;
    }

    return Transform(
      transform: Matrix4.skewX(skew),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lớp 1: Đổ bóng 3D sâu phía dưới
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF1A1A1A),
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  offset: Offset(0, 6),
                  blurRadius: 10,
                ),
                Shadow(
                  color: Colors.black54,
                  offset: Offset(-2, 4),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
          // Lớp 2: Viền đen socola dày dặn (Thick outer stroke)
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = fontSize * 0.16
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..color = const Color(0xFF1E1E1E),
            ),
          ),
          // Lớp 3: Màu Gradient theo Anime Concept
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: numberGradient,
              stops: const [0.0, 0.25, 0.65, 1.0],
            ).createShader(bounds),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chữ "COMBO" độc quyền theo Concept Anime
  Widget _build3DComboWord(double fontSize, TableAnimeConcept concept) {
    String text;
    List<Color> wordGradient;
    Color innerStrokeColor;

    switch (concept) {
      case TableAnimeConcept.cyberTokyo:
        text = 'CYBER 連撃';
        wordGradient = const [
          Color(0xFFE0F7FA),
          Color(0xFF00E5FF),
          Color(0xFFE040FB),
          Color(0xFF7C4DFF),
        ];
        innerStrokeColor = const Color(0xFF00B0FF);
        break;
      case TableAnimeConcept.sakuraZen:
        text = 'ISSEN 一閃';
        wordGradient = const [
          Color(0xFFFFF0F5),
          Color(0xFFFF80AB),
          Color(0xFFF06292),
          Color(0xFF880E4F),
        ];
        innerStrokeColor = const Color(0xFFC2185B);
        break;
      case TableAnimeConcept.dragonLava:
        text = 'BURNING 爆炎';
        wordGradient = const [
          Color(0xFFFFF8E1),
          Color(0xFFFFD54F),
          Color(0xFFFF6D00),
          Color(0xFFB71C1C),
        ];
        innerStrokeColor = const Color(0xFFBF360C);
        break;
      case TableAnimeConcept.arcaneGrimoire:
        text = 'ARCANE 詠唱';
        wordGradient = const [
          Color(0xFFEDE7F6),
          Color(0xFFB388FF),
          Color(0xFF7C4DFF),
          Color(0xFF311B92),
        ];
        innerStrokeColor = const Color(0xFF512DA8);
        break;
      case TableAnimeConcept.shadowVoid:
        text = 'SHADOW 支配';
        wordGradient = const [
          Color(0xFFF3E5F5),
          Color(0xFFCE93D8),
          Color(0xFF8E24AA),
          Color(0xFF1A002C),
        ];
        innerStrokeColor = const Color(0xFF4A148C);
        break;
      case TableAnimeConcept.mechaEva:
        text = 'CRITICAL 殲滅';
        wordGradient = const [
          Color(0xFFF1F8E9),
          Color(0xFF76FF03),
          Color(0xFFFF9100),
          Color(0xFFBF360C),
        ];
        innerStrokeColor = const Color(0xFF33691E);
        break;
      case TableAnimeConcept.classic:
        text = 'COMBO';
        wordGradient = const [
          Color(0xFFE0F7FA),
          Color(0xFF00E5FF),
          Color(0xFF0091EA),
          Color(0xFF0D47A1),
        ];
        innerStrokeColor = const Color(0xFF01579B);
        break;
    }

    const skew = -0.18; // Đồng bộ góc nghiêng với số

    return Transform(
      transform: Matrix4.skewX(skew),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lớp 1: Đổ bóng 3D khối phía dưới
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.5,
              color: const Color(0xFF0A0A0A),
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  offset: Offset(0, 6),
                  blurRadius: 10,
                ),
                Shadow(
                  color: Colors.black54,
                  offset: Offset(-2, 4),
                  blurRadius: 0,
                ),
              ],
            ),
          ),
          // Lớp 2: Viền Trắng Tinh Khôi Dày (Thick crisp white border)
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.5,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = fontSize * 0.18
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..color = Colors.white,
            ),
          ),
          // Lớp 3: Viền màu đậm bên trong viền trắng để tạo độ nét viền
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.5,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = fontSize * 0.08
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..color = innerStrokeColor,
            ),
          ),
          // Lớp 4: Màu Gradient Concept Anime
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: wordGradient,
              stops: const [0.0, 0.28, 0.68, 1.0],
            ).createShader(bounds),
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: 1.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
