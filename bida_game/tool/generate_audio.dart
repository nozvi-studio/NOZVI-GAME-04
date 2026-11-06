// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

void main() async {
  final outDir = Directory('assets/audio');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  print('Generating game sound effects and BGM...');

  // 1. Ball hit (phenolic resin collision)
  final ballHit = generateBallHit();
  File('${outDir.path}/ball_hit.wav').writeAsBytesSync(ballHit);
  print('Saved ball_hit.wav (${ballHit.length} bytes)');

  // 2. Rail hit (cushion bounce)
  final railHit = generateRailHit();
  File('${outDir.path}/rail_hit.wav').writeAsBytesSync(railHit);
  print('Saved rail_hit.wav (${railHit.length} bytes)');

  // 3. Pocket drop (ball sinking into leather pocket cup)
  final pocket = generatePocket();
  File('${outDir.path}/pocket.wav').writeAsBytesSync(pocket);
  print('Saved pocket.wav (${pocket.length} bytes)');

  // 4. Cue stroke hit
  final cueHit = generateCueHit();
  File('${outDir.path}/cue_hit.wav').writeAsBytesSync(cueHit);
  print('Saved cue_hit.wav (${cueHit.length} bytes)');

  // 5. Combo celebration chime fanfare
  final combo = generateCombo();
  File('${outDir.path}/combo.wav').writeAsBytesSync(combo);
  print('Saved combo.wav (${combo.length} bytes)');

  // 6. Chill lounge / jazz background music loop
  final bgm = generateBgm();
  File('${outDir.path}/bgm.wav').writeAsBytesSync(bgm);
  print('Saved bgm.wav (${bgm.length} bytes)');

  print('All audio assets successfully generated!');
}

Uint8List buildWavHeader({
  required int numChannels,
  required int sampleRate,
  required int numSamples,
}) {
  const bitsPerSample = 16;
  final bytesPerSample = bitsPerSample ~/ 8;
  final dataSize = numSamples * numChannels * bytesPerSample;
  final fileSize = 36 + dataSize;

  final header = Uint8List(44);
  final b = ByteData.sublistView(header);

  // "RIFF"
  header.setRange(0, 4, 'RIFF'.codeUnits);
  b.setUint32(4, fileSize, Endian.little);
  // "WAVE"
  header.setRange(8, 12, 'WAVE'.codeUnits);
  // "fmt "
  header.setRange(12, 16, 'fmt '.codeUnits);
  b.setUint32(16, 16, Endian.little); // chunk size
  b.setUint16(20, 1, Endian.little); // PCM
  b.setUint16(22, numChannels, Endian.little);
  b.setUint32(24, sampleRate, Endian.little);
  b.setUint32(28, sampleRate * numChannels * bytesPerSample, Endian.little);
  b.setUint16(32, numChannels * bytesPerSample, Endian.little);
  b.setUint16(34, bitsPerSample, Endian.little);
  // "data"
  header.setRange(36, 40, 'data'.codeUnits);
  b.setUint32(40, dataSize, Endian.little);

  return header;
}

