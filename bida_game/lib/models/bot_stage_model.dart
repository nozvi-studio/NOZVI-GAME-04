import 'cue_model.dart';

class BotStageModel {
  final int stageNumber;
  final String title;
  final String botName;
  final String cueId;
  final double aimErrorRad;      // Sai số góc ngắm ngẫu nhiên (radians)
  final double powerAccuracy;     // Độ chính xác khi căn lực (0.0 - 1.0)
  final bool useSpin;             // Có biết dùng áp-phê Cu-lê/Trô không
  final bool useScratchPrevention;// Có biết né bi cái rơi lỗ không
  final bool useSafetyShot;       // Có biết giấu bi cái khi không có thế ăn không
  final int firstClearCoins;
  final int firstClearXP;
  final int firstClearDiamonds;
  final String description;

  const BotStageModel({
    required this.stageNumber,
    required this.title,
    required this.botName,
    required this.cueId,
    required this.aimErrorRad,
    required this.powerAccuracy,
    required this.useSpin,
    required this.useScratchPrevention,
    required this.useSafetyShot,
    required this.firstClearCoins,
    required this.firstClearXP,
    required this.firstClearDiamonds,
    required this.description,
  });

  CueModel get cue => CueCatalog.getById(cueId);

  String get tierName {
    if (stageNumber <= 3) return 'Hạng Đồng (Tân Thủ)';
    if (stageNumber <= 6) return 'Hạng Bạc (Chuyên Nghiệp)';
    if (stageNumber <= 8) return 'Hạng Vàng (Bậc Thầy)';
    return 'Hạng Kim Cương (Huyền Thoại)';
  }
}

