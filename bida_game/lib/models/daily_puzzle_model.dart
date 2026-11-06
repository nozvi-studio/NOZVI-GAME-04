class PuzzleBallConfig {
  final int ballNumber;
  final double normX; // Tỉ lệ 0.0 -> 1.0 theo chiều dài bàn
  final double normY; // Tỉ lệ 0.0 -> 1.0 theo chiều rộng bàn
  final bool isObstacle; // Bi cản trở (nếu đánh rơi lỗ sẽ bị phạt/thua)

  const PuzzleBallConfig({
    required this.ballNumber,
    required this.normX,
    required this.normY,
    this.isObstacle = false,
  });
}

class DailyPuzzleModel {
  final String dateKey; // YYYY-MM-DD
  final String title;
  final String description;
  final String hint;
  final double cueBallNormX;
  final double cueBallNormY;
  final List<PuzzleBallConfig> balls;
  final int maxShotsAllowed;
  final int rewardCoins;
  final int rewardXP;
  final int rewardDiamonds;

  const DailyPuzzleModel({
    required this.dateKey,
    required this.title,
    required this.description,
    required this.hint,
    required this.cueBallNormX,
    required this.cueBallNormY,
    required this.balls,
    required this.maxShotsAllowed,
    required this.rewardCoins,
    required this.rewardXP,
    required this.rewardDiamonds,
  });

  /// Sinh thế bi ngẫu nhiên theo ngày (cùng 1 ngày mọi người chơi đều nhận thế bi giống nhau)
  static DailyPuzzleModel generateForDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final dateKey = '$year-$month-$day';

    final seed = year * 10000 + date.month * 100 + date.day;
    final puzzleIndex = seed % 6;

    switch (puzzleIndex) {
      case 0:
        return DailyPuzzleModel(
          dateKey: dateKey,
          title: 'Thế Bi: Khe Cửa Hẹp',
          description: 'Ăn bi số 1 vào lỗ góc phía trên qua khe hẹp giữa 2 bi chướng ngại vật!',
          hint: 'Gợi ý: Căn tia ngắm thật chuẩn xác và dùng lực nhẹ vừa đủ (lực 40%).',
          cueBallNormX: 0.28,
          cueBallNormY: 0.50,
          balls: [
            const PuzzleBallConfig(ballNumber: 1, normX: 0.65, normY: 0.35),
            const PuzzleBallConfig(ballNumber: 8, normX: 0.62, normY: 0.26, isObstacle: true),
            const PuzzleBallConfig(ballNumber: 9, normX: 0.66, normY: 0.44, isObstacle: true),
          ],
          maxShotsAllowed: 1,
          rewardCoins: 500,
          rewardXP: 250,
          rewardDiamonds: 5,
        );

      case 1:
        return DailyPuzzleModel(
          dateKey: dateKey,
          title: 'Thế Bi: Trô Giật Ngược',
          description: 'Ăn bi số 3 vào lỗ giữa, sau đó bi cái phải trô lùi lại để ăn tiếp bi số 7!',
          hint: 'Gợi ý: Chỉnh áp-phê Trô lùi hết cỡ xuống phía dưới và kéo lực 80%.',
          cueBallNormX: 0.35,
          cueBallNormY: 0.35,
          balls: [
            const PuzzleBallConfig(ballNumber: 3, normX: 0.50, normY: 0.24),
            const PuzzleBallConfig(ballNumber: 7, normX: 0.24, normY: 0.45),
          ],
          maxShotsAllowed: 2,
          rewardCoins: 500,
          rewardXP: 250,
          rewardDiamonds: 5,
        );

      case 2:
        return DailyPuzzleModel(
          dateKey: dateKey,
          title: 'Thế Bi: Dội Băng A-băng',
          description: 'Bi số 5 bị che khuất đường thẳng, bắt buộc phải dội bi cái qua 1 băng để ăn bi số 5!',
          hint: 'Gợi ý: Ngắm đập băng dưới để góc phản xạ dội trúng bi mục tiêu.',
          cueBallNormX: 0.32,
          cueBallNormY: 0.30,
          balls: [
            const PuzzleBallConfig(ballNumber: 5, normX: 0.65, normY: 0.72),
            const PuzzleBallConfig(ballNumber: 8, normX: 0.48, normY: 0.51, isObstacle: true),
          ],
          maxShotsAllowed: 1,
          rewardCoins: 600,
          rewardXP: 300,
          rewardDiamonds: 5,
        );

      case 3:
        return DailyPuzzleModel(
          dateKey: dateKey,
          title: 'Thế Bi: Cu-lê Đẩy Tới',
          description: 'Đánh ăn bi số 2 và dùng lực Cu-lê đẩy bi cái tiến tới để phá rơi bi số 6 vào lỗ đối diện!',
          hint: 'Gợi ý: Chỉnh điểm chạm cơ lên đỉnh cao nhất của bi cái (Top-spin).',
          cueBallNormX: 0.30,
          cueBallNormY: 0.55,
          balls: [
            const PuzzleBallConfig(ballNumber: 2, normX: 0.55, normY: 0.55),
            const PuzzleBallConfig(ballNumber: 6, normX: 0.78, normY: 0.55),
          ],
          maxShotsAllowed: 1,
          rewardCoins: 500,
          rewardXP: 250,
          rewardDiamonds: 5,
        );

      case 4:
        return DailyPuzzleModel(
          dateKey: dateKey,
          title: 'Thế Bi: Tam Điểm Liên Hoàn',
          description: 'Dọn sạch 3 bi mục tiêu (bi 4, 10, 11) trên bàn trong vòng 2 lượt bắn!',
          hint: 'Gợi ý: Có thể đánh bi 4 ăn vào lỗ và làm bi 4 văng sang bi 10 tạo cú va chạm kép (Combo Shot).',
          cueBallNormX: 0.25,
          cueBallNormY: 0.45,
          balls: [
            const PuzzleBallConfig(ballNumber: 4, normX: 0.55, normY: 0.35),
            const PuzzleBallConfig(ballNumber: 10, normX: 0.70, normY: 0.30),
            const PuzzleBallConfig(ballNumber: 11, normX: 0.72, normY: 0.68),
          ],
          maxShotsAllowed: 2,
          rewardCoins: 700,
          rewardXP: 350,
          rewardDiamonds: 8,
        );

      default:
        // Bi kẹt sát băng
        return DailyPuzzleModel(
          dateKey: dateKey,
          title: 'Thế Bi: Cắt Băng Mép Bàn',
          description: 'Bi mục tiêu nằm dính sát mép băng, đòi hỏi cú cắt mỏng cực kỳ tinh tế vào lỗ góc!',
          hint: 'Gợi ý: Căn góc cắt thật mỏng và áp-phê nhẹ theo chiều băng.',
          cueBallNormX: 0.32,
          cueBallNormY: 0.70,
          balls: [
            const PuzzleBallConfig(ballNumber: 9, normX: 0.78, normY: 0.84),
            const PuzzleBallConfig(ballNumber: 8, normX: 0.55, normY: 0.70, isObstacle: true),
          ],
          maxShotsAllowed: 1,
          rewardCoins: 550,
          rewardXP: 280,
          rewardDiamonds: 5,
        );
    }
  }
}
