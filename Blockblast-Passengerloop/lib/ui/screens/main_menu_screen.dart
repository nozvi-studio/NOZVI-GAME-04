import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../logic/win_streak_manager.dart';
import '../../logic/bus_rush_race_service.dart';
import '../../logic/player_economy_service.dart';
import '../../logic/daily_quest_service.dart';
import '../widgets/bus_rush_hud_bar.dart';
import 'shop_screen.dart';
import 'saga_map_screen.dart';
import 'pet_sanctuary_screen.dart';
import 'bus_rush_quests_screen.dart';

/// Main Shell thương mại với Bottom Navigation 4 Tabs:
/// Tab 0: Cửa Hàng & Kho Skin
/// Tab 1: Bản Đồ Hành Trình 500 Màn (Mặc định)
/// Tab 2: Đảo Thú Cưng 2.5D
/// Tab 3: Đua Top Giờ Cao Điểm & 3 Nhiệm Vụ Hàng Ngày
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
  int _selectedTabIndex = 1; // Mặc định mở Bản Đồ Hành Trình 500 Màn
  String _username = 'Khách #3021';
  bool _isGuest = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await PlayerEconomyService.instance.init(forceReload: true);
    await WinStreakManager.instance.init();
    await BusRushRaceService.instance.init();
    await PetSanctuaryService.instance.init();
    await DailyQuestService.instance.init();

    if (mounted) {
      setState(() {
        _username = prefs.getString('user_name') ?? 'Khách #${1000 + math.Random().nextInt(8999)}';
        _isGuest = prefs.getBool('is_guest') ?? true;
      });
    }
  }

  Future<void> _saveUserIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', _username);
    await prefs.setBool('is_guest', _isGuest);
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
              'Đăng nhập để đồng bộ Xu, Skin và tiến độ 500 màn chơi lên Đám mây (High-Watermark Merge).',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Nhập tên người chơi',
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
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD84D), foregroundColor: Colors.black87),
            onPressed: () async {
              final name = usernameController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() {
                  _username = name;
                  _isGuest = false;
                });
                await _saveUserIdentity();
                await PlayerEconomyService.instance.addRewards(coinsDelta: 100, gemsDelta: 10);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã liên kết cho $name (+100 Xu, +10 Ngọc)!')),
                  );
                }
              }
            },
            child: const Text('ĐỒNG BỘ'),
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
            const Text('🔥', style: TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Text(
              'CHUỖI THẮNG: ${streak.streakCount}',
              style: const TextStyle(color: Color(0xFFFFD84D), fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bậc hiện tại: ${streak.tierBadgeTitle}',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
            const SizedBox(height: 4),
            Text(streak.tierPerkSummary, style: const TextStyle(color: Color(0xFF81E659), fontSize: 12)),
            const Divider(color: Colors.white24, height: 22),
            _buildTierRow('Bậc 1 (1 Trận)', '🧭 +1 La Bàn Gió xuất phát', streak.streakTier >= 1),
            _buildTierRow('Bậc 2 (2 Trận)', '💺 Mở rộng Ghế VIP thứ 6 ở Dock', streak.streakTier >= 2),
            _buildTierRow('Bậc 3 (3+ Trận)', '🌈 Rainbow Express + 🔨 1 Búa Rèn Lửa', streak.streakTier >= 3),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD84D), foregroundColor: Colors.black87),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ĐÃ HIỂU'),
          ),
        ],
      ),
    );
  }

  Widget _buildTierRow(String title, String desc, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isActive ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isActive ? const Color(0xFF81E659) : Colors.white30, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                Text(desc, style: TextStyle(color: isActive ? const Color(0xFFFFD84D) : Colors.white38, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return const ShopScreen();
      case 1:
        return Column(
          children: [
            const BusRushHudBar(),
            Expanded(
              child: SagaMapScreen(onSelectLevel: widget.onSelectLevel),
            ),
          ],
        );
      case 2:
        return PetSanctuaryScreen(
          onBack: () => setState(() => _selectedTabIndex = 1),
        );
      case 3:
      default:
        return const BusRushQuestsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1F23),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh Profile + Ví Xu Vàng & Ngọc + Chuỗi thắng trên đỉnh mọi tab (trừ tab Đảo có HUD riêng)
            if (_selectedTabIndex != 2) _buildTopBar(),
            Expanded(child: _buildCurrentTabContent()),
          ],
        ),
      ),
      bottomNavigationBar: _buildWoodenToyDock(),
    );
  }

  Widget _buildWoodenToyDock() {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDE9F67), Color(0xFFA66436), Color(0xFF6E3F1F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x60000000), offset: Offset(0, -3), blurRadius: 6),
        ],
        border: Border(top: BorderSide(color: Color(0xFF4A2610), width: 2.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Tab 0: Chơi ngay (Bus)
            _buildDockItem(
              iconEmoji: '🚌',
              label: 'Bus',
              isSelected: false,
              onTap: () => widget.onSelectLevel(PlayerEconomyService.instance.unlockedLevel),
            ),

            // Tab 1: Bản Đồ (Map)
            _buildDockItem(
              iconEmoji: '🗺️',
              label: 'Map',
              isSelected: _selectedTabIndex == 1,
              onTap: () => setState(() => _selectedTabIndex = 1),
            ),

            // Tab 2: Cửa Hàng (Shop & Corgi)
            _buildDockItem(
              iconEmoji: '🐶',
              label: 'Shop',
              isSelected: _selectedTabIndex == 0,
              isProminent: true,
              onTap: () => setState(() => _selectedTabIndex = 0),
            ),

            // Tab 3: Đảo Thú Cưng (Sanctuary)
            _buildDockItem(
              iconEmoji: '🏠',
              label: 'Sanctuary',
              isSelected: _selectedTabIndex == 2,
              onTap: () => setState(() => _selectedTabIndex = 2),
            ),

            // Tab 4: Đua Top / Quests
            _buildDockItem(
              iconEmoji: '🏆',
              label: 'Quests',
              isSelected: _selectedTabIndex == 3,
              onTap: () => setState(() => _selectedTabIndex = 3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDockItem({
    required String iconEmoji,
    required String label,
    required bool isSelected,
    bool isProminent = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 8, vertical: 4),
        decoration: isSelected
            ? BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Color(0x40000000), offset: Offset(0, 3), blurRadius: 4),
                ],
              )
            : (isProminent
                ? BoxDecoration(
                    color: const Color(0xFF8D5531),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF4A250B), width: 1.5),
                  )
                : null),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              iconEmoji,
              style: TextStyle(fontSize: isSelected ? 22 : 20),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF3B2314) : const Color(0xFFFFF7D6),
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                fontSize: 10,
                shadows: isSelected
                    ? null
                    : const [Shadow(color: Color(0xFF4A250B), offset: Offset(0, 1), blurRadius: 1)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFDE9F67), Color(0xFFA66436)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF542E13), width: 2)),
        boxShadow: [
          BoxShadow(color: Color(0x40000000), offset: Offset(0, 2), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showLoginDialog,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const CircleAvatar(
                backgroundColor: Color(0xFFE84538),
                radius: 14,
                child: Text('🐶', style: TextStyle(fontSize: 14)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: _showLoginDialog,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFF9E6),
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                      shadows: [Shadow(color: Color(0xFF4A250B), offset: Offset(0, 1), blurRadius: 1)],
                    ),
                  ),
                  Text(
                    _isGuest ? 'Chạm để đồng bộ' : 'Cloud Synced ✓',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isGuest ? const Color(0xFFFFF176) : const Color(0xFFB9F6CA),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Ví Xu Vàng & Ngọc dạng Viên Nhộng 3D chuẩn Mockup
          ListenableBuilder(
            listenable: PlayerEconomyService.instance,
            builder: (context, _) {
              final eco = PlayerEconomyService.instance;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildWalletPill('🪙', '${eco.coins}', const Color(0xFFFFD54F), const Color(0xFFFF8F00)),
                  const SizedBox(width: 5),
                  _buildWalletPill('💎', '${eco.gems}', const Color(0xFF81D4FA), const Color(0xFF0288D1)),
                ],
              );
            },
          ),
          const SizedBox(width: 5),
          // Huy hiệu Win Streak ngọn lửa
          ListenableBuilder(
            listenable: WinStreakManager.instance,
            builder: (context, _) {
              final streak = WinStreakManager.instance;
              return InkWell(
                onTap: _showStreakInfoDialog,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFE65100)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: const [
                      BoxShadow(color: Color(0x40000000), offset: Offset(0, 2), blurRadius: 3),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 2),
                      Text(
                        'x${streak.streakCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWalletPill(String emoji, String text, Color c1, Color c2) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [c1, c2], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white, width: 1.4),
        boxShadow: const [
          BoxShadow(color: Color(0x35000000), offset: Offset(0, 2), blurRadius: 2.5),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              shadows: [Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 1)],
            ),
          ),
        ],
      ),
    );
  }
}
