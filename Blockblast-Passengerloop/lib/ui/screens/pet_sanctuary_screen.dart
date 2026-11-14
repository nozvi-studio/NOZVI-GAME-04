import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/enums.dart';
import '../../models/bus_data.dart';
import '../../core/pentatonic_audio_synth.dart';
import '../../logic/player_economy_service.dart';

/// Dịch vụ lưu trữ và tính toán Khu Nghỉ Dưỡng Thú Cưng (Pet Sanctuary)
class PetSanctuaryService extends ChangeNotifier {
  static final PetSanctuaryService instance = PetSanctuaryService._internal();
  static const String _prefRescuedPrefix = 'sanctuary_rescued_';
  static const String _prefCoinsKey = 'sanctuary_coins';
  static const String _prefUnlockedZonesKey = 'sanctuary_unlocked_zones';
  static const String _prefLastHarvestKey = 'sanctuary_last_harvest';

  PetSanctuaryService._internal();

  final Map<PetColor, int> _rescuedCounts = {
    for (final color in PetColor.values) color: 0,
  };

  final Set<String> _unlockedZones = {'corgi_beach'};
  DateTime _lastHarvestTime = DateTime.now();
  bool _isLoaded = false;

  Map<PetColor, int> get rescuedCounts => Map.unmodifiable(_rescuedCounts);
  int get coins => PlayerEconomyService.instance.coins;
  Set<String> get unlockedZones => Set.unmodifiable(_unlockedZones);
  bool get isLoaded => _isLoaded;

  int get totalRescuedCount => _rescuedCounts.values.fold(0, (sum, count) => sum + count);

  /// Số xu thụ động (Idle Coins) tích lũy theo thời gian thực:
  /// Mỗi 10 giây mỗi thú cưng sinh ra 1 xu, tối đa tích lũy 500 xu khi vắng mặt
  int get pendingIdleCoins {
    final petCount = math.max(1, totalRescuedCount);
    final elapsedSec = DateTime.now().difference(_lastHarvestTime).inSeconds;
    final generated = (elapsedSec ~/ 10) * petCount;
    return generated.clamp(0, 500);
  }

  Future<void> init() async {
    if (_isLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final color in PetColor.values) {
        _rescuedCounts[color] = prefs.getInt('$_prefRescuedPrefix${color.name}') ?? 0;
      }
      final zones = prefs.getStringList(_prefUnlockedZonesKey);
      if (zones != null) {
        _unlockedZones.addAll(zones);
      }
      final harvestMs = prefs.getInt(_prefLastHarvestKey);
      if (harvestMs != null) {
        _lastHarvestTime = DateTime.fromMillisecondsSinceEpoch(harvestMs);
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('PetSanctuaryService init error: $e');
    }
  }

  /// Ghi nhận mỗi khi một chuyến xe buýt lăn bánh trong trận đấu
  Future<void> recordBusDeparted(BusData bus) async {
    final petColor = bus.color;
    final passengers = math.max(1, bus.currentPassengers);
    _rescuedCounts[petColor] = (_rescuedCounts[petColor] ?? 0) + passengers;

    await PlayerEconomyService.instance.addRewards(coinsDelta: 25);
    notifyListeners();
    await _save();
  }

  /// Thu hoạch xu thụ động
  Future<int> harvestIdleCoins() async {
    final reward = pendingIdleCoins;
    if (reward <= 0) return 0;
    await PlayerEconomyService.instance.addRewards(coinsDelta: reward);
    _lastHarvestTime = DateTime.now();
    notifyListeners();
    await _save();
    return reward;
  }

  /// Mở khóa khu vực trên đảo bằng xu
  Future<bool> unlockZone(String zoneId, int cost) async {
    final currentCoins = PlayerEconomyService.instance.coins;
    if (currentCoins < cost || _unlockedZones.contains(zoneId)) return false;
    await PlayerEconomyService.instance.addRewards(coinsDelta: -cost);
    _unlockedZones.add(zoneId);
    notifyListeners();
    await _save();
    return true;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final color in PetColor.values) {
        await prefs.setInt('$_prefRescuedPrefix${color.name}', _rescuedCounts[color] ?? 0);
      }
      await prefs.setInt(_prefCoinsKey, PlayerEconomyService.instance.coins);
      await prefs.setStringList(_prefUnlockedZonesKey, _unlockedZones.toList());
      await prefs.setInt(_prefLastHarvestKey, _lastHarvestTime.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('PetSanctuaryService save error: $e');
    }
  }
}