Uint8List generateBallHit() {
  const sampleRate = 44100;
  // 38ms - cực kỳ giòn, đanh, dứt khoát như va chạm bi thực tế, không bị ngân vang kiểu kim loại/thủy tinh
  const duration = 0.038;
  final numSamples = (sampleRate * duration).toInt();
  final samples = Float64List(numSamples);

  final rand = math.Random(777);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;

    // 1. Xung áp lực va chạm tức thì (0 đến 1.0ms): âm thanh gõ cực bén
    double transient = 0.0;
    if (t < 0.0010) {
      final envT = math.sin((t / 0.0010) * math.pi);
      final pulse = math.sin((t / 0.0010) * math.pi * 2.0);
      final noise = (rand.nextDouble() * 2.0 - 1.0);
      transient = (pulse * 0.85 + noise * 0.50) * envT;
    }

    // 2. Tiếng "tách" tần số cao tại điểm biến dạng đàn hồi
    final dSnap = math.exp(-t / 0.0022); // Tắt trong 2.2ms
    final snap = math.sin(2.0 * math.pi * 4400.0 * t) * dSnap * 0.45;

    // 3. Dao động riêng của nhựa Phenolic Aramith nguyên khối tạo tiếng "CẠCH"
    final d1 = math.exp(-t / 0.0055); // Tắt trong 5.5ms - đanh và khô ráo
    final m1 = math.sin(2.0 * math.pi * 2180.0 * t) * d1 * 0.70;

    final d2 = math.exp(-t / 0.0040); // 4ms
    final m2 = math.sin(2.0 * math.pi * 3350.0 * t) * d2 * 0.40;

    // 4. Độ nặng khối lượng của bi 170g
    final d3 = math.exp(-t / 0.0070); // 7ms
    final m3 = math.sin(2.0 * math.pi * 1520.0 * t) * d3 * 0.35;

    // 5. Thump quán tính tiếp xúc
    final d4 = math.exp(-t / 0.0045);
    final m4 = math.sin(2.0 * math.pi * 780.0 * t) * d4 * 0.30;

    var s = transient + snap + m1 + m2 + m3 + m4;

    // Triệt tiêu êm dịu 4ms cuối để triệt tiêu hoàn toàn nhiễu đuôi
    final remain = duration - t;
    if (remain < 0.004) {
      s *= (remain / 0.004);
    }

    samples[i] = s;
  }

  return packMonoWav(samples, sampleRate);
}

Uint8List generateRailHit() {
  const sampleRate = 44100;
  const duration = 0.13;
  final numSamples = (sampleRate * duration).toInt();
  final samples = Float64List(numSamples);
  final rand = math.Random(1337);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;

    // Muffled cloth & rubber friction
    double cloth = 0.0;
    if (t < 0.025) {
      final noise = (rand.nextDouble() * 2.0 - 1.0);
      final env = math.sin((t / 0.025) * math.pi);
      cloth = noise * env * 0.35;
    }

    // Low rubber thud
    final d1 = math.exp(-t / 0.038);
    final m1 = math.sin(2.0 * math.pi * 145.0 * t) * d1 * 0.75;

    final d2 = math.exp(-t / 0.025);
    final m2 = math.sin(2.0 * math.pi * 225.0 * t) * d2 * 0.40;

    samples[i] = cloth + m1 + m2;
  }

  return packMonoWav(samples, sampleRate);
}

Uint8List generatePocket() {
  const sampleRate = 44100;
  const duration = 0.28;
  final numSamples = (sampleRate * duration).toInt();
  final samples = Float64List(numSamples);
  final rand = math.Random(999);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;

    // Phase 1: mouth slide (0 - 35ms)
    double slide = 0.0;
    if (t < 0.035) {
      final noise = (rand.nextDouble() * 2.0 - 1.0);
      final env = math.sin((t / 0.035) * math.pi);
      slide = noise * env * 0.30;
    }

    // Phase 2: leather cup deep drop impact (starts at 25ms)
    double drop = 0.0;
    if (t >= 0.025) {
      final td = t - 0.025;
      final d1 = math.exp(-td / 0.058);
      final m1 = math.sin(2.0 * math.pi * 96.0 * td) * d1 * 0.85;

      final d2 = math.exp(-td / 0.038);
      final m2 = math.sin(2.0 * math.pi * 165.0 * td) * d2 * 0.45;

      final d3 = math.exp(-td / 0.020);
      final m3 = math.sin(2.0 * math.pi * 280.0 * td) * d3 * 0.25;
      drop = m1 + m2 + m3;
    }

    samples[i] = slide + drop;
  }

  return packMonoWav(samples, sampleRate);
}

