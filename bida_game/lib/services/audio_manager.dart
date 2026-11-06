import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioManager {
  static final AudioManager instance = AudioManager._internal();
  AudioManager._internal();

  final ValueNotifier<bool> isMusicEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> isSfxEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<double> musicVolume = ValueNotifier<double>(0.40);
  final ValueNotifier<double> sfxVolume = ValueNotifier<double>(0.85);

  bool _isInitialized = false;
  bool _isPlayingBgm = false;
  bool _pendingAutoplay = false;
  int _lastBallHitTime = 0;
  int _lastPocketTime = 0;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      isMusicEnabled.value = prefs.getBool('audio_music_enabled') ?? true;
      isSfxEnabled.value = prefs.getBool('audio_sfx_enabled') ?? true;
      musicVolume.value = prefs.getDouble('audio_music_volume') ?? 0.40;
      sfxVolume.value = prefs.getDouble('audio_sfx_volume') ?? 0.85;

      // Khởi tạo và nạp sẵn cache âm thanh của game
      FlameAudio.bgm.initialize();
      await FlameAudio.audioCache.loadAll([
        'ball_hit.wav',
        'pocket.wav',
        'combo.wav',
      ]);

      if (isMusicEnabled.value) {
        startBgm();
      }
    } catch (e) {
      debugPrint('AudioManager initialize error: $e');
    }
  }

  // ==========================================
  // 1. NHẠC NỀN BIDA (Background Music - BGM)
  // ==========================================

  void startBgm() {
    if (!isMusicEnabled.value) return;
    try {
      FlameAudio.bgm.play(
        'bgm.wav',
        volume: musicVolume.value,
      ).then((_) {
        _isPlayingBgm = true;
        _pendingAutoplay = false;
      }).catchError((e) {
        // Trình duyệt (Chrome/Web/Mobile) chặn autoplay khi chưa có cử chỉ người dùng
        _isPlayingBgm = false;
        _pendingAutoplay = true;
      });
    } catch (e) {
      _isPlayingBgm = false;
      _pendingAutoplay = true;
      debugPrint('Error playing BGM: $e');
    }
  }

  /// Tự động phát nhạc ngay khi người dùng chạm hoặc click lần đầu vào màn hình
  void onUserInteraction() {
    if (_pendingAutoplay && isMusicEnabled.value && !_isPlayingBgm) {
      _pendingAutoplay = false;
      startBgm();
    }
  }

  void stopBgm() {
    _isPlayingBgm = false;
    _pendingAutoplay = false;
    try {
      FlameAudio.bgm.stop();
    } catch (e) {
      debugPrint('Error stopping BGM: $e');
    }
  }

  void pauseBgm() {
    try {
      FlameAudio.bgm.pause();
    } catch (e) {
      debugPrint('Error pausing BGM: $e');
    }
  }

  void resumeBgm() {
    if (!isMusicEnabled.value) return;
    try {
      FlameAudio.bgm.resume();
    } catch (e) {
      debugPrint('Error resuming BGM: $e');
    }
  }

  Future<void> toggleMusic() async {
    isMusicEnabled.value = !isMusicEnabled.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_music_enabled', isMusicEnabled.value);

    if (isMusicEnabled.value) {
      startBgm();
    } else {
      stopBgm();
    }
  }

  Future<void> setMusicVolume(double vol) async {
    musicVolume.value = vol.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('audio_music_volume', musicVolume.value);
    if (isMusicEnabled.value) {
      try {
        FlameAudio.bgm.audioPlayer.setVolume(musicVolume.value);
      } catch (_) {}
    }
  }

  // ==========================================
  // 2. HIỆU ỨNG ÂM THANH (Sound Effects - SFX)
  // ==========================================

  Future<void> toggleSfx() async {
    isSfxEnabled.value = !isSfxEnabled.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_sfx_enabled', isSfxEnabled.value);
  }

  Future<void> setSfxVolume(double vol) async {
    sfxVolume.value = vol.clamp(0.0, 1.0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('audio_sfx_volume', sfxVolume.value);
  }

  /// Va chạm giữa 2 quả bi bida (tiếng "cạch" giòn, đanh, dứt khoát như thực tế)
  void playBallHit({double relativeSpeed = 200.0}) {
    if (!isSfxEnabled.value) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    // Chống quá tải âm thanh khi phá bi (Break shot va chạm 15 bi liên tục)
    if (now - _lastBallHitTime < 18) return;
    _lastBallHitTime = now;

    try {
      // Âm lượng tỷ lệ thuận với vận tốc va chạm thực tế:
      // - Chạm nhẹ (< 60 px/s): kêu "cạch" thanh mảnh, âm lượng êm dịu
      // - Chạm trung bình (150 - 350 px/s): tiếng bi vang chuẩn xác
      // - Phá bi mạnh (> 450 px/s): tiếng va chạm đanh, giòn, uy lực
      final speedFactor = relativeSpeed <= 60.0
          ? (relativeSpeed / 60.0) * 0.35 + 0.15
          : (relativeSpeed / 500.0).clamp(0.35, 1.0);
      final vol = (sfxVolume.value * speedFactor).clamp(0.06, 1.0);
      FlameAudio.play('ball_hit.wav', volume: vol);
    } catch (_) {}
  }

  /// Bi nảy đập vào băng cao su (đã tắt theo yêu cầu người dùng)
  void playRailHit({double speed = 150.0}) {
    // Không phát âm thanh theo yêu cầu
  }

  /// Đánh gậy cơ vào bi cái (đã tắt theo yêu cầu người dùng)
  void playCueHit({double power = 0.5}) {
    // Không phát âm thanh theo yêu cầu
  }

  /// Bi rơi chìm vào lòng lỗ da
  void playPocket() {
    if (!isSfxEnabled.value) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastPocketTime < 40) return;
    _lastPocketTime = now;

    try {
      FlameAudio.play('pocket.wav', volume: sfxVolume.value);
    } catch (_) {}
  }

  /// Hiệu ứng âm thanh khi đạt Combo ăn từ 2 bi trở lên
  void playCombo(int comboCount) {
    if (!isSfxEnabled.value) return;
    try {
      final vol = (sfxVolume.value * 1.05).clamp(0.1, 1.0);
      FlameAudio.play('combo.wav', volume: vol);
    } catch (_) {}
  }
}
