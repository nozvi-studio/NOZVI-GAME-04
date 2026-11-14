import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/enums.dart';
import '../core/pentatonic_audio_synth.dart';
import '../core/haptics_manager.dart';

/// Quản lý kinh tế người chơi (Xu Vàng, Ngọc), Kho Skin, Nâng cấp Cổ vật,
/// Tiến độ Sao 500 màn chơi, Rương Mốc & Cài đặt Âm thanh/Rung.
class PlayerEconomyService extends ChangeNotifier {
  static final PlayerEconomyService instance = PlayerEconomyService._internal();
  PlayerEconomyService._internal();

  static const String _prefCoinsKey = 'sanctuary_coins'; // Dùng chung ví Xu với Pet Sanctuary
  static const String _prefGemsKey = 'player_gems';
  static const String _prefActiveSkinKey = 'player_active_skin';
  static const String _prefUnlockedSkinsKey = 'player_unlocked_skins';
  static const String _prefHammerUpgradeKey = 'upgrade_hammer_level';
  static const String _prefCompassUpgradeKey = 'upgrade_compass_level';
  static const String _prefUnlockedLevelKey = 'unlocked_level';
  static const String _prefClaimedChestsKey = 'saga_claimed_chests';
  static const String _prefBgmKey = 'settings_bgm_enabled';
  static const String _prefSfxKey = 'settings_sfx_enabled';
  static const String _prefHapticsKey = 'settings_haptics_enabled';

  static const List<int> kMilestoneLevels = [
    10, 25, 50, 100, 150, 200, 250, 300, 350, 400, 450, 500,
  ];

  int _coins = 350; // Tặng 350 Xu khởi đầu để trải nghiệm Shop & nâng cấp
  int _gems = 50;
  GameSkinTheme _activeSkin = GameSkinTheme.kawaiiPets;
  final Set<GameSkinTheme> _unlockedSkins = {GameSkinTheme.kawaiiPets};

  int _starterHammerLevel = 0; // Tối đa 3 (mỗi cấp +1 sạc Búa khởi đầu trận)
  int _starterCompassLevel = 0; // Tối đa 2 (mỗi cấp +1 sạc La Bàn khởi đầu trận)

  int _unlockedLevel = 1;
  final Map<int, int> _levelStars = {};
  final Set<int> _claimedMilestones = {};

  bool _bgmEnabled = true;
  bool _sfxEnabled = true;
  bool _hapticsEnabled = true;
  bool _isInitialized = false;

  int get coins => _coins;
  int get gems => _gems;
  GameSkinTheme get activeSkin => _activeSkin;
  Set<GameSkinTheme> get unlockedSkins => Set.unmodifiable(_unlockedSkins);

  int get starterHammerLevel => _starterHammerLevel;
  int get starterCompassLevel => _starterCompassLevel;
  int get starterHammerCharges => _starterHammerLevel;
  int get starterCompassCharges => _starterCompassLevel;

  int get unlockedLevel => _unlockedLevel;
  Map<int, int> get levelStars => Map.unmodifiable(_levelStars);
  Set<int> get claimedMilestones => Set.unmodifiable(_claimedMilestones);

  bool get bgmEnabled => _bgmEnabled;
  bool get sfxEnabled => _sfxEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

