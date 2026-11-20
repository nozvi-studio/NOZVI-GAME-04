import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../logic/player_economy_service.dart';
import '../../core/pentatonic_audio_synth.dart';

<<<<<<< HEAD
/// Tab 2 - Bản Đồ Hành Trình 500 Màn (Saga World Map) uốn lượn qua 11 Chương
=======
/// Màn hình 2: BẢN ĐỒ (Saga Map)
/// Tái tạo chuẩn xác 100% theo Mockup:
/// 1. Bầu trời xanh mây trắng cùng khinh khí cầu bay lơ lửng
/// 2. Chuỗi đảo bay 2.5D Diorama: Sunny Park, Frozen Station, Vine Jungle & Lâu đài Vua Cánh Cụt
/// 3. Đường uốn lượn kèm rương mốc quà tặng & sao 1-3 sao
/// 4. Thanh đáy nổi gồm nút level, Nút Vàng "PLAY" 3D to bản & Nút Cài đặt
>>>>>>> 9c029f433040f9f1582aba761103e9d6623e2aeb
class SagaMapScreen extends StatefulWidget {
  final Function(int level) onSelectLevel;

  const SagaMapScreen({
    super.key,
    required this.onSelectLevel,
  });

  @override
  State<SagaMapScreen> createState() => _SagaMapScreenState();
}

class _SagaMapScreenState extends State<SagaMapScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _floatAnimController;

  @override
  void initState() {
    super.initState();
    _floatAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Tự động cuộn đến màn hiện tại khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentLevel();
    });
  }

<<<<<<< HEAD
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