class WanderingPet {
  final PetColor color;
  Offset position;
  Offset velocity;
  double phase;
  double hopHeight;

  WanderingPet({
    required this.color,
    required this.position,
    required this.velocity,
    required this.phase,
    this.hopHeight = 0.0,
  });
}

class FloatingHeart {
  final Offset position;
  double progress; // 0.0 -> 1.0

  FloatingHeart({required this.position, this.progress = 0.0});
}

/// Màn hình Khu Nghỉ Dưỡng Thú Cưng 2.5D
class PetSanctuaryScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const PetSanctuaryScreen({super.key, this.onBack});

  @override
  State<PetSanctuaryScreen> createState() => _PetSanctuaryScreenState();
}

class _PetSanctuaryScreenState extends State<PetSanctuaryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ticker;
  final List<WanderingPet> _pets = [];
  final List<FloatingHeart> _hearts = [];
  final math.Random _rng = math.Random();
  double _elapsed = 0.0;

  @override
  void initState() {
    super.initState();
    PetSanctuaryService.instance.init().then((_) {
      if (mounted) _spawnWanderingPets();
    });

    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onTick)..repeat();
  }

  void _spawnWanderingPets() {
    _pets.clear();
    final counts = PetSanctuaryService.instance.rescuedCounts;
    // Tạo ít nhất 1 thú cưng mỗi màu hoặc theo số lượng đã cứu (tối đa 15 thú cưng trên đảo)
    for (final color in PetColor.values) {
      final int numToSpawn = math.max(1, math.min(3, counts[color] ?? 0));
      for (int i = 0; i < numToSpawn; i++) {
        _pets.add(WanderingPet(
          color: color,
          position: Offset(
            80.0 + _rng.nextDouble() * 200.0,
            240.0 + _rng.nextDouble() * 220.0,
          ),
          velocity: Offset(
            (_rng.nextDouble() - 0.5) * 24.0,
            (_rng.nextDouble() - 0.5) * 18.0,
          ),
          phase: _rng.nextDouble() * math.pi * 2,
        ));
      }
    }
  }

  void _onTick() {
    setState(() {
      _elapsed += 0.016;

      // Cập nhật vị trí thú cưng đi dạo & nhún nhảy
      for (final pet in _pets) {
        pet.position += pet.velocity * 0.016;
        pet.hopHeight = (math.sin(_elapsed * 5.0 + pet.phase) * 6.0).abs();

        // Nảy lại khi chạm rìa đảo
        if (pet.position.dx < 40 || pet.position.dx > 340) {
          pet.velocity = Offset(-pet.velocity.dx, pet.velocity.dy);
        }
        if (pet.position.dy < 180 || pet.position.dy > 500) {
          pet.velocity = Offset(pet.velocity.dx, -pet.velocity.dy);
        }
      }

      // Cập nhật trái tim bay lên
      for (final heart in _hearts) {
        heart.progress += 0.024;
      }
      _hearts.removeWhere((h) => h.progress >= 1.0);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _handleTapIsland(TapUpDetails details) {
    final pos = details.localPosition;
    // Kiểm tra chạm vào thú cưng
    for (final pet in _pets) {
      if ((pet.position - pos).distance <= 28.0) {
        // Sinh trái tim bay
        _hearts.add(FloatingHeart(position: pet.position + const Offset(0, -16)));
        // Phát âm thanh Ngũ cung vui tươi
        PentatonicAudioSynth.instance.playNote('E5');
        // Cho bé thú nhảy cao phấn khích
        pet.velocity = Offset((_rng.nextDouble() - 0.5) * 50.0, -40.0);
        return;
      }
    }

    // Nếu chạm vị trí khác trên đảo, sinh trái tim nhỏ tại điểm chạm
    _hearts.add(FloatingHeart(position: pos));
    PentatonicAudioSynth.instance.playNote('C5');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PetSanctuaryService.instance,
      builder: (context, _) {
        final service = PetSanctuaryService.instance;
        final pendingCoins = service.pendingIdleCoins;

        return Scaffold(
          backgroundColor: const Color(0xFF001E28),
          body: SafeArea(
            child: Stack(
              children: [
                // 1. Canvas Đảo Thú Cưng 2.5D
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: _handleTapIsland,
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: SanctuaryIslandPainter(
                      pets: _pets,
                      hearts: _hearts,
                      unlockedZones: service.unlockedZones,
                    ),
                  ),
                ),

                // 2. Thanh HUD trên đỉnh: Nút quay lại, Tiền vàng, Thu hoạch xu
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Row(
                    children: [
                      if (widget.onBack != null)
                        InkWell(
                          onTap: widget.onBack,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xDD1E252B),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Huy hiệu Xu
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xEE1E252B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('💰', style: TextStyle(fontSize: 15)),
                            const SizedBox(width: 6),
                            Text(
                              '${service.coins}',
                              style: const TextStyle(
                                color: Color(0xFFFFD54F),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Nút Thu hoạch Xu thụ động (Idle Coins)
                      Flexible(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: pendingCoins > 0
                                ? () async {
                                    final gained = await service.harvestIdleCoins();
                                    if (context.mounted && gained > 0) {
                                      PentatonicAudioSynth.instance.playFanfare();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('🎉 Đã thu hoạch +$gained Xu thụ động từ đảo!'),
                                          backgroundColor: const Color(0xFF2E7D32),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.stars, color: Colors.amber, size: 16),
                            label: Text(
                              pendingCoins > 0
                                  ? 'Thu hoạch Xu thụ động (+$pendingCoins)'
                                  : 'Thu hoạch Xu thụ động',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00897B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 3. Thanh Thống kê Thú Cưng Giải Cứu
                Positioned(
                  top: 64,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xCC0D1B2A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: PetColor.values.map((c) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(c.emoji, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              '${service.rescuedCounts[c] ?? 0}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // 4. Thanh mở khóa 3 Khu Vực ở đáy màn hình
                Positioned(
                  bottom: 16,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xF01A222B),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF26A69A), width: 1.5),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '🏝️ KHU NGHỈ DƯỠNG THÚ CƯNG 2.5D',
                          style: TextStyle(
                            color: Color(0xFFFFD180),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _buildZoneCard(
                              title: 'Bãi Biển Corgi',
                              emoji: '🏖️',
                              zoneId: 'corgi_beach',
                              cost: 50,
                              isUnlocked: service.unlockedZones.contains('corgi_beach'),
                              onUnlock: () => service.unlockZone('corgi_beach', 50),
                            ),
                            const SizedBox(width: 8),
                            _buildZoneCard(
                              title: 'Quán Cà Phê Mèo',
                              emoji: '☕',
                              zoneId: 'cat_cafe',
                              cost: 150,
                              isUnlocked: service.unlockedZones.contains('cat_cafe'),
                              onUnlock: () => service.unlockZone('cat_cafe', 150),
                            ),
                            const SizedBox(width: 8),
                            _buildZoneCard(
                              title: 'Hồ Bơi Vịt Vàng',
                              emoji: '🏊',
                              zoneId: 'duck_pool',
                              cost: 300,
                              isUnlocked: service.unlockedZones.contains('duck_pool'),
                              onUnlock: () => service.unlockZone('duck_pool', 300),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildZoneCard({
    required String title,
    required String emoji,
    required String zoneId,
    required int cost,
    required bool isUnlocked,
    required VoidCallback onUnlock,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isUnlocked ? const Color(0xFF1E3A2F) : const Color(0xFF263238),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked ? const Color(0xFF00E676) : Colors.white24,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (isUnlocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Đã Mở', style: TextStyle(color: Color(0xFF00E676), fontSize: 9, fontWeight: FontWeight.bold)),
              )
            else
              InkWell(
                onTap: onUnlock,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Mở $cost 💰',
                    style: const TextStyle(color: Colors.black87, fontSize: 9, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bộ vẽ hòn đảo 2.5D, các khu nghỉ dưỡng và thú cưng đang nhún nhảy
class SanctuaryIslandPainter extends CustomPainter {
  final List<WanderingPet> pets;
  final List<FloatingHeart> hearts;
  final Set<String> unlockedZones;

  SanctuaryIslandPainter({
    required this.pets,
    required this.hearts,
    required this.unlockedZones,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Biển xanh nhiệt đới
    final oceanPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF004D40), Color(0xFF006064), Color(0xFF00838F)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, oceanPaint);

    // Gợn sóng biển nhẹ
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.5), width: size.width * 0.95, height: size.height * 0.65), wavePaint);
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.5), width: size.width * 0.85, height: size.height * 0.55), wavePaint);

    // 2. Khối đảo 2.5D: Vách đá đáy + Bãi cát vàng + Thảm cỏ xanh
    final center = Offset(size.width * 0.5, size.height * 0.46);
    final islandWidth = size.width * 0.88;
    final islandHeight = size.height * 0.50;

    // Vách đá 2.5D đáy đảo
    final cliffRect = Rect.fromCenter(center: center + const Offset(0, 16), width: islandWidth, height: islandHeight);
    canvas.drawOval(cliffRect, Paint()..color = const Color(0xFF3E2723));

    // Bãi cát vàng ven bờ
    final sandRect = Rect.fromCenter(center: center + const Offset(0, 8), width: islandWidth - 8, height: islandHeight - 6);
    canvas.drawOval(sandRect, Paint()..color = const Color(0xFFFFD54F));

    // Thảm cỏ xanh mướt trên đỉnh đảo
    final grassRect = Rect.fromCenter(center: center, width: islandWidth - 28, height: islandHeight - 24);
    canvas.drawOval(grassRect, Paint()..color = const Color(0xFF4CAF50));

    // 3. Vẽ 3 khu nghỉ dưỡng mở khóa
    // Zone 1: Bãi Biển Corgi (Góc trái dưới)
    if (unlockedZones.contains('corgi_beach')) {
      _drawBeachZone(canvas, center + Offset(-islandWidth * 0.25, islandHeight * 0.15));
    }
    // Zone 2: Quán Cà Phê Mèo (Góc phải trên)
    if (unlockedZones.contains('cat_cafe')) {
      _drawCafeZone(canvas, center + Offset(islandWidth * 0.22, -islandHeight * 0.16));
    }
    // Zone 3: Hồ Bơi Vịt Vàng (Góc trái trên)
    if (unlockedZones.contains('duck_pool')) {
      _drawPoolZone(canvas, center + Offset(-islandWidth * 0.20, -islandHeight * 0.14));
    }

    // 4. Vẽ các bé thú cưng nhún nhảy
    for (final pet in pets) {
      _drawWanderingPet(canvas, pet);
    }

    // 5. Vẽ trái tim bay lượn
    for (final heart in hearts) {
      final yOffset = -heart.progress * 42.0;
      final opacity = (1.0 - heart.progress).clamp(0.0, 1.0);
      final heartPos = heart.position + Offset(0, yOffset);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '❤️',
          style: TextStyle(
            fontSize: 16.0 * (1.0 + heart.progress * 0.3),
            color: Colors.red.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, heartPos - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  void _drawBeachZone(Canvas canvas, Offset pos) {
    // Dù bãi biển sọc đỏ trắng
    final umbrellaPaint = Paint()..color = const Color(0xFFFF5252);
    canvas.drawCircle(pos, 16, umbrellaPaint);
    canvas.drawCircle(pos, 8, Paint()..color = Colors.white);
    canvas.drawCircle(pos, 3, Paint()..color = const Color(0xFFFFD54F));
  }

  void _drawCafeZone(Canvas canvas, Offset pos) {
    // Quán cà phê gỗ nhỏ
    final boothRect = Rect.fromCenter(center: pos, width: 34, height: 24);
    canvas.drawRRect(RRect.fromRectAndRadius(boothRect, const Radius.circular(6)), Paint()..color = const Color(0xFF795548));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pos + const Offset(0, -10), width: 38, height: 8), const Radius.circular(4)), Paint()..color = const Color(0xFFFF9800));
  }

  void _drawPoolZone(Canvas canvas, Offset pos) {
    // Hồ bơi nước ngọt tròn xanh biếc
    final poolRect = Rect.fromCenter(center: pos, width: 44, height: 32);
    canvas.drawOval(poolRect, Paint()..color = const Color(0xFF00E5FF));
    canvas.drawOval(poolRect, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0);
    // Vịt vàng phao bơi nhỏ
    canvas.drawCircle(pos, 5, Paint()..color = const Color(0xFFFFEB3B));
  }

  void _drawWanderingPet(Canvas canvas, WanderingPet pet) {
    final petPos = pet.position + Offset(0, -pet.hopHeight);

    // Đổ bóng dưới chân
    canvas.drawOval(
      Rect.fromCenter(center: pet.position + const Offset(0, 8), width: 18, height: 6),
      Paint()..color = Colors.black26,
    );

    // Thân bé thú tròn
    final bodyPaint = Paint()..color = pet.color.primaryColor;
    canvas.drawCircle(petPos, 12, bodyPaint);

    // Khuôn mặt đáng yêu
    final eyePaint = Paint()..color = Colors.black87;
    canvas.drawCircle(petPos + const Offset(-4, -2), 1.6, eyePaint);
    canvas.drawCircle(petPos + const Offset(4, -2), 1.6, eyePaint);
    canvas.drawCircle(petPos + const Offset(0, 2), 1.5, Paint()..color = pet.color.darkColor);
  }

  @override
  bool shouldRepaint(covariant SanctuaryIslandPainter oldDelegate) => true;
}