  Future<void> init({bool forceReload = false}) async {
    if (_isInitialized && !forceReload) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _coins = prefs.getInt(_prefCoinsKey) ?? 350;
      _gems = prefs.getInt(_prefGemsKey) ?? 50;

      final skinName = prefs.getString(_prefActiveSkinKey);
      _activeSkin = GameSkinTheme.values.firstWhere(
        (e) => e.name == skinName,
        orElse: () => GameSkinTheme.kawaiiPets,
      );

      final unlockedList = prefs.getStringList(_prefUnlockedSkinsKey);
      _unlockedSkins
        ..clear()
        ..add(GameSkinTheme.kawaiiPets);
      if (unlockedList != null) {
        for (final name in unlockedList) {
          final match = GameSkinTheme.values.where((s) => s.name == name);
          if (match.isNotEmpty) {
            _unlockedSkins.add(match.first);
          }
        }
      }

      _starterHammerLevel = (prefs.getInt(_prefHammerUpgradeKey) ?? 0).clamp(0, 3);
      _starterCompassLevel = (prefs.getInt(_prefCompassUpgradeKey) ?? 0).clamp(0, 2);
      _unlockedLevel = (prefs.getInt(_prefUnlockedLevelKey) ?? 1).clamp(1, 500);

      _levelStars.clear();
      for (int i = 1; i <= 500; i++) {
        final stars = prefs.getInt('level_stars_$i');
        if (stars != null) {
          _levelStars[i] = stars;
        }
      }

      final chestsList = prefs.getStringList(_prefClaimedChestsKey) ?? [];
      _claimedMilestones
        ..clear()
        ..addAll(chestsList.map((e) => int.tryParse(e)).whereType<int>());

      _bgmEnabled = prefs.getBool(_prefBgmKey) ?? true;
      _sfxEnabled = prefs.getBool(_prefSfxKey) ?? true;
      _hapticsEnabled = prefs.getBool(_prefHapticsKey) ?? true;

      PentatonicAudioSynth.instance.setSfxEnabled(_sfxEnabled);
      PentatonicAudioSynth.instance.bgmEnabled = _bgmEnabled;
      HapticsManager.instance.isEnabled = _hapticsEnabled;

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('PlayerEconomyService init error: $e');
    }
  }

  /// Đồng bộ lại ví Xu từ SharedPreferences (khi Pet Sanctuary thay đổi Xu)
  Future<void> syncCoinsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latest = prefs.getInt(_prefCoinsKey);
      if (latest != null && latest != _coins) {
        _coins = latest;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> addRewards({int coinsDelta = 0, int gemsDelta = 0}) async {
    _coins = math.max(0, _coins + coinsDelta);
    _gems = math.max(0, _gems + gemsDelta);
    notifyListeners();
    await _save();
  }

  /// Mở khóa Skin bằng Xu Vàng
  Future<bool> buySkinWithCoins(GameSkinTheme skin) async {
    if (_unlockedSkins.contains(skin)) {
      return equipSkin(skin);
    }
    if (_coins < skin.priceCoins) return false;
    _coins -= skin.priceCoins;
    _unlockedSkins.add(skin);
    _activeSkin = skin;
    notifyListeners();
    await _save();
    return true;
  }

  /// Mở khóa Skin bằng Ngọc
  Future<bool> buySkinWithGems(GameSkinTheme skin) async {
    if (_unlockedSkins.contains(skin)) {
      return equipSkin(skin);
    }
    if (_gems < skin.priceGems) return false;
    _gems -= skin.priceGems;
    _unlockedSkins.add(skin);
    _activeSkin = skin;
    notifyListeners();
    await _save();
    return true;
  }

  Future<bool> equipSkin(GameSkinTheme skin) async {
    if (!_unlockedSkins.contains(skin)) return false;
    _activeSkin = skin;
    notifyListeners();
    await _save();
    return true;
  }

  int getHammerUpgradeCost() => 150 + _starterHammerLevel * 200;
  int getCompassUpgradeCost() => 120 + _starterCompassLevel * 180;

  Future<bool> upgradeStarterHammer() async {
    if (_starterHammerLevel >= 3) return false;
    final cost = getHammerUpgradeCost();
    if (_coins < cost) return false;
    _coins -= cost;
    _starterHammerLevel++;
    notifyListeners();
    await _save();
    return true;
  }

  Future<bool> upgradeStarterCompass() async {
    if (_starterCompassLevel >= 2) return false;
    final cost = getCompassUpgradeCost();
    if (_coins < cost) return false;
    _coins -= cost;
    _starterCompassLevel++;
    notifyListeners();
    await _save();
    return true;
  }

  /// Lưu kết quả thắng màn (1-3 Sao) & mở khóa màn tiếp theo
  Future<void> recordLevelVictory(int level, int stars, int rewardCoins) async {
    if (level >= 1 && level <= 500) {
      final oldStars = _levelStars[level] ?? 0;
      _levelStars[level] = math.max(oldStars, stars.clamp(1, 3));
      if (level >= _unlockedLevel && level < 500) {
        _unlockedLevel = level + 1;
      }
    }
    _coins += rewardCoins;
    notifyListeners();
    await _save();
  }

  bool isMilestoneUnlocked(int milestoneLevel) {
    return _unlockedLevel > milestoneLevel || (_levelStars[milestoneLevel] ?? 0) > 0;
  }

  bool isMilestoneClaimed(int milestoneLevel) {
    return _claimedMilestones.contains(milestoneLevel);
  }

  /// Mở Rương Quà tại các mốc Saga 10, 25, 50, 100, 150, 200
  Future<({int coins, int gems})?> claimMilestoneChest(int milestoneLevel) async {
    if (!isMilestoneUnlocked(milestoneLevel) || isMilestoneClaimed(milestoneLevel)) {
      return null;
    }
    _claimedMilestones.add(milestoneLevel);
    final int coinsReward = 150 + milestoneLevel * 2;
    final int gemsReward = 10 + (milestoneLevel ~/ 10);
    _coins += coinsReward;
    _gems += gemsReward;
    notifyListeners();
    await _save();
    return (coins: coinsReward, gems: gemsReward);
  }

  Future<void> setBgmEnabled(bool enabled) async {
    _bgmEnabled = enabled;
    await PentatonicAudioSynth.instance.setBgmEnabled(enabled);
    notifyListeners();
    await _save();
  }

  Future<void> setSfxEnabled(bool enabled) async {
    _sfxEnabled = enabled;
    PentatonicAudioSynth.instance.setSfxEnabled(enabled);
    notifyListeners();
    await _save();
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    _hapticsEnabled = enabled;
    HapticsManager.instance.isEnabled = enabled;
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefCoinsKey, _coins);
      await prefs.setInt(_prefGemsKey, _gems);
      await prefs.setString(_prefActiveSkinKey, _activeSkin.name);
      await prefs.setStringList(
        _prefUnlockedSkinsKey,
        _unlockedSkins.map((s) => s.name).toList(),
      );
      await prefs.setInt(_prefHammerUpgradeKey, _starterHammerLevel);
      await prefs.setInt(_prefCompassUpgradeKey, _starterCompassLevel);
      await prefs.setInt(_prefUnlockedLevelKey, _unlockedLevel);
      for (final entry in _levelStars.entries) {
        await prefs.setInt('level_stars_${entry.key}', entry.value);
      }
      await prefs.setStringList(
        _prefClaimedChestsKey,
        _claimedMilestones.map((e) => '$e').toList(),
      );
      await prefs.setBool(_prefBgmKey, _bgmEnabled);
      await prefs.setBool(_prefSfxKey, _sfxEnabled);
      await prefs.setBool(_prefHapticsKey, _hapticsEnabled);
    } catch (e) {
      debugPrint('PlayerEconomyService save error: $e');
    }
  }
}

