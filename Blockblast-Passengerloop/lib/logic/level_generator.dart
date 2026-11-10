import 'dart:math' as math;
import '../models/enums.dart';
import '../models/grid_cell_data.dart';
import '../models/bus_data.dart';
import '../models/polyomino_shape.dart';

class GameLevelConfig {
  final int levelNumber;
  final int chapter;
  final String chapterName;
  final List<PetColor> availableColors;
  final List<BusData> buses;
  final List<GridCellData> initialGrid;
  final List<int> lockedDockSlots;
  final int targetScore;
  final String description;

  const GameLevelConfig({
    required this.levelNumber,
    required this.chapter,
    required this.chapterName,
    required this.availableColors,
    required this.buses,
    required this.initialGrid,
    this.lockedDockSlots = const [],
    required this.targetScore,
    required this.description,
  });
}

class LevelGenerator {
  static final Map<int, GameLevelConfig> _cache = {};

  static GameLevelConfig getLevel(int level) {
    if (_cache.containsKey(level)) {
      return _cache[level]!;
    }
    final config = _generate(level);
    _cache[level] = config;
    return config;
  }

  static GameLevelConfig _generate(int level) {
    int chapter = 1;
    String chapterName = 'Chương 1: Công Viên Corgi & Mèo';
    List<PetColor> colors = [PetColor.red, PetColor.yellow];
    int busCount = 2 + (level / 10).floor();
    List<int> lockedDockSlots = [];

    if (level <= 30) {
      chapter = 1;
      chapterName = 'Chương 1: Công Viên Corgi & Mèo (Đá Tảng)';
      colors = [PetColor.red, PetColor.yellow];
    } else if (level <= 80) {
      chapter = 2;
      chapterName = 'Chương 2: Đầm Vịt Băng Giá & Bom Hẹn Giờ';
      colors = [PetColor.red, PetColor.yellow, PetColor.blue];
      busCount = 3 + ((level - 30) / 12).floor();
    } else if (level <= 130) {
      chapter = 3;
      chapterName = 'Chương 3: Rừng Thỏ Dây Leo & Khóa Ghế Chờ';
      colors = [PetColor.red, PetColor.yellow, PetColor.blue, PetColor.green];
      busCount = 4 + ((level - 80) / 12).floor();
      // Khóa 1 hoặc 2 ghế chờ ở các màn cao
      if (level >= 95) {
        lockedDockSlots = [4];
      }
      if (level >= 115) {
        lockedDockSlots = [3, 4];
      }
    } else if (level <= 170) {
      chapter = 4;
      chapterName = 'Chương 4: Thung Lũng Cáo & Hố Đen Dịch Chuyển';
      colors = [PetColor.red, PetColor.yellow, PetColor.blue, PetColor.green, PetColor.orange];
      busCount = 5 + ((level - 130) / 10).floor();
    } else {
      chapter = 5;
      chapterName = 'Chương 5: Bàn Cờ Dị Hình & Đại Chiến Boss';
      colors = [PetColor.red, PetColor.yellow, PetColor.blue, PetColor.green, PetColor.orange];
      busCount = 6 + ((level - 170) / 8).floor();
      if (level >= 185) {
        lockedDockSlots = [4];
      }
    }

    // 1. Tạo danh sách xe buýt
    final List<BusData> buses = [];
    for (int i = 0; i < busCount; i++) {
      final color = colors[(level + i * 2) % colors.length];
      final capacity = 3 + ((level + i) % 3); // dung tích 3, 4 hoặc 5
      buses.add(BusData(
        id: 'bus_${level}_$i',
        color: color,
        name: '${color.animalName} Express',
        capacity: capacity,
      ));
    }

    // 2. Tạo bố cục chướng ngại vật ban đầu
    final List<GridCellData> initialGrid = [];
    final random = math.Random(level * 31 + 17);
    final obstacleCount = math.min(12, 2 + (level / 15).floor());

    final Set<String> used = {};
    for (int i = 0; i < obstacleCount; i++) {
      final r = random.nextInt(8);
      final c = random.nextInt(8);
      final key = '$r,$c';
      if (used.contains(key)) continue;
      used.add(key);

      HazardType? hazard;
      int iceLayer = 0;
      int bombTurns = 0;
      PetColor? petColor = colors[random.nextInt(colors.length)];

      if (chapter == 1) {
        // Đá tảng
        hazard = HazardType.stone;
        petColor = null;
      } else if (chapter == 2) {
        // Băng giá hoặc Bom
        if (i % 2 == 0) {
          hazard = HazardType.ice;
          iceLayer = 2;
        } else {
          hazard = HazardType.bomb;
          bombTurns = math.max(5, 9 - (level / 20).floor());
        }
      } else if (chapter == 3) {
        // Dây leo hoặc Băng
        if (i % 2 == 0) {
          hazard = HazardType.vine;
        } else {
          hazard = HazardType.ice;
          iceLayer = 2;
        }
      } else if (chapter == 4) {
        // Hố đen (ô bị khóa) & Bom
        if (i % 3 == 0) {
          hazard = HazardType.stone;
          petColor = null;
        } else if (i % 3 == 1) {
          hazard = HazardType.bomb;
          bombTurns = 6;
        } else {
          hazard = HazardType.ice;
          iceLayer = 2;
        }
      } else {
        // Chương 5: Dị hình & Boss
        if (i % 2 == 0) {
          hazard = HazardType.stone;
          petColor = null;
        } else {
          hazard = HazardType.bomb;
          bombTurns = 6;
        }
      }

      initialGrid.add(GridCellData(
        row: r,
        col: c,
        petColor: petColor,
        hazard: hazard,
        iceLayer: iceLayer,
        bombTurns: bombTurns,
      ));
    }

    // Địa hình dị hình góc (Chương 5: khóa 4 góc bàn cờ)
    if (chapter == 5) {
      final corners = [
        const PointInt(0, 0), const PointInt(0, 7),
        const PointInt(7, 0), const PointInt(7, 7),
      ];
      for (final corner in corners) {
        if (!initialGrid.any((c) => c.row == corner.r && c.col == corner.c)) {
          initialGrid.add(GridCellData(
            row: corner.r,
            col: corner.c,
            isLocked: true,
            hazard: HazardType.stone,
          ));
        }
      }
    }

    return GameLevelConfig(
      levelNumber: level,
      chapter: chapter,
      chapterName: chapterName,
      availableColors: colors,
      buses: buses,
      initialGrid: initialGrid,
      lockedDockSlots: lockedDockSlots,
      targetScore: busCount * 650,
      description: 'Đón đủ $busCount chuyến xe buýt và giải cứu các bé thú cưng!',
    );
  }
}
