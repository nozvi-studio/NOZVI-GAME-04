import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cue_model.dart';
import '../models/bot_stage_model.dart';
import '../models/daily_puzzle_model.dart';
import '../models/achievement_model.dart';
import '../models/tournament_model.dart';
import '../models/legendary_trickshot_model.dart';
import '../models/table_skin_model.dart';

class MatchRewardResult {
  final int earnedXP;
  final int earnedCoins;
  final bool didLevelUp;
  final int oldLevel;
  final int newLevel;
  final int bonusDiamonds;
  final String? customMessage;

  const MatchRewardResult({
    required this.earnedXP,
    required this.earnedCoins,
    required this.didLevelUp,
    required this.oldLevel,
    required this.newLevel,
    required this.bonusDiamonds,
    this.customMessage,
  });
}

class ProgressionService extends ChangeNotifier {
  static final ProgressionService instance = ProgressionService._internal();

  ProgressionService._internal();

  int _playerLevel = 1;
  int _currentXP = 0;
  int _coins = 1200;
  int _diamonds = 30;
  int _totalWins = 0;
  String _equippedCueId = 'standard_cue';
  final Map<String, int> _ownedCueLevels = {'standard_cue': 1};

  // Quản lý Bàn Bida (Table Skins - 20 mẫu bàn)
  String _equippedTableId = 'classic_green';
  final Set<String> _ownedTableIds = {'classic_green'};

  // Quản lý Ải Bot Campaign
  int _unlockedBotStage = 1;
  final Set<int> _completedBotStages = {};

  // Quản lý Nhiệm Vụ Thế Bi Hàng Ngày
  String? _lastDailyPuzzleDateCompleted;

  // Quản lý Giải Đấu Tournament 6 Brackets
  int _currentTournamentBracket = 1;
  int _tournamentWins = 0;

  // Quản lý Chế Độ Luyện Tập Thế Đánh Huyền Thoại (Masters Trickshot)
  final Set<String> _completedTrickshots = {};

  // Quản lý Thành Tựu & Huy Chương
  final Set<String> _unlockedAchievements = {};
  final Set<String> _claimedAchievements = {};
  final Set<String> _unlockedMedals = {};
  final List<String> _showcasedMedals = []; // Tối đa 5 huy chương hiển thị trên Profile

  bool _isInitialized = false;
  bool isGuestSession = false; // Khi chơi Khách (Offline): không lưu tiến trình

  int get playerLevel => _playerLevel;
  int get currentXP => _currentXP;
  int get coins => _coins;
  int get diamonds => _diamonds;
  int get totalWins => _totalWins;
  String get equippedCueId => _equippedCueId;
  Map<String, int> get ownedCueLevels => Map.unmodifiable(_ownedCueLevels);
  int get unlockedBotStage => _unlockedBotStage;
  Set<int> get completedBotStages => Set.unmodifiable(_completedBotStages);
  String? get lastDailyPuzzleDateCompleted => _lastDailyPuzzleDateCompleted;
  int get currentTournamentBracket => _currentTournamentBracket;
  int get tournamentWins => _tournamentWins;
  Set<String> get unlockedAchievements => Set.unmodifiable(_unlockedAchievements);
  Set<String> get claimedAchievements => Set.unmodifiable(_claimedAchievements);
  Set<String> get unlockedMedals => Set.unmodifiable(_unlockedMedals);
  List<String> get showcasedMedals => List.unmodifiable(_showcasedMedals);
  Set<String> get completedTrickshots => Set.unmodifiable(_completedTrickshots);
  bool get isInitialized => _isInitialized;

  CueModel get equippedCue => CueCatalog.getById(_equippedCueId);
  int get equippedCueLevel => _ownedCueLevels[_equippedCueId] ?? 1;

  String get equippedTableId => _equippedTableId;
  TableSkinModel get equippedTable => TableSkinCatalog.getById(_equippedTableId);
  Set<String> get ownedTableIds => Set.unmodifiable(_ownedTableIds);
  bool isTableOwned(String id) => _ownedTableIds.contains(id);
  bool isTableEquipped(String id) => _equippedTableId == id;
  bool canUnlockTable(TableSkinModel table) => _playerLevel >= table.unlockLevel;

  int get xpRequiredForNextLevel => _playerLevel * 120;
  double get xpProgress => (_currentXP / xpRequiredForNextLevel).clamp(0.0, 1.0);

  bool isBotStageUnlocked(int stageNumber) => stageNumber <= _unlockedBotStage;
  bool isBotStageCompleted(int stageNumber) => _completedBotStages.contains(stageNumber);
  bool isTrickshotCompleted(String id) => _completedTrickshots.contains(id);

