import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RacerInfo {
  final String id;
  final String name;
  final String emoji;
  final bool isPlayer;
  int busesDispatched;

  RacerInfo({
    required this.id,
    required this.name,
    required this.emoji,
    required this.isPlayer,
    this.busesDispatched = 0,
  });
}

/// Dịch vụ quản lý sự kiện "Cuộc Đua Giờ Cao Điểm" (Bus Rush Race - Đua 15 Xe Buýt)
class BusRushRaceService extends ChangeNotifier {
  static final BusRushRaceService instance = BusRushRaceService._internal();

  static const String _prefPlayerBusesKey = 'bus_rush_player_buses';
  static const String _prefBotBusesPrefix = 'bus_rush_bot_';
  static const String _prefChestClaimedKey = 'bus_rush_chest_claimed';
  static const int kTargetBuses = 15;

  BusRushRaceService._internal();

  int _playerBuses = 0;
  bool _chestClaimed = false;
  bool _isLoaded = false;

  final List<RacerInfo> _racers = [
    RacerInfo(id: 'player', name: 'Bạn (Cơ Thủ)', emoji: '👑', isPlayer: true),
    RacerInfo(id: 'bot_corgi', name: 'Corgi Tia Chớp', emoji: '🐶', isPlayer: false),
    RacerInfo(id: 'bot_cat', name: 'Mèo Ninja', emoji: '🐱', isPlayer: false),
    RacerInfo(id: 'bot_rabbit', name: 'Thỏ Tên Lửa', emoji: '🐰', isPlayer: false),
    RacerInfo(id: 'bot_fox', name: 'Cáo Thần Tốc', emoji: '🦊', isPlayer: false),
  ];

  int get playerBuses => _playerBuses;
  int get targetBuses => kTargetBuses;
  bool get isChestClaimed => _chestClaimed;
  bool get isLoaded => _isLoaded;

  bool get isFinished => _racers.any((r) => r.busesDispatched >= kTargetBuses);
  bool get isPlayerWinner => _playerBuses >= kTargetBuses && getPlayerRank() == 1;

  List<RacerInfo> get sortedRacers {
    final list = List<RacerInfo>.from(_racers);
    list.sort((a, b) => b.busesDispatched.compareTo(a.busesDispatched));
    return list;
  }

  int getPlayerRank() {
    final sorted = sortedRacers;
    final idx = sorted.indexWhere((r) => r.isPlayer);
    return idx >= 0 ? idx + 1 : 1;
  }

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _playerBuses = prefs.getInt(_prefPlayerBusesKey) ?? 0;
      _chestClaimed = prefs.getBool(_prefChestClaimedKey) ?? false;

      final rng = math.Random();
      for (final racer in _racers) {
        if (racer.isPlayer) {
          racer.busesDispatched = _playerBuses;
        } else {
          racer.busesDispatched = prefs.getInt('$_prefBotBusesPrefix${racer.id}') ?? (rng.nextInt(3));
        }
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('BusRushRaceService init error: $e');
    }
  }

  /// Ghi nhận khi người chơi xuất bến thành công các chuyến xe buýt
  Future<void> recordPlayerBuses(int count) async {
    if (count <= 0) return;
    _playerBuses = math.min(kTargetBuses, _playerBuses + count);
    _racers.firstWhere((r) => r.isPlayer).busesDispatched = _playerBuses;

    // Các Bot tự động tiến bước thích ứng (mỗi ván cộng 1-2 xe ngẫu nhiên)
    final rng = math.Random();
    for (final racer in _racers) {
      if (!racer.isPlayer && racer.busesDispatched < kTargetBuses) {
        final botAdvance = rng.nextInt(2) + 1;
        racer.busesDispatched = math.min(kTargetBuses, racer.busesDispatched + botAdvance);
      }
    }

    notifyListeners();
    await _save();
  }

  /// Nhận thưởng Rương Cổ Vật khi về Nhất
  Future<bool> claimRewardChest() async {
    if (_chestClaimed || !isPlayerWinner) return false;
    _chestClaimed = true;
    notifyListeners();
    await _save();
    return true;
  }

  /// Bắt đầu một mùa giải đua mới
  Future<void> resetNewSeason() async {
    _playerBuses = 0;
    _chestClaimed = false;
    final rng = math.Random();
    for (final racer in _racers) {
      racer.busesDispatched = racer.isPlayer ? 0 : rng.nextInt(2);
    }
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefPlayerBusesKey, _playerBuses);
      await prefs.setBool(_prefChestClaimedKey, _chestClaimed);
      for (final racer in _racers) {
        if (!racer.isPlayer) {
          await prefs.setInt('$_prefBotBusesPrefix${racer.id}', racer.busesDispatched);
        }
      }
    } catch (e) {
      debugPrint('BusRushRaceService save error: $e');
    }
  }
}