class BotStageCatalog {
  static const List<BotStageModel> stages = [
    // --- TIER I: HẠNG ĐỒNG (TÂN THỦ & TẬP SỰ) ---
    BotStageModel(
      stageNumber: 1,
      title: 'Ải 1: Tân Thủ Học Việc',
      botName: 'Tân Thủ Tom',
      cueId: 'standard_cue',
      aimErrorRad: 0.075, // ~4.3 độ
      powerAccuracy: 0.65,
      useSpin: false,
      useScratchPrevention: false,
      useSafetyShot: false,
      firstClearCoins: 1000,
      firstClearXP: 120,
      firstClearDiamonds: 0,
      description: 'Đối thủ mới vào nghề, thường ngắm lệch ở khoảng cách xa và chưa biết dùng xoáy áp-phê.',
    ),
    BotStageModel(
      stageNumber: 2,
      title: 'Ải 2: Đấu Sĩ Titan',
      botName: 'Titan Jack',
      cueId: 'titan_striker',
      aimErrorRad: 0.048, // ~2.7 độ
      powerAccuracy: 0.72,
      useSpin: false,
      useScratchPrevention: true,
      useSafetyShot: false,
      firstClearCoins: 2500,
      firstClearXP: 220,
      firstClearDiamonds: 0,
      description: 'Lực phá bi cực mạnh nhờ gậy Titan, biết tính toán sơ lược để tránh bi cái rơi lỗ.',
    ),
    BotStageModel(
      stageNumber: 3,
      title: 'Ải 3: Tay Cơ Bán Chuyên',
      botName: 'Dennis Miller',
      cueId: 'titan_striker',
      aimErrorRad: 0.035, // ~2.0 độ
      powerAccuracy: 0.78,
      useSpin: false,
      useScratchPrevention: true,
      useSafetyShot: false,
      firstClearCoins: 5000,
      firstClearXP: 350,
      firstClearDiamonds: 2,
      description: 'Bắt đầu biết lựa chọn các bi ăn đơn giản và kiểm soát hướng bi cái không rơi vào thế bí.',
    ),

    // --- TIER II: HẠNG BẠC (CHUYÊN NGHIỆP & CAO THỦ) ---
    BotStageModel(
      stageNumber: 4,
      title: 'Ải 4: Băng Phong Hiệp Sĩ',
      botName: 'Arthur Frost',
      cueId: 'frostbite',
      aimErrorRad: 0.024, // ~1.4 độ
      powerAccuracy: 0.85,
      useSpin: true,
      useScratchPrevention: true,
      useSafetyShot: false,
      firstClearCoins: 9000,
      firstClearXP: 500,
      firstClearDiamonds: 5,
      description: 'Đường cơ ổn định và chính xác cao, bắt đầu áp dụng kỹ thuật cu-lê đẩy bóng cơ bản.',
    ),
    BotStageModel(
      stageNumber: 5,
      title: 'Ải 5: Kim Ngưu Trưởng Lão',
      botName: 'Đại sư Taurus',
      cueId: 'golden_bull',
      aimErrorRad: 0.015, // ~0.85 độ
      powerAccuracy: 0.88,
      useSpin: true,
      useScratchPrevention: true,
      useSafetyShot: true,
      firstClearCoins: 16000,
      firstClearXP: 750,
      firstClearDiamonds: 10,
      description: 'Bậc thầy chiến thuật phòng ngự, biết giấu bi cái (Safety Shot) khi không có cơ hội ăn bi.',
    ),
    BotStageModel(
      stageNumber: 6,
      title: 'Ải 6: Thợ Săn Tinh Anh',
      botName: 'Hunter Scott',
      cueId: 'golden_bull',
      aimErrorRad: 0.010, // ~0.57 độ
      powerAccuracy: 0.92,
      useSpin: true,
      useScratchPrevention: true,
      useSafetyShot: true,
      firstClearCoins: 28000,
      firstClearXP: 1000,
      firstClearDiamonds: 15,
      description: 'Khả năng tính toán gom cụm bi và tạo thế dọn bàn liên tiếp từ 2 đến 3 bi mục tiêu.',
    ),

    // --- TIER III: HẠNG VÀNG (BẬC THẦY QUỐC GIA) ---
    BotStageModel(
      stageNumber: 7,
      title: 'Ải 7: Chiến Binh Cyber Neo',
      botName: 'Cyborg 2077',
      cueId: 'cyber_neo',
      aimErrorRad: 0.006, // ~0.34 độ
      powerAccuracy: 0.95,
      useSpin: true,
      useScratchPrevention: true,
      useSafetyShot: true,
      firstClearCoins: 45000,
      firstClearXP: 1400,
      firstClearDiamonds: 25,
      description: 'Phân tích hình học vi mạch chuẩn xác, đánh được các góc cắt siêu hẹp và dội băng hoàn hảo.',
    ),
    BotStageModel(
      stageNumber: 8,
      title: 'Ải 8: Phượng Hoàng Lửa',
      botName: 'Hỏa Nữ Phoenix',
      cueId: 'phoenix_flame',
      aimErrorRad: 0.003, // ~0.17 độ
      powerAccuracy: 0.98,
      useSpin: true,
      useScratchPrevention: true,
      useSafetyShot: true,
      firstClearCoins: 75000,
      firstClearXP: 2000,
      firstClearDiamonds: 50,
      description: 'Lối đánh áp-phê trô giật ngược và cu-lê đẩy bóng đỉnh cao, dọn bàn trong tích tắc.',
    ),

    // --- TIER IV: HẠNG KIM CƯƠNG & HUYỀN THOẠI (QUÁN QUÂN THẾ GIỚI) ---
    BotStageModel(
      stageNumber: 9,
      title: 'Ải 9: Độc Cô Cầu Bại',
      botName: 'Sát Thủ Ronin',
      cueId: 'phoenix_flame',
      aimErrorRad: 0.0012, // ~0.06 độ
      powerAccuracy: 0.99,
      useSpin: true,
      useScratchPrevention: true,
      useSafetyShot: true,
      firstClearCoins: 110000,
      firstClearXP: 3200,
      firstClearDiamonds: 75,
      description: 'Cơ thủ bất bại với tuyệt kỹ trô bóng xuyên bàn, điều bi chuẩn từng milimet trên mặt nỉ.',
    ),
    BotStageModel(
      stageNumber: 10,
      title: 'Ải 10: Thần Long Tối Thượng (World Champion)',
      botName: 'Long Đế Master',
      cueId: 'dragon_god',
      aimErrorRad: 0.0, // Chuẩn xác tuyệt đối
      powerAccuracy: 1.0,
      useSpin: true,
      useScratchPrevention: true,
      useSafetyShot: true,
      firstClearCoins: 200000,
      firstClearXP: 6000,
      firstClearDiamonds: 150,
      description: 'Đẳng cấp Kiện Tướng Thế Giới: Ngắm chuẩn tuyệt đối từng phân số góc, không phạm bất kỳ sai sót nào!',
    ),
  ];

  static BotStageModel getStage(int stageNumber) {
    return stages.firstWhere(
      (s) => s.stageNumber == stageNumber,
      orElse: () => stages.first,
    );
  }
}