  bool isDailyPuzzleCompletedToday() {
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return _lastDailyPuzzleDateCompleted == todayKey;
  }

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _playerLevel = prefs.getInt('progression_level') ?? 1;
      _currentXP = prefs.getInt('progression_xp') ?? 0;
      _coins = prefs.getInt('progression_coins') ?? 1200;
      _diamonds = prefs.getInt('progression_diamonds') ?? 30;
      _totalWins = prefs.getInt('progression_total_wins') ?? 0;
      _equippedCueId = prefs.getString('progression_equipped_cue') ?? 'standard_cue';
      _unlockedBotStage = prefs.getInt('progression_unlocked_bot_stage') ?? 1;
      _lastDailyPuzzleDateCompleted = prefs.getString('progression_last_daily_puzzle');
      _currentTournamentBracket = prefs.getInt('progression_tournament_bracket') ?? 1;
      _tournamentWins = prefs.getInt('progression_tournament_wins') ?? 0;

      final completedStagesList = prefs.getStringList('progression_completed_bot_stages');
      if (completedStagesList != null) {
        _completedBotStages.clear();
        for (final item in completedStagesList) {
          final val = int.tryParse(item);
          if (val != null) _completedBotStages.add(val);
        }
      }

      final achList = prefs.getStringList('progression_unlocked_achievements');
      if (achList != null) {
        _unlockedAchievements.addAll(achList);
      }
      final claimedList = prefs.getStringList('progression_claimed_achievements');
      if (claimedList != null) {
        _claimedAchievements.addAll(claimedList);
      }

      final medalList = prefs.getStringList('progression_unlocked_medals');
      if (medalList != null) {
        _unlockedMedals.addAll(medalList);
      }

      final showList = prefs.getStringList('progression_showcased_medals');
      if (showList != null) {
        _showcasedMedals.clear();
        _showcasedMedals.addAll(showList.take(5));
      }

      final trickshotsList = prefs.getStringList('progression_completed_trickshots');
      if (trickshotsList != null) {
        _completedTrickshots.clear();
        _completedTrickshots.addAll(trickshotsList);
      }

      final ownedJson = prefs.getString('progression_owned_cues');
      if (ownedJson != null) {
        final decoded = jsonDecode(ownedJson) as Map<String, dynamic>;
        _ownedCueLevels.clear();
        decoded.forEach((key, val) {
          _ownedCueLevels[key] = (val as num).toInt();
        });
      }
      if (!_ownedCueLevels.containsKey('standard_cue')) {
        _ownedCueLevels['standard_cue'] = 1;
      }
      if (!_ownedCueLevels.containsKey(_equippedCueId)) {
        _equippedCueId = 'standard_cue';
      }

      _equippedTableId = prefs.getString('progression_equipped_table') ?? 'classic_green';
      final tableList = prefs.getStringList('progression_owned_tables');
      if (tableList != null) {
        _ownedTableIds.addAll(tableList);
      }
      _ownedTableIds.add('classic_green');
      if (!_ownedTableIds.contains(_equippedTableId)) {
        _equippedTableId = 'classic_green';
      }

