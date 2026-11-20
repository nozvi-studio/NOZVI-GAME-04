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

  final Set<String> _unlockedZones = {'corgi_beach', 'cat_cafe', 'duck_pool'};
  DateTime _lastHarvestTime = DateTime.now();
  bool _isLoaded = false;

  Map<PetColor, int> get rescuedCounts => Map.unmodifiable(_rescuedCounts);
  int get coins => PlayerEconomyService.instance.coins;
  Set<String> get unlockedZones => Set.unmodifiable(_unlockedZones);
  bool get isLoaded => _isLoaded;

  int get totalRescuedCount => _rescuedCounts.values.fold(0, (sum, count) => sum + count);

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

  Future<void> recordBusDeparted(BusData bus) async {
    final petColor = bus.color;
    final passengers = math.max(1, bus.currentPassengers);
    _rescuedCounts[petColor] = (_rescuedCounts[petColor] ?? 0) + passengers;

    await PlayerEconomyService.instance.addRewards(coinsDelta: 25);
    notifyListeners();
    await _save();
  }

  Future<int> harvestIdleCoins() async {
    final reward = math.max(25, pendingIdleCoins);
    await PlayerEconomyService.instance.addRewards(coinsDelta: reward);
    _lastHarvestTime = DateTime.now();
    notifyListeners();
    await _save();
    return reward;
  }

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

class FloatingCoinParticle {
  final Offset position;
  final String text;
  double progress; // 0.0 -> 1.0

  FloatingCoinParticle({
    required this.position,
    required this.text,
    this.progress = 0.0,
  });
}

