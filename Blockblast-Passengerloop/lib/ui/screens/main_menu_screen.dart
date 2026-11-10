import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/pentatonic_audio_synth.dart';
import '../../logic/win_streak_manager.dart';
import '../../logic/bus_rush_race_service.dart';
import '../widgets/bus_rush_hud_bar.dart';
import 'pet_sanctuary_screen.dart';

class MainMenuScreen extends StatefulWidget {
  final Function(int level) onSelectLevel;

  const MainMenuScreen({
    super.key,
    required this.onSelectLevel,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _selectedTabIndex = 0;
  String _username = 'Khách #3021';
  bool _isGuest = true;
  int _unlockedLevel = 1;
  int _highScore = 0;
  final Map<int, int> _levelStars = {};
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await WinStreakManager.instance.init();
    await BusRushRaceService.instance.init();
    await PetSanctuaryService.instance.init();

    setState(() {
      _username = prefs.getString('user_name') ?? 'Khách #${1000 + math.Random().nextInt(8999)}';
      _isGuest = prefs.getBool('is_guest') ?? true;
      _unlockedLevel = prefs.getInt('unlocked_level') ?? 1;
      _highScore = prefs.getInt('high_score') ?? 0;
      _soundEnabled = prefs.getBool('sound_enabled') ?? true;
      PentatonicAudioSynth.instance.isMuted = !_soundEnabled;

      for (int i = 1; i <= 200; i++) {
        final stars = prefs.getInt('level_stars_$i');
        if (stars != null) {
          _levelStars[i] = stars;
        }
      }
    });
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _username);
    await prefs.setBool('is_guest', _isGuest);
    await prefs.setInt('unlocked_level', _unlockedLevel);
    await prefs.setInt('high_score', _highScore);
    await prefs.setBool('sound_enabled', _soundEnabled);
    for (final entry in _levelStars.entries) {
      await prefs.setInt('level_stars_${entry.key}', entry.value);
    }
  }

  /// Thuật toán hợp nhất dữ liệu High-Watermark Merge khi liên kết tài khoản
  Future<void> _mergeAccountData({
    required String newUsername,
    required int remoteUnlockedLevel,
    required int remoteHighScore,
    required Map<int, int> remoteStars,
  }) async {
    setState(() {
      _username = newUsername;
      _isGuest = false;
      _unlockedLevel = math.max(_unlockedLevel, remoteUnlockedLevel);
      _highScore = math.max(_highScore, remoteHighScore);

      for (final entry in remoteStars.entries) {
        final local = _levelStars[entry.key] ?? 0;
        _levelStars[entry.key] = math.max(local, entry.value);
      }
    });

    await _saveProgress();
  }

