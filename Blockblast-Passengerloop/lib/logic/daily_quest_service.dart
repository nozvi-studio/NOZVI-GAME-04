import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';
import '../core/game_event_bus.dart';
import 'player_economy_service.dart';

class DailyQuestItem {
  final String id;
  final String title;
  final String emoji;
  final int target;
  int progress;
  final int rewardCoins;
  final int rewardGems;
  bool isClaimed;

  DailyQuestItem({
    required this.id,
    required this.title,
    required this.emoji,
    required this.target,
    this.progress = 0,
    required this.rewardCoins,
    required this.rewardGems,
    this.isClaimed = false,
  });

  bool get isCompleted => progress >= target;
}

/// Dịch vụ quản lý 3 Nhiệm vụ Hàng ngày (Daily Quests) theo thời gian thực
class DailyQuestService extends ChangeNotifier {
  static final DailyQuestService instance = DailyQuestService._internal();
  DailyQuestService._internal();

  static const String _prefDateKey = 'daily_quest_date';

  final List<DailyQuestItem> _quests = [
    DailyQuestItem(
      id: 'corgi_buses',
      title: 'Đón 10 xe Corgi Đỏ',
      emoji: '🐶',
      target: 10,
      rewardCoins: 200,
      rewardGems: 10,
    ),
    DailyQuestItem(
      id: 'combo_x4',
      title: 'Đạt Combo x4!',
      emoji: '⚡',
      target: 1,
      rewardCoins: 250,
      rewardGems: 15,
    ),
    DailyQuestItem(
      id: 'ice_cleared',
      title: 'Phá 15 ô Băng Giá',
      emoji: '❄️',
      target: 15,
      rewardCoins: 300,
      rewardGems: 20,
    ),
  ];

  bool _isInitialized = false;
  StreamSubscription<GameEvent>? _sub;

  List<DailyQuestItem> get quests => List.unmodifiable(_quests);

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> init() async {
    if (_isInitialized) return;
    _sub?.cancel();
    _sub = GameEventBus.instance.stream.listen(_onGameEvent);

    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _todayKey();
      final savedDate = prefs.getString(_prefDateKey);

      if (savedDate != today) {
        await prefs.setString(_prefDateKey, today);
        for (final q in _quests) {
          q.progress = 0;
          q.isClaimed = false;
          await prefs.setInt('quest_prog_${q.id}', 0);
          await prefs.setBool('quest_claim_${q.id}', false);
        }
      } else {
        for (final q in _quests) {
          q.progress = (prefs.getInt('quest_prog_${q.id}') ?? 0).clamp(0, q.target);
          q.isClaimed = prefs.getBool('quest_claim_${q.id}') ?? false;
        }
      }
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('DailyQuestService init error: $e');
    }
  }

  void _onGameEvent(GameEvent event) {
    if (event is BusDispatchedEvent) {
      if (event.bus.color == PetColor.red || event.bus.isRainbow) {
        incrementQuest('corgi_buses', 1);
      }
    } else if (event is LinesClearedEvent) {
      if (event.comboMultiplier >= 4) {
        incrementQuest('combo_x4', 1);
      }
    } else if (event is HazardUpdatedEvent) {
      if (event.hazard == HazardType.ice && event.details == 0) {
        incrementQuest('ice_cleared', 1);
      }
    }
  }

  Future<void> incrementQuest(String questId, int amount) async {
    final idx = _quests.indexWhere((q) => q.id == questId);
    if (idx < 0 || amount <= 0) return;

    final quest = _quests[idx];
    if (quest.progress >= quest.target) return;
    quest.progress = math.min(quest.target, quest.progress + amount);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quest_prog_${quest.id}', quest.progress);
    } catch (_) {}
  }

  Future<bool> claimQuest(String questId) async {
    final idx = _quests.indexWhere((q) => q.id == questId);
    if (idx < 0) return false;

    final quest = _quests[idx];
    if (!quest.isCompleted || quest.isClaimed) return false;

    quest.isClaimed = true;
    notifyListeners();

    await PlayerEconomyService.instance.addRewards(
      coinsDelta: quest.rewardCoins,
      gemsDelta: quest.rewardGems,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('quest_claim_${quest.id}', true);
    } catch (_) {}

    return true;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