Uint8List generateCueHit() {
  const sampleRate = 44100;
  const duration = 0.09;
  final numSamples = (sampleRate * duration).toInt();
  final samples = Float64List(numSamples);
  final rand = math.Random(555);

  for (int i = 0; i < numSamples; i++) {
    final t = i / sampleRate;

    // Leather chalk snap
    double chalk = 0.0;
    if (t < 0.008) {
      final noise = (rand.nextDouble() * 2.0 - 1.0);
      final env = math.sin((t / 0.008) * math.pi);
      chalk = noise * env * 0.65;
    }

    // Wooden shaft impulse
    final d1 = math.exp(-t / 0.025);
    final m1 = math.sin(2.0 * math.pi * 680.0 * t) * d1 * 0.55;

    final d2 = math.exp(-t / 0.015);
    final m2 = math.sin(2.0 * math.pi * 1150.0 * t) * d2 * 0.35;

    samples[i] = chalk + m1 + m2;
  }

  return packMonoWav(samples, sampleRate);
}

Uint8List generateCombo() {
  const sampleRate = 44100;
  const duration = 0.85;
  final numSamples = (sampleRate * duration).toInt();
  final leftSamples = Float64List(numSamples);
  final rightSamples = Float64List(numSamples);

  // Arpeggio notes: C5, E5, G5, C6 (Hz)
  final notes = [
    {'time': 0.00, 'freq': 523.25, 'pan': -0.3},
    {'time': 0.09, 'freq': 659.25, 'pan': 0.3},
    {'time': 0.18, 'freq': 783.99, 'pan': -0.2},
    {'time': 0.27, 'freq': 1046.50, 'pan': 0.0},
  ];

  for (final note in notes) {
    final startTime = note['time'] as double;
    final freq = note['freq'] as double;
    final pan = note['pan'] as double;
    final startIndex = (startTime * sampleRate).toInt();

    final leftGain = (1.0 - pan).clamp(0.0, 1.0);
    final rightGain = (1.0 + pan).clamp(0.0, 1.0);

    for (int i = startIndex; i < numSamples; i++) {
      final t = (i - startIndex) / sampleRate;
      final decay = math.exp(-t / 0.22);

      // Fundamental + shimmer harmonics
      final f0 = math.sin(2.0 * math.pi * freq * t) * 0.50;
      final f1 = math.sin(2.0 * math.pi * (freq * 2.0) * t) * 0.25;
      final f2 = math.sin(2.0 * math.pi * (freq * 3.0) * t) * 0.12;
      final f3 = math.sin(2.0 * math.pi * (freq * 4.0) * t) * 0.06;

      final val = (f0 + f1 + f2 + f3) * decay;
      leftSamples[i] += val * leftGain;
      rightSamples[i] += val * rightGain;
    }
  }

  return packStereoWav(leftSamples, rightSamples, sampleRate);
}