=======
  void _scrollToCurrentLevel() {
    final economy = PlayerEconomyService.instance;
    final int current = economy.unlockedLevel;
>>>>>>> 9c029f433040f9f1582aba761103e9d6623e2aeb
    if (_scrollController.hasClients) {
      // Mỗi đảo chiếm khoảng 260px chiều cao
      final int islandIndex = _islandIndexForLevel(current);
      final double targetOffset = (4 - islandIndex) * 260.0;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  int _islandIndexForLevel(int level) {
    if (level <= 30) return 0; // Sunny Park
    if (level <= 80) return 1; // Frozen Station
    if (level <= 130) return 2; // Vine Jungle
    if (level <= 170) return 3; // Toy City
    return 4; // Penguin Castle
  }

<<<<<<< HEAD
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
=======
  @override
  void dispose() {
    _floatAnimController.dispose();
    _scrollController.dispose();
    super.dispose();
>>>>>>> 9c029f433040f9f1582aba761103e9d6623e2aeb
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PlayerEconomyService.instance,
      builder: (context, _) {
        final economy = PlayerEconomyService.instance;

<<<<<<< HEAD
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
=======
        return Scaffold(
          backgroundColor: const Color(0xFF64B5F6), // Xanh da trời sáng chuẩn diorama
          body: Stack(
            children: [
              // 1. Nền bầu trời 2.5D: Mây trôi bồng bềnh & Khinh khí cầu
              Positioned.fill(
                child: CustomPaint(
                  painter: _SkyBackgroundPainter(floatProgress: _floatAnimController.value),
                ),
              ),

              // 2. Danh sách cuộn các Đảo bay Diorama 2.5D từ dưới lên trên
              Positioned.fill(
                child: ListView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(12, 60, 12, 110),
                  children: [
                    // Đảo Đỉnh: Lâu Đài Vua Cánh Cụt (Chương 5: 171 - 200)
                    _buildDioramaIsland(
                      context: context,
                      economy: economy,
                      islandType: _IslandType.penguinCastle,
                      title: 'Penguin Castle',
                      levelRange: '171 - 200',
                      milestoneLevel: 200,
                      isTopPeak: true,
>>>>>>> 9c029f433040f9f1582aba761103e9d6623e2aeb
                    ),
                    const SizedBox(height: 18),

                    // Đảo 4: Xứ Sở Băng Giá - Frozen Station (Chương 2: 31 - 80)
                    _buildDioramaIsland(
                      context: context,
                      economy: economy,
                      islandType: _IslandType.frozenStation,
                      title: 'Frozen Station',
                      levelRange: '31 - 80',
                      milestoneLevel: 50,
                      isTopPeak: false,
                    ),
                    const SizedBox(height: 18),

                    // Đảo 3: Rừng Dây Leo - Vine Jungle (Chương 3: 81 - 130)
                    _buildDioramaIsland(
                      context: context,
                      economy: economy,
                      islandType: _IslandType.vineJungle,
                      title: 'Vine Jungle',
                      levelRange: '81 - 130',
                      milestoneLevel: 100,
                      isTopPeak: false,
                    ),
                    const SizedBox(height: 18),

                    // Đảo 1: Công Viên Nắng Ấm - Sunny Park (Chương 1: 1 - 30)
                    _buildDioramaIsland(
                      context: context,
                      economy: economy,
                      islandType: _IslandType.sunnyPark,
                      title: 'Sunny Park',
                      levelRange: '1 - 30',
                      milestoneLevel: 25,
                      isTopPeak: false,
                    ),
                  ],
                ),
              ),

<<<<<<< HEAD
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
=======
              // 3. Header Treo: "2. BẢN ĐỒ (Saga Map)" & 3 Sao Vàng
              Positioned(
                top: 8,
                left: 12,
                right: 12,
                child: _buildHeaderBanner(),
>>>>>>> 9c029f433040f9f1582aba761103e9d6623e2aeb
              ),

              // 4. Thanh đáy nổi: Level Pill, Nút PLAY Vàng 3D To Bản & Nút Cài Đặt
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: _buildBottomPlayDock(context, economy),
              ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // HEADER BANNER BẢN ĐỒ
  // ==========================================
  Widget _buildHeaderBanner() {
    return Column(
      children: [
        // 3 Sao vàng lấp lánh trên đỉnh
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 18),
            SizedBox(width: 2),
            Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 24),
            SizedBox(width: 2),
            Icon(Icons.star_rounded, color: Color(0xFFFFD54F), size: 18),
          ],
        ),
        const SizedBox(height: 2),

        // Chữ "2. BẢN ĐỒ (Saga Map)" nổi bật
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white30, width: 1.2),
          ),
          child: const Text(
            '2. BẢN ĐỒ (Saga Map)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 0.5,
              shadows: [
                Shadow(color: Color(0xFF0D47A1), offset: Offset(0, 2), blurRadius: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ĐẢO BAY DIORAMA 2.5D
  // ==========================================
  Widget _buildDioramaIsland({
    required BuildContext context,
    required PlayerEconomyService economy,
    required _IslandType islandType,
    required String title,
    required String levelRange,
    required int milestoneLevel,
    required bool isTopPeak,
  }) {
    final bool isMilestoneUnlocked = economy.isMilestoneUnlocked(milestoneLevel);
    final bool isMilestoneClaimed = economy.isMilestoneClaimed(milestoneLevel);

    return Container(
      width: double.infinity,
      height: isTopPeak ? 310 : 255,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x35000000), offset: Offset(0, 8), blurRadius: 10),
        ],
      ),
      child: Stack(
        children: [
          // Khối đảo bay vẽ bằng Vector CustomPainter
          Positioned.fill(
            child: CustomPaint(
              painter: _IslandDioramaPainter(
                islandType: islandType,
                floatPhase: _floatAnimController.value,
              ),
            ),
          ),

          // Biển tên đảo bằng gỗ
          Positioned(
            bottom: 22,
            left: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDE9F67), Color(0xFFA66436)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF542E13), width: 1.8),
                boxShadow: const [
                  BoxShadow(color: Color(0x50000000), offset: Offset(0, 2), blurRadius: 3),
                ],
              ),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFF9E6),
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  shadows: [Shadow(color: Color(0xFF4A250B), offset: Offset(0, 1), blurRadius: 1)],
                ),
              ),
            ),
          ),

          // Rương báu vật mốc trên đảo
          Positioned(
            right: 28,
            bottom: 24,
            child: GestureDetector(
              onTap: () async {
                if (!isMilestoneUnlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Vượt qua Màn $milestoneLevel để mở Rương Quà!')),
                  );
                  return;
                }
                if (isMilestoneClaimed) return;
                final reward = await economy.claimMilestoneChest(milestoneLevel);
                if (reward != null && context.mounted) {
                  PentatonicAudioSynth.instance.playWinFanfare();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎁 Rương Mốc $milestoneLevel: +${reward.coins} Xu & +${reward.gems} Ngọc!'),
                      backgroundColor: const Color(0xFF2D8512),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isMilestoneClaimed
                        ? [const Color(0xFF546E7A), const Color(0xFF37474F)]
                        : (isMilestoneUnlocked
                            ? [const Color(0xFFFFD54F), const Color(0xFFFF8F00)]
                            : [const Color(0xFF8D6E63), const Color(0xFF4E342E)]),
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x40000000), offset: Offset(0, 3), blurRadius: 4),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isMilestoneClaimed ? '✅' : '🎁', style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      'Mốc $milestoneLevel',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Nếu là Lâu đài Đỉnh thì có nút cờ "Play" dẫn vào trận
          if (isTopPeak)
            Positioned(
              right: 36,
              top: 130,
              child: GestureDetector(
                onTap: () => widget.onSelectLevel(economy.unlockedLevel),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4FC3F7), Color(0xFF0288D1)]),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Color(0x50000000), offset: Offset(0, 3), blurRadius: 4),
                    ],
                  ),
                  child: const Text(
                    'Play',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // THANH ĐÁY NỔI: PLAY DOCK
  // ==========================================
  Widget _buildBottomPlayDock(BuildContext context, PlayerEconomyService economy) {
    return Row(
      children: [
        // Nút tròn Level góc trái
        GestureDetector(
          onTap: () => widget.onSelectLevel(economy.unlockedLevel),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB74D), Color(0xFFF57C00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: const [
                BoxShadow(color: Color(0x50000000), offset: Offset(0, 4), blurRadius: 5),
              ],
            ),
            child: Stack(
              children: [
                const Center(
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                ),
                Positioned(
                  bottom: 2,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Lv.${economy.unlockedLevel}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // NÚT CHÍNH: NÚT VÀNG "PLAY" 3D CỰC ĐẠI
        Expanded(
          child: GestureDetector(
            onTap: () {
              PentatonicAudioSynth.instance.playPopSound(1.2);
              widget.onSelectLevel(economy.unlockedLevel);
            },
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFFF176), // Vàng sáng rực rỡ đỉnh
                    Color(0xFFFFD54F),
                    Color(0xFFFF8F00), // Vàng đậm đáy 3D
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x60000000), offset: Offset(0, 6), blurRadius: 6),
                ],
              ),
              child: const Center(
                child: Text(
                  'PLAY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(color: Color(0xFFC45A00), offset: Offset(0, 2.5), blurRadius: 3),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Nút Bánh răng Cài đặt góc phải
        GestureDetector(
          onTap: () => _showSettingsDialog(context, economy),
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF90CAF9), Color(0xFF1E88E5)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: const [
                BoxShadow(color: Color(0x50000000), offset: Offset(0, 4), blurRadius: 5),
              ],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.settings_rounded, color: Colors.white, size: 22),
                Text(
                  'Cài đặt',
                  style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog(BuildContext context, PlayerEconomyService economy) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF263238),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('CÀI ĐẶT BẢN ĐỒ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Âm nhạc nền (BGM)', style: TextStyle(color: Colors.white, fontSize: 13)),
              value: economy.bgmEnabled,
              activeColor: const Color(0xFFFFD84D),
              onChanged: (val) => economy.setBgmEnabled(val),
            ),
            SwitchListTile(
              title: const Text('Hiệu ứng âm thanh (SFX)', style: TextStyle(color: Colors.white, fontSize: 13)),
              value: economy.sfxEnabled,
              activeColor: const Color(0xFFFFD84D),
              onChanged: (val) => economy.setSfxEnabled(val),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD84D), foregroundColor: Colors.black87),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐÓNG'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// VẼ DIORAMA VÀ CÁC ĐẢO BAY 2.5D
// ==========================================

enum _IslandType { sunnyPark, frozenStation, vineJungle, penguinCastle }

/// Nền trời mây và khinh khí cầu
class _SkyBackgroundPainter extends CustomPainter {
  final double floatProgress;
  _SkyBackgroundPainter({required this.floatProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient nền trời
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5BA7F5), Color(0xFF90CAF9), Color(0xFFBBDEFB)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Mây trắng bồng bềnh
    _drawCloud(canvas, Offset(size.width * 0.15, size.height * 0.12), 48);
    _drawCloud(canvas, Offset(size.width * 0.82, size.height * 0.28), 60);
    _drawCloud(canvas, Offset(size.width * 0.22, size.height * 0.52), 52);
    _drawCloud(canvas, Offset(size.width * 0.88, size.height * 0.75), 44);

    // Khinh khí cầu sọc màu pastel
    final double balloonBob = math.sin(floatProgress * 2 * math.pi) * 6;
    _drawHotAirBalloon(canvas, Offset(size.width * 0.16, size.height * 0.25 + balloonBob));
    _drawHotAirBalloon(canvas, Offset(size.width * 0.84, size.height * 0.45 - balloonBob));
  }

  void _drawCloud(Canvas canvas, Offset p, double radius) {
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.55);
    canvas.drawCircle(p, radius, cloudPaint);
    canvas.drawCircle(p.translate(-radius * 0.45, radius * 0.15), radius * 0.65, cloudPaint);
    canvas.drawCircle(p.translate(radius * 0.45, radius * 0.15), radius * 0.65, cloudPaint);
  }

  void _drawHotAirBalloon(Canvas canvas, Offset p) {
    // Quả cầu khí cầu
    canvas.drawOval(
      Rect.fromCenter(center: p, width: 28, height: 36),
      Paint()..color = const Color(0xFFFF8A80),
    );
    // Sọc vàng
    canvas.drawOval(
      Rect.fromCenter(center: p, width: 14, height: 36),
      Paint()..color = const Color(0xFFFFD54F),
    );
    // Giỏ mây
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(0, 24), width: 10, height: 8), const Radius.circular(2)),
      Paint()..color = const Color(0xFF8D6E63),
    );
    // Dây nối
    canvas.drawLine(p.translate(-4, 18), p.translate(-3, 22), Paint()..color = Colors.black45);
    canvas.drawLine(p.translate(4, 18), p.translate(3, 22), Paint()..color = Colors.black45);
  }

  @override
  bool shouldRepaint(covariant _SkyBackgroundPainter oldDelegate) => true;
}

