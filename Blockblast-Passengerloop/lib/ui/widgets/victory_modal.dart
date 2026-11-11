import 'package:flutter/material.dart';
import '../../logic/win_streak_manager.dart';

class VictoryModal extends StatefulWidget {
  final int level;
  final int stars;
  final int score;
  final int coinsEarned;
  final VoidCallback onNextLevel;
  final VoidCallback onBackToMap;

  const VictoryModal({
    super.key,
    required this.level,
    required this.stars,
    required this.score,
    required this.coinsEarned,
    required this.onNextLevel,
    required this.onBackToMap,
  });

  @override
  State<VictoryModal> createState() => _VictoryModalState();
}

class _VictoryModalState extends State<VictoryModal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = WinStreakManager.instance;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4A2E1B), Color(0xFF3B2314)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFD84D), width: 2.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD84D).withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final coinCount = (widget.coinsEarned * _controller.value).round();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tiêu đề Chiến Thắng
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF81E659), Color(0xFF4BC226)]),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        widget.level == 0 ? '🎉 HOÀN THÀNH HƯỚNG DẪN!' : '🎉 CHIẾN THẮNG MÀN ${widget.level}!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF1F1A17),
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Hoạt ảnh 3 Ngôi Sao bay lần lượt vào bảng kết quả
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final bool isEarned = index < widget.stars;
                        final double start = index * 0.22;
                        final double end = (start + 0.42).clamp(0.0, 1.0);
                        final double t = Interval(start, end, curve: Curves.elasticOut).transform(_controller.value);
                        final double dy = (1.0 - t) * -36.0;

                        return Transform.translate(
                          offset: Offset(0, dy + (index == 1 ? -8 : 0)),
                          child: Transform.scale(
                            scale: isEarned ? t.clamp(0.2, 1.25) : 0.85,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                Icons.star_rounded,
                                size: index == 1 ? 54 : 44,
                                color: isEarned ? const Color(0xFFFFD84D) : Colors.white12,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Bảng điểm số & Đếm số Xu thưởng
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2B1D14),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF6D4226)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Điểm số đạt được:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(
                                '${widget.score}',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white12, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Xu thưởng nhận được:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Row(
                                children: [
                                  const Text('🪙', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+$coinCount',
                                    style: const TextStyle(
                                      color: Color(0xFFFFD84D),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Huy hiệu Super Bus Streak tăng lên
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFFFF9D42), Color(0xFFE86F17)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Super Bus Streak: ${streak.streakCount} Trận (Bậc ${streak.streakTier})',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Nút sang màn tiếp theo
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD84D),
                          foregroundColor: const Color(0xFF3B2314),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'MÀN TIẾP THEO',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                        ),
                        onPressed: widget.onNextLevel,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: widget.onBackToMap,
                      child: const Text('Về Bản Đồ Hành Trình', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