Uint8List generateBgm() {
  const sampleRate = 44100;
  // 72 BPM, 4 beats per bar, 8 bars: duration = 8 * 4 * (60 / 72) = 26.6667 seconds
  const bpm = 72.0;
  const beatSec = 60.0 / bpm;
  const barSec = beatSec * 4.0;
  const totalBars = 8;
  const duration = barSec * totalBars;
  final numSamples = (sampleRate * duration).toInt();

  final leftSamples = Float64List(numSamples);
  final rightSamples = Float64List(numSamples);

  // 8-bar Jazz Lounge Chords (frequencies in Hz)
  // Bar 0: Cmaj9  (C3, G3, B3, D4, E4)
  // Bar 1: Am9    (A2, E3, G3, C4, B3)
  // Bar 2: Dm9    (D3, A3, C4, F4, E4)
  // Bar 3: G13    (G2, F3, B3, E4, A4)
  // Bar 4: Em9    (E3, B3, D4, G4, F#4)
  // Bar 5: A7b13  (A2, G3, C#4, F4)
  // Bar 6: Dm9    (D3, A3, C4, E4, F4)
  // Bar 7: G7     (G2, F3, B3, D4)
  final chords = [
    [130.81, 196.00, 246.94, 293.66, 329.63], // Cmaj9
    [110.00, 164.81, 196.00, 261.63, 246.94], // Am9
    [146.83, 220.00, 261.63, 349.23, 329.63], // Dm9
    [98.00,  174.61, 246.94, 329.63, 440.00], // G13
    [164.81, 246.94, 293.66, 392.00, 369.99], // Em9
    [110.00, 196.00, 277.18, 349.23],         // A7b13
    [146.83, 220.00, 261.63, 329.63, 349.23], // Dm9
    [98.00,  174.61, 246.94, 293.66],         // G7
  ];

  // Upright Bass roots (Hz)
  final bassNotes = [
    65.41, // C2
    55.00, // A1
    73.42, // D2
    49.00, // G1
    82.41, // E2
    55.00, // A1
    73.42, // D2
    49.00, // G1
  ];

  final rand = math.Random(777);

  // Synthesize Electric Piano / Rhodes Chords & Bass & Percussion
  for (int bar = 0; bar < totalBars; bar++) {
    final barStart = bar * barSec;
    final chord = chords[bar];
    final bassFreq = bassNotes[bar];

    // Chords on beat 0 and beat 2.5 (syncopated jazz comping)
    final chordHits = [0.0, 2.5 * beatSec];
    for (final hitOffset in chordHits) {
      final chordStart = barStart + hitOffset;
      final chordStartIndex = (chordStart * sampleRate).toInt();
      final chordLen = (barSec * 0.95 * sampleRate).toInt();

      for (int noteIdx = 0; noteIdx < chord.length; noteIdx++) {
        final freq = chord[noteIdx];
        final pan = -0.4 + (noteIdx / (chord.length - 1)) * 0.8;
        final leftGain = (1.0 - pan) * 0.18;
        final rightGain = (1.0 + pan) * 0.18;

        for (int i = 0; i < chordLen; i++) {
          final sampleIdx = (chordStartIndex + i) % numSamples;
          final t = i / sampleRate;

          // Warm Rhodes electric piano tone: fundamental + mellow 2nd & 3rd harmonics + vibrato
          final vibrato = math.sin(2.0 * math.pi * 4.5 * t) * 0.003;
          final fMod = freq * (1.0 + vibrato);

          final decay = math.exp(-t / 1.6);
          final h1 = math.sin(2.0 * math.pi * fMod * t) * 0.65;
          final h2 = math.sin(2.0 * math.pi * (fMod * 2.0) * t) * 0.25 * math.exp(-t / 0.8);
          final h3 = math.sin(2.0 * math.pi * (fMod * 3.0) * t) * 0.10 * math.exp(-t / 0.4);

          final val = (h1 + h2 + h3) * decay;
          leftSamples[sampleIdx] += val * leftGain;
          rightSamples[sampleIdx] += val * rightGain;
        }
      }
    }

    // Walking / Upright Bass on beat 0 and beat 2
    final bassHits = [
      {'offset': 0.0, 'freq': bassFreq},
      {'offset': 1.0 * beatSec, 'freq': bassFreq * 1.5}, // Fifth
      {'offset': 2.0 * beatSec, 'freq': bassFreq},
      {'offset': 3.0 * beatSec, 'freq': bassFreq * 1.122}, // Passing note
    ];

    for (final bh in bassHits) {
      final bOffset = bh['offset'] as double;
      final bFreq = bh['freq'] as double;
      final bStart = barStart + bOffset;
      final bStartIndex = (bStart * sampleRate).toInt();
      final bLen = (beatSec * 0.95 * sampleRate).toInt();

      for (int i = 0; i < bLen; i++) {
        final sampleIdx = (bStartIndex + i) % numSamples;
        final t = i / sampleRate;
        final decay = math.exp(-t / 0.65);

        // Warm rounded sub-bass + wood body
        final b1 = math.sin(2.0 * math.pi * bFreq * t) * 0.55;
        final b2 = math.sin(2.0 * math.pi * (bFreq * 2.0) * t) * 0.18 * math.exp(-t / 0.35);

        final val = (b1 + b2) * decay * 0.38;
        leftSamples[sampleIdx] += val;
        rightSamples[sampleIdx] += val;
      }
    }
  }

  // Soft jazz brush drums / ride cymbal pattern across all beats
  final totalBeats = (totalBars * 4);
  for (int b = 0; b < totalBeats; b++) {
    final beatTime = b * beatSec;

    // Ride cymbal tick on beat and upbeat swing (triplet swing feel)
    final cymbalHits = [beatTime, beatTime + beatSec * 0.667];
    for (final cTime in cymbalHits) {
      final cIdx = (cTime * sampleRate).toInt();
      final cLen = (0.08 * sampleRate).toInt();
      for (int i = 0; i < cLen; i++) {
        final sampleIdx = (cIdx + i) % numSamples;
        final t = i / sampleRate;
        final noise = (rand.nextDouble() * 2.0 - 1.0);
        final decay = math.exp(-t / 0.028);
        final val = noise * decay * 0.035;
        leftSamples[sampleIdx] += val * 0.7;
        rightSamples[sampleIdx] += val * 1.0;
      }
    }

    // Soft rimshot / brush snare on beat 2 and 4 (indices 1, 3 in 0-indexed bar)
    if (b % 2 == 1) {
      final sIdx = (beatTime * sampleRate).toInt();
      final sLen = (0.10 * sampleRate).toInt();
      for (int i = 0; i < sLen; i++) {
        final sampleIdx = (sIdx + i) % numSamples;
        final t = i / sampleRate;
        final noise = (rand.nextDouble() * 2.0 - 1.0);
        final decay = math.exp(-t / 0.035);
        final ton = math.sin(2.0 * math.pi * 320.0 * t) * math.exp(-t / 0.015) * 0.2;
        final val = (noise * 0.8 + ton) * decay * 0.055;
        leftSamples[sampleIdx] += val * 0.9;
        rightSamples[sampleIdx] += val * 0.8;
      }
    }
  }

  // Soft vinyl warmth / tape hiss in background
  for (int i = 0; i < numSamples; i++) {
    final hiss = (rand.nextDouble() * 2.0 - 1.0) * 0.006;
    leftSamples[i] += hiss;
    rightSamples[i] += hiss;
  }

  return packStereoWav(leftSamples, rightSamples, sampleRate);
}

