import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Quản lý chuỗi thắng "Super Bus Streak" (Bậc 0 đến Bậc 3)
class WinStreakManager extends ChangeNotifier {
  static final WinStreakManager _instance = WinStreakManager._internal();
  static WinStreakManager get instance => _instance;

  WinStreakManager._internal();

  static const String _streakKey = 'super_bus_win_streak';

  int _streakCount = 0;
  bool _isInitialized = false;

  int get streakCount => _streakCount;
  bool get isInitialized => _isInitialized;

  /// Bậc chuỗi thắng từ 0 đến 3
  int get streakTier {
    if (_streakCount >= 3) return 3;
    if (_streakCount >= 2) return 2;
    if (_streakCount >= 1) return 1;
    return 0;
  }

  /// Quyền lợi Bậc 1+: Tặng sẵn 1 lượt La Bàn Gió khi vào màn
  int get startingCompassCharges => streakTier >= 1 ? 1 : 0;

  /// Quyền lợi Bậc 2+: Mở rộng ghế chờ Holding Dock từ 5 lên 6 ghế
  int get dockCapacity => streakTier >= 2 ? 6 : 5;

  /// Quyền lợi Bậc 3: Tặng sẵn 1 lượt Búa Rèn Lửa
  int get startingHammerCharges => streakTier >= 3 ? 1 : 0;

  /// Quyền lợi Bậc 3: Chiếc xe buýt đầu tiên trong màn hóa thành Rainbow Express
  bool get firstBusIsRainbow => streakTier >= 3;

  String get tierBadgeTitle {
    switch (streakTier) {
      case 3:
        return 'Super Bus Bậc 3 (Rainbow)';
      case 2:
        return 'Super Bus Bậc 2 (VIP)';
      case 1:
        return 'Super Bus Bậc 1 (Gió)';
      default:
        return 'Chưa có chuỗi';
    }
  }

  String get tierPerkSummary {
    switch (streakTier) {
      case 3:
        return '🌈 Xe Cầu Vồng + 🔨 1 Búa + 🧭 1 La Bàn + 💺 6 Ghế VIP';
      case 2:
        return '💺 6 Ghế Chờ VIP + 🧭 1 La Bàn Gió';
      case 1:
        return '🧭 1 La Bàn Gió xuất phát';
      default:
        return 'Thắng các màn liên tiếp để mở khóa Siêu Xe Buýt!';
    }
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _streakCount = prefs.getInt(_streakKey) ?? 0;
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('WinStreakManager init error: $e');
    }
  }

  Future<void> recordWin() async {
    _streakCount++;
    notifyListeners();
    await _save();
  }

  Future<void> resetStreak() async {
    if (_streakCount == 0) return;
    _streakCount = 0;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_streakKey, _streakCount);
    } catch (e) {
      debugPrint('WinStreakManager save error: $e');
    }
  }
}