      checkAchievementsAndMedals();
    } catch (e) {
      debugPrint('Error loading progression data: $e');
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _save() async {
    if (isGuestSession) {
      // Chế độ Khách (Guest / Offline): không lưu tiến trình vào bộ nhớ máy hay máy chủ
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('progression_level', _playerLevel);
      await prefs.setInt('progression_xp', _currentXP);
      await prefs.setInt('progression_coins', _coins);
      await prefs.setInt('progression_diamonds', _diamonds);
      await prefs.setInt('progression_total_wins', _totalWins);
      await prefs.setString('progression_equipped_cue', _equippedCueId);
      await prefs.setInt('progression_unlocked_bot_stage', _unlockedBotStage);
      await prefs.setInt('progression_tournament_bracket', _currentTournamentBracket);
      await prefs.setInt('progression_tournament_wins', _tournamentWins);
      await prefs.setStringList(
        'progression_completed_bot_stages',
        _completedBotStages.map((e) => e.toString()).toList(),
      );
      await prefs.setStringList(
        'progression_unlocked_achievements',
        _unlockedAchievements.toList(),
      );
      await prefs.setStringList(
        'progression_claimed_achievements',
        _claimedAchievements.toList(),
      );
      await prefs.setStringList(
        'progression_unlocked_medals',
        _unlockedMedals.toList(),
      );
      await prefs.setStringList(
        'progression_showcased_medals',
        _showcasedMedals.take(5).toList(),
      );
      await prefs.setStringList(
        'progression_completed_trickshots',
        _completedTrickshots.toList(),
      );
      if (_lastDailyPuzzleDateCompleted != null) {
        await prefs.setString('progression_last_daily_puzzle', _lastDailyPuzzleDateCompleted!);
      }
      await prefs.setString('progression_owned_cues', jsonEncode(_ownedCueLevels));
      await prefs.setString('progression_equipped_table', _equippedTableId);
      await prefs.setStringList('progression_owned_tables', _ownedTableIds.toList());
    } catch (e) {
      debugPrint('Error saving progression data: $e');
    }
  }

  bool isCueOwned(String cueId) => _ownedCueLevels.containsKey(cueId);

  bool isCueEquipped(String cueId) => _equippedCueId == cueId;

  int getCueLevel(String cueId) => _ownedCueLevels[cueId] ?? 0;

  bool canUnlockCue(CueModel cue) => _playerLevel >= cue.requiredLevel;

  void addCoins(int amount) {
    if (amount <= 0) return;
    _coins += amount;
    _save();
    notifyListeners();
  }

  void addDiamonds(int amount) {
    if (amount <= 0) return;
    _diamonds += amount;
    _save();
    notifyListeners();
  }

  void recordWin() {
    _totalWins++;
    _save();
    notifyListeners();
  }

  /// Kích hoạt đặc quyền và chỉ số tài khoản Admin:
  /// Cấp độ 99, 9.999.999 Vàng, 99.999 Kim Cương, 999 Trận thắng,
  /// Mở khóa tất cả Ải Bot và sở hữu toàn bộ gậy Max Cấp (Lv.10).
  void applyAdminPrivileges() {
    _playerLevel = 99;
    _currentXP = 0;
    _coins = 9999999;
    _diamonds = 99999;
    _totalWins = 999;
    _unlockedBotStage = 10;
    _tournamentWins = 5;
    for (int i = 1; i <= 10; i++) {
      _completedBotStages.add(i);
    }
    for (final shot in LegendaryTrickshotCatalog.trickshots) {
      _completedTrickshots.add(shot.id);
    }
    for (final cue in CueCatalog.allCues) {
      _ownedCueLevels[cue.id] = 10;
    }
    _equippedCueId = 'dragon_god';
    for (final table in TableSkinCatalog.allTables) {
      _ownedTableIds.add(table.id);
    }
    _equippedTableId = 'dragon_emperor';
    checkAchievementsAndMedals();
    _save();
    notifyListeners();
  }

  /// Áp dụng dữ liệu đồng bộ từ Firebase Realtime Database cho người chơi
  void applyCloudStats({
    int? level,
    int? xp,
    int? coins,
    int? diamonds,
    int? wins,
    String? equippedCue,
  }) {
    bool hasChanged = false;
    if (level != null && level > 0 && level != _playerLevel) {
      _playerLevel = level;
      hasChanged = true;
    }
    if (xp != null && xp >= 0) {
      _currentXP = xp;
      hasChanged = true;
    }
    if (coins != null && coins >= 0 && coins != _coins) {
      _coins = coins;
      hasChanged = true;
    }
    if (diamonds != null && diamonds >= 0 && diamonds != _diamonds) {
      _diamonds = diamonds;
      hasChanged = true;
    }
    if (wins != null && wins >= 0 && wins != _totalWins) {
      _totalWins = wins;
      hasChanged = true;
    }
    if (equippedCue != null && CueCatalog.getById(equippedCue).id == equippedCue) {
      _equippedCueId = equippedCue;
      if (!_ownedCueLevels.containsKey(equippedCue)) {
        _ownedCueLevels[equippedCue] = 1;
      }
      hasChanged = true;
    }

    if (hasChanged) {
      _save();
      notifyListeners();
    }
  }

  /// Đặt lại chỉ số về mặc định khi đăng xuất hoặc vào chế độ Khách
  void resetToDefault({bool save = true}) {
    _playerLevel = 1;
    _currentXP = 0;
    _coins = 1200;
    _diamonds = 30;
    _totalWins = 0;
    _equippedCueId = 'standard_cue';
    _ownedCueLevels.clear();
    _ownedCueLevels['standard_cue'] = 1;
    _unlockedBotStage = 1;
    _completedBotStages.clear();
    _currentTournamentBracket = 1;
    _tournamentWins = 0;
    _completedTrickshots.clear();
    _lastDailyPuzzleDateCompleted = null;
    _unlockedAchievements.clear();
    _claimedAchievements.clear();
    _unlockedMedals.clear();
    _showcasedMedals.clear();
    _equippedTableId = 'classic_green';
    _ownedTableIds.clear();
    _ownedTableIds.add('classic_green');
    if (save && !isGuestSession) {
      _save();
    }
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (amount <= 0) return true;
    if (_coins < amount) return false;
    _coins -= amount;
    _save();
    notifyListeners();
    return true;
  }

  bool spendDiamonds(int amount) {
    if (amount <= 0) return true;
    if (_diamonds < amount) return false;
    _diamonds -= amount;
    _save();
    notifyListeners();
    return true;
  }

  /// Mua gậy trong Shop
  bool buyCue(CueModel cue) {
    if (isCueOwned(cue.id)) return false;
    if (!canUnlockCue(cue)) return false;

    if (cue.priceDiamonds != null && cue.priceDiamonds! > 0) {
      if (!spendDiamonds(cue.priceDiamonds!)) return false;
    } else if (cue.priceCoins != null && cue.priceCoins! > 0) {
      if (!spendCoins(cue.priceCoins!)) return false;
    }

    _ownedCueLevels[cue.id] = 1;
    _equippedCueId = cue.id;
    checkAchievementsAndMedals();
    _save();
    notifyListeners();
    return true;
  }

  /// Nâng cấp gậy lên cấp kế tiếp (Lv. 1 -> Lv. 10)
  bool upgradeCue(String cueId) {
    if (!isCueOwned(cueId)) return false;
    final currentLvl = _ownedCueLevels[cueId] ?? 1;
    if (currentLvl >= 10) return false;

    final cue = CueCatalog.getById(cueId);
    final cost = cue.getUpgradeCostCoins(currentLvl);

    if (!spendCoins(cost)) return false;

    _ownedCueLevels[cueId] = currentLvl + 1;
    checkAchievementsAndMedals();
    _save();
    notifyListeners();
    return true;
  }

  /// Trang bị gậy
  void equipCue(String cueId) {
    if (!isCueOwned(cueId)) return;
    _equippedCueId = cueId;
    checkAchievementsAndMedals();
    _save();
    notifyListeners();
  }

  /// Mua bàn bida trong Shop
  bool buyTable(TableSkinModel table) {
    if (isTableOwned(table.id)) return false;
    if (!canUnlockTable(table)) return false;

    if (table.priceDiamonds > 0) {
      if (!spendDiamonds(table.priceDiamonds)) return false;
    } else if (table.priceCoins > 0) {
      if (!spendCoins(table.priceCoins)) return false;
    }

    _ownedTableIds.add(table.id);
    _equippedTableId = table.id;
    _save();
    notifyListeners();
    return true;
  }

  /// Trang bị bàn bida
  bool equipTable(String tableId) {
    if (!isTableOwned(tableId)) return false;
    _equippedTableId = tableId;
    _save();
    notifyListeners();
    return true;
  }

  /// Thêm XP và tính toán thăng cấp (Level Up)
  MatchRewardResult addXPAndCoins({
    required int xpGained,
    required int coinsGained,
  }) {
    final oldLevel = _playerLevel;
    _currentXP += xpGained;
    _coins += coinsGained;

    int bonusDiamonds = 0;
    bool didLevelUp = false;

    while (_currentXP >= xpRequiredForNextLevel) {
      _currentXP -= xpRequiredForNextLevel;
      _playerLevel++;
      didLevelUp = true;
      // Phần thưởng khi thăng cấp: Vàng + Kim Cương
      _coins += _playerLevel * 250;
      bonusDiamonds += 5;
      _diamonds += 5;
    }

    _save();
    notifyListeners();

    return MatchRewardResult(
      earnedXP: xpGained,
      earnedCoins: coinsGained,
      didLevelUp: didLevelUp,
      oldLevel: oldLevel,
      newLevel: _playerLevel,
      bonusDiamonds: bonusDiamonds,
    );
  }

  /// Thưởng trận đấu dựa trên kết quả Thắng / Thua và gậy trang bị
  MatchRewardResult handleMatchRewards({
    required bool isWinner,
    required int pottedBallsCount,
  }) {
    int baseXp = isWinner ? 140 : 40;
    int baseCoins = isWinner ? 300 : 50;

    baseXp += pottedBallsCount * 12;
    baseCoins += pottedBallsCount * 25;

    // Kỹ năng nội tại gậy:
    // Cơ Kim Ngưu: +10% Vàng thắng ván
    if (isWinner && _equippedCueId == 'golden_bull') {
      baseCoins = (baseCoins * 1.10).round();
    }
    // Cơ Đế Vương Rồng: Thua được trợ giá hoàn 50%
    if (!isWinner && _equippedCueId == 'dragon_god') {
      baseCoins = 150; // Hoàn trợ cấp an ủi lớn
    }

    return addXPAndCoins(
      xpGained: baseXp,
      coinsGained: baseCoins,
    );
  }

  /// Khấu trừ số tiền bị mất khi thua trận (không để âm dưới 0)
  int deductMatchLostCoins(int amount) {
    if (amount <= 0) return 0;
    final lost = _coins >= amount ? amount : _coins;
    _coins -= lost;
    _save();
    notifyListeners();
    return lost;
  }

  void recordLoss() {
    notifyListeners();
  }

  /// Xử lý tiền cược và phần thưởng riêng cho chế độ Đấu Mạng Local WiFi:
  /// - Người thắng: Nhận tiền cược (+ Vàng) và XP
  /// - Người thua: Bị trừ tiền cược (- Vàng) từ tài khoản
  MatchRewardResult handleMultiplayerMatchRewards({
    required bool isWinner,
    int betAmount = 500,
  }) {
    if (isWinner) {
      int gainedCoins = betAmount;
      if (_equippedCueId == 'golden_bull') {
        gainedCoins = (gainedCoins * 1.10).round();
      }
      final xpResult = addXPAndCoins(
        xpGained: 150,
        coinsGained: gainedCoins,
      );
      recordWin();
      return MatchRewardResult(
        earnedXP: 150,
        earnedCoins: gainedCoins,
        didLevelUp: xpResult.didLevelUp,
        oldLevel: xpResult.oldLevel,
        newLevel: xpResult.newLevel,
        bonusDiamonds: xpResult.bonusDiamonds,
        customMessage: 'THẮNG ĐẤU MẠNG LOCAL (+$gainedCoins VÀNG)',
      );
    } else {
      int lostCoins = betAmount;
      if (_equippedCueId == 'dragon_god') {
        lostCoins = (lostCoins * 0.5).round();
      }
      final actualLost = deductMatchLostCoins(lostCoins);
      recordLoss();
      return MatchRewardResult(
        earnedXP: 30,
        earnedCoins: -actualLost,
        didLevelUp: false,
        oldLevel: playerLevel,
        newLevel: playerLevel,
        bonusDiamonds: 0,
        customMessage: 'THUA ĐẤU MẠNG LOCAL (-$actualLost VÀNG)',
      );
    }
  }

  /// Trao thưởng khi người chơi vượt qua 1 Ải Bot Campaign
  MatchRewardResult completeBotStage(BotStageModel stage) {
    final isFirstClear = !_completedBotStages.contains(stage.stageNumber);
    if (isFirstClear) {
      _completedBotStages.add(stage.stageNumber);
      if (stage.stageNumber == _unlockedBotStage && _unlockedBotStage < BotStageCatalog.stages.length) {
        _unlockedBotStage++;
      }
      if (stage.firstClearDiamonds > 0) {
        _diamonds += stage.firstClearDiamonds;
      }
      final result = addXPAndCoins(
        xpGained: stage.firstClearXP,
        coinsGained: stage.firstClearCoins,
      );
      checkAchievementsAndMedals();
      _save();
      return MatchRewardResult(
        earnedXP: stage.firstClearXP,
        earnedCoins: stage.firstClearCoins,
        didLevelUp: result.didLevelUp,
        oldLevel: result.oldLevel,
        newLevel: result.newLevel,
        bonusDiamonds: stage.firstClearDiamonds + result.bonusDiamonds,
        customMessage: 'VƯỢT ẢI ${stage.stageNumber} LẦN ĐẦU THÀNH CÔNG!',
      );
    } else {
      // Vượt ải các lần sau nhận thưởng bình thường
      return addXPAndCoins(
        xpGained: (stage.firstClearXP * 0.4).round(),
        coinsGained: (stage.firstClearCoins * 0.35).round(),
      );
    }
  }

  /// Trao thưởng khi hoàn thành Thế Đánh Huyền Thoại (Masters Trickshot)
  MatchRewardResult completeLegendaryTrickshot(LegendaryTrickshotModel shot) {
    final isFirstClear = !_completedTrickshots.contains(shot.id);
    _completedTrickshots.add(shot.id);
    final coins = isFirstClear ? shot.rewardCoins : (shot.rewardCoins * 0.35).round();
    final xp = isFirstClear ? shot.rewardXP : (shot.rewardXP * 0.4).round();
    final diamonds = isFirstClear
        ? shot.rewardDiamonds
        : (shot.rewardDiamonds > 2 ? (shot.rewardDiamonds * 0.25).round() : 0);

    if (diamonds > 0) {
      _diamonds += diamonds;
    }

    final result = addXPAndCoins(
      xpGained: xp,
      coinsGained: coins,
    );
    checkAchievementsAndMedals();
    _save();
    return MatchRewardResult(
      earnedXP: xp,
      earnedCoins: coins,
      didLevelUp: result.didLevelUp,
      oldLevel: result.oldLevel,
      newLevel: result.newLevel,
      bonusDiamonds: diamonds + result.bonusDiamonds,
      customMessage: isFirstClear
          ? 'CHINH PHỤC THẾ ĐÁNH CỦA ${shot.masterName.toUpperCase()}!'
          : 'HOÀN THÀNH LUYỆN TẬP THẾ ĐÁNH ${shot.masterName.toUpperCase()}!',
    );
  }

  /// Trao thưởng khi hoàn thành Nhiệm Vụ Thế Bi Hàng Ngày
  MatchRewardResult? claimDailyPuzzleReward(DailyPuzzleModel puzzle) {
    if (isDailyPuzzleCompletedToday()) {
      return null;
    }
    _lastDailyPuzzleDateCompleted = puzzle.dateKey;
    if (puzzle.rewardDiamonds > 0) {
      _diamonds += puzzle.rewardDiamonds;
    }
    final result = addXPAndCoins(
      xpGained: puzzle.rewardXP,
      coinsGained: puzzle.rewardCoins,
    );
    checkAchievementsAndMedals();
    _save();
    return MatchRewardResult(
      earnedXP: puzzle.rewardXP,
      earnedCoins: puzzle.rewardCoins,
      didLevelUp: result.didLevelUp,
      oldLevel: result.oldLevel,
      newLevel: result.newLevel,
      bonusDiamonds: puzzle.rewardDiamonds + result.bonusDiamonds,
      customMessage: 'HOÀN THÀNH NHIỆM VỤ THẾ BI HÀNG NGÀY!',
    );
  }

  // --- QUẢN LÝ HUY CHƯƠNG & SHOWCASE (TỐI ĐA 5 HUY CHƯƠNG) ---
  bool isMedalUnlocked(String medalId) => _unlockedMedals.contains(medalId);
  bool isMedalShowcased(String medalId) => _showcasedMedals.contains(medalId);

  void unlockMedal(String medalId) {
    if (!_unlockedMedals.contains(medalId)) {
      _unlockedMedals.add(medalId);
      if (_showcasedMedals.length < 5 && !_showcasedMedals.contains(medalId)) {
        _showcasedMedals.add(medalId);
      }
      _save();
      notifyListeners();
    }
  }

  /// Bật/tắt ghim huy chương lên hồ sơ (Profile) - Tối đa 5 huy chương
  /// Trả về true nếu thành công, false nếu đã đạt giới hạn 5 huy chương
  bool toggleShowcaseMedal(String medalId) {
    if (!isMedalUnlocked(medalId)) return false;
    if (_showcasedMedals.contains(medalId)) {
      _showcasedMedals.remove(medalId);
      _save();
      notifyListeners();
      return true;
    } else {
      if (_showcasedMedals.length >= 5) {
        return false; // Đã đạt tối đa 5 huy chương
      }
      _showcasedMedals.add(medalId);
      _save();
      notifyListeners();
      return true;
    }
  }

  // --- QUẢN LÝ THÀNH TỰU (ACHIEVEMENTS) & NHẬN EXP ---
  bool isAchievementUnlocked(String id) => _unlockedAchievements.contains(id);
  bool isAchievementClaimed(String id) => _claimedAchievements.contains(id);

  void unlockAchievement(String id) {
    if (!_unlockedAchievements.contains(id)) {
      _unlockedAchievements.add(id);
      _save();
      notifyListeners();
    }
  }

  /// Nhận thưởng EXP cho thành tựu dựa trên độ khó
  MatchRewardResult? claimAchievement(String id) {
    final ach = AchievementCatalog.getById(id);
    if (ach == null) return null;
    if (!_unlockedAchievements.contains(id)) return null;
    if (_claimedAchievements.contains(id)) return null;

    _claimedAchievements.add(id);
    final result = addXPAndCoins(
      xpGained: ach.rewardXP,
      coinsGained: 0,
    );
    _save();
    return MatchRewardResult(
      earnedXP: ach.rewardXP,
      earnedCoins: 0,
      didLevelUp: result.didLevelUp,
      oldLevel: result.oldLevel,
      newLevel: result.newLevel,
      bonusDiamonds: result.bonusDiamonds,
      customMessage: 'NHẬN THƯỞNG THÀNH TỰU: ${ach.title} (+${ach.rewardXP} XP)!',
    );
  }

  /// Tự động kiểm tra và mở khóa các thành tựu và huy chương đủ điều kiện
  void checkAchievementsAndMedals() {
    bool changed = false;

    void tryUnlockAch(String id) {
      if (!_unlockedAchievements.contains(id)) {
        _unlockedAchievements.add(id);
        changed = true;
      }
    }

    void tryUnlockMedal(String id) {
      if (!_unlockedMedals.contains(id)) {
        _unlockedMedals.add(id);
        if (_showcasedMedals.length < 5 && !_showcasedMedals.contains(id)) {
          _showcasedMedals.add(id);
        }
        changed = true;
      }
    }

    // 1. Trận thắng & Chiến tích
    if (_totalWins >= 1) {
      tryUnlockAch('first_win');
      tryUnlockMedal('bronze_champion');
    }
    if (_totalWins >= 3) tryUnlockAch('win_streak_3');
    if (_totalWins >= 10) tryUnlockAch('win_10');
    if (_totalWins >= 15) tryUnlockMedal('veteran_striker');
    if (_totalWins >= 25) tryUnlockAch('win_25');
    if (_totalWins >= 30) tryUnlockMedal('centurion_victor');
    if (_totalWins >= 50) tryUnlockAch('win_50');
    if (_totalWins >= 75) tryUnlockMedal('legendary_champion');
    if (_totalWins >= 100) tryUnlockAch('win_100');
    if (_totalWins >= 200) tryUnlockAch('win_200');

    // 2. Cấp độ người chơi (Level)
    if (_playerLevel >= 3) tryUnlockAch('reach_level_3');
    if (_playerLevel >= 5) {
      tryUnlockAch('reach_level_5');
      tryUnlockMedal('rising_star');
    }
    if (_playerLevel >= 8) tryUnlockAch('reach_level_8');
    if (_playerLevel >= 10) {
      tryUnlockAch('reach_level_10');
      tryUnlockMedal('grandmaster');
    }
    if (_playerLevel >= 15) tryUnlockAch('reach_level_15');
    if (_playerLevel >= 20) tryUnlockAch('reach_level_20');
    if (_playerLevel >= 25) tryUnlockMedal('hall_of_fame');
    if (_playerLevel >= 30) tryUnlockAch('reach_level_30');
    if (_playerLevel >= 50) {
      tryUnlockAch('reach_level_50');
      tryUnlockMedal('immortal_sovereign');
    }

    // 3. Tài sản Vàng & Kim Cương
    if (_coins >= 5000) tryUnlockAch('first_wealth');
    if (_coins >= 10000) tryUnlockAch('coins_10k');
    if (_coins >= 20000) {
      tryUnlockAch('coins_20k');
      tryUnlockMedal('wealthy_striker');
    }
    if (_coins >= 25000) tryUnlockAch('rich_player');
    if (_coins >= 50000) {
      tryUnlockAch('coins_50k');
      tryUnlockMedal('silver_treasury');
    }
    if (_coins >= 75000) tryUnlockAch('coins_75k');
    if (_coins >= 100000) {
      tryUnlockMedal('golden_treasury');
      if (_totalWins >= 50) tryUnlockAch('billiard_god');
    }
    if (_coins >= 200000) tryUnlockAch('coins_200k');
    if (_coins >= 500000 && _playerLevel >= 70 && _totalWins >= 100) {
      tryUnlockAch('billiard_emperor');
    }

    if (_diamonds >= 30) tryUnlockAch('first_diamond');
    if (_diamonds >= 100) tryUnlockMedal('diamond_royalty');

    // 4. Số lượng gậy sở hữu & Trang bị
    if (_ownedCueLevels.length >= 2) {
      tryUnlockAch('cue_enthusiast');
      tryUnlockMedal('cue_collector_bronze');
    }
    if (_ownedCueLevels.length >= 4) {
      tryUnlockAch('cue_collector');
      tryUnlockMedal('cue_collector_gold');
    }
    if (_ownedCueLevels.length >= 7) {
      tryUnlockAch('cue_arsenal_full');
      tryUnlockMedal('cue_collector_mythic');
    }
    if (_equippedCueId != 'standard_cue') {
      tryUnlockAch('change_profile_cue');
    }

    // 5. Cấp độ nâng cấp gậy
    final hasCueLv2 = _ownedCueLevels.values.any((lvl) => lvl >= 2);
    final hasCueLv3 = _ownedCueLevels.values.any((lvl) => lvl >= 3);
    final hasCueLv4 = _ownedCueLevels.values.any((lvl) => lvl >= 4);
    final hasCueLv5 = _ownedCueLevels.values.any((lvl) => lvl >= 5);
    final hasCueLv7 = _ownedCueLevels.values.any((lvl) => lvl >= 7);
    final hasCueLv8 = _ownedCueLevels.values.any((lvl) => lvl >= 8);
    final hasCueLv10 = _ownedCueLevels.values.any((lvl) => lvl >= 10);

    if (hasCueLv2) tryUnlockAch('cue_upgrade_first');
    if (hasCueLv3) {
      tryUnlockAch('cue_upgrade_level_3');
      tryUnlockMedal('cue_apprentice');
    }
    if (hasCueLv4) tryUnlockMedal('cue_artisan');
    if (hasCueLv5) {
      tryUnlockAch('cue_upgrade_level_5');
      tryUnlockMedal('cue_master');
    }
    if (hasCueLv7) tryUnlockAch('cue_upgrade_level_7');
    if (hasCueLv8) tryUnlockAch('cue_upgrade_level_8');
    if (hasCueLv10) {
      tryUnlockAch('cue_level_max');
      tryUnlockMedal('cue_god_forge');
    }

    // 6. Chiến dịch Bot Campaign
    if (_completedBotStages.contains(1)) {
      tryUnlockAch('bot_stage_1');
      tryUnlockMedal('bot_cadet');
    }
    if (_completedBotStages.contains(2)) tryUnlockAch('bot_stage_2');
    if (_completedBotStages.contains(3)) {
      tryUnlockAch('bot_stage_3');
      tryUnlockMedal('bot_fighter');
    }
    if (_completedBotStages.contains(4)) tryUnlockAch('bot_stage_4');
    if (_completedBotStages.contains(5)) {
      tryUnlockAch('bot_stage_5');
      tryUnlockMedal('bot_challenger');
    }
    if (_completedBotStages.contains(6)) tryUnlockAch('bot_stage_6');
    if (_completedBotStages.contains(7)) {
      tryUnlockAch('bot_campaign_clear');
      tryUnlockMedal('bot_slayer');
    }
    if (_completedBotStages.contains(8)) tryUnlockMedal('master_duel_victor');
    if (_completedBotStages.contains(9)) {
      tryUnlockAch('bot_stage_9');
      tryUnlockMedal('bot_annihilator');
    }
    if (_completedBotStages.contains(10)) {
      tryUnlockAch('bot_stage_10');
      tryUnlockMedal('bot_overlord');
    }

    // 7. Giải đấu Tournament 5 Brackets
    if (_currentTournamentBracket >= 2 || _tournamentWins >= 1) {
      tryUnlockAch('tournament_entry');
      tryUnlockMedal('tournament_quarter');
    }
    if (_currentTournamentBracket >= 3 || _tournamentWins >= 1) {
      tryUnlockAch('tournament_bracket_2');
    }
    if (_currentTournamentBracket >= 4 || _tournamentWins >= 1) {
      tryUnlockAch('tournament_bracket_3');
      tryUnlockMedal('tournament_semis');
    }
    if (_currentTournamentBracket >= 5 || _tournamentWins >= 1) {
      tryUnlockAch('tournament_bracket_4');
      tryUnlockMedal('tournament_runner_up');
    }
    if (_tournamentWins >= 1) {
      tryUnlockAch('tournament_champion_legend');
      tryUnlockMedal('tournament_champion');
    }
    if (_tournamentWins >= 3) {
      tryUnlockAch('tournament_multi_champ');
      tryUnlockMedal('tournament_dynasty');
    }

    // 8. Thế Đánh Huyền Thoại & Thế Bi Hàng Ngày
    if (_completedTrickshots.isNotEmpty) {
      tryUnlockAch('trickshot_first');
      tryUnlockMedal('trickshot_apprentice');
    }
    if (_completedTrickshots.length >= 5) {
      tryUnlockAch('trickshot_master_5');
      tryUnlockMedal('trickshot_virtuoso');
    }
    if (_completedTrickshots.length >= 10) {
      tryUnlockAch('trickshot_master_10');
      tryUnlockMedal('trickshot_legend');
    }
    if (_completedTrickshots.length >= 25) {
      tryUnlockMedal('trickshot_immortal');
    }
    if (_lastDailyPuzzleDateCompleted != null) {
      tryUnlockAch('explore_daily_puzzle');
      tryUnlockAch('daily_puzzle_clear');
      tryUnlockMedal('trickshot_master');
    }

    // 9. Huy chương ghim trên Profile
    if (_showcasedMedals.length >= 3) tryUnlockAch('medals_showcase_3');
    if (_showcasedMedals.length >= 5) {
      tryUnlockAch('medals_showcase_5');
      tryUnlockMedal('profile_perfection');
    }

    if (changed) {
      _save();
      notifyListeners();
    }
  }

  // --- QUẢN LÝ GIẢI ĐẤU TOURNAMENT 5 BRACKETS ---
  /// Trao thưởng sau khi người chơi thắng 1 Bracket Tournament
  MatchRewardResult completeTournamentBracket(TournamentBracketStage stage) {
    final isChampion = stage.bracketNumber == 5;

    final result = addXPAndCoins(
      xpGained: stage.xpReward,
      coinsGained: stage.coinReward,
    );
    recordWin();

    if (stage.bonusMedalId != null) {
      unlockMedal(stage.bonusMedalId!);
    }

    if (isChampion) {
      _tournamentWins++;
      _currentTournamentBracket = 1;
      unlockMedal('tournament_champion');
      unlockAchievement('tournament_champion_legend');
      if (!_showcasedMedals.contains('tournament_champion')) {
        if (_showcasedMedals.length < 5) {
          _showcasedMedals.add('tournament_champion');
        } else {
          _showcasedMedals[0] = 'tournament_champion';
        }
      }
      checkAchievementsAndMedals();
      _save();
      return MatchRewardResult(
        earnedXP: stage.xpReward,
        earnedCoins: stage.coinReward,
        didLevelUp: result.didLevelUp,
        oldLevel: result.oldLevel,
        newLevel: result.newLevel,
        bonusDiamonds: 50 + result.bonusDiamonds,
        customMessage: '🏆 QUÁN QUÂN VÔ ĐỊCH TOURNAMENT 5 BRACKETS (+${stage.coinReward} VÀNG, CÚP VÀNG & THÀNH TỰU)!',
      );
    } else {
      _currentTournamentBracket = stage.bracketNumber + 1;
      checkAchievementsAndMedals();
      _save();
      return MatchRewardResult(
        earnedXP: stage.xpReward,
        earnedCoins: stage.coinReward,
        didLevelUp: result.didLevelUp,
        oldLevel: result.oldLevel,
        newLevel: result.newLevel,
        bonusDiamonds: result.bonusDiamonds,
        customMessage: 'VƯỢT QUA ${stage.title} (TIẾN VÀO BRACKET $_currentTournamentBracket)!',
      );
    }
  }

  void resetTournament() {
    _currentTournamentBracket = 1;
    _save();
    notifyListeners();
  }
}