Uint8List packMonoWav(Float64List samples, int sampleRate) {
  // Normalize
  double maxVal = 0.0;
  for (final s in samples) {
    if (s.abs() > maxVal) maxVal = s.abs();
  }
  final scale = maxVal > 0.0 ? (0.92 / maxVal) : 1.0;

  final header = buildWavHeader(
    numChannels: 1,
    sampleRate: sampleRate,
    numSamples: samples.length,
  );

  final byteBuffer = Uint8List(header.length + samples.length * 2);
  byteBuffer.setRange(0, header.length, header);
  final bd = ByteData.sublistView(byteBuffer, header.length);

  for (int i = 0; i < samples.length; i++) {
    final v = (samples[i] * scale).clamp(-1.0, 1.0);
    final intSample = (v * 32767).toInt();
    bd.setInt16(i * 2, intSample, Endian.little);
  }

  return byteBuffer;
}

Uint8List packStereoWav(Float64List left, Float64List right, int sampleRate) {
  assert(left.length == right.length);
  final numSamples = left.length;

  double maxVal = 0.0;
  for (int i = 0; i < numSamples; i++) {
    if (left[i].abs() > maxVal) maxVal = left[i].abs();
    if (right[i].abs() > maxVal) maxVal = right[i].abs();
  }
  final scale = maxVal > 0.0 ? (0.88 / maxVal) : 1.0;

  final header = buildWavHeader(
    numChannels: 2,
    sampleRate: sampleRate,
    numSamples: numSamples,
  );

  final byteBuffer = Uint8List(header.length + numSamples * 4);
  byteBuffer.setRange(0, header.length, header);
  final bd = ByteData.sublistView(byteBuffer, header.length);

  for (int i = 0; i < numSamples; i++) {
    final lv = (left[i] * scale).clamp(-1.0, 1.0);
    final rv = (right[i] * scale).clamp(-1.0, 1.0);
    bd.setInt16(i * 4, (lv * 32767).toInt(), Endian.little);
    bd.setInt16(i * 4 + 2, (rv * 32767).toInt(), Endian.little);
  }

  return byteBuffer;
}