/// Dựng từng Đảo Bay Diorama 2.5D
class _IslandDioramaPainter extends CustomPainter {
  final _IslandType islandType;
  final double floatPhase;

  _IslandDioramaPainter({required this.islandType, required this.floatPhase});

  @override
  void paint(Canvas canvas, Size size) {
    final double bob = math.sin(floatPhase * 2 * math.pi) * 3;
    canvas.save();
    canvas.translate(0, bob);

    switch (islandType) {
      case _IslandType.sunnyPark:
        _drawSunnyPark(canvas, size);
        break;
      case _IslandType.frozenStation:
        _drawFrozenStation(canvas, size);
        break;
      case _IslandType.vineJungle:
        _drawVineJungle(canvas, size);
        break;
      case _IslandType.penguinCastle:
        _drawPenguinCastle(canvas, size);
        break;
    }

    canvas.restore();
  }

  void _drawSunnyPark(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Chân vách đá nón ngược 3D
    final cliff = Path()
      ..moveTo(w * 0.08, h * 0.52)
      ..lineTo(w * 0.50, h * 0.95)
      ..lineTo(w * 0.92, h * 0.52)
      ..close();
    canvas.drawPath(
      cliff,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8D6E63), Color(0xFF4E342E)],
        ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5)),
    );

    // Bề mặt thảm cỏ xanh tươi (Sunny Plateau)
    final plateau = Path()
      ..moveTo(w * 0.05, h * 0.52)
      ..quadraticBezierTo(w * 0.50, h * 0.38, w * 0.95, h * 0.52)
      ..quadraticBezierTo(w * 0.50, h * 0.64, w * 0.05, h * 0.52);
    canvas.drawPath(
      plateau,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF81C784), Color(0xFF388E3C)],
        ).createShader(Rect.fromLTWH(0, h * 0.35, w, h * 0.3)),
    );

    // Cây xanh công viên & ghế nghỉ
    _drawLushTree(canvas, Offset(w * 0.22, h * 0.44));
    _drawLushTree(canvas, Offset(w * 0.78, h * 0.44));
    _drawLushTree(canvas, Offset(w * 0.84, h * 0.48));

    // Thú cưng nằm phơi nắng
    canvas.drawCircle(Offset(w * 0.42, h * 0.50), 6, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(Offset(w * 0.56, h * 0.50), 6, Paint()..color = const Color(0xFFFF8A65));
  }

  void _drawFrozenStation(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Vách đá băng xanh lơ
    final cliff = Path()
      ..moveTo(w * 0.08, h * 0.52)
      ..lineTo(w * 0.50, h * 0.95)
      ..lineTo(w * 0.92, h * 0.52)
      ..close();
    canvas.drawPath(
      cliff,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4FC3F7), Color(0xFF0277BD)],
        ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5)),
    );

    // Bề mặt tuyết trắng xanh (Snow plateau)
    final snow = Path()
      ..moveTo(w * 0.05, h * 0.52)
      ..quadraticBezierTo(w * 0.50, h * 0.38, w * 0.95, h * 0.52)
      ..quadraticBezierTo(w * 0.50, h * 0.64, w * 0.05, h * 0.52);
    canvas.drawPath(
      snow,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
        ).createShader(Rect.fromLTWH(0, h * 0.35, w, h * 0.3)),
    );

    // Tinh thể pha lê băng khổng lồ nhô lên sáng rực
    _drawIceCrystal(canvas, Offset(w * 0.28, h * 0.42), 34);
    _drawIceCrystal(canvas, Offset(w * 0.38, h * 0.46), 26);
    _drawIceCrystal(canvas, Offset(w * 0.74, h * 0.44), 30);
  }

  void _drawVineJungle(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Vách đá rêu phong sẫm màu
    final cliff = Path()
      ..moveTo(w * 0.08, h * 0.52)
      ..lineTo(w * 0.50, h * 0.95)
      ..lineTo(w * 0.92, h * 0.52)
      ..close();
    canvas.drawPath(
      cliff,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF558B2F), Color(0xFF2E7D32)],
        ).createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5)),
    );

    // Bề mặt rừng nhiệt đới
    final plateau = Path()
      ..moveTo(w * 0.05, h * 0.52)
      ..quadraticBezierTo(w * 0.50, h * 0.38, w * 0.95, h * 0.52)
      ..quadraticBezierTo(w * 0.50, h * 0.64, w * 0.05, h * 0.52);
    canvas.drawPath(plateau, Paint()..color = const Color(0xFF689F38));

    // Dây leo buông thõng xuống vách
    final vinePaint = Paint()
      ..color = const Color(0xFF33691E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.24, h * 0.54), Offset(w * 0.26, h * 0.78), vinePaint);
    canvas.drawLine(Offset(w * 0.72, h * 0.54), Offset(w * 0.70, h * 0.75), vinePaint);

    // Cây cổ thụ
    _drawLushTree(canvas, Offset(w * 0.20, h * 0.42));
    _drawLushTree(canvas, Offset(w * 0.80, h * 0.42));
  }

  void _drawPenguinCastle(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Núi tuyết đỉnh cao
    final mountain = Path()
      ..moveTo(w * 0.06, h * 0.88)
      ..lineTo(w * 0.50, h * 0.22)
      ..lineTo(w * 0.94, h * 0.88)
      ..close();
    canvas.drawPath(
      mountain,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFB3E5FC), Color(0xFF0288D1)],
        ).createShader(Rect.fromLTWH(0, h * 0.2, w, h * 0.7)),
    );

    // Lâu đài đá băng kỳ vĩ (Castle)
    final castleRect = Rect.fromCenter(center: Offset(w * 0.50, h * 0.48), width: 110, height: 80);
    canvas.drawRRect(
      RRect.fromRectAndRadius(castleRect, const Radius.circular(10)),
      Paint()..color = const Color(0xFFE1F5FE),
    );

    // 2 Tháp canh hai bên chóp nón xanh
    _drawTower(canvas, Offset(w * 0.35, h * 0.40));
    _drawTower(canvas, Offset(w * 0.65, h * 0.40));

    // Vua Cánh Cụt ngồi trên đỉnh tháp chính
    _drawPenguinKing(canvas, Offset(w * 0.50, h * 0.32));
  }

  void _drawTower(Canvas canvas, Offset p) {
    canvas.drawRect(Rect.fromCenter(center: p, width: 22, height: 44), Paint()..color = const Color(0xFFB3E5FC));
    final roof = Path()
      ..moveTo(p.dx - 14, p.dy - 22)
      ..lineTo(p.dx, p.dy - 40)
      ..lineTo(p.dx + 14, p.dy - 22)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF0288D1));
  }

  void _drawPenguinKing(Canvas canvas, Offset p) {
    // Thân cánh cụt đen
    canvas.drawOval(Rect.fromCenter(center: p, width: 22, height: 26), Paint()..color = const Color(0xFF263238));
    // Bụng trắng
    canvas.drawOval(Rect.fromCenter(center: p.translate(0, 3), width: 14, height: 18), Paint()..color = Colors.white);
    // Mỏ cam
    canvas.drawCircle(p.translate(0, -4), 3, Paint()..color = const Color(0xFFFF9800));
    // Mắt
    canvas.drawCircle(p.translate(-4, -6), 1.8, Paint()..color = Colors.black);
    canvas.drawCircle(p.translate(4, -6), 1.8, Paint()..color = Colors.black);
    // Vương miện vàng lấp lánh (Crown)
    final crown = Path()
      ..moveTo(p.dx - 8, p.dy - 12)
      ..lineTo(p.dx - 6, p.dy - 18)
      ..lineTo(p.dx - 2, p.dy - 14)
      ..lineTo(p.dx + 2, p.dy - 18)
      ..lineTo(p.dx + 6, p.dy - 14)
      ..lineTo(p.dx + 8, p.dy - 12)
      ..close();
    canvas.drawPath(crown, Paint()..color = const Color(0xFFFFD54F));
  }

  void _drawLushTree(Canvas canvas, Offset p) {
    // Thân cây gỗ
    canvas.drawRect(Rect.fromLTWH(p.dx - 3, p.dy, 6, 16), Paint()..color = const Color(0xFF795548));
    // Tán lá xanh tròn
    canvas.drawCircle(p.translate(0, -4), 14, Paint()..color = const Color(0xFF4CAF50));
    canvas.drawCircle(p.translate(-6, -2), 10, Paint()..color = const Color(0xFF66BB6A));
  }

  void _drawIceCrystal(Canvas canvas, Offset p, double h) {
    final Path crystal = Path()
      ..moveTo(p.dx, p.dy - h)
      ..lineTo(p.dx + 9, p.dy)
      ..lineTo(p.dx, p.dy + 8)
      ..lineTo(p.dx - 9, p.dy)
      ..close();
    canvas.drawPath(
      crystal,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE0F7FA), Color(0xFF00E5FF), Color(0xFF0091EA)],
        ).createShader(Rect.fromLTWH(p.dx - 10, p.dy - h, 20, h + 10)),
    );
  }

  @override
  bool shouldRepaint(covariant _IslandDioramaPainter oldDelegate) => true;
}
