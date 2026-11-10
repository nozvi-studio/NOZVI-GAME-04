import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Bộ tổng hợp âm thanh thủ tục dạng byte WAV PCM 16-bit
/// Khóa theo âm giai Ngũ cung Đô Trưởng: C4, D4, E4, G4, A4, C5, D5, E5
class PentatonicAudioSynth {
  static final PentatonicAudioSynth _instance = PentatonicAudioSynth._internal();
  static PentatonicAudioSynth get instance => _instance;

  final AudioPlayer _player = AudioPlayer();
  bool isMuted = false;

  static const int kSampleRate = 22050;

  // Tần số âm giai Ngũ cung Đô Trưởng (Hz)
  static const List<double> kPentatonicNotes = [
    261.63, // C4
    293.66, // D4
    329.63, // E4
    392.00, // G4
    440.00, // A4
    523.25, // C5
    587.33, // D5
    659.25, // E5
    783.99, // G5
    1046.50 // C6
  ];

  PentatonicAudioSynth._internal() {
    _player.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: false,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.game,
        audioFocus: AndroidAudioFocus.none,
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient,
      ),
    ));
  }

  /// Tiếng "Bộp" đàn hồi khi đặt khối gạch
  Future<void> playBlockDrop() async {
    if (isMuted) return;
    final bytes = _generateBlockDropWav();
    await _playBytes(bytes);
  }

  /// Tiếng thú cưng nhảy / tiếng Marimba theo nốt Ngũ cung tăng dần theo Combo
  Future<void> playPetJump({int comboIndex = 0}) async {
    if (isMuted) return;
    final noteIdx = comboIndex.clamp(0, kPentatonicNotes.length - 1);
    final freq = kPentatonicNotes[noteIdx];
    final bytes = _generateMarimbaNoteWav(freq, durationMs: 240);
    await _playBytes(bytes);
  }

  /// Tiếng còi xe buýt "Bim Bim!" (2 tiếng bíp hài âm vui nhộn)
  Future<void> playBusHorn() async {
    if (isMuted) return;
    final bytes = _generateBusHornWav();
    await _playBytes(bytes);
  }

  /// Tiếng Búa Rèn Lửa đập nổ 3x3
  Future<void> playHammerSmash() async {
    if (isMuted) return;
    final bytes = _generateHammerSmashWav();
    await _playBytes(bytes);
  }

  /// Tiếng La Bàn Gió vút nhẹ xoay khối
  Future<void> playWindCompass() async {
    if (isMuted) return;
    final bytes = _generateWindCompassWav();
    await _playBytes(bytes);
  }

  /// Nhạc thắng màn
  Future<void> playWinFanfare() async {
    if (isMuted) return;
    final bytes = _generateWinFanfareWav();
    await _playBytes(bytes);
  }

  /// Phát nốt ngũ cung đơn lẻ (cho Pet tương tác chạm, nhận int index hoặc String tên nốt)
  Future<void> playNote(dynamic note) async {
    if (note is int) {
      await playPetJump(comboIndex: note);
    } else if (note is String) {
      const map = {
        'C4': 0, 'D4': 1, 'E4': 2, 'G4': 3, 'A4': 4,
        'C5': 5, 'D5': 6, 'E5': 7, 'G5': 8, 'C6': 9,
      };
      await playPetJump(comboIndex: map[note] ?? 5);
    } else {
      await playPetJump(comboIndex: 0);
    }
  }

  /// Tiếng kèn chiến thắng (alias cho playWinFanfare)
  Future<void> playFanfare() async {
    await playWinFanfare();
  }

  Future<void> _playBytes(Uint8List bytes) async {
    try {
      await _player.stop();
      await _player.play(BytesSource(bytes));
    } catch (_) {
      // Bỏ qua lỗi phát âm thanh trên một số thiết bị không có channel
    }
  }

  // --- CÁC HÀM TẠO SÓNG ÂM THANH (WAV GENERATORS) ---

  /// Tạo âm thanh Marimba/Kalimba: Sóng sin cơ bản + họa âm bậc 2 suy giảm nhanh
  Uint8List _generateMarimbaNoteWav(double freq, {int durationMs = 220}) {
    final numSamples = (kSampleRate * durationMs / 1000).round();
    final pcmSamples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / kSampleRate;
      final envelope = math.exp(-t * 14.0); // Suy giảm theo hàm mũ mô phỏng gõ phím gỗ

      // Âm cơ bản + họa âm bậc 2
      final wave = 0.75 * math.sin(2 * math.pi * freq * t) +
          0.25 * math.sin(2 * math.pi * (freq * 2.0) * t);

      final sample = (wave * envelope * 24000).clamp(-32767, 32767).toInt();
      pcmSamples[i] = sample;
    }

    return _createWavContainer(pcmSamples);
  }

  /// Tạo tiếng "Bộp" đàn hồi: Tần số quét nhanh từ 260Hz xuống 65Hz
  Uint8List _generateBlockDropWav() {
    const durationMs = 120;
    final numSamples = (kSampleRate * durationMs / 1000).round();
    final pcmSamples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / kSampleRate;
      final progress = i / numSamples;
      final freq = 260.0 * (1.0 - progress * 0.75); // Quét tần số xuống
      final envelope = math.exp(-t * 22.0);

      final wave = math.sin(2 * math.pi * freq * t);
      pcmSamples[i] = (wave * envelope * 26000).clamp(-32767, 32767).toInt();
    }

    return _createWavContainer(pcmSamples);
  }

  /// Tạo tiếng còi xe "Bim Bim!": 2 xung hài âm 698Hz + 880Hz
  Uint8List _generateBusHornWav() {
    const durationMs = 380;
    final numSamples = (kSampleRate * durationMs / 1000).round();
    final pcmSamples = Int16List(numSamples);

    final beep1End = (numSamples * 0.38).round();
    final pauseEnd = (numSamples * 0.52).round();

    for (int i = 0; i < numSamples; i++) {
      if (i > beep1End && i < pauseEnd) {
        pcmSamples[i] = 0;
        continue;
      }

      final t = i / kSampleRate;
      final wave = 0.5 * math.sin(2 * math.pi * 698.46 * t) +
          0.5 * math.sin(2 * math.pi * 880.00 * t);
      pcmSamples[i] = (wave * 20000).clamp(-32767, 32767).toInt();
    }

    return _createWavContainer(pcmSamples);
  }

  /// Tạo tiếng Búa đập nổ 3x3: Nhiễu trắng nén + sóng trầm sub-bass 50Hz
  Uint8List _generateHammerSmashWav() {
    const durationMs = 280;
    final numSamples = (kSampleRate * durationMs / 1000).round();
    final pcmSamples = Int16List(numSamples);
    final random = math.Random();

    for (int i = 0; i < numSamples; i++) {
      final t = i / kSampleRate;
      final envelope = math.exp(-t * 12.0);
      final noise = (random.nextDouble() * 2.0 - 1.0) * 0.5;
      final boom = math.sin(2 * math.pi * (120.0 - t * 200.0).clamp(40.0, 120.0) * t);

      final combined = (noise + boom) * envelope;
      pcmSamples[i] = (combined * 26000).clamp(-32767, 32767).toInt();
    }

    return _createWavContainer(pcmSamples);
  }

  /// Tạo tiếng La Bàn Gió xoay: Sóng sin quét tần số vút lên
  Uint8List _generateWindCompassWav() {
    const durationMs = 250;
    final numSamples = (kSampleRate * durationMs / 1000).round();
    final pcmSamples = Int16List(numSamples);

    for (int i = 0; i < numSamples; i++) {
      final t = i / kSampleRate;
      final progress = i / numSamples;
      final freq = 320.0 + math.sin(progress * math.pi) * 380.0;
      final envelope = math.sin(progress * math.pi);

      final wave = math.sin(2 * math.pi * freq * t);
      pcmSamples[i] = (wave * envelope * 18000).clamp(-32767, 32767).toInt();
    }

    return _createWavContainer(pcmSamples);
  }

  /// Tạo đoạn nhạc thắng màn: Hợp âm C4 -> E4 -> G4 -> C5
  Uint8List _generateWinFanfareWav() {
    const durationMs = 600;
    final numSamples = (kSampleRate * durationMs / 1000).round();
    final pcmSamples = Int16List(numSamples);

    final chordNotes = [261.63, 329.63, 392.00, 523.25];

    for (int i = 0; i < numSamples; i++) {
      final t = i / kSampleRate;
      final noteSection = ((i / numSamples) * chordNotes.length).floor().clamp(0, chordNotes.length - 1);
      final freq = chordNotes[noteSection];
      final envelope = math.exp(-(t % 0.15) * 10.0);

      final wave = math.sin(2 * math.pi * freq * t);
      pcmSamples[i] = (wave * envelope * 22000).clamp(-32767, 32767).toInt();
    }

    return _createWavContainer(pcmSamples);
  }

  /// Đóng gói dữ liệu mẫu PCM 16-bit vào Header WAV chuẩn 44 bytes
  Uint8List _createWavContainer(Int16List pcmSamples) {
    final int dataSize = pcmSamples.length * 2;
    final int fileSize = 44 + dataSize;
    final byteData = ByteData(fileSize);

    // 1. "RIFF" chunk descriptor
    byteData.setUint8(0, 0x52); // 'R'
    byteData.setUint8(1, 0x49); // 'I'
    byteData.setUint8(2, 0x46); // 'F'
    byteData.setUint8(3, 0x46); // 'F'
    byteData.setUint32(4, fileSize - 8, Endian.little);
    byteData.setUint8(8, 0x57);  // 'W'
    byteData.setUint8(9, 0x41);  // 'A'
    byteData.setUint8(10, 0x56); // 'V'
    byteData.setUint8(11, 0x45); // 'E'

    // 2. "fmt " sub-chunk
    byteData.setUint8(12, 0x66); // 'f'
    byteData.setUint8(13, 0x6D); // 'm'
    byteData.setUint8(14, 0x74); // 't'
    byteData.setUint8(15, 0x20); // ' '
    byteData.setUint32(16, 16, Endian.little); // Subchunk1Size = 16 for PCM
    byteData.setUint16(20, 1, Endian.little);  // AudioFormat = 1 (PCM)
    byteData.setUint16(22, 1, Endian.little);  // NumChannels = 1 (Mono)
    byteData.setUint32(24, kSampleRate, Endian.little); // SampleRate
    byteData.setUint32(28, kSampleRate * 2, Endian.little); // ByteRate = SampleRate * NumChannels * BitsPerSample/8
    byteData.setUint16(32, 2, Endian.little); // BlockAlign = NumChannels * BitsPerSample/8
    byteData.setUint16(34, 16, Endian.little); // BitsPerSample = 16

    // 3. "data" sub-chunk
    byteData.setUint8(36, 0x64); // 'd'
    byteData.setUint8(37, 0x61); // 'a'
    byteData.setUint8(38, 0x74); // 't'
    byteData.setUint8(39, 0x61); // 'a'
    byteData.setUint32(40, dataSize, Endian.little);

    // 4. Ghi các mẫu PCM
    int offset = 44;
    for (int i = 0; i < pcmSamples.length; i++) {
      byteData.setInt16(offset, pcmSamples[i], Endian.little);
      offset += 2;
    }

    return byteData.buffer.asUint8List();
  }
}

