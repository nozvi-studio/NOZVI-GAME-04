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
/// Tab 1: Bản Đồ Hành Trình 200 Màn (Mặc định)
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
  int _selectedTabIndex = 1; // Mặc định mở Bản Đồ Hành Trình 200 Màn
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
              'Đăng nhập để đồng bộ Xu, Skin và tiến độ 200 màn chơi lên Đám mây (High-Watermark Merge).',
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
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white12, width: 1)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedTabIndex,
          onTap: (index) => setState(() => _selectedTabIndex = index),
          backgroundColor: const Color(0xFF1E282D),
          selectedItemColor: const Color(0xFFFFD84D),
          unselectedItemColor: Colors.white54,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.store_rounded),
              label: 'Cửa Hàng',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Bản Đồ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pets_rounded),
              label: 'Đảo Thú',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_rounded),
              label: 'Đua Top',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      color: const Color(0xFF263238),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showLoginDialog,
            child: const CircleAvatar(
              backgroundColor: Color(0xFFE84538),
              radius: 15,
              child: Text('🐶', style: TextStyle(fontSize: 15)),
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  Text(
                    _isGuest ? 'Chạm để đồng bộ' : 'Cloud Synced',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isGuest ? Colors.white54 : const Color(0xFF81E659),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Ví Xu Vàng & Ngọc
          ListenableBuilder(
            listenable: PlayerEconomyService.instance,
            builder: (context, _) {
              final eco = PlayerEconomyService.instance;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildWalletPill('🪙', '${eco.coins}', const Color(0xFFFFD84D)),
                  const SizedBox(width: 5),
                  _buildWalletPill('💎', '${eco.gems}', const Color(0xFF4FC3F7)),
                ],
              );
            },
          ),
          const SizedBox(width: 5),
          // Huy hiệu Super Bus Streak
          ListenableBuilder(
            listenable: WinStreakManager.instance,
            builder: (context, _) {
              final streak = WinStreakManager.instance;
              return InkWell(
                onTap: _showStreakInfoDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: streak.streakCount > 0 ? const Color(0xFFE86F17).withValues(alpha: 0.3) : Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: streak.streakCount > 0 ? const Color(0xFFFFD84D) : Colors.white24,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 2),
                      Text(
                        '${streak.streakCount}',
                        style: TextStyle(
                          color: streak.streakCount > 0 ? const Color(0xFFFFD84D) : Colors.white54,
                          fontWeight: FontWeight.bold,
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

  Widget _buildWalletPill(String emoji, String text, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11.5)),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(color: accent, fontWeight: FontWeight.w900, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
