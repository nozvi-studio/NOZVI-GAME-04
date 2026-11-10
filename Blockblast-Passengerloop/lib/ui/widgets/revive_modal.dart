import 'package:flutter/material.dart';
import '../../logic/revive_controller.dart';
import '../../logic/win_streak_manager.dart';

class ReviveModal extends StatefulWidget {
  final ReviveType type;
  final VoidCallback onRevive;
  final VoidCallback onGiveUp;

  const ReviveModal({
    super.key,
    required this.type,
    required this.onRevive,
    required this.onGiveUp,
  });

  @override
  State<ReviveModal> createState() => _ReviveModalState();
}

class _ReviveModalState extends State<ReviveModal> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final streak = WinStreakManager.instance;
    final hasStreak = streak.streakCount > 0;
    final isDock = widget.type == ReviveType.dockOverflow;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF1E252B),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasStreak ? const Color(0xFFFF5722) : const Color(0xFF00E676),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (hasStreak ? Colors.deepOrange : Colors.green).withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Cảnh báo Chuỗi Thắng (Super Bus Streak)
              if (hasStreak) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD84315), Color(0xFFFF6E40)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'NGUY CƠ MẤT CHUỖI THẮNG ${streak.streakTier > 0 ? "BẬC ${streak.streakTier}" : ""} (${streak.streakCount} TRẬN)!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const Text(
                  'CƠ HỘI CỨU THUA KHẨN CẤP!',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // 2. Biểu tượng và Tiêu đề cứu trợ
              Text(
                isDock ? '🚁' : '🚒',
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 8),
              Text(
                isDock ? 'TRỰC THĂNG GIẢI CỨU' : 'ĐỘI CỨU HỘ KHẨN CẤP',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 12),

              // 3. Quyền lợi nhận được khi hồi sinh
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: isDock
                      ? [
                          _buildPerkRow('✨ Bốc ngay 3 bé thú cưng khỏi ghế chờ'),
                          const SizedBox(height: 6),
                          _buildPerkRow('💺 Mở thêm 1 ghế VIP vĩnh viễn cho ván này'),
                        ]
                      : [
                          _buildPerkRow('💥 Quét sạch 2 hàng đông gạch nhất trên bàn cờ'),
                          const SizedBox(height: 6),
                          _buildPerkRow('🎁 Cấp 3 khối đơn 1x1 siêu giải cứu trùng màu xe'),
                        ],
                ),
              ),
              const SizedBox(height: 22),

              // 4. Nút bấm: Hồi Sinh Ngay (Nổi bật) vs Bỏ Cuộc
              ScaleTransition(
                scale: _scaleAnimation,
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: widget.onRevive,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C853),
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: Colors.greenAccent.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.favorite, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'HỒI SINH CỨU CHUỖI NGAY',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              TextButton(
                onPressed: widget.onGiveUp,
                child: const Text(
                  'Bỏ cuộc (Chấp nhận mất chuỗi)',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerkRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