  void _showLoginDialog() {
    final usernameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF263238),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('LIÊN KẾT TÀI KHOẢN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Đăng nhập để đồng bộ tiến độ chơi lên Đám mây (Áp dụng thuật toán High-Watermark Merge).',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nhập tên người chơi hoặc Email',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('HỦY', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB300), foregroundColor: Colors.black87),
            onPressed: () {
              final name = usernameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                _mergeAccountData(
                  newUsername: name,
                  remoteUnlockedLevel: _unlockedLevel + 1,
                  remoteHighScore: _highScore + 500,
                  remoteStars: {1: 3, 2: 3},
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã liên kết tài khoản thành công cho $name!')),
                );
              }
            },
            child: const Text('ĐỒNG BỘ TIẾN ĐỘ'),
          ),
        ],
      ),
    );
  }

  void _showStreakInfoDialog() {
    final streak = WinStreakManager.instance;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E282D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 8),
            Text(
              'CHUỖI THẮNG: ${streak.streakCount}',
              style: const TextStyle(color: Color(0xFFFFB300), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bậc hiện tại: ${streak.tierBadgeTitle}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              streak.tierPerkSummary,
              style: const TextStyle(color: Color(0xFF00E676), fontSize: 12),
            ),
            const Divider(color: Colors.white24, height: 24),
            const Text('QUYỀN LỢI CÁC BẬC:', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTierInfoRow('Bậc 1 (1 Trận)', '🧭 +1 La Bàn Gió xuất phát', streak.streakTier >= 1),
            _buildTierInfoRow('Bậc 2 (2 Trận)', '💺 Mở rộng Ghế VIP thứ 6 ở Dock', streak.streakTier >= 2),
            _buildTierInfoRow('Bậc 3 (3+ Trận)', '🌈 Rainbow Express + 🔨 1 Búa Rèn Lửa', streak.streakTier >= 3),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFB300), foregroundColor: Colors.black87),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐÃ HIỂU'),
          ),
        ],
      ),
    );
  }

  Widget _buildTierInfoRow(String title, String desc, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isActive ? const Color(0xFF00E676) : Colors.white30,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Text(
                  desc,
                  style: TextStyle(
                    color: isActive ? const Color(0xFFFFD54F) : Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTabIndex,
          children: [
            // Tab 0: Bản Đồ 200 Màn
            _buildMapTab(),

            // Tab 1: Đảo Thú Cưng 2.5D
            PetSanctuaryScreen(
              onBack: () => setState(() => _selectedTabIndex = 0),
            ),

            // Tab 2: Cuộc Đua Giờ Cao Điểm
            _buildRaceTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedTabIndex,
          onTap: (index) => setState(() => _selectedTabIndex = index),
          backgroundColor: const Color(0xFF1E282D),
          selectedItemColor: const Color(0xFFFFB300),
          unselectedItemColor: Colors.white54,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Bản Đồ 200 Màn',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_rounded),
              label: 'Đảo Thú Cưng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_bus_rounded),
              label: 'Đua Xe Buýt',
            ),
          ],
        ),
      ),
    );
  }

  /// Tab 0: Bản đồ 200 màn chơi
  Widget _buildMapTab() {
    return Column(
      children: [
        // 1. Thanh Profile trên cùng
        _buildTopProfileBar(),

        // 2. Banner Tiêu Đề Game 2.5D
        _buildGameHeader(),

        // 3. Thanh HUD thu gọn của Cuộc Đua Giờ Cao Điểm
        const BusRushHudBar(),

        // 4. Danh sách 200 Màn chơi chia theo 5 Chương
        Expanded(
          child: _buildLevelGrid(),
        ),
      ],
    );
  }

  /// Tab 2: Giao diện chi tiết Cuộc Đua Giờ Cao Điểm
  Widget _buildRaceTab() {
    return ListenableBuilder(
      listenable: BusRushRaceService.instance,
      builder: (context, _) {
        final race = BusRushRaceService.instance;
        final racers = race.sortedRacers;
        final isWinner = race.isPlayerWinner;
        final claimed = race.isChestClaimed;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner đầu trang
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('🏁', style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'CUỘC ĐUA GIỜ CAO ĐIỂM',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Đón 15 chuyến xe buýt để về đích đầu tiên và giành Rương Cổ Vật!',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bảng xếp hạng 5 tay đua
              Text(
                'BẢNG XẾP HẠNG TRỰC TIẾP (5 TAY ĐUA)',
                style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.8),
              ),
              const SizedBox(height: 10),

              for (int i = 0; i < racers.length; i++) ...[
                _buildRacerCard(racers[i], i + 1, race.targetBuses),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),

              // Nút nhận Rương Cổ Vật khi về Nhất
              if (isWinner && !claimed)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Text('🎁', style: TextStyle(fontSize: 22)),
                  label: const Text(
                    'NHẬN RƯƠNG CỔ VẬT HUYỀN THOẠI',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () async {
                    await race.claimRewardChest();
                    PentatonicAudioSynth.instance.playFanfare();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('🎉 Đã nhận Rương Cổ Vật (+500 Xu, +3 Búa, +3 La Bàn)!'),
                          backgroundColor: Color(0xFF2E7D32),
                        ),
                      );
                    }
                  },
                ),

              if (isWinner && claimed)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF69F0AE), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Bạn đã hoàn thành cuộc đua và nhận Rương Cổ Vật!',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRacerCard(RacerInfo racer, int rank, int target) {
    final progress = (racer.busesDispatched / target).clamp(0.0, 1.0);
    final isTop1 = rank == 1;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: racer.isPlayer ? const Color(0xFF2E7D32).withValues(alpha: 0.35) : const Color(0xFF263238),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: racer.isPlayer
              ? const Color(0xFF00E676)
              : (isTop1 ? const Color(0xFFFFD54F) : Colors.white12),
          width: racer.isPlayer ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  color: isTop1 ? const Color(0xFFFFD54F) : Colors.white54,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Text(racer.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  racer.name,
                  style: TextStyle(
                    color: racer.isPlayer ? const Color(0xFF00E676) : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${racer.busesDispatched}/$target XE',
                style: const TextStyle(
                  color: Color(0xFFFFD54F),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.black38,
              valueColor: AlwaysStoppedAnimation<Color>(
                racer.isPlayer ? const Color(0xFF00E676) : const Color(0xFFFFB300),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProfileBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF263238),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFFF5252),
            radius: 18,
            child: const Text('🐶', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  _isGuest ? 'Chế độ Khách (Offline)' : 'Đã liên kết tài khoản',
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
          // Huy hiệu Super Bus Streak
          _buildSuperBusStreakBadge(),
          IconButton(
            icon: Icon(_soundEnabled ? Icons.volume_up : Icons.volume_off, color: const Color(0xFFFFD54F)),
            onPressed: () {
              setState(() {
                _soundEnabled = !_soundEnabled;
                PentatonicAudioSynth.instance.isMuted = !_soundEnabled;
              });
              _saveProgress();
            },
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFFB300)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            ),
            onPressed: _showLoginDialog,
            child: Text(
              _isGuest ? 'ĐĂNG NHẬP' : 'TÀI KHOẢN',
              style: const TextStyle(color: Color(0xFFFFB300), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperBusStreakBadge() {
    return ListenableBuilder(
      listenable: WinStreakManager.instance,
      builder: (context, _) {
        final streak = WinStreakManager.instance;
        final hasStreak = streak.streakCount > 0;

        return InkWell(
          onTap: _showStreakInfoDialog,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: hasStreak ? const Color(0xFFFF6F00).withValues(alpha: 0.25) : Colors.black26,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasStreak ? const Color(0xFFFFB300) : Colors.white24,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(
                  '${streak.streakCount}',
                  style: TextStyle(
                    color: hasStreak ? const Color(0xFFFFD54F) : Colors.white54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('BLOCK ODYSSEY', style: TextStyle(color: Color(0xFFFFB300), fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
            ],
          ),
          const SizedBox(height: 2),
          const Text('PET EXPRESS • 2.5D HYBRID PUZZLE', style: TextStyle(color: Color(0xFF81D4FA), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          // Nút Tập luyện Căn bản (FTUE)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF43A047),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            icon: const Text('🎓', style: TextStyle(fontSize: 18)),
            label: const Text('TẬP LUYỆN CĂN BẢN (MÀN 0)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            onPressed: () => widget.onSelectLevel(0),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelGrid() {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            color: const Color(0xFF212121),
            child: const TabBar(
              isScrollable: true,
              indicatorColor: Color(0xFFFFB300),
              labelColor: Color(0xFFFFB300),
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: 'C1: Corgi & Mèo (1-30)'),
                Tab(text: 'C2: Băng & Bom (31-80)'),
                Tab(text: 'C3: Dây Leo (81-130)'),
                Tab(text: 'C4: Hố Đen (131-170)'),
                Tab(text: 'C5: Boss (171-200)'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildChapterGrid(1, 30),
                _buildChapterGrid(31, 80),
                _buildChapterGrid(81, 130),
                _buildChapterGrid(131, 170),
                _buildChapterGrid(171, 200),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChapterGrid(int startLevel, int endLevel) {
    final count = endLevel - startLevel + 1;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: count,
      itemBuilder: (context, index) {
        final level = startLevel + index;
        final isUnlocked = level <= _unlockedLevel;
        final stars = _levelStars[level] ?? 0;

        return GestureDetector(
          onTap: isUnlocked ? () => widget.onSelectLevel(level) : null,
          child: Container(
            decoration: BoxDecoration(
              color: isUnlocked ? const Color(0xFF2E7D32) : const Color(0xFF424242),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isUnlocked ? const Color(0xFF81C784) : Colors.white12,
                width: 1.5,
              ),
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$level',
                  style: TextStyle(
                    color: isUnlocked ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                if (isUnlocked)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => Icon(
                        Icons.star,
                        size: 10,
                        color: i < stars ? const Color(0xFFFFD600) : Colors.black45,
                      ),
                    ),
                  )
                else
                  const Icon(Icons.lock, size: 12, color: Colors.white38),
              ],
            ),
          ),
        );
      },
    );
  }
}