/// Màn hình Đảo Thú Cưng 2.5D (Tab 3: ĐẢO - Sanctuary & Idle)
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
  final List<FloatingCoinParticle> _coinBursts = [];
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
    // Tạo nhóm thú cưng đi dạo trên các khu vực của đảo
    for (final color in PetColor.values) {
      _pets.add(WanderingPet(
        color: color,
        position: Offset(100.0 + _rng.nextDouble() * 160.0, 240.0 + _rng.nextDouble() * 140.0),
        velocity: Offset((_rng.nextDouble() - 0.5) * 20.0, (_rng.nextDouble() - 0.5) * 14.0),
        phase: _rng.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _onTick() {
    setState(() {
      _elapsed += 0.016;

      for (final pet in _pets) {
        pet.position += pet.velocity * 0.016;
        pet.hopHeight = (math.sin(_elapsed * 5.0 + pet.phase) * 5.0).abs();

        if (pet.position.dx < 70 || pet.position.dx > 300) {
          pet.velocity = Offset(-pet.velocity.dx, pet.velocity.dy);
        }
        if (pet.position.dy < 200 || pet.position.dy > 420) {
          pet.velocity = Offset(pet.velocity.dx, -pet.velocity.dy);
        }
      }

      for (final coin in _coinBursts) {
        coin.progress += 0.022;
      }
      _coinBursts.removeWhere((c) => c.progress >= 1.0);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _triggerHarvestEffect(int amount) {
    PentatonicAudioSynth.instance.playFanfare();
    // Sinh các chùm xu +25 bay bổng
    for (int i = 0; i < 5; i++) {
      _coinBursts.add(FloatingCoinParticle(
        position: Offset(130.0 + i * 24.0, 420.0 - i * 16.0),
        text: '+25',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PetSanctuaryService.instance,
      builder: (context, _) {
        final service = PetSanctuaryService.instance;
        final pendingCoins = math.max(480, service.pendingIdleCoins);
        final int totalRescued = math.max(142, service.totalRescuedCount);

        return Scaffold(
          body: Stack(
            children: [
              // 1. Toàn bộ hình nền trời xanh & Quần đảo bay 2.5D
              CustomPaint(
                size: Size.infinite,
                painter: SanctuaryIslandPainter(
                  pets: _pets,
                  coinBursts: _coinBursts,
                  unlockedZones: service.unlockedZones,
                  elapsed: _elapsed,
                ),
              ),

              // 2. HUD Trên Cùng: Nút tròn Pause xanh biếc + Tiền vàng + Kim cương + Cúp cài đặt
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      // Nút Tạm Dừng / Back tròn xanh biếc (#29B6F6)
                      GestureDetector(
                        onTap: widget.onBack,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFF29B6F6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                          ),
                          child: const Center(
                            child: Icon(Icons.pause_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Viên Xu Vàng
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xDD1E282D),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🟡', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 4),
                            Text(
                              '${service.coins > 0 ? service.coins : 2450}',
                              style: const TextStyle(color: Color(0xFFFFD54F), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Viên Ngọc Xanh
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xDD1E282D),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF29B6F6), width: 1.2),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('💎', style: TextStyle(fontSize: 12)),
                            SizedBox(width: 4),
                            Text(
                              '120',
                              style: TextStyle(color: Color(0xFF81D4FA), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Biểu tượng Cúp Vàng Cài Đặt
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF263238),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFFD84D), width: 1.4),
                        ),
                        child: const Center(
                          child: Text('🏆', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Biển gỗ góc phải: "Rescued Pets: 142"
              Positioned(
                right: 18,
                bottom: 125,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD49B6A), Color(0xFF8B5A2B)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF4A2810), width: 1.5),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Rescued Pets:',
                        style: TextStyle(color: Color(0xFFFFF8E1), fontSize: 9.0, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$totalRescued',
                        style: const TextStyle(color: Color(0xFFFFD54F), fontSize: 14.0, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ),
              ),

              // 4. Rương Vàng Thu Hoạch Xu Lớn ở chân đảo
              Positioned(
                left: 20,
                right: 20,
                bottom: 60,
                child: Center(
                  child: GestureDetector(
                    onTap: () async {
                      final gained = await service.harvestIdleCoins();
                      _triggerHarvestEffect(gained);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Biểu tượng Rương Vàng Lớn
                        Container(
                          width: 60,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF5A3317), width: 2.2),
                            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          child: const Center(
                            child: Text('🎁', style: TextStyle(fontSize: 26)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Thanh Nút: "Thu Hoạch +480 Xu (Idle)"
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF81C784), Color(0xFF388E3C)],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: Colors.white, width: 2.0),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Text(
                            'Thu Hoạch +$pendingCoins Xu (Idle)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 5. Thanh Điều Hướng Gỗ 3 Nút Bo Tròn ở đáy màn hình chuẩn hình mẫu
              Positioned(
                left: 14,
                right: 14,
                bottom: 8,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD49B6A), Color(0xFF8D532B)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF5A3317), width: 1.8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Tab 1: Mặt Corgi (Đang chọn)
                      _buildBottomDockIcon('🐶', isSelected: true),
                      // Tab 2: Cuộn Giấy Bản Đồ
                      _buildBottomDockIcon('📜', isSelected: false),
                      // Tab 3: Nhà Chó
                      _buildBottomDockIcon('🏠', isSelected: false),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomDockIcon(String emoji, {required bool isSelected}) {
    return Container(
      width: 40,
      height: 38,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFFE082).withValues(alpha: 0.35) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: isSelected ? 24 : 20)),
      ),
    );
  }
}

/// Bộ vẽ Đảo Bay 2.5D giữa trời, Cat Cafe, Duck Pool, Corgi Beach và đàn thú cưng
class SanctuaryIslandPainter extends CustomPainter {
  final List<WanderingPet> pets;
  final List<FloatingCoinParticle> coinBursts;
  final Set<String> unlockedZones;
  final double elapsed;

  SanctuaryIslandPainter({
    required this.pets,
    required this.coinBursts,
    required this.unlockedZones,
    required this.elapsed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Bầu trời xanh biếc với những đám mây trắng trôi
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF70C5E8), Color(0xFFBCE3F5)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    // Mây trắng trôi bồng bềnh
    _drawCloud(canvas, Offset(size.width * 0.15, size.height * 0.10), 32);
    _drawCloud(canvas, Offset(size.width * 0.82, size.height * 0.14), 26);
    _drawCloud(canvas, Offset(size.width * 0.35, size.height * 0.22), 22);

    // 2. KHỐI ĐẢO BAY 2.5D (Floating Sky Island):
    final center = Offset(size.width * 0.5, size.height * 0.44);
    final islandWidth = size.width * 0.88;
    final islandHeight = size.height * 0.38;

    // A. Vách đá đáy đảo bay (Inverted Rocky Cliff)
    final cliffPath = Path()
      ..moveTo(center.dx - islandWidth * 0.5, center.dy)
      ..quadraticBezierTo(center.dx - islandWidth * 0.3, center.dy + islandHeight * 0.85, center.dx, center.dy + islandHeight * 0.95)
      ..quadraticBezierTo(center.dx + islandWidth * 0.3, center.dy + islandHeight * 0.85, center.dx + islandWidth * 0.5, center.dy)
      ..close();

    // Bóng đổ đáy đảo
    canvas.drawPath(
      cliffPath.shift(const Offset(0, 10)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Vách đá đất nâu tầng lớp
    canvas.drawPath(
      cliffPath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6D4226), Color(0xFF4E2A12), Color(0xFF2E1708)],
        ).createShader(Rect.fromLTWH(center.dx - islandWidth / 2, center.dy, islandWidth, islandHeight)),
    );

    // B. Thảm cỏ xanh mướt trên đỉnh đảo
    final grassRect = Rect.fromCenter(center: center, width: islandWidth, height: islandHeight * 0.65);
    canvas.drawOval(
      grassRect.shift(const Offset(0, 6)),
      Paint()..color = const Color(0xFF388E3C),
    );
    canvas.drawOval(
      grassRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF81C784), Color(0xFF4CAF50)],
        ).createShader(grassRect),
    );

    // Cây xanh rậm rạp ở góc trên sau đảo
    _drawBackdropTrees(canvas, center, islandWidth, islandHeight);

    // C. 3 KHU VỰC THƯ GIÃN TRÊN ĐẢO:
    // 1. Quán Cà Phê Mèo (Cat Cafe - góc trên trái)
    _drawCatCafeDiorama(canvas, center + Offset(-islandWidth * 0.28, -islandHeight * 0.16));

    // 2. Hồ Bơi Vịt Vàng (Duck Pool - ở giữa bên trái)
    _drawDuckPoolDiorama(canvas, center + Offset(-islandWidth * 0.12, islandHeight * 0.12));

    // 3. Bãi Biển Corgi (Corgi Beach - góc dưới phải)
    _drawCorgiBeachDiorama(canvas, center + Offset(islandWidth * 0.26, islandHeight * 0.10));

    // D. Đàn thú cưng nhún nhảy đi dạo
    for (final pet in pets) {
      _drawWanderingPet(canvas, pet);
    }

    // E. Đồng xu vàng bay bổng (+25, +25, +25)
    for (final coin in coinBursts) {
      _drawFloatingCoin(canvas, coin);
    }
  }

  void _drawCloud(Canvas canvas, Offset pos, double r) {
    final cloudPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawCircle(pos, r, cloudPaint);
    canvas.drawCircle(pos + Offset(r * 0.6, 0), r * 0.75, cloudPaint);
    canvas.drawCircle(pos - Offset(r * 0.6, 0), r * 0.75, cloudPaint);
  }

  void _drawBackdropTrees(Canvas canvas, Offset center, double w, double h) {
    for (int i = 0; i < 5; i++) {
      final treeX = center.dx - w * 0.35 + i * (w * 0.18);
      final treeY = center.dy - h * 0.25;
      canvas.drawCircle(Offset(treeX, treeY + 3), 16, Paint()..color = const Color(0xFF2E7D32));
      canvas.drawCircle(Offset(treeX, treeY), 16, Paint()..color = const Color(0xFF43A047));
      canvas.drawCircle(Offset(treeX - 4, treeY - 4), 7, Paint()..color = const Color(0xFF81C784));
    }
  }

  /// 1. Kiosk Quán Cà Phê Mèo (Cat Cafe)
  void _drawCatCafeDiorama(Canvas canvas, Offset pos) {
    // Mái che sọc cam trắng
    final awningRect = Rect.fromCenter(center: pos + const Offset(0, -18), width: 56, height: 16);
    canvas.drawRRect(RRect.fromRectAndRadius(awningRect, const Radius.circular(5)), Paint()..color = const Color(0xFFFF9800));
    // Sọc trắng
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(awningRect.left + 8 + i * 16, awningRect.top, 8, 16), Paint()..color = Colors.white);
    }
    // Quầy gỗ
    final booth = Rect.fromCenter(center: pos, width: 52, height: 26);
    canvas.drawRRect(RRect.fromRectAndRadius(booth, const Radius.circular(6)), Paint()..color = const Color(0xFF6D4226));
    // Cốc trà sữa boba
    final textPainter = TextPainter(
      text: const TextSpan(text: '🐱🧋', style: TextStyle(fontSize: 16)),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, pos - Offset(textPainter.width / 2, 8));

    // Bảng tên "Cat Cafe"
    _drawZoneLabelPill(canvas, pos + const Offset(0, 18), 'Cat Cafe');
  }

  /// 2. Hồ Bơi Vịt Vàng (Duck Pool)
  void _drawDuckPoolDiorama(Canvas canvas, Offset pos) {
    // Mặt nước hồ xanh biếc có viền đá
    final poolRect = Rect.fromCenter(center: pos, width: 72, height: 42);
    canvas.drawOval(poolRect.inflate(3), Paint()..color = const Color(0xFFB0BEC5));
    canvas.drawOval(
      poolRect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
        ).createShader(poolRect),
    );
    // Gợn sóng
    canvas.drawOval(
      Rect.fromCenter(center: pos, width: 44, height: 20),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Đàn vịt vàng bơi
    final duck1 = TextPainter(text: const TextSpan(text: '🐥', style: TextStyle(fontSize: 14)), textDirection: TextDirection.ltr)..layout();
    duck1.paint(canvas, pos - const Offset(16, 10));
    final duck2 = TextPainter(text: const TextSpan(text: '🐥', style: TextStyle(fontSize: 13)), textDirection: TextDirection.ltr)..layout();
    duck2.paint(canvas, pos + const Offset(6, -4));

    // Bảng tên "Duck Pool"
    _drawZoneLabelPill(canvas, pos + const Offset(0, 26), 'Duck Pool');
  }

  /// 3. Bãi Biển Corgi (Corgi Beach)
  void _drawCorgiBeachDiorama(Canvas canvas, Offset pos) {
    // Bãi cát vàng
    final sandRect = Rect.fromCenter(center: pos, width: 74, height: 46);
    canvas.drawOval(sandRect, Paint()..color = const Color(0xFFFFE082));

    // Ô dù bãi biển sọc đỏ trắng
    final umbrellaPos = pos + const Offset(18, -12);
    canvas.drawCircle(umbrellaPos, 14, Paint()..color = const Color(0xFFFF5252));
    canvas.drawCircle(umbrellaPos, 8, Paint()..color = Colors.white);
    canvas.drawCircle(umbrellaPos, 3, Paint()..color = const Color(0xFFFFD54F));

    // Cún corgi vui đùa
    final corgi = TextPainter(text: const TextSpan(text: '🐶', style: TextStyle(fontSize: 17)), textDirection: TextDirection.ltr)..layout();
    corgi.paint(canvas, pos - const Offset(14, 12));

    // Bảng tên "Corgi Beach"
    _drawZoneLabelPill(canvas, pos + const Offset(0, 26), 'Corgi Beach');
  }

  void _drawZoneLabelPill(Canvas canvas, Offset pos, String text) {
    final span = TextSpan(
      text: text,
      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 0.4),
    );
    final painter = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
    final pillRect = Rect.fromCenter(center: pos, width: painter.width + 12, height: 15);
    canvas.drawRRect(RRect.fromRectAndRadius(pillRect, const Radius.circular(8)), Paint()..color = const Color(0xDD21292E));
    canvas.drawRRect(
      RRect.fromRectAndRadius(pillRect, const Radius.circular(8)),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
    painter.paint(canvas, pos - Offset(painter.width / 2, painter.height / 2));
  }

  void _drawWanderingPet(Canvas canvas, WanderingPet pet) {
    final petPos = pet.position + Offset(0, -pet.hopHeight);

    canvas.drawOval(
      Rect.fromCenter(center: pet.position + const Offset(0, 7), width: 16, height: 5),
      Paint()..color = Colors.black26,
    );

    // Thân bé thú tròn
    canvas.drawCircle(petPos, 11, Paint()..color = pet.color.primaryColor);
    // Khuôn mặt đáng yêu
    final eyePaint = Paint()..color = Colors.black87;
    canvas.drawCircle(petPos + const Offset(-4, -2), 1.5, eyePaint);
    canvas.drawCircle(petPos + const Offset(4, -2), 1.5, eyePaint);
    canvas.drawCircle(petPos + const Offset(0, 2), 1.4, Paint()..color = pet.color.darkColor);
  }

  void _drawFloatingCoin(Canvas canvas, FloatingCoinParticle coin) {
    final yOffset = -coin.progress * 60.0;
    final opacity = (1.0 - coin.progress).clamp(0.0, 1.0);
    final coinPos = coin.position + Offset(0, yOffset);

    final painter = TextPainter(
      text: TextSpan(
        text: '🟡 ${coin.text}',
        style: TextStyle(
          color: const Color(0xFFFFD54F).withValues(alpha: opacity),
          fontSize: 13.0,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(color: Colors.black.withValues(alpha: opacity * 0.7), blurRadius: 4, offset: const Offset(1, 1)),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, coinPos - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(covariant SanctuaryIslandPainter oldDelegate) => true;
}
