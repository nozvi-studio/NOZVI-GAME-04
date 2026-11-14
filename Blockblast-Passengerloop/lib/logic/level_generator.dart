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
    // 0. Hướng Dẫn Nhập Môn FTUE
    if (level == 0) {
      return GameLevelConfig(
        levelNumber: 0,
        chapter: 1,
        chapterName: 'Hướng Dẫn Nhập Môn (FTUE)',
        availableColors: const [PetColor.red, PetColor.yellow, PetColor.blue],
        buses: [
          BusData(id: 'ftue_bus_0', color: PetColor.red, name: 'Corgi Bus', capacity: 8),
          BusData(id: 'ftue_bus_1', color: PetColor.red, name: 'Corgi Bus', capacity: 8),
          BusData(id: 'ftue_bus_2', color: PetColor.red, name: 'Corgi Bus', capacity: 5),
          BusData(id: 'ftue_bus_3', color: PetColor.yellow, name: 'Cat Bus', capacity: 4),
          BusData(id: 'ftue_bus_4', color: PetColor.blue, name: 'Duck Bus', capacity: 4),
        ],
        initialGrid: const [],
        targetScore: 1500,
        description: 'Làm quen cơ chế xếp khối 8x8, đón thú lên xe buýt và ghế chờ.',
      );
    }

    int chapter = 1;
    String chapterName = 'Chương 1: Công Viên Nắng Ấm';
    List<PetColor> colors = [PetColor.red, PetColor.yellow];
    int baseBusCount = 2 + (level / 10).floor();
    List<int> lockedDockSlots = [];

    // Phân bổ 11 Chương qua 500 Màn Chơi
    if (level <= 30) {
      chapter = 1;
      chapterName = 'Chương 1: Công Viên Nắng Ấm';
      colors = [PetColor.red, PetColor.yellow];
      baseBusCount = 2 + (level / 10).floor();
    } else if (level <= 80) {
      chapter = 2;
      chapterName = 'Chương 2: Xứ Sở Băng Giá';
      colors = [PetColor.red, PetColor.yellow, PetColor.blue];
      baseBusCount = 3 + ((level - 30) / 12).floor();
    } else if (level <= 130) {
      chapter = 3;
      chapterName = 'Chương 3: Rừng Dây Leo';
      colors = [PetColor.red, PetColor.yellow, PetColor.blue, PetColor.green];
      baseBusCount = 4 + ((level - 80) / 12).floor();
      if (level >= 95) lockedDockSlots = [4];
      if (level >= 115) lockedDockSlots = [3, 4];
    } else if (level <= 170) {
      chapter = 4;
      chapterName = 'Chương 4: Thành Phố Đồ Chơi';
      colors = [PetColor.red, PetColor.yellow, PetColor.blue, PetColor.green, PetColor.orange];
      baseBusCount = 5 + ((level - 130) / 10).floor();
    } else if (level <= 200) {
      chapter = 5;
      chapterName = 'Chương 5: Thủ Đô Di Chúc';
      colors = [PetColor.red, PetColor.yellow, PetColor.blue, PetColor.green, PetColor.orange];
      baseBusCount = 6 + ((level - 170) / 8).floor();
      if (level >= 185) lockedDockSlots = [4];
    } else if (level <= 250) {
      chapter = 6;
      chapterName = 'Chương 6: Thung Lũng Dung Nham';
      colors = [PetColor.red, PetColor.orange, PetColor.yellow, PetColor.blue, PetColor.green];
      baseBusCount = 5 + ((level - 200) / 14).floor();
    } else if (level <= 300) {
      chapter = 7;
      chapterName = 'Chương 7: Bến Cảng Hoàng Hôn';
      colors = [PetColor.blue, PetColor.yellow, PetColor.red, PetColor.green, PetColor.orange];
      baseBusCount = 5 + ((level - 250) / 13).floor();
      lockedDockSlots = [3, 4]; // Thắt cổ chai ghế chờ: chỉ còn 3 ghế trống
    } else if (level <= 350) {
      chapter = 8;
      chapterName = 'Chương 8: Vườn Nấm Phát Sáng';
      colors = [PetColor.green, PetColor.blue, PetColor.yellow, PetColor.orange, PetColor.red];
      baseBusCount = 6 + ((level - 300) / 14).floor();
    } else if (level <= 400) {
      chapter = 9;
      chapterName = 'Chương 9: Nhà Máy Bánh Răng';
      colors = [PetColor.red, PetColor.yellow, PetColor.blue, PetColor.green, PetColor.orange];
      baseBusCount = 6 + ((level - 350) / 13).floor();
      if (level >= 385) lockedDockSlots = [4];
    } else if (level <= 450) {
      chapter = 10;
      chapterName = 'Chương 10: Xứ Sở Kẹo Ngọt';
      colors = [PetColor.red, PetColor.yellow, PetColor.blue, PetColor.green, PetColor.orange];
      baseBusCount = 5 + ((level - 400) / 15).floor(); // Màn xả stress Domino
    } else {
      chapter = 11;
      final bool isBossLevel = level % 10 == 0;
      chapterName = isBossLevel
          ? (level == 500 ? 'ĐẠI BOSS VŨ TRỤ (MÀN 500)' : 'BOSS TINH VÂN (MÀN $level)')
          : 'Chương 11: Thiên Hà Tinh Vân';
      colors = [PetColor.red, PetColor.yellow, PetColor.blue, PetColor.green, PetColor.orange];
      if (isBossLevel) {
        baseBusCount = level == 500 ? 9 : 8;
        lockedDockSlots = [4];
      } else {
        baseBusCount = 6 + ((level - 450) / 14).floor();
      }
    }

    // Nhịp điều biến sóng sin tạo sự xen kẽ giữa các màn thở phào (breather) và màn căng não
    final bool isBoss = chapter == 11 && level % 10 == 0;
    final double breathMod = (level <= 200 || isBoss) ? 0.0 : math.sin(level * 0.45) * 0.75;
    final int busCount = (baseBusCount + breathMod.round()).clamp(2, 9);

    // 1. Tạo danh sách xe buýt
    final List<BusData> buses = [];
    for (int i = 0; i < busCount; i++) {
      final PetColor color;
      if (chapter == 6) {
        // Ưu tiên Corgi Red và Fox Orange
        color = (i % 2 == 0)
            ? (i % 4 == 0 ? PetColor.red : PetColor.orange)
            : colors[(level + i) % colors.length];
      } else if (chapter == 8) {
        // Nhịp luân phiên xen kẽ màu: Green xen kẽ các màu khác
        color = (i % 2 == 0)
            ? PetColor.green
            : colors[(level + i) % colors.length];
      } else {
        color = colors[(level + i) % colors.length];
      }

      int capacity;
      if (chapter == 6) {
        // Xe dung tích lớn 5-6 khách
        capacity = 5 + ((level + i) % 2);
      } else if (chapter == 10) {
        // Xứ sở kẹo ngọt: dung tích vừa phải 4-5 khách để combo nhanh
        capacity = 4 + ((level + i) % 2);
      } else if (chapter == 11 && level == 500 && i == busCount - 1) {
        // Chiếc xe buýt thần thoại cuối cùng của màn 500 là Rainbow Express đón mọi pet
        capacity = 6;
      } else {
        capacity = 3 + ((level + i) % 3); // 3, 4 hoặc 5 khách
      }

      final bool isRainbow = (chapter == 11 && level == 500 && i == busCount - 1);

      buses.add(BusData(
        id: 'bus_${level}_$i',
        color: color,
        name: isRainbow ? '🌈 Rainbow Express' : '${color.displayName} Bus',
        capacity: capacity,
        isRainbow: isRainbow,
      ));
    }

    // 2. Tạo bố cục chướng ngại vật ban đầu
    final List<GridCellData> initialGrid = [];
    final random = math.Random(level * 31 + 17);

    if (level <= 200) {
      // Giữ nguyên 100% logic cổ điển cho Level 1 - 200
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
          hazard = HazardType.stone;
          petColor = null;
        } else if (chapter == 2) {
          if (i % 2 == 0) {
            hazard = HazardType.ice;
            iceLayer = 2;
          } else {
            hazard = HazardType.bomb;
            bombTurns = math.max(5, 9 - (level / 20).floor());
          }
        } else if (chapter == 3) {
          if (i % 2 == 0) {
            hazard = HazardType.vine;
          } else {
            hazard = HazardType.ice;
            iceLayer = 2;
          }
        } else if (chapter == 4) {
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
          // Chương 5
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

      // Khóa 4 góc ở Chương 5
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
    } else {
      // 3. Áp dụng Procedural Matrix Template Math cho Level 201 - 500
      _applyGeometricTemplate(
        level: level,
        chapter: chapter,
        initialGrid: initialGrid,
        colors: colors,
        random: random,
      );
    }

    final int targetScore = busCount * 650 + (level > 200 ? ((level - 200) * 12) : 0);

    String description;
    switch (chapter) {
      case 1:
        description = 'Làm quen xếp khối và tiễn các chuyến xe buýt đầu tiên.';
        break;
      case 2:
        description = 'Phá tan các khối băng 2 lớp và đón thú cưng lên xe kịp lúc.';
        break;
      case 3:
        description = 'Ngăn chặn dây leo lan rộng và thích nghi với ghế chờ bị giới hạn.';
        break;
      case 4:
        description = 'Thành phố đồ chơi sầm uất với đủ 5 màu thú cưng và bom hẹn giờ!';
        break;
      case 5:
        description = 'Chinh phục thủ đô di chúc với địa hình 4 góc bị phong tỏa!';
        break;
      case 6:
        description = 'Thung lũng dung nham: Núi lửa nứt khóa tâm 2x2, đón xe Corgi & Cáo lớn!';
        break;
      case 7:
        description = 'Bến cảng hoàng hôn: Bàn cờ khuyết chữ H và áp lực chỉ còn 3 ghế chờ!';
        break;
      case 8:
        description = 'Vườn nấm phát sáng: Mê cung dây leo & băng tuyết, xe buýt luân phiên!';
        break;
      case 9:
        description = 'Nhà máy bánh răng: Bố cục đá xoay đối xứng cùng bom nổ nhanh 4-5 lượt!';
        break;
      case 10:
        description = 'Xứ sở kẹo ngọt: Bùng nổ phản ứng dây chuyền Domino trên 50% thảm băng!';
        break;
      case 11:
      default:
        description = (level % 10 == 0)
            ? 'ĐẠI CHIẾN BOSS TINH VÂN (MÀN $level): Vượt qua 3 chướng ngại vật cùng $busCount xe vũ trụ!'
            : 'Thiên Hà Tinh Vân: Khéo léo né tránh lỗ đen vũ trụ và giải cứu thú cưng!';
        break;
    }

    return GameLevelConfig(
      levelNumber: level,
      chapter: chapter,
      chapterName: chapterName,
      availableColors: colors,
      buses: buses,
      initialGrid: initialGrid,
      lockedDockSlots: lockedDockSlots,
      targetScore: targetScore,
      description: description,
    );
  }

  /// Helper sinh bố cục ma trận hình học nghệ thuật cho các chương 6 - 11
  static void _applyGeometricTemplate({
    required int level,
    required int chapter,
    required List<GridCellData> initialGrid,
    required List<PetColor> colors,
    required math.Random random,
  }) {
    final Set<String> used = {
      for (final cell in initialGrid) '${cell.row},${cell.col}',
    };

    void addCell(
      int r,
      int c, {
      bool isLocked = false,
      HazardType? hazard,
      int iceLayer = 0,
      int bombTurns = 0,
      PetColor? petColor,
    }) {
      if (r < 0 || r >= 8 || c < 0 || c >= 8) return;
      final key = '$r,$c';
      if (used.contains(key)) return;
      used.add(key);
      initialGrid.add(GridCellData(
        row: r,
        col: c,
        isLocked: isLocked,
        hazard: hazard,
        iceLayer: iceLayer,
        bombTurns: bombTurns,
        petColor: petColor,
      ));
    }

    if (chapter == 6) {
      // Chương 6: Thung Lũng Dung Nham (Khóa ô tâm 2x2 miệng núi lửa)
      const centerFissures = [
        PointInt(3, 3), PointInt(3, 4),
        PointInt(4, 3), PointInt(4, 4),
      ];
      for (final p in centerFissures) {
        addCell(p.r, p.c, isLocked: true, hazard: HazardType.stone);
      }

      // Các nhánh nứt nham thạch phụ
      final int branches = 2 + (level % 3);
      for (int i = 0; i < branches; i++) {
        final r = (i % 2 == 0) ? 2 : 5;
        final c = (i % 2 == 0) ? (2 + (i % 4)) : (5 - (i % 4));
        addCell(
          r,
          c,
          hazard: i % 2 == 0 ? HazardType.bomb : HazardType.stone,
          bombTurns: 6,
          petColor: (i % 2 == 0) ? colors[random.nextInt(colors.length)] : null,
        );
      }
    } else if (chapter == 7) {
      // Chương 7: Bến Cảng Hoàng Hôn (Bàn cờ khuyết góc chữ H)
      const hCutouts = [
        PointInt(0, 3), PointInt(0, 4), PointInt(1, 3), PointInt(1, 4),
        PointInt(6, 3), PointInt(6, 4), PointInt(7, 3), PointInt(7, 4),
      ];
      for (final p in hCutouts) {
        addCell(p.r, p.c, isLocked: true, hazard: HazardType.stone);
      }

      // Thêm 2-3 ô đá ngầm hoặc băng ven cảng
      final int rocks = 2 + (level % 3);
      for (int i = 0; i < rocks; i++) {
        final r = (i * 3 + 2) % 8;
        final c = (i * 2 + 1) % 8;
        addCell(
          r,
          c,
          hazard: HazardType.ice,
          iceLayer: 2,
          petColor: colors[random.nextInt(colors.length)],
        );
      }
    } else if (chapter == 8) {
      // Chương 8: Vườn Nấm Phát Sáng (Mê cung dây leo ziczac & băng 2 HP)
      final int offset = level % 2;
      for (int r = 1; r < 7; r += 2) {
        for (int c = 1; c < 7; c += 2) {
          final isVine = (((r + c) ~/ 2) + offset) % 2 == 0;
          addCell(
            r,
            c,
            hazard: isVine ? HazardType.vine : HazardType.ice,
            iceLayer: isVine ? 0 : 2,
            petColor: colors[random.nextInt(colors.length)],
          );
        }
      }
    } else if (chapter == 9) {
      // Chương 9: Nhà Máy Bánh Răng (Bố cục đá đối xứng tâm 4 hướng & bom 4-5 lượt)
      final int symmetrySeeds = 2 + (level % 2);
      final int bombTurns = (level % 2 == 0) ? 4 : 5;

      for (int i = 0; i < symmetrySeeds; i++) {
        final r = 1 + (i * 2 + (level % 2)) % 3;
        final c = 2 + (i + 1) % 3;
        final bool isBomb = (i % 2 == 1);
        final HazardType hazard = isBomb ? HazardType.bomb : HazardType.stone;
        final PetColor? petColor = isBomb ? colors[random.nextInt(colors.length)] : null;

        // 4 điểm đối xứng quay 90 độ
        final points = [
          PointInt(r, c),
          PointInt(c, 7 - r),
          PointInt(7 - r, 7 - c),
          PointInt(7 - c, r),
        ];
        for (final p in points) {
          addCell(p.r, p.c, hazard: hazard, bombTurns: isBomb ? bombTurns : 0, petColor: petColor);
        }
      }
    } else if (chapter == 10) {
      // Chương 10: Xứ Sở Kẹo Ngọt (Màn Domino xả stress - 50% bàn cờ phủ băng 1-hit)
      final int totalIce = 24 + (level % 5); // 24 đến 28 ô băng 1 HP
      int placed = 0;
      for (int r = 0; r < 8 && placed < totalIce; r++) {
        for (int c = 0; c < 8 && placed < totalIce; c++) {
          if ((r + c + (level % 2)) % 2 == 0) {
            addCell(
              r,
              c,
              hazard: HazardType.ice,
              iceLayer: 1, // 1 HP duy nhất: nổ 1 hàng kích hoạt nổ domino toàn bàn
              petColor: colors[(r * 8 + c + level) % colors.length],
            );
            placed++;
          }
        }
      }
    } else if (chapter == 11) {
      // Chương 11: Thiên Hà Tinh Vân (Lỗ đen rỗng tâm Donut)
      const blackHole = [
        PointInt(3, 3), PointInt(3, 4),
        PointInt(4, 3), PointInt(4, 4),
      ];
      for (final p in blackHole) {
        addCell(p.r, p.c, isLocked: true, hazard: HazardType.stone);
      }

      final bool isBossLevel = level % 10 == 0;
      if (isBossLevel) {
        // MÀN BOSS QUY TỤ CẢ 3 CHƯỚNG NGẠI VẬT (Đá, Băng 2 HP, Bom 5 lượt, Dây leo)
        const corners = [PointInt(0, 0), PointInt(0, 7), PointInt(7, 0), PointInt(7, 7)];
        for (final p in corners) {
          addCell(p.r, p.c, isLocked: true, hazard: HazardType.stone);
        }
        const bombs = [PointInt(1, 3), PointInt(1, 4), PointInt(6, 3), PointInt(6, 4)];
        for (final p in bombs) {
          addCell(p.r, p.c, hazard: HazardType.bomb, bombTurns: 5, petColor: colors[random.nextInt(colors.length)]);
        }
        const ices = [PointInt(3, 1), PointInt(4, 1), PointInt(3, 6), PointInt(4, 6)];
        for (final p in ices) {
          addCell(p.r, p.c, hazard: HazardType.ice, iceLayer: 2, petColor: colors[random.nextInt(colors.length)]);
        }
        const vines = [PointInt(2, 2), PointInt(2, 5), PointInt(5, 2), PointInt(5, 5)];
        for (final p in vines) {
          addCell(p.r, p.c, hazard: HazardType.vine, petColor: colors[random.nextInt(colors.length)]);
        }
      } else {
        // Màn thường Chương 11: Bom 5-6 lượt & Băng 2 HP
        final int hazardsCount = 4 + (level % 3);
        for (int i = 0; i < hazardsCount; i++) {
          final r = (i * 2 + 1) % 8;
          final c = (i * 3 + 2) % 8;
          final bool isBomb = (i % 2 == 0);
          addCell(
            r,
            c,
            hazard: isBomb ? HazardType.bomb : HazardType.ice,
            bombTurns: isBomb ? 6 : 0,
            iceLayer: isBomb ? 0 : 2,
            petColor: colors[random.nextInt(colors.length)],
          );
        }
      }
    }
  }
}
