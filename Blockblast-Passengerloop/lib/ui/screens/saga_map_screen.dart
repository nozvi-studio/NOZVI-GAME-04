import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../logic/player_economy_service.dart';
import '../../core/pentatonic_audio_synth.dart';

/// Tab 2 - Bản Đồ Hành Trình 500 Màn (Saga World Map) uốn lượn qua 11 Chương
class SagaMapScreen extends StatefulWidget {
  final Function(int level) onSelectLevel;

  const SagaMapScreen({
    super.key,
    required this.onSelectLevel,
  });

  @override
  State<SagaMapScreen> createState() => _SagaMapScreenState();
}

class _SagaMapScreenState extends State<SagaMapScreen> {
  final ScrollController _scrollController = ScrollController();
  int _selectedChapter = 1;

  static const double _rowHeight = 92.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToChapter(int chapter) {
    setState(() {
      _selectedChapter = chapter;
    });
    final int startLevel;
    switch (chapter) {
      case 1:
        startLevel = 1;
        break;
      case 2:
        startLevel = 31;
        break;
      case 3:
        startLevel = 81;
        break;
      case 4:
        startLevel = 131;
        break;
      case 5:
        startLevel = 171;
        break;
      case 6:
        startLevel = 201;
        break;
      case 7:
        startLevel = 251;
        break;
      case 8:
        startLevel = 301;
        break;
      case 9:
        startLevel = 351;
        break;
      case 10:
        startLevel = 401;
        break;
      case 11:
      default:
        startLevel = 451;
        break;
    }

    if (_scrollController.hasClients) {
      final offset = (startLevel - 1) * _rowHeight;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  double _nodeNormalizedX(int levelIndex) {
    // Quỹ đạo hình sin uốn lượn mượt mà trong khoảng [-0.65, 0.65]
    return math.sin(levelIndex * 0.72) * 0.62;
  }

  ({String title, Color c1, Color c2, String emoji}) _chapterInfo(int level) {
    if (level <= 30) {
      return (
        title: 'Chương 1: Công Viên Nắng Ấm (1-30)',
        c1: const Color(0xFF88D45E),
        c2: const Color(0xFF4BC226),
        emoji: '🌞',
      );
    }
    if (level <= 80) {
      return (
        title: 'Chương 2: Xứ Sở Băng Giá (31-80)',
        c1: const Color(0xFF4FC3F7),
        c2: const Color(0xFF0D5CA8),
        emoji: '❄️',
      );
    }
    if (level <= 130) {
      return (
        title: 'Chương 3: Rừng Dây Leo (81-130)',
        c1: const Color(0xFF66BB6A),
        c2: const Color(0xFF2D8512),
        emoji: '🌿',
      );
    }
    if (level <= 170) {
      return (
        title: 'Chương 4: Thành Phố Đồ Chơi (131-170)',
        c1: const Color(0xFFFF9D42),
        c2: const Color(0xFFE86F17),
        emoji: '🧸',
      );
    }
    if (level <= 200) {
      return (
        title: 'Chương 5: Thủ Đô Di Chúc (171-200)',
        c1: const Color(0xFFFF6B5B),
        c2: const Color(0xFFA82419),
        emoji: '👑',
      );
    }
    if (level <= 250) {
      return (
        title: 'Chương 6: Thung Lũng Dung Nham (201-250)',
        c1: const Color(0xFFFF5722),
        c2: const Color(0xFFD84315),
        emoji: '🌋',
      );
    }
    if (level <= 300) {
      return (
        title: 'Chương 7: Bến Cảng Hoàng Hôn (251-300)',
        c1: const Color(0xFF7E57C2),
        c2: const Color(0xFF283593),
        emoji: '⚓',
      );
    }
    if (level <= 350) {
      return (
        title: 'Chương 8: Vườn Nấm Phát Sáng (301-350)',
        c1: const Color(0xFF26A69A),
        c2: const Color(0xFF004D40),
        emoji: '🍄',
      );
    }
    if (level <= 400) {
      return (
        title: 'Chương 9: Nhà Máy Bánh Răng (351-400)',
        c1: const Color(0xFFFFA000),
        c2: const Color(0xFF455A64),
        emoji: '⚙️',
      );
    }
    if (level <= 450) {
      return (
        title: 'Chương 10: Xứ Sở Kẹo Ngọt (401-450)',
        c1: const Color(0xFFEC407A),
        c2: const Color(0xFFAD1457),
        emoji: '🍭',
      );
    }
    return (
      title: 'Chương 11: Thiên Hà Tinh Vân (451-500)',
      c1: const Color(0xFF7C4DFF),
      c2: const Color(0xFF1A237E),
      emoji: '🚀',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerEconomyService.instance,
      builder: (context, _) {
        final economy = PlayerEconomyService.instance;

        return Column(
          children: [
            // Nút Tập luyện Căn bản (FTUE) + Thanh chọn nhanh 11 Chương
            Container(
              color: const Color(0xFF21292E),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4BC226),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                          icon: const Text('🎓', style: TextStyle(fontSize: 15)),
                          label: const Text(
                            'TẬP LUYỆN CĂN BẢN (MÀN 0)',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11.5),
                          ),
                          onPressed: () => widget.onSelectLevel(0),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildChapterChip(1, 'C1: Công Viên'),
                        _buildChapterChip(2, 'C2: Băng Giá'),
                        _buildChapterChip(3, 'C3: Dây Leo'),
                        _buildChapterChip(4, 'C4: Đồ Chơi'),
                        _buildChapterChip(5, 'C5: Thủ Đô'),
                        _buildChapterChip(6, 'C6: Dung Nham'),
                        _buildChapterChip(7, 'C7: Bến Cảng'),
                        _buildChapterChip(8, 'C8: Vườn Nấm'),
                        _buildChapterChip(9, 'C9: Bánh Răng'),
                        _buildChapterChip(10, 'C10: Kẹo Ngọt'),
                        _buildChapterChip(11, 'C11: Thiên Hà'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Đường đi Saga uốn lượn 500 màn
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double width = constraints.maxWidth;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: 500,
                    itemBuilder: (context, index) {
                      final int level = index + 1;
                      final bool isChapterStart = level == 1 ||
                          level == 31 ||
                          level == 81 ||
                          level == 131 ||
                          level == 171 ||
                          level == 201 ||
                          level == 251 ||
                          level == 301 ||
                          level == 351 ||
                          level == 401 ||
                          level == 451;
                      final info = _chapterInfo(level);
                      final bool isMilestone = PlayerEconomyService.kMilestoneLevels.contains(level);

                      final double xNorm = _nodeNormalizedX(index);
                      final double nextXNorm = level < 500 ? _nodeNormalizedX(index + 1) : xNorm;
                      final double nodeX = width / 2 + xNorm * (width * 0.34);
                      final double nextNodeX = width / 2 + nextXNorm * (width * 0.34);

                      final bool isUnlocked = level <= economy.unlockedLevel;
                      final bool isCurrent = level == economy.unlockedLevel;
                      final int stars = economy.levelStars[level] ?? 0;

                      return Column(
                        children: [
                          if (isChapterStart)
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [info.c1, info.c2]),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5, offset: Offset(0, 3))],
                              ),
                              child: Row(
                                children: [
                                  Text(info.emoji, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      info.title,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12.5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            height: _rowHeight,
                            width: width,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Đoạn đường cong nối sang màn kế tiếp
                                if (level < 500)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _SagaPathPainter(
                                        startX: nodeX,
                                        endX: nextNodeX,
                                        height: _rowHeight,
                                        isUnlocked: isUnlocked,
                                      ),
                                    ),
                                  ),

                                // Nút màn chơi trên đường uốn lượn
                                Positioned(
                                  left: nodeX - 30,
                                  top: 8,
                                  width: 60,
                                  child: _buildLevelNode(
                                    level: level,
                                    stars: stars,
                                    isUnlocked: isUnlocked,
                                    isCurrent: isCurrent,
                                    chapterColor: info.c2,
                                  ),
                                ),

                                // Rương Quà tại các mốc màn 10, 25, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500
                                if (isMilestone)
                                  Positioned(
                                    left: xNorm > 0 ? nodeX - 102 : nodeX + 42,
                                    top: 10,
                                    child: _buildMilestoneChest(context, economy, level),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChapterChip(int chapter, String label) {
    final bool selected = _selectedChapter == chapter;
    return GestureDetector(
      onTap: () => _jumpToChapter(chapter),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFD84D) : const Color(0xFF2E3A40),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? Colors.white : Colors.white24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF3B2314) : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelNode({
    required int level,
    required int stars,
    required bool isUnlocked,
    required bool isCurrent,
    required Color chapterColor,
  }) {
    return GestureDetector(
      onTap: isUnlocked ? () => widget.onSelectLevel(level) : null,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? chapterColor : const Color(0xFF424242),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFFFFD84D)
                    : (isUnlocked ? Colors.white : Colors.white24),
                width: isCurrent ? 3.2 : 2.0,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: (isCurrent ? const Color(0xFFFFD84D) : chapterColor).withValues(alpha: 0.45),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: isUnlocked
                  ? Text(
                      '$level',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    )
                  : const Icon(Icons.lock_rounded, color: Colors.white38, size: 18),
            ),
          ),
          const SizedBox(height: 3),
          if (isUnlocked)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: i < stars ? const Color(0xFFFFD84D) : Colors.white24,
                ),
              ),
            )
          else
            Text(
              'Màn $level',
              style: const TextStyle(color: Colors.white38, fontSize: 9.5, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _buildMilestoneChest(BuildContext context, PlayerEconomyService economy, int level) {
    final bool unlocked = economy.isMilestoneUnlocked(level);
    final bool claimed = economy.isMilestoneClaimed(level);

    return GestureDetector(
      onTap: () async {
        if (!unlocked) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Vượt qua Màn $level để mở Rương Quà Mốc!')),
          );
          return;
        }
        if (claimed) return;
        final reward = await economy.claimMilestoneChest(level);
        if (reward != null && context.mounted) {
          PentatonicAudioSynth.instance.playWinFanfare();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎁 Rương Mốc $level: +${reward.coins} Xu & +${reward.gems} Ngọc!'),
              backgroundColor: const Color(0xFF2D8512),
            ),
          );
        }
      },
      child: Container(
        width: 58,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: claimed
              ? const Color(0xFF263238)
              : (unlocked ? const Color(0xFFFF9D42) : const Color(0xFF3E2723)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: unlocked && !claimed ? const Color(0xFFFFD84D) : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(claimed ? '✅' : '🎁', style: const TextStyle(fontSize: 18)),
            Text(
              'Mốc $level',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _SagaPathPainter extends CustomPainter {
  final double startX;
  final double endX;
  final double height;
  final bool isUnlocked;

  const _SagaPathPainter({
    required this.startX,
    required this.endX,
    required this.height,
    required this.isUnlocked,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..moveTo(startX, 34)
      ..cubicTo(
        startX,
        height * 0.65,
        endX,
        height * 0.65,
        endX,
        height + 34,
      );

    // Đường nền đất rộng
    canvas.drawPath(
      path,
      Paint()
        ..color = isUnlocked ? const Color(0xFF9E633A) : const Color(0xFF37474F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    // Đường chỉ vàng bên trong
    canvas.drawPath(
      path,
      Paint()
        ..color = isUnlocked ? const Color(0xFFFFD84D).withValues(alpha: 0.75) : Colors.white24
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SagaPathPainter oldDelegate) =>
      oldDelegate.startX != startX || oldDelegate.endX != endX || oldDelegate.isUnlocked != isUnlocked;
}

