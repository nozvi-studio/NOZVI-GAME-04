import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'trickshot_localization.dart';
import 'game_content_localization.dart';

/// 5 ngôn ngữ hỗ trợ: Việt, Anh, Trung, Nhật, Hàn
enum AppLanguage {
  vi('vi', 'Tiếng Việt', 'Vietnamese', '🇻🇳'),
  en('en', 'English', 'English', '🇬🇧'),
  zh('zh', '中文', 'Chinese', '🇨🇳'),
  ja('ja', '日本語', 'Japanese', '🇯🇵'),
  ko('ko', '한국어', 'Korean', '🇰🇷');

  final String code;
  final String nativeName;
  final String englishName;
  final String flag;

  const AppLanguage(this.code, this.nativeName, this.englishName, this.flag);

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.vi,
    );
  }
}

/// Dịch vụ quản lý ngôn ngữ và bản địa hóa đa ngôn ngữ toàn game
class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._();
  LanguageService._();

  static const String _prefKey = 'app_selected_language';
  AppLanguage _currentLanguage = AppLanguage.vi;

  AppLanguage get currentLanguage => _currentLanguage;
  String get currentCode => _currentLanguage.code;

  /// Khởi tạo và nạp ngôn ngữ đã lưu từ SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null) {
        _currentLanguage = AppLanguage.fromCode(savedCode);
      }
    } catch (e) {
      debugPrint('LanguageService init error: $e');
    }
  }

  /// Thay đổi ngôn ngữ và lưu vĩnh viễn
  Future<void> setLanguage(AppLanguage language) async {
    if (_currentLanguage == language) return;
    _currentLanguage = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, language.code);
    } catch (e) {
      debugPrint('LanguageService save error: $e');
    }
  }

  /// Lấy bản dịch theo key
  String t(String key) {
    final langMap = _translations[key];
    if (langMap == null) return key;
    return langMap[_currentLanguage.code] ?? langMap['en'] ?? langMap['vi'] ?? key;
  }


  /// Bản địa hóa gậy cơ, thành tựu, huy chương & xoáy bi
  String localizeCueName(String id, [String fallback = '']) =>
      GameContentLocalization.getCueName(id, _currentLanguage.code, fallback);

  String localizeCueDescription(String id, [String fallback = '']) =>
      GameContentLocalization.getCueDescription(id, _currentLanguage.code, fallback);

  String localizeCuePerk(String id, [String fallback = '']) =>
      GameContentLocalization.getCuePerk(id, _currentLanguage.code, fallback);

  String localizeCueRarity(String key, [String fallback = '']) =>
      GameContentLocalization.getCueRarity(key, _currentLanguage.code, fallback);

  String localizeAchievementTitle(String id, [String fallback = '']) =>
      GameContentLocalization.getAchievementTitle(id, _currentLanguage.code, fallback);

  String localizeAchievementDescription(String id, [String fallback = '']) =>
      GameContentLocalization.getAchievementDescription(id, _currentLanguage.code, fallback);

  String localizeAchievementDifficulty(String key, [String fallback = '']) =>
      GameContentLocalization.getAchievementDifficulty(key, _currentLanguage.code, fallback);

  String localizeMedalName(String id, [String fallback = '']) =>
      GameContentLocalization.getMedalName(id, _currentLanguage.code, fallback);

  String localizeMedalDescription(String id, [String fallback = '']) =>
      GameContentLocalization.getMedalDescription(id, _currentLanguage.code, fallback);

  String localizeMedalRequirement(String id, [String fallback = '']) =>
      GameContentLocalization.getMedalRequirement(id, _currentLanguage.code, fallback);

  String localizeMedalRarity(String key, [String fallback = '']) =>
      GameContentLocalization.getMedalRarity(key, _currentLanguage.code, fallback);

  String localizeTableRarity(String key, [String fallback = '']) =>
      GameContentLocalization.getTableRarity(key, _currentLanguage.code, fallback);

  String localizeTableSkinName(String id, [String fallback = '']) =>
      GameContentLocalization.getTableSkinName(id, _currentLanguage.code, fallback);

  String localizeTableSkinDescription(String id, [String fallback = '']) =>
      GameContentLocalization.getTableSkinDescription(id, _currentLanguage.code, fallback);

  String describeSpin(Offset spin) =>
      GameContentLocalization.describeSpin(spin, _currentLanguage.code);

  /// Bản địa hóa tên đối thủ máy / giải đấu / người chơi
  String localizeOpponentName(String raw) {
    if (raw.isEmpty) return raw;
    final lang = _currentLanguage.code;
    if (lang == 'vi') return raw;

    if (raw == 'Đối thủ Online') {
      return switch (lang) {
        'en' => 'Online Opponent',
        'zh' => '网络对手',
        'ja' => 'オンライン対戦相手',
        'ko' => '온라인 상대',
        _ => raw,
      };
    }
    if (raw == 'Đối thủ') {
      return switch (lang) {
        'en' => 'Opponent',
        'zh' => '对手',
        'ja' => '対戦相手',
        'ko' => '상대방',
        _ => raw,
      };
    }
    if (raw == 'Chủ phòng (P1)') {
      return switch (lang) {
        'en' => 'Host (P1)',
        'zh' => '房主 (P1)',
        'ja' => 'ホスト (P1)',
        'ko' => '방장 (P1)',
        _ => raw,
      };
    }
    if (raw == 'Khách (P2)') {
      return switch (lang) {
        'en' => 'Guest (P2)',
        'zh' => '访客 (P2)',
        'ja' => 'ゲスト (P2)',
        'ko' => '게스트 (P2)',
        _ => raw,
      };
    }
    if (raw == 'Hoàng Nam') {
      return switch (lang) {
        'en' => 'Hoang Nam',
        'zh' => '黄楠',
        'ja' => 'ホアン・ナム',
        'ko' => '황남',
        _ => raw,
      };
    }
    if (raw == 'Minh Tuấn') {
      return switch (lang) {
        'en' => 'Minh Tuan',
        'zh' => '明俊',
        'ja' => 'ミン・トゥアン',
        'ko' => '민투안',
        _ => raw,
      };
    }
    if (raw == 'Kim Sơn') {
      return switch (lang) {
        'en' => 'Kim Son',
        'zh' => '金山',
        'ja' => 'キム・ソン',
        'ko' => '김손',
        _ => raw,
      };
    }
    if (raw == 'Bảo Long') {
      return switch (lang) {
        'en' => 'Bao Long',
        'zh' => '保龙',
        'ja' => 'バオ・ロン',
        'ko' => '바오롱',
        _ => raw,
      };
    }
    if (raw.contains('Long Hoàng Vũ') || raw.contains('(Đương Kim Vô Địch)')) {
      return switch (lang) {
        'en' => 'Long Hoang Vu (Defending Champion)',
        'zh' => '龙皇武 (卫冕冠军)',
        'ja' => 'ロン・ホアン・ヴー (ディフェンディングチャンピオン)',
        'ko' => '롱황부 (디펜딩 챔피언)',
        _ => raw,
      };
    }
    if (raw == 'Tân Thủ Tom') {
      return switch (lang) {
        'en' => 'Rookie Tom',
        'zh' => '新手汤姆',
        'ja' => 'ルーキー・トム',
        'ko' => '루키 톰',
        _ => raw,
      };
    }
    if (raw == 'Titan Jack') {
      return switch (lang) {
        'en' => 'Titan Jack',
        'zh' => '泰坦杰克',
        'ja' => 'タイタン・ジャック',
        'ko' => '타이탄 잭',
        _ => raw,
      };
    }
    if (raw.startsWith('Cơ Thủ Khách')) {
      final id = raw.replaceFirst('Cơ Thủ Khách', '').trim();
      return switch (lang) {
        'en' => 'Guest Cueist $id',
        'zh' => '访客球手 $id',
        'ja' => 'ゲストプレイヤー $id',
        'ko' => '게스트 플레이어 $id',
        _ => raw,
      };
    }
    if (raw == 'Khách') {
      return switch (lang) {
        'en' => 'Guest',
        'zh' => '访客',
        'ja' => 'ゲスト',
        'ko' => '게스트',
        _ => raw,
      };
    }
    if (raw == 'Quản Trị Viên (Admin)') {
      return switch (lang) {
        'en' => 'Administrator (Admin)',
        'zh' => '管理员 (Admin)',
        'ja' => '管理者 (Admin)',
        'ko' => '관리자 (Admin)',
        _ => raw,
      };
    }
    return raw;
  }

  /// Bản địa hóa thông điệp phần thưởng khi kết thúc trận đấu
  String localizeCustomRewardMessage(String raw) {
    if (raw.isEmpty) return raw;
    final lang = _currentLanguage.code;
    if (lang == 'vi') return raw;

    final winLocalReg = RegExp(r'^THẮNG ĐẤU MẠNG LOCAL\s*\(\+(\d+)\s*VÀNG\)$', caseSensitive: false);
    final winLocalMatch = winLocalReg.firstMatch(raw);
    if (winLocalMatch != null) {
      final coins = winLocalMatch.group(1) ?? '';
      return switch (lang) {
        'en' => 'LOCAL MULTIPLAYER VICTORY (+$coins COINS)',
        'zh' => '局域网对决胜利 (+$coins 金币)',
        'ja' => 'ローカル対戦勝利 (+$coins コイン)',
        'ko' => '로컬 대전 승리 (+$coins 코인)',
        _ => raw,
      };
    }

    final loseLocalReg = RegExp(r'^THUA ĐẤU MẠNG LOCAL\s*\(-(\d+)\s*VÀNG\)$', caseSensitive: false);
    final loseLocalMatch = loseLocalReg.firstMatch(raw);
    if (loseLocalMatch != null) {
      final coins = loseLocalMatch.group(1) ?? '';
      return switch (lang) {
        'en' => 'LOCAL MULTIPLAYER DEFEAT (-$coins COINS)',
        'zh' => '局域网对决战败 (-$coins 金币)',
        'ja' => 'ローカル対戦敗北 (-$coins コイン)',
        'ko' => '로컬 대전 패배 (-$coins 코인)',
        _ => raw,
      };
    }

    final clearStageReg = RegExp(r'^VƯỢT ẢI\s*(\d+)\s*LẦN ĐẦU THÀNH CÔNG!$', caseSensitive: false);
    final clearStageMatch = clearStageReg.firstMatch(raw);
    if (clearStageMatch != null) {
      final num = clearStageMatch.group(1) ?? '';
      return switch (lang) {
        'en' => 'FIRST CLEAR STAGE $num BONUS!',
        'zh' => '首次通关第 $num 关奖励!',
        'ja' => 'ステージ $num 初回クリア報酬!',
        'ko' => '스테이지 $num 최초 클리어 보너스!',
        _ => raw,
      };
    }

    final conquerShotReg = RegExp(r'^CHINH PHỤC THẾ ĐÁNH CỦA\s*(.*?)!$', caseSensitive: false);
    final conquerShotMatch = conquerShotReg.firstMatch(raw);
    if (conquerShotMatch != null) {
      final master = conquerShotMatch.group(1)?.trim() ?? '';
      return switch (lang) {
        'en' => "CONQUERED $master'S TRICKSHOT!",
        'zh' => '成功征服 $master 的传奇杆法!',
        'ja' => '$master のトリックショットを完全攻略!',
        'ko' => '$master 의 명샷 정복 완료!',
        _ => raw,
      };
    }

    final practiceShotReg = RegExp(r'^HOÀN THÀNH LUYỆN TẬP THẾ ĐÁNH\s*(.*?)!$', caseSensitive: false);
    final practiceShotMatch = practiceShotReg.firstMatch(raw);
    if (practiceShotMatch != null) {
      final master = practiceShotMatch.group(1)?.trim() ?? '';
      return switch (lang) {
        'en' => "COMPLETED PRACTICE: $master'S SHOT!",
        'zh' => '完成练习: $master 的击球!',
        'ja' => '練習完了: $master のショット!',
        'ko' => '연습 완료: $master 의 샷!',
        _ => raw,
      };
    }

    final champReg = RegExp(r'^🏆\s*QUÁN QUÂN VÔ ĐỊCH TOURNAMENT 5 BRACKETS\s*\(\+(\d+)\s*VÀNG,\s*CÚP VÀNG & THÀNH TỰU\)!$', caseSensitive: false);
    final champMatch = champReg.firstMatch(raw);
    if (champMatch != null) {
      final coins = champMatch.group(1) ?? '';
      return switch (lang) {
        'en' => '🏆 TOURNAMENT CHAMPION 5 BRACKETS (+$coins COINS, GOLD CUP & ACHIEVEMENTS)!',
        'zh' => '🏆 5 轮锦标赛总冠军 (+$coins 金币，金杯与成就)!',
        'ja' => '🏆 5回戦トーナメント完全制覇 (+$coins コイン、ゴールドトロフィー＆実績)!',
        'ko' => '🏆 5라운드 토너먼트 종합 우승 (+$coins 코인, 골드 트로피 및 업적)!',
        _ => raw,
      };
    }

    return raw;
  }

  /// Bản địa hóa lỗi xác thực đăng nhập / đăng ký
  String localizeAuthError(String err) {
    if (err.isEmpty) return err;
    final lang = _currentLanguage.code;
    if (lang == 'vi') return err;

    if (err.contains('Mật khẩu phải có ít nhất 6 ký tự')) {
      return switch (lang) {
        'en' => 'Password must be at least 6 characters.',
        'zh' => '密码长度至少为 6 个字符。',
        'ja' => 'パスワードは6文字以上である必要があります。',
        'ko' => '비밀번호는 최소 6자 이상이어야 합니다.',
        _ => err,
      };
    }
    if (err.contains('Vui lòng nhập tên hiển thị')) {
      return switch (lang) {
        'en' => 'Please enter a display name.',
        'zh' => '请输入显示昵称。',
        'ja' => '表示名を入力してください。',
        'ko' => '표시 이름을 입력해 주세요.',
        _ => err,
      };
    }
    if (err.contains('Firebase chưa được khởi tạo')) {
      return switch (lang) {
        'en' => 'Firebase is not initialized.',
        'zh' => 'Firebase 尚未初始化。',
        'ja' => 'Firebase が初期化されていません。',
        'ko' => 'Firebase가 초기화되지 않았습니다.',
        _ => err,
      };
    }
    if (err.contains('Tài khoản hoặc Email này đã tồn tại')) {
      return switch (lang) {
        'en' => 'This account or email already exists in the system.',
        'zh' => '该账号或邮箱已存在。',
        'ja' => 'このアカウントまたはメールアドレスは既に登録されています。',
        'ko' => '이 계정 또는 이메일은 이미 등록되어 있습니다.',
        _ => err,
      };
    }
    if (err.contains('Địa chỉ Email không hợp lệ')) {
      return switch (lang) {
        'en' => 'Invalid email address.',
        'zh' => '无效的电子邮箱地址。',
        'ja' => '無効なメールアドレスです。',
        'ko' => '유효하지 않은 이메일 주소입니다.',
        _ => err,
      };
    }
    if (err.contains('Mật khẩu quá yếu')) {
      return switch (lang) {
        'en' => 'Weak password, please choose a stronger one.',
        'zh' => '密码太弱，请设置更复杂的密码。',
        'ja' => 'パスワードが脆弱です。より強力なものを設定してください。',
        'ko' => '비밀번호가 취약합니다. 더 강력한 비밀번호를 선택하세요.',
        _ => err,
      };
    }
    if (err.contains('Đăng ký thất bại')) {
      return switch (lang) {
        'en' => 'Registration failed. Please try again.',
        'zh' => '注册失败，请稍后重试。',
        'ja' => '登録に失敗しました。再試行してください。',
        'ko' => '회원가입 실패. 다시 시도해 주세요.',
        _ => err,
      };
    }
    if (err.contains('Không tìm thấy tài khoản')) {
      return switch (lang) {
        'en' => 'Account not found in the system.',
        'zh' => '系统中未找到该账号。',
        'ja' => 'アカウントが見つかりません。',
        'ko' => '시스템에서 해당 계정을 찾을 수 없습니다.',
        _ => err,
      };
    }
    if (err.contains('Sai mật khẩu hoặc thông tin')) {
      return switch (lang) {
        'en' => 'Incorrect password or login credentials.',
        'zh' => '密码或登录凭据错误。',
        'ja' => 'パスワードまたはログイン情報が間違っています。',
        'ko' => '비밀번호 또는 로그인 정보가 올바르지 않습니다.',
        _ => err,
      };
    }
    if (err.contains('Tên tài khoản hoặc Email không hợp lệ')) {
      return switch (lang) {
        'en' => 'Invalid username or email format.',
        'zh' => '账号名称或邮箱格式无效。',
        'ja' => 'ユーザー名またはメールの形式が無効です。',
        'ko' => '유효하지 않은 사용자 이름 또는 이메일 형식입니다.',
        _ => err,
      };
    }
    if (err.contains('Tài khoản này đã bị tạm khóa')) {
      return switch (lang) {
        'en' => 'This account has been temporarily disabled.',
        'zh' => '此账号已被暂时停用。',
        'ja' => 'このアカウントは一時的に凍結されています。',
        'ko' => '이 계정은 일시적으로 비활성화되었습니다.',
        _ => err,
      };
    }
    if (err.contains('Đăng nhập thất bại')) {
      return switch (lang) {
        'en' => 'Login failed. Please try again.',
        'zh' => '登录失败，请稍后重试。',
        'ja' => 'ログインに失敗しました。再試行してください。',
        'ko' => '로그인 실패. 다시 시도해 주세요.',
        _ => err,
      };
    }
    if (err.contains('Không thể vào chế độ khách')) {
      return switch (lang) {
        'en' => 'Unable to enter guest mode.',
        'zh' => '无法进入访客模式。',
        'ja' => 'ゲストモードに入ることができません。',
        'ko' => '게스트 모드로 들어갈 수 없습니다.',
        _ => err,
      };
    }
    if (err.startsWith('Đã xảy ra lỗi:')) {
      final detail = err.replaceFirst('Đã xảy ra lỗi:', '').trim();
      return switch (lang) {
        'en' => 'An error occurred: $detail',
        'zh' => '发生错误: $detail',
        'ja' => 'エラーが発生しました: $detail',
        'ko' => '오류가 발생했습니다: $detail',
        _ => err,
      };
    }
    return err;
  }

  /// Dịch tên tầng hạng (Tier) của ải Bot
  String localizeTierName(String tier) {
    final lang = _currentLanguage.code;
    if (tier.contains('Đồng')) {
      return switch (lang) {
        'en' => 'Bronze Tier',
        'zh' => '青铜段位',
        'ja' => 'ブロンズ階級',
        'ko' => '브론즈 등급',
        _ => tier,
      };
    }
    if (tier.contains('Bạc')) {
      return switch (lang) {
        'en' => 'Silver Tier',
        'zh' => '白银段位',
        'ja' => 'シルバー階級',
        'ko' => '실버 등급',
        _ => tier,
      };
    }
    if (tier.contains('Vàng')) {
      return switch (lang) {
        'en' => 'Gold Tier',
        'zh' => '黄金段位',
        'ja' => 'ゴールド階級',
        'ko' => '골드 등급',
        _ => tier,
      };
    }
    if (tier.contains('Kim Cương')) {
      return switch (lang) {
        'en' => 'Diamond Tier',
        'zh' => '钻石段位',
        'ja' => 'ダイヤ階級',
        'ko' => '다이아몬드 등급',
        _ => tier,
      };
    }
    return tier;
  }

  /// Dịch tên các ải thử thách hoặc vòng đấu
  String localizeStageTitle(String title) {
    final lang = _currentLanguage.code;
    if (lang == 'vi' || title.isEmpty) return title;

    // Tách tiền tố "Ải X: " nếu có
    final stagePrefixReg = RegExp(r'^(?:Ải|Stage)\s*(\d+)[:.]\s*(.*)$', caseSensitive: false);
    final prefixMatch = stagePrefixReg.firstMatch(title);
    String core = title;
    int? stageNum;
    if (prefixMatch != null) {
      stageNum = int.tryParse(prefixMatch.group(1) ?? '');
      core = prefixMatch.group(2)?.trim() ?? title;
    }

    String translatedCore = core;

    // 10 Ải Bot Campaign
    if (core.contains('Tân Thủ Học Việc')) {
      translatedCore = switch (lang) {
        'en' => 'Apprentice Novice',
        'zh' => '学徒新手',
        'ja' => '見習いルーキー',
        'ko' => '수습 초보자',
        _ => core,
      };
    } else if (core.contains('Đấu Sĩ Titan')) {
      translatedCore = switch (lang) {
        'en' => 'Titan Striker',
        'zh' => '泰坦斗士',
        'ja' => 'タイタンファイター',
        'ko' => '타이탄 전사',
        _ => core,
      };
    } else if (core.contains('Tay Cơ Bán Chuyên')) {
      translatedCore = switch (lang) {
        'en' => 'Semi-Pro Player',
        'zh' => '半职业球手',
        'ja' => 'セミプロプレイヤー',
        'ko' => '세미프로 선수',
        _ => core,
      };
    } else if (core.contains('Băng Phong Hiệp Sĩ')) {
      translatedCore = switch (lang) {
        'en' => 'Frost Knight',
        'zh' => '寒冰骑士',
        'ja' => '氷霜の騎士',
        'ko' => '빙풍의 기사',
        _ => core,
      };
    } else if (core.contains('Kim Ngưu Trưởng Lão')) {
      translatedCore = switch (lang) {
        'en' => 'Taurus Elder',
        'zh' => '金牛长老',
        'ja' => '金牛の長老',
        'ko' => '황소 장로',
        _ => core,
      };
    } else if (core.contains('Thợ Săn Tinh Anh')) {
      translatedCore = switch (lang) {
        'en' => 'Elite Hunter',
        'zh' => '精英猎手',
        'ja' => 'エリートハンター',
        'ko' => '엘리트 헌터',
        _ => core,
      };
    } else if (core.contains('Chiến Binh Cyber Neo')) {
      translatedCore = switch (lang) {
        'en' => 'Cyber Neo Warrior',
        'zh' => '赛博新纪元勇士',
        'ja' => 'サイバーネオ戦士',
        'ko' => '사이버 네오 워리어',
        _ => core,
      };
    } else if (core.contains('Phượng Hoàng Lửa')) {
      translatedCore = switch (lang) {
        'en' => 'Phoenix Flame',
        'zh' => '烈焰凤凰',
        'ja' => '不死鳥の炎',
        'ko' => '불사조의 화염',
        _ => core,
      };
    } else if (core.contains('Độc Cô Cầu Bại')) {
      translatedCore = switch (lang) {
        'en' => 'Invincible Ronin',
        'zh' => '独孤求败',
        'ja' => '無敗の浪人',
        'ko' => '독고구패',
        _ => core,
      };
    } else if (core.contains('Thần Long Tối Thượng')) {
      final isWc = core.contains('World Champion');
      translatedCore = switch (lang) {
        'en' => isWc ? 'Supreme Dragon (World Champion)' : 'Supreme Dragon',
        'zh' => isWc ? '至尊神龙 (世界冠军)' : '至尊神龙',
        'ja' => isWc ? '至高の神龍 (世界チャンピオン)' : '至高の神龍',
        'ko' => isWc ? '지고의 신룡 (세계 챔피언)' : '지고의 신룡',
        _ => core,
      };
    } else if (core.contains('Nhập Môn Bida')) {
      translatedCore = switch (lang) {
        'en' => 'Billiards Novice',
        'zh' => '台球初入门',
        'ja' => 'ビリヤード入門',
        'ko' => '당구 입문',
        _ => core,
      };
    } else if (core.contains('Tập Sự Băng Ngắn')) {
      translatedCore = switch (lang) {
        'en' => 'Short Rail Trainee',
        'zh' => '短库学徒',
        'ja' => 'ショートレール見習い',
        'ko' => '단쿠션 연습생',
        _ => core,
      };
    } else if (core.contains('Chiến Binh Bàn Xanh')) {
      translatedCore = switch (lang) {
        'en' => 'Green Table Warrior',
        'zh' => '绿台勇士',
        'ja' => 'グリーンテーブル戦士',
        'ko' => '녹색 테이블의 전사',
        _ => core,
      };
    }
    // Tournament Brackets
    else if (core.contains('VÒNG SƠ TUYỂN')) {
      translatedCore = switch (lang) {
        'en' => 'QUALIFYING ROUND',
        'zh' => '初赛选拔',
        'ja' => '予選ラウンド',
        'ko' => '예선 라운드',
        _ => core,
      };
    } else if (core.contains('VÒNG TUYỂN CHỌN')) {
      translatedCore = switch (lang) {
        'en' => 'SELECTION ROUND',
        'zh' => '晋级赛',
        'ja' => '選抜ラウンド',
        'ko' => '선발 라운드',
        _ => core,
      };
    } else if (core.contains('VÒNG TỨ KẾT')) {
      translatedCore = switch (lang) {
        'en' => 'QUARTER-FINALS',
        'zh' => '1/4 决赛',
        'ja' => '準々決勝',
        'ko' => '8강 준준결승',
        _ => core,
      };
    } else if (core.contains('VÒNG BÁN KẾT')) {
      translatedCore = switch (lang) {
        'en' => 'SEMI-FINALS',
        'zh' => '半决赛',
        'ja' => '準決勝',
        'ko' => '4강 준결승',
        _ => core,
      };
    } else if (core.contains('ĐẠI CHUNG KẾT')) {
      translatedCore = switch (lang) {
        'en' => 'GRAND CHAMPIONSHIP FINALS',
        'zh' => '巅峰总决赛',
        'ja' => '頂上グランドファイナル',
        'ko' => '정상 그랜드 파이널',
        _ => core,
      };
    }
    // Daily Puzzles
    else if (core.contains('Khe Cửa Hẹp')) {
      translatedCore = switch (lang) {
        'en' => 'Narrow Gap',
        'zh' => '狭窄缝隙',
        'ja' => '狭い隙間',
        'ko' => '좁은 틈새',
        _ => core,
      };
    } else if (core.contains('Trô Giật Ngược')) {
      translatedCore = switch (lang) {
        'en' => 'Extreme Draw',
        'zh' => '强力低杆',
        'ja' => 'エクストリーム・ドロー',
        'ko' => '강력한 끌어치기',
        _ => core,
      };
    } else if (core.contains('Dội Băng A-băng')) {
      translatedCore = switch (lang) {
        'en' => 'Bank Shot Ricochet',
        'zh' => '翻袋解球',
        'ja' => 'バンクショット',
        'ko' => '쿠션 뱅크샷',
        _ => core,
      };
    } else if (core.contains('Cu-lê Đẩy Tới')) {
      translatedCore = switch (lang) {
        'en' => 'Topspin Follow',
        'zh' => '高杆推杆',
        'ja' => 'フォローショット',
        'ko' => '상단 밀어치기',
        _ => core,
      };
    } else if (core.contains('Tam Điểm Liên Hoàn')) {
      translatedCore = switch (lang) {
        'en' => 'Triple Combo',
        'zh' => '三点连环',
        'ja' => 'トリプルコンボ',
        'ko' => '3연속 콤보',
        _ => core,
      };
    } else if (core.contains('Cắt Băng Mép Bàn')) {
      translatedCore = switch (lang) {
        'en' => 'Thin Rail Cut',
        'zh' => '贴库薄切',
        'ja' => 'クッション薄切り',
        'ko' => '쿠션 얇은 컷',
        _ => core,
      };
    }
    // Legendary Trickshots
    else if (core.contains('Z-Bank')) {
      translatedCore = switch (lang) {
        'en' => 'Legendary Z-Bank Shot',
        'zh' => '传奇Z字折射',
        'ja' => '伝説のZバンクショット',
        'ko' => '전설의 Z-뱅크 샷',
        _ => core,
      };
    } else if (core.contains('Siêu Trô Kéo Lùi Xuyên Bàn')) {
      translatedCore = switch (lang) {
        'en' => 'Super Table-Length Draw',
        'zh' => '超级全台强拉低杆',
        'ja' => 'スーパードローバック',
        'ko' => '슈퍼 테이블 드로우',
        _ => core,
      };
    } else if (core.contains('Cu-Lê Đẩy Xoáy 2 Băng Tuyệt Đỉnh')) {
      translatedCore = switch (lang) {
        'en' => 'Masterful 2-Cushion Follow',
        'zh' => '绝妙两库高杆推杆',
        'ja' => '2クッション極上フォロー',
        'ko' => '2쿠션 탑스핀 팔로우',
        _ => core,
      };
    } else if (core.contains('Áp-Phê Ngược Bẻ Băng Lỗ Tít')) {
      translatedCore = switch (lang) {
        'en' => 'Reverse English Sharp Kick',
        'zh' => '强烈反塞翻袋',
        'ja' => '逆ひねり激鋭キック',
        'ko' => '역회전 샤프 킥',
        _ => core,
      };
    } else if (core.contains('Đường Cơ Kết Liễu Vươn Tầm Thế Giới')) {
      translatedCore = switch (lang) {
        'en' => 'World-Class Clutch Finish',
        'zh' => '世界级一杆决胜',
        'ja' => '世界レベルのクラッチフィニッシュ',
        'ko' => '세계적인 클러치 피니시',
        _ => core,
      };
    } else if (core.contains('Massé Bẻ Cong Quanh Bi Cản') || core.contains('Masse')) {
      translatedCore = switch (lang) {
        'en' => 'Masse Curve Around Obstacles',
        'zh' => '弧线马塞绕过障碍',
        'ja' => '障害物回避マッセカーブ',
        'ko' => '장애물 우회 마세 커브',
        _ => core,
      };
    } else if (core.contains('Combo Xuyên Khe Cửa Lỗ Thần Kỳ')) {
      translatedCore = switch (lang) {
        'en' => 'Miracle Needle-Eye Combo',
        'zh' => '针眼穿梭奇迹组合球',
        'ja' => '針の穴を通す奇跡のコンボ',
        'ko' => '바늘구멍 기적의 콤보',
        _ => core,
      };
    } else if (core.contains('Cú Dọn Bàn Cấp Tốc Đỉnh Cao')) {
      translatedCore = switch (lang) {
        'en' => 'Lightning Speed Center Pot',
        'zh' => '闪电极速中袋清台',
        'ja' => '電光石火のセンターストップ',
        'ko' => '전광석화 센터 스톱',
        _ => core,
      };
    }

    if (stageNum != null) {
      return switch (lang) {
        'en' => 'Stage $stageNum: $translatedCore',
        'zh' => '第$stageNum关: $translatedCore',
        'ja' => 'ステージ$stageNum: $translatedCore',
        'ko' => '스테이지 $stageNum: $translatedCore',
        _ => 'Ải $stageNum: $translatedCore',
      };
    }

    return translatedCore;
  }

  /// Dịch tên các lỗ bida
  String localizePocketName(String pocket) {
    final lang = _currentLanguage.code;
    if (lang == 'vi') return pocket;

    if (pocket.contains('góc trên trái')) {
      return switch (lang) {
        'en' => 'top-left pocket',
        'zh' => '左上角袋',
        'ja' => '左上ポケット',
        'ko' => '좌상단 포켓',
        _ => pocket,
      };
    }
    if (pocket.contains('góc trên phải')) {
      return switch (lang) {
        'en' => 'top-right pocket',
        'zh' => '右上角袋',
        'ja' => '右上ポケット',
        'ko' => '우상단 포켓',
        _ => pocket,
      };
    }
    if (pocket.contains('giữa trên')) {
      return switch (lang) {
        'en' => 'top middle pocket',
        'zh' => '上方中袋',
        'ja' => '上中央ポケット',
        'ko' => '상단 미들 포켓',
        _ => pocket,
      };
    }
    if (pocket.contains('góc dưới trái')) {
      return switch (lang) {
        'en' => 'bottom-left pocket',
        'zh' => '左下角袋',
        'ja' => '左下ポケット',
        'ko' => '좌하단 포켓',
        _ => pocket,
      };
    }
    if (pocket.contains('góc dưới phải')) {
      return switch (lang) {
        'en' => 'bottom-right pocket',
        'zh' => '右下角袋',
        'ja' => '右下ポケット',
        'ko' => '우하단 포켓',
        _ => pocket,
      };
    }
    if (pocket.contains('giữa dưới')) {
      return switch (lang) {
        'en' => 'bottom middle pocket',
        'zh' => '下方中袋',
        'ja' => '下中央ポケット',
        'ko' => '하단 미들 포켓',
        _ => pocket,
      };
    }
    if (pocket.contains('Bất kỳ') || pocket.contains('bất kỳ')) {
      return switch (lang) {
        'en' => 'any pocket',
        'zh' => '任意球袋',
        'ja' => '任意のポケット',
        'ko' => '모든 포켓',
        _ => pocket,
      };
    }
    return pocket;
  }

  /// Dịch tên cơ thủ huyền thoại
  String localizeMasterName(String master, {bool short = false}) {
    return TrickshotLocalization.getMasterName(master, _currentLanguage.code, short: short);
  }

  /// Dịch tiêu đề thế đánh huyền thoại
  String localizeTrickshotTitle(String id, String raw) {
    return TrickshotLocalization.getTitle(id, _currentLanguage.code, raw);
  }

  /// Dịch biệt danh cơ thủ huyền thoại
  String localizeTrickshotNickname(String id, String raw) {
    return TrickshotLocalization.getNickname(id, _currentLanguage.code, raw);
  }

  /// Dịch tên giải đấu / năm của thế đánh huyền thoại
  String localizeTrickshotTournament(String id, String raw) {
    return TrickshotLocalization.getTournament(id, _currentLanguage.code, raw);
  }

  /// Dịch mô tả chi tiết thế đánh huyền thoại
  String localizeTrickshotDescription(String id, String raw) {
    return TrickshotLocalization.getDescription(id, _currentLanguage.code, raw);
  }

  /// Dịch hướng dẫn kỹ thuật cơ thế đánh huyền thoại
  String localizeTrickshotHint(String id, String raw) {
    return TrickshotLocalization.getHint(id, _currentLanguage.code, raw);
  }

  /// Dịch mô tả thế bi hàng ngày
  String localizeDailyPuzzleDescription(String title, String raw) {
    final lang = _currentLanguage.code;
    if (lang == 'vi') return raw;
    for (final entry in _dailyPuzzleDescriptionTranslations.entries) {
      if (title.contains(entry.key) || raw.contains(entry.key)) {
        return entry.value[lang] ?? raw;
      }
    }
    return raw;
  }

  /// Dịch gợi ý thế bi hàng ngày
  String localizeDailyPuzzleHint(String title, String raw) {
    final lang = _currentLanguage.code;
    if (lang == 'vi') return raw;
    for (final entry in _dailyPuzzleHintTranslations.entries) {
      if (title.contains(entry.key) || raw.contains(entry.key)) {
        return entry.value[lang] ?? raw;
      }
    }
    return raw;
  }

  /// Dịch mô tả ải BOT
  String localizeBotStageDescription(int stageNumber, String raw) {
    final lang = _currentLanguage.code;
    if (lang == 'vi') return raw;
    final map = _botStageDescriptionTranslations[stageNumber];
    return map?[lang] ?? raw;
  }

  static const Map<String, Map<String, String>> _dailyPuzzleDescriptionTranslations = {
    'Khe Cửa Hẹp': {
      'en': 'Pot ball #1 into the top corner through the narrow gap between two obstacles!',
      'zh': '穿过两颗障碍球之间的狭窄缝隙，将1号球打入顶角袋！',
      'ja': '2つの障害球の間にある狭い隙間を通し、1番ボールを上のコーナーに沈めよう！',
      'ko': '두 장애물 공 사이의 좁은 틈새를 뚫고 1번 공을 상단 코너에 넣으세요!',
    },
    'Trô Giật Ngược': {
      'en': 'Pot ball #3 into the side pocket, then draw the cue ball back to pocket ball #7!',
      'zh': '将3号球打入中袋，随后母球强力后退继续击落7号球！',
      'ja': '3番をサイドポケットに決め、手玉をドローバックして7番を沈めよう！',
      'ko': '3번 공을 사이드에 넣은 뒤, 수구를 뒤로 끌어당겨 7번 공을 연속으로 넣으세요!',
    },
    'Dội Băng A-băng': {
      'en': 'Ball #5 is blocked directly; you must bank the cue ball off 1 rail to pot ball #5!',
      'zh': '5号球直线受阻，必须借由母球吃一库折射击进5号球！',
      'ja': '5番の直線上は塞がれているため、手玉を1クッション反射させて5番を狙おう！',
      'ko': '5번 공의 직선 경로가 막혀 있어, 수구를 1쿠션으로 꺾어 5번을 넣어야 합니다!',
    },
    'Cu-lê Đẩy Tới': {
      'en': 'Pot ball #2 with follow spin surging forward to carom ball #6 into the opposite pocket!',
      'zh': '打进2号球并利用高杆前冲推力，将6号球撞进对向袋口！',
      'ja': '2番を沈め、トップスピンの前進力で6番を対角ポケットへ弾き飛ばそう！',
      'ko': '2번 공을 넣고 밀어치기 전진력으로 6번 공을 반대편 포켓으로 밀어 넣으세요!',
    },
    'Tam Điểm Liên Hoàn': {
      'en': 'Clear all 3 target balls (#4, #10, #11) off the table in just 2 shots!',
      'zh': '在2杆之内清空台面上的3颗目标球 (4号、10号、11号)！',
      'ja': 'テーブル上の3つの目標球(4番、10番、11番)をわずか2打で一掃しよう！',
      'ko': '테이블 위의 3개 목표구(4번, 10번, 11번)를 단 2번의 샷으로 모두 넣으세요!',
    },
    'Cắt Băng Mép Bàn': {
      'en': 'The target ball is frozen to the cushion; execute an ultra-delicate thin cut into the corner!',
      'zh': '目标球紧贴库边，需要极其细腻的薄切角度将其送入角袋！',
      'ja': '目標球がクッションに密着しているため、極めて繊細な薄切りカットでコーナーへ沈めよう！',
      'ko': '목표구가 쿠션에 바짝 붙어 있어, 극도로 섬세한 얇은 컷으로 코너에 넣어야 합니다!',
    },
  };

  static const Map<String, Map<String, String>> _dailyPuzzleHintTranslations = {
    'Khe Cửa Hẹp': {
      'en': 'Hint: Line up the aim guide precisely and use mild power (40% power).',
      'zh': '提示: 精准对齐瞄准线，使用适度轻力 (40% 力度)。',
      'ja': 'ヒント: ガイドラインを正確に合わせ、適度な力加減(力40%)で打ちます。',
      'ko': '힌트: 조준선을 정확히 맞추고 알맞은 약한 힘(힘 40%)을 사용하세요.',
    },
    'Trô Giật Ngược': {
      'en': 'Hint: Set bottom draw spin all the way down and pull 80% power.',
      'zh': '提示: 将低杆塞拉至最下方，力度拉到 80%。',
      'ja': 'ヒント: ひねりを最下部に設定し、80%の強打で引き戻します。',
      'ko': '힌트: 하단 끌기 스핀을 맨 아래로 내리고 80% 파워로 치세요.',
    },
    'Dội Băng A-băng': {
      'en': 'Hint: Bank off the bottom rail so the rebound angle strikes the target ball.',
      'zh': '提示: 瞄准下库反弹，利用入射角折射击中目标球。',
      'ja': 'ヒント: 下レールへ向けて打ち、反射角で目標球を捉えます。',
      'ko': '힌트: 하단 레일에 맞춰 반사각으로 목표구를 맞추세요.',
    },
    'Cu-lê Đẩy Tới': {
      'en': 'Hint: Position the cue contact point at the very top (Top-spin).',
      'zh': '提示: 将击球点调整至母球最顶部 (高杆推杆)。',
      'ja': 'ヒント: タップ位置を手玉の最上部に合わせます(トップスピン)。',
      'ko': '힌트: 수구의 최상단에 팁을 맞추세요(상단 밀어치기)。',
    },
    'Tam Điểm Liên Hoàn': {
      'en': 'Hint: Pot ball #4 while deflecting it into #10 for a double combo shot.',
      'zh': '提示: 可以打4号进袋的同时撞击10号制造组合进球 (Combo Shot)。',
      'ja': 'ヒント: 4番を沈めつつ10番へ当ててコンボショットを狙えます。',
      'ko': '힌트: 4번을 넣으면서 10번으로 튕겨 콤보 샷을 노릴 수 있습니다.',
    },
    'Cắt Băng Mép Bàn': {
      'en': 'Hint: Slice at an ultra-thin angle with mild running english along the rail.',
      'zh': '提示: 切极薄的角度，顺着库边微带顺塞。',
      'ja': 'ヒント: 極薄の角度を狙い、クッション方向に軽くひねりを加えます。',
      'ko': '힌트: 극도로 얇은 각도를 노리고 쿠션 방향으로 약한 스핀을 주세요.',
    },
  };

  static const Map<int, Map<String, String>> _botStageDescriptionTranslations = {
    1: {
      'en': 'Rookie opponent who often misses long-range shots and cannot use cue spin.',
      'zh': '新手对手，远距离瞄准常有偏差，尚未掌握旋转加塞技巧。',
      'ja': '初心者の相手。長距離の狙いが甘く、ひねりは使えません。',
      'ko': '초보 상대. 장거리 샷에서 오차가 잦고 스핀을 사용할 줄 모릅니다.',
    },
    2: {
      'en': 'Heavy break power with Titan cue; basic awareness to avoid cue ball scratches.',
      'zh': '依靠泰坦球杆拥有强大开球力量，略懂走位避免母球落袋。',
      'ja': 'タイタンキューによる強烈なブレイク。手玉のスクラッチを避ける基本技術あり。',
      'ko': '타이탄 큐로 강력한 브레이크를 구사하며, 수구 스크래치를 피할 줄 압니다.',
    },
    3: {
      'en': 'Knows how to choose easier balls and controls cue ball to avoid snookering.',
      'zh': '开始懂得选择容易进的球，并控制母球方向不陷入困境。',
      'ja': '簡単な球を選び、手玉が不利な位置に行かないようコントロールします。',
      'ko': '쉬운 공을 골라 치며 수구가 곤란한 위치에 빠지지 않도록 조절합니다.',
    },
    4: {
      'en': 'Steady aim with Frostbite cue, smoothly dampening cue ball roll speed.',
      'zh': '瞄准稳定，善用寒冰球杆平稳减缓母球滚动速度。',
      'ja': '安定したエイムで、氷霜キューを活かして手玉の転がりをスムーズに抑えます。',
      'ko': '안정적인 조준 실력과 빙풍 큐를 활용해 수구 속도를 부드럽게 제어합니다.',
    },
    5: {
      'en': 'Seasoned veteran who frequently plays safety shots behind obstacle balls.',
      'zh': '经验丰富的老将，经常将母球藏在障碍球背后进行防守。',
      'ja': '経験豊富なベテラン。障害球の裏に手玉を隠すセーフティを多用します。',
      'ko': '풍부한 경험으로 장애물 공 뒤에 수구를 숨기는 세이프티를 자주 구사합니다.',
    },
    6: {
      'en': 'Lightning-fast, decisive strokes with up to 95% targeting accuracy.',
      'zh': '出杆迅捷果断，目标球命中率高达95%。',
      'ja': '素早く鋭いキュー出しで、目標球の的中率は95%に達します。',
      'ko': '매우 빠르고 결단력 있는 스트로크로 목표구 적중률이 95%에 달합니다.',
    },
    7: {
      'en': 'High precision; masters topspin follow-through to run out the table in a single turn.',
      'zh': '高超精准度，精通高杆推杆走位，具备一杆清台实力。',
      'ja': '高精度でトップスピンを自在に操り、1ターンでテーブルを一掃する腕前。',
      'ko': '높은 정확도로 상단 밀어치기를 완벽히 구사해 한 턴에 테이블을 정리합니다.',
    },
    8: {
      'en': 'Draw shot specialist who controls cue ball paths flawlessly with zero margin of error.',
      'zh': '强力低杆专家，完美控制母球行进路线，分毫不差。',
      'ja': 'ドローショットのスペシャリスト。手玉の走行ラインを寸分違わず制御。',
      'ko': '하단 끌어치기 전문 대가로 오차 없이 수구의 경로를 완벽히 통제합니다.',
    },
    9: {
      'en': 'Supreme master who never squanders an opportunity after even a single opponent foul.',
      'zh': '顶尖台球宗师，一旦对手犯规哪怕一次便绝不给反扑机会。',
      'ja': '至高のマスター。相手が一度でもファウルすれば決して好機を逃しません。',
      'ko': '당구의 최고수. 상대가 단 한 번만 파울을 범해도 결코 기회를 놓치지 않습니다.',
    },
    10: {
      'en': 'Undefeated legend with the Dragon cue, calculating shot trajectories like a computer.',
      'zh': '持有神龙球杆的不败传奇，计算球路如同超级计算机般精密。',
      'ja': '神龍キューを持つ無敗の伝説。コンピュータ並みの精密さで軌道を計算。',
      'ko': '신룡 큐를 쥔 무패의 전설. 컴퓨터처럼 정밀하게 공의 궤적을 계산합니다.',
    },
  };

  /// Dịch thanh thông báo hành động / luật chơi hiển thị trực tiếp trên bàn bida
  String localizeRuleMessage(String raw) {
    if (raw.isEmpty) return raw;
    final lang = _currentLanguage.code;
    if (lang == 'vi') return raw;

    // 1. Kiểm tra trực tiếp trong từ điển trước
    final direct = _ruleTranslations[raw]?[lang];
    if (direct != null) return direct;

    // 2. Mẫu Ải Bot: "Ải X: [Title] - Bắt đầu!" hoặc "[Title] - Bắt đầu!"
    final botStartReg = RegExp(
      r'^(?:(?:Ải|Stage)\s*(\d+)[:.]\s*)?(.*?)\s*-\s*(?:Bắt đầu!|Start!)$',
      caseSensitive: false,
    );
    final botStartMatch = botStartReg.firstMatch(raw);
    if (botStartMatch != null) {
      final stageNum = botStartMatch.group(1);
      final rawTitle = botStartMatch.group(2)?.trim() ?? '';
      final title = localizeStageTitle(rawTitle);
      return switch (lang) {
        'en' => stageNum != null ? 'Stage $stageNum: $title - Start!' : '$title - Start!',
        'zh' => stageNum != null ? '第$stageNum关: $title - 开始!' : '$title - 开始!',
        'ja' => stageNum != null ? 'ステージ$stageNum: $title - 開始!' : '$title - 開始!',
        'ko' => stageNum != null ? '스테이지 $stageNum: $title - 시작!' : '$title - 시작!',
        _ => raw,
      };
    }

    // 3. Mẫu Tournament: "Bracket X: [Title] vs [Opponent]"
    final bracketReg = RegExp(r'^Bracket\s*(\d+)[:.]\s*(.*?)\s+vs\s+(.*?)$', caseSensitive: false);
    final bracketMatch = bracketReg.firstMatch(raw);
    if (bracketMatch != null) {
      final bNum = bracketMatch.group(1);
      final bTitle = localizeStageTitle(bracketMatch.group(2)?.trim() ?? '');
      var opp = bracketMatch.group(3)?.trim() ?? '';
      if (opp.contains('(Đương Kim Vô Địch)')) {
        final rep = switch (lang) {
          'en' => '(Defending Champion)',
          'zh' => '(卫冕冠军)',
          'ja' => '(ディフェンディングチャンピオン)',
          'ko' => '(디펜딩 챔피언)',
          _ => '(Đương Kim Vô Địch)',
        };
        opp = opp.replaceAll('(Đương Kim Vô Địch)', rep);
      }
      return switch (lang) {
        'en' => 'Bracket $bNum: $bTitle vs $opp',
        'zh' => '第$bNum轮: $bTitle 对阵 $opp',
        'ja' => 'ブラケット$bNum: $bTitle 対 $opp',
        'ko' => '브래킷 $bNum: $bTitle 대 $opp',
        _ => raw,
      };
    }

    // 4. Mẫu Thế Bi Hàng Ngày: "Thế bi: [Title]"
    if (raw.startsWith('Thế bi:') || raw.startsWith('Thế bi :')) {
      final title = raw.substring(raw.indexOf(':') + 1).trim();
      final transTitle = localizeStageTitle(title);
      return switch (lang) {
        'en' => 'Daily Puzzle: $transTitle',
        'zh' => '每日残局: $transTitle',
        'ja' => 'デイリーパズル: $transTitle',
        'ko' => '일일 퍼즐: $transTitle',
        _ => raw,
      };
    }

    // 5. Mẫu Thế Đánh Huyền Thoại: "🎯 [Player]: Ăn bi [N] vào [Pocket][Avoid]"
    final trickshotReg = RegExp(
      r'^(🎯\s*.*?[:.]\s*)Ăn bi\s*(\d+)\s*vào\s*([^\(]+?)(?:\s*\((?:Tránh rơi bi|Tránh)\s*(.*?)\))?$',
      caseSensitive: false,
    );
    final trickshotMatch = trickshotReg.firstMatch(raw);
    if (trickshotMatch != null) {
      final prefix = trickshotMatch.group(1)?.trim() ?? '🎯';
      final bNum = trickshotMatch.group(2);
      final rawPocket = trickshotMatch.group(3)?.trim() ?? '';
      final pocket = localizePocketName(rawPocket);
      final avoid = trickshotMatch.group(4);
      final avoidText = avoid != null && avoid.isNotEmpty
          ? switch (lang) {
              'en' => ' (Avoid $avoid)',
              'zh' => ' (避免进 $avoid)',
              'ja' => ' ($avoid 回避)',
              'ko' => ' ($avoid 피하기)',
              _ => ' (Tránh $avoid)',
            }
          : '';
      return switch (lang) {
        'en' => '$prefix Pocket #$bNum into $pocket$avoidText',
        'zh' => '$prefix 将 #$bNum 号球打入 $pocket$avoidText',
        'ja' => '$prefix #$bNum番ボールを $pocketへ$avoidText',
        'ko' => '$prefix #$bNum번 볼을 $pocket에 넣기$avoidText',
        _ => raw,
      };
    }

    // 6. Mẫu Lượt đánh: "Đấu mạng: Lượt ..." hoặc "Lượt ..."
    if (raw.startsWith('Đấu mạng: Lượt ') || raw.startsWith('Đấu Online: Lượt ')) {
      final isOnline = raw.startsWith('Đấu Online: Lượt ');
      final after = raw.substring(isOnline ? 17 : 15).trim();
      final prefix = switch (lang) {
        'en' => isOnline ? 'Online Match: ' : 'Network Match: ',
        'zh' => isOnline ? '在线对战: ' : '局域网对决: ',
        'ja' => isOnline ? 'オンライン対戦: ' : 'ローカル対戦: ',
        'ko' => isOnline ? '온라인 대전: ' : '로컬 대전: ',
        _ => isOnline ? 'Đấu Online: ' : 'Đấu mạng: ',
      };
      if (after.startsWith('của bạn')) {
        final ballInHand = after.contains('Đặt bi');
        final suffix = switch (lang) {
          'en' => ballInHand ? 'Your turn (Ball in hand!)' : 'Your turn',
          'zh' => ballInHand ? '您的回合 (自由球!)' : '您的回合',
          'ja' => ballInHand ? 'あなたのターン (フリーボール!)' : 'あなたのターン',
          'ko' => ballInHand ? '당신의 턴 (프리볼!)' : '당신의 턴',
          _ => after,
        };
        return '$prefix$suffix';
      }
      if (after.startsWith('của ')) {
        final name = after.substring(4).replaceAll('...', '').trim();
        final suffix = switch (lang) {
          'en' => "$name's turn...",
          'zh' => '$name 的回合...',
          'ja' => '$name のターン...',
          'ko' => '$name 의 턴...',
          _ => after,
        };
        return '$prefix$suffix';
      }
    }

    if (raw.startsWith('Lượt ')) {
      final who = raw.substring(5).trim();
      if (who == 'của bạn' || who == 'của bạn (Đặt bi tuỳ ý!)') {
        final ballInHand = who.contains('Đặt bi');
        return switch (lang) {
          'en' => ballInHand ? 'Your turn (Ball in hand!)' : 'Your turn',
          'zh' => ballInHand ? '您的回合 (自由球!)' : '您的回合',
          'ja' => ballInHand ? 'あなたのターン (フリーボール!)' : 'あなたのターン',
          'ko' => ballInHand ? '당신의 턴 (프리볼!)' : '당신의 턴',
          _ => raw,
        };
      }
      if (who.startsWith('của ')) {
        final name = who.substring(4).replaceAll('...', '').trim();
        return switch (lang) {
          'en' => "$name's turn...",
          'zh' => '$name 的回合...',
          'ja' => '$name のターン...',
          'ko' => '$name 의 턴...',
          _ => raw,
        };
      }
      if (who == 'Máy (Khó)') {
        return switch (lang) {
          'en' => "Bot's turn (Hard)",
          'zh' => '电脑回合 (困难)',
          'ja' => 'BOTのターン (上級)',
          'ko' => '봇의 턴 (어려움)',
          _ => raw,
        };
      }
      if (who == 'Máy (Dễ)') {
        return switch (lang) {
          'en' => "Bot's turn (Easy)",
          'zh' => '电脑回合 (简单)',
          'ja' => 'BOTのターン (初級)',
          'ko' => '봇의 턴 (쉬움)',
          _ => raw,
        };
      }
      final pTurnReg = RegExp(r'^Player\s*(\d+)$', caseSensitive: false);
      final pTurnMatch = pTurnReg.firstMatch(who);
      if (pTurnMatch != null) {
        final pNum = pTurnMatch.group(1);
        return switch (lang) {
          'en' => "Player $pNum's turn",
          'zh' => '玩家 $pNum 回合',
          'ja' => 'プレイヤー $pNum のターン',
          'ko' => '플레이어 $pNum 의 턴',
          _ => raw,
        };
      }
      return switch (lang) {
        'en' => 'Turn: $who',
        'zh' => '回合: $who',
        'ja' => 'ターン: $who',
        'ko' => '턴: $who',
        _ => raw,
      };
    }

    // 7. Mẫu "Player X tiếp tục"
    final continueReg = RegExp(r'^(?:Player|Cơ thủ)\s*(\d+)\s*tiếp tục$', caseSensitive: false);
    final continueMatch = continueReg.firstMatch(raw);
    if (continueMatch != null) {
      final pNum = continueMatch.group(1);
      return switch (lang) {
        'en' => 'Player $pNum continues',
        'zh' => '玩家$pNum继续击球',
        'ja' => 'プレイヤー$pNum 継続',
        'ko' => '플레이어 $pNum 계속',
        _ => raw,
      };
    }

    // 8. Mẫu "Player X bị xử thua"
    final loserReg = RegExp(r'^(?:Player|Cơ thủ)\s*(\d+)\s*bị xử thua$', caseSensitive: false);
    final loserMatch = loserReg.firstMatch(raw);
    if (loserMatch != null) {
      final pNum = loserMatch.group(1);
      return switch (lang) {
        'en' => 'Player $pNum forfeited',
        'zh' => '玩家$pNum被判负',
        'ja' => 'プレイヤー$pNum の不戦敗',
        'ko' => '플레이어 $pNum 몰수패',
        _ => raw,
      };
    }

    // 9. Mẫu "Player X wins the rack!"
    final winRackReg = RegExp(r'^Player\s*(\d+)\s*wins the rack!$', caseSensitive: false);
    final winRackMatch = winRackReg.firstMatch(raw);
    if (winRackMatch != null) {
      final pNum = winRackMatch.group(1);
      return switch (lang) {
        'en' => 'Player $pNum wins the rack!',
        'zh' => '玩家$pNum赢得此局!',
        'ja' => 'プレイヤー$pNum の勝利!',
        'ko' => '플레이어 $pNum 세트 승리!',
        _ => raw,
      };
    }

    // 10. Mẫu "Player X loses: 8-ball early"
    final loseEarlyReg = RegExp(r'^Player\s*(\d+)\s*loses:\s*8-ball early$', caseSensitive: false);
    final loseEarlyMatch = loseEarlyReg.firstMatch(raw);
    if (loseEarlyMatch != null) {
      final pNum = loseEarlyMatch.group(1);
      return switch (lang) {
        'en' => 'Player $pNum loses: 8-ball pocketed early',
        'zh' => '玩家$pNum惜败: 过早击入8号球',
        'ja' => 'プレイヤー$pNum 敗北: 8番早期落袋',
        'ko' => '플레이어 $pNum 패배: 8번 볼 조기 낙하',
        _ => raw,
      };
    }

    // 11. Mẫu Daily Puzzle Shot Counter: "Lượt X/Y - Đánh tiếp!"
    final puzzleShotReg = RegExp(r'^Lượt\s*(\d+)\s*/\s*(\d+)\s*-\s*Đánh tiếp!$', caseSensitive: false);
    final puzzleShotMatch = puzzleShotReg.firstMatch(raw);
    if (puzzleShotMatch != null) {
      final cur = puzzleShotMatch.group(1);
      final max = puzzleShotMatch.group(2);
      return switch (lang) {
        'en' => 'Shot $cur/$max - Keep shooting!',
        'zh' => '第 $cur/$max 杆 - 继续击球!',
        'ja' => 'ショット $cur/$max - 継続!',
        'ko' => '샷 $cur/$max - 계속!',
        _ => raw,
      };
    }

    // 12. Mẫu Hết số cơ: "Thất bại: Hết số cơ cho phép (X)!"
    final outOfShotsReg = RegExp(r'^Thất bại:\s*Hết số cơ cho phép\s*\((\d+)\)!$', caseSensitive: false);
    final outOfShotsMatch = outOfShotsReg.firstMatch(raw);
    if (outOfShotsMatch != null) {
      final max = outOfShotsMatch.group(1);
      return switch (lang) {
        'en' => 'Failed: Out of allowed shots ($max)!',
        'zh' => '失败: 超出允许出杆数 ($max)!',
        'ja' => '失敗: 規定ショット数終了 ($max)!',
        'ko' => '실패: 허용 샷 수 초과 ($max)!',
        _ => raw,
      };
    }

    // 13. Mẫu Trickshot tái hiện đỉnh cao: "🏆 Xuất sắc! Bạn đã tái hiện đường cơ đỉnh cao của [Player]!"
    final trickshotWinReg = RegExp(r'^🏆\s*Xuất sắc!\s*Bạn đã tái hiện đường cơ đỉnh cao của\s*(.*?)!$', caseSensitive: false);
    final trickshotWinMatch = trickshotWinReg.firstMatch(raw);
    if (trickshotWinMatch != null) {
      final master = trickshotWinMatch.group(1);
      return switch (lang) {
        'en' => '🏆 Superb! You recreated $master\'s master shot!',
        'zh' => '🏆 绝妙! 完美重现 $master 的巅峰杆法!',
        'ja' => '🏆 見事! $master の神技を完全再現!',
        'ko' => '🏆 환상적입니다! $master의 명샷 재현 성공!',
        _ => raw,
      };
    }

    // 14. Tra cứu từ điển dự phòng linh hoạt
    for (final entry in _ruleTranslations.entries) {
      if (raw.contains(entry.key)) {
        final trans = entry.value[lang];
        if (trans != null) {
          return raw.replaceAll(entry.key, trans);
        }
      }
    }

    return raw;
  }

  static final Map<String, Map<String, String>> _ruleTranslations = {
    'Player 1: break shot': {
      'vi': 'Player 1: Cú phá bi',
      'en': 'Player 1: Break shot',
      'zh': '玩家 1: 开球',
      'ja': 'プレイヤー 1: ブレイクショット',
      'ko': '플레이어 1: 브레이크 샷',
    },
    'Foul - ball in hand': {
      'vi': 'Phạm lỗi - Bi trong tay',
      'en': 'Foul - Ball in hand',
      'zh': '犯规 - 自由球',
      'ja': 'ファウル - フリーボール',
      'ko': '파울 - 프리볼',
    },
    'Foul: 8-ball on an illegal shot': {
      'vi': 'Phạm lỗi: Rơi bi 8 phạm quy',
      'en': 'Foul: 8-ball on an illegal shot',
      'zh': '犯规: 违规击入8号球',
      'ja': 'ファウル: 8番ボール反則落袋',
      'ko': '파울: 파울 샷으로 8번 볼 낙하',
    },
    'Chúc mừng! Phá giải thế bi thành công!': {
      'vi': 'Chúc mừng! Phá giải thế bi thành công!',
      'en': 'Congratulations! Puzzle solved!',
      'zh': '恭喜! 成功解开残局!',
      'ja': 'おめでとう! パズルクリア!',
      'ko': '축하합니다! 퍼즐 완료!',
    },
    'Thất bại: Bi cái rơi lỗ!': {
      'vi': 'Thất bại: Bi cái rơi lỗ!',
      'en': 'Failed: Cue ball scratched!',
      'zh': '失败: 白球落袋!',
      'ja': '失敗: スクラッチ!',
      'ko': '실패: 수구 낙하!',
    },
    'Thất bại: Bi chướng ngại rơi lỗ!': {
      'vi': 'Thất bại: Bi chướng ngại rơi lỗ!',
      'en': 'Failed: Obstacle ball pocketed!',
      'zh': '失败: 障碍球落袋!',
      'ja': '失敗: 障害球落袋!',
      'ko': '실패: 장애구 낙하!',
    },
    'Chưa vào lỗ! Hãy bấm "ĐẶT LẠI" để luyện tập lại!': {
      'vi': 'Chưa vào lỗ! Hãy bấm "ĐẶT LẠI" để luyện tập lại!',
      'en': 'Missed! Tap "RESET" to try again!',
      'zh': '未进球! 请点击"重置"再次练习!',
      'ja': '入らず!「リセット」をタップして再挑戦!',
      'ko': '실패! "재설정"을 눌러 다시 연습하세요!',
    },
    'Đặt bi cái ở bất kỳ đâu trong khu vực bếp': {
      'vi': 'Đặt bi cái ở bất kỳ đâu trong khu vực bếp',
      'en': 'Place cue ball behind the head string',
      'zh': '在开球区内放置白球',
      'ja': 'キッチン内に手球を配置',
      'ko': '헤드 스트링 뒤에 수구 배치',
    },
    'Đặt bi cái ở bất kỳ đâu trên bàn': {
      'vi': 'Đặt bi cái ở bất kỳ đâu trên bàn',
      'en': 'Place cue ball anywhere on the table',
      'zh': '在桌面任意位置放置白球',
      'ja': 'テーブル上の好きな位置に手球を配置',
      'ko': '테이블 위 원하는 위치에 수구 배치',
    },
    'Đối thủ đang đặt bi cái...': {
      'vi': 'Đối thủ đang đặt bi cái...',
      'en': 'Opponent is placing cue ball...',
      'zh': '对手正在放置白球...',
      'ja': '相手が手球を配置中...',
      'ko': '상대방이 수구를 배치 중입니다...',
    },
    'Đấu Online: Lượt của bạn (P1 break shot)': {
      'vi': 'Đấu Online: Lượt của bạn (P1 break shot)',
      'en': 'Online Match: Your turn (P1 break shot)',
      'zh': '网络对决: 您的回合 (P1开球)',
      'ja': 'オンライン対戦: あなたのターン (P1ブレイク)',
      'ko': '온라인 대전: 당신의 턴 (P1 브레이크)',
    },
    'Đấu mạng: Lượt của bạn (P1 break shot)': {
      'vi': 'Đấu mạng: Lượt của bạn (P1 break shot)',
      'en': 'Network Match: Your turn (P1 break shot)',
      'zh': '局域网对决: 您的回合 (P1开球)',
      'ja': 'ローカル対戦: あなたのターン (P1ブレイク)',
      'ko': '로컬 대전: 당신의 턴 (P1 브레이크)',
    },
    'Đấu mạng: Lượt của bạn': {
      'vi': 'Đấu mạng: Lượt của bạn',
      'en': 'Network Match: Your turn',
      'zh': '局域网对决: 您的回合',
      'ja': 'ローカル対戦: あなたのターン',
      'ko': '로컬 대전: 당신의 턴',
    },
    'Đấu mạng: Lượt của bạn (Đặt bi tuỳ ý!)': {
      'vi': 'Đấu mạng: Lượt của bạn (Đặt bi tuỳ ý!)',
      'en': 'Network Match: Your turn (Ball in hand!)',
      'zh': '局域网对决: 您的回合 (自由球!)',
      'ja': 'ローカル対戦: あなたのターン (フリーボール!)',
      'ko': '로컬 대전: 당신의 턴 (프리볼!)',
    },
    '✅ Đã kết nối lại vào trận đấu thành công!': {
      'vi': '✅ Đã kết nối lại vào trận đấu thành công!',
      'en': '✅ Successfully reconnected to match!',
      'zh': '✅ 成功重新连接至比赛!',
      'ja': '✅ 試合に再接続しました!',
      'ko': '✅ 경기에 성공적으로 재연결되었습니다!',
    },
    '⚠️ Đối thủ bị ngắt kết nối! Trận đấu vẫn tiếp tục theo thời gian thực...': {
      'vi': '⚠️ Đối thủ bị ngắt kết nối! Trận đấu vẫn tiếp tục theo thời gian thực...',
      'en': '⚠️ Opponent disconnected! Match continues in real-time...',
      'zh': '⚠️ 对手已断开连接! 比赛仍在实时进行中...',
      'ja': '⚠️ 相手の接続が切れました! 試合はリアルタイムで継続中...',
      'ko': '⚠️ 상대방의 연결이 끊어졌습니다! 경기는 실시간으로 계속됩니다...',
    },
    '✅ Đối thủ đã kết nối lại! Tiếp tục thi đấu.': {
      'vi': '✅ Đối thủ đã kết nối lại! Tiếp tục thi đấu.',
      'en': '✅ Opponent reconnected! Resuming match.',
      'zh': '✅ 对手已重新连回! 继续比赛。',
      'ja': '✅ 相手が再接続しました! 試合を再開します。',
      'ko': '✅ 상대방이 재연결되었습니다! 경기를 재개합니다.',
    },
    '🏆 Đối thủ đã rời trận! Bạn giành chiến thắng!': {
      'vi': '🏆 Đối thủ đã rời trận! Bạn giành chiến thắng!',
      'en': '🏆 Opponent left! You win the match!',
      'zh': '🏆 对手已退出! 您赢得了比赛!',
      'ja': '🏆 相手が退出しました! あなたの勝利です!',
      'ko': '🏆 상대방이 나갔습니다! 승리하셨습니다!',
    },
  };

  static final Map<String, Map<String, String>> _translations = {
    // Quản lý Bàn Đấu (Table Shop) & Profile Localization
    'concept_label': {
      'vi': 'Chủ Đề',
      'en': 'Theme',
      'zh': '主题风格',
      'ja': 'テーマ',
      'ko': '테마',
    },
    'diamonds_unit': {
      'vi': 'KC',
      'en': 'Diamonds',
      'zh': '钻石',
      'ja': 'ダイヤ',
      'ko': '다이아',
    },
    'table_shop': {
      'vi': 'BÀN ĐẤU',
      'en': 'TABLES',
      'zh': '球桌',
      'ja': 'テーブル',
      'ko': '테이블',
    },
    'table_shop_title': {
      'vi': 'CỬA HÀNG BÀN BIDA',
      'en': 'POOL TABLE SHOP',
      'zh': '台球桌商城',
      'ja': 'テーブルショップ',
      'ko': '당구대 상점',
    },
    'table_shop_subtitle': {
      'vi': '20 Mẫu Bàn Độc Quyền • Thay Đổi Diện Mạo Bàn Đấu',
      'en': '20 Exclusive Tables • Customize Table Appearance',
      'zh': '20款专属球桌 • 自由定制球台外观',
      'ja': '20種類の限定テーブル • 外観を自由に変更',
      'ko': '20가지 전용 당구대 스킨 • 테이블 외형 변경',
    },
    'all_tables_filter': {
      'vi': 'Tất cả (20)',
      'en': 'All (20)',
      'zh': '全部 (20)',
      'ja': 'すべて (20)',
      'ko': '전체 (20)',
    },
    'table_in_use': {
      'vi': '✓ Đang dùng',
      'en': '✓ In Use',
      'zh': '✓ 使用中',
      'ja': '✓ 使用中',
      'ko': '✓ 사용 중',
    },
    'table_owned': {
      'vi': '✓ Đã sở hữu',
      'en': '✓ Owned',
      'zh': '✓ 已拥有',
      'ja': '✓ 獲得済み',
      'ko': '✓ 보유 중',
    },
    'table_equipped_banner': {
      'vi': 'ĐANG TRANG BỊ TRÊN BÀN ĐẤU',
      'en': 'CURRENTLY EQUIPPED ON TABLE',
      'zh': '当前已装备在球桌上',
      'ja': 'テーブルに装備中',
      'ko': '현재 당구대에 장착 중',
    },
    'equip_table_btn': {
      'vi': 'TRANG BỊ BÀN NÀY',
      'en': 'EQUIP THIS TABLE',
      'zh': '装备此球桌',
      'ja': 'このテーブルを装備',
      'ko': '이 당구대 장착',
    },
    'unlock_table_level': {
      'vi': 'MỞ KHÓA Ở CẤP {level}',
      'en': 'UNLOCKED AT LEVEL {level}',
      'zh': '达到等级 {level} 解锁',
      'ja': 'レベル {level} で解放',
      'ko': '레벨 {level} 에서 잠금 해제',
    },
    'buy_with_diamonds': {
      'vi': 'MUA BẰNG {price} KIM CƯƠNG',
      'en': 'BUY FOR {price} DIAMONDS',
      'zh': '使用 {price} 钻石购买',
      'ja': 'ダイヤ {price} 個で購入',
      'ko': '다이아 {price}개로 구매',
    },
    'buy_with_coins': {
      'vi': 'MUA BẰNG {price} VÀNG',
      'en': 'BUY FOR {price} COINS',
      'zh': '使用 {price} 金币购买',
      'ja': 'コイン {price} 枚で購入',
      'ko': '코인 {price}개로 구매',
    },
    'table_cushion_bounce': {
      'vi': 'Độ Nảy Băng',
      'en': 'Cushion Bounce',
      'zh': '库边弹性',
      'ja': 'クッション弾性',
      'ko': '쿠션 탄성',
    },
    'table_cloth_felt': {
      'vi': 'Mặt Vải Nỉ',
      'en': 'Cloth Felt',
      'zh': '台呢材质',
      'ja': 'ラシャ布',
      'ko': '당구 천(나사)',
    },
    'tour_standard': {
      'vi': 'Chuẩn Tour',
      'en': 'Tour Grade',
      'zh': '职业巡回级',
      'ja': 'プロ基準',
      'ko': '투어 표준',
    },
    'ultra_smooth': {
      'vi': 'Siêu Mịn',
      'en': 'Ultra Smooth',
      'zh': '超顺滑',
      'ja': '超スムーズ',
      'ko': '초극세사 매끄러움',
    },
    'table_applied_toast': {
      'vi': 'Đã áp dụng {name} cho bàn thi đấu!',
      'en': 'Applied {name} to the match table!',
      'zh': '已为比赛球桌应用 {name}!',
      'ja': '試合用テーブルに {name} を適用しました!',
      'ko': '경기 테이블에 {name} 적용 완료!',
    },
    'table_bought_toast': {
      'vi': 'Đã mua thành công và trang bị {name}!',
      'en': 'Successfully purchased and equipped {name}!',
      'zh': '成功购买并装备 {name}!',
      'ja': '{name} を購入して装備しました!',
      'ko': '{name} 구매 및 장착 성공!',
    },
    'table_buy_error_toast': {
      'vi': 'Không thể mua bàn bida!',
      'en': 'Cannot purchase table!',
      'zh': '无法购买球桌!',
      'ja': 'テーブルを購入できません!',
      'ko': '당구대를 구매할 수 없습니다!',
    },
    'not_enough_coins': {
      'vi': 'Bạn không đủ Vàng!',
      'en': 'Not enough Coins!',
      'zh': '金币不足!',
      'ja': 'コインが不足しています!',
      'ko': '코인이 부족합니다!',
    },
    'guest_player': {
      'vi': 'Cơ Thủ Khách',
      'en': 'Guest Player',
      'zh': '游客选手',
      'ja': 'ゲストプレイヤー',
      'ko': '게스트 플레이어',
    },
    'cue_perk_max_state': {
      'vi': '★ Cảnh giới Tối Thượng: Đầy đủ Hào Quang & Kim Cương Khảm Chuôi',
      'en': '★ Supreme Tier: Full Aura & Diamond Inlaid Butt',
      'zh': '★ 至尊境界: 专属炫彩光环与握把钻石镶嵌',
      'ja': '★ 至高の境地: オーラ全開＆ダイヤモンドインレイ',
      'ko': '★ 최상의 경지: 풀 아우라 & 다이아몬드 인레이 그립',
    },
    'cue_perk_unlocked_state': {
      'vi': '✓ Đã mở khóa: Dát Vàng 24K & Khảm Ngọc Chuôi (Cấp 10: Tối Thượng)',
      'en': '✓ Unlocked: 24K Gold Plated & Gem Inlay (Lv.10: Supreme)',
      'zh': '✓ 已解锁: 24K镀金与宝石镶嵌 (10级: 至尊)',
      'ja': '✓ 解放済み: 24K金メッキ＆宝石インレイ (Lv.10: 至高)',
      'ko': '✓ 해금됨: 24K 금도금 & 보석 인레이 (Lv.10: 최상)',
    },
    'cue_perk_level5_req': {
      'vi': '• Nâng lên Cấp 5: Mở khóa Dát Vàng 24K & Khảm Ngọc Chuôi',
      'en': '• Upgrade to Lv.5: Unlock 24K Gold Plated & Gem Inlay',
      'zh': '• 升级至5级: 解锁24K镀金与宝石镶嵌',
      'ja': '• Lv.5にアップグレード: 24K金メッキ＆宝石インレイ解放',
      'ko': '• 레벨 5로 업그레이드: 24K 금도금 & 보석 인레이 해금',
    },
    'auth_tagline': {
      'vi': 'BIDA 8 LỖ CASUAL • MULTIPLAYER',
      'en': 'CASUAL 8-BALL • MULTIPLAYER',
      'zh': '休闲8球台球 • 多人对战',
      'ja': 'カジュアル8ボール • マルチプレイヤー',
      'ko': '캐주얼 8볼 당구 • 멀티플레이어',
    },
    // Menu & Chế độ chơi
    'app_title': {
      'vi': '8 POOL BILLIARDS',
      'en': '8 POOL BILLIARDS',
      'zh': '8球台球大师',
      'ja': '8ボール ビリヤード',
      'ko': '8볼 당구 마스터',
    },
    'choose_match': {
      'vi': 'CHỌN CHẾ ĐỘ ĐẤU',
      'en': 'CHOOSE YOUR MATCH',
      'zh': '选择对决模式',
      'ja': '試合モードを選択',
      'ko': '경기 모드 선택',
    },
    'p1_vs_p2': {
      'vi': 'P1 vs P2 (CÙNG MÁY)',
      'en': 'P1 vs P2 (LOCAL 2P)',
      'zh': '双人对决 (同机)',
      'ja': 'P1 vs P2 (ローカル対戦)',
      'ko': 'P1 vs P2 (로컬 2인)',
    },
    'p1_vs_p2_desc': {
      'vi': '2 người chơi trên 1 thiết bị',
      'en': '2 players on 1 device',
      'zh': '一台手机双人对战',
      'ja': '1台の端末で2人対戦',
      'ko': '한 기기에서 2인 대전',
    },
    'legendary_trickshot': {
      'vi': 'THẾ ĐÁNH HUYỀN THOẠI',
      'en': 'LEGENDARY TRICKSHOTS',
      'zh': '传奇花式杆法',
      'ja': '伝説のトリックショット',
      'ko': '전설의 트릭샷',
    },
    'legendary_trickshot_desc': {
      'vi': '112 tuyệt kỹ của 14 cơ thủ vĩ đại nhất',
      'en': '112 trickshots by 14 greatest legends',
      'zh': '14位传奇大师的112种旷世绝技',
      'ja': '伝説のプレイヤー14名による112の神技',
      'ko': '역대 최고 마스터 14인의 112대 명샷',
    },
    'legendary_trickshot_count_badge': {
      'vi': '(112 TUYỆT KỸ)',
      'en': '(112 TRICKSHOTS)',
      'zh': '(112 绝技)',
      'ja': '(112 技)',
      'ko': '(112 기술)',
    },
    'legendary_trickshot_sub': {
      'vi': 'Đường cơ kinh điển: Efren Reyes, Ronnie O\'Sullivan, Shane Van Boening...',
      'en': 'Mastershots: Efren Reyes, Ronnie O\'Sullivan, Shane Van Boening...',
      'zh': '世界大师名局: 雷耶斯、奥沙利文、范伯宁...',
      'ja': '名人の神技: エフレン・レイズ、オサリバン、シェーン...',
      'ko': '명선수의 명샷: 에프렌 레예스, 로니 오설리반, 셰인...',
    },
    'trickshots_unit': {
      'vi': 'THẾ ĐÁNH',
      'en': 'TRICKSHOTS',
      'zh': '绝技球',
      'ja': 'ショット',
      'ko': '트릭샷',
    },
    'completed_unit': {
      'vi': 'HOÀN THÀNH',
      'en': 'COMPLETED',
      'zh': '已完成',
      'ja': '完了',
      'ko': '완료',
    },
    'all_masters': {
      'vi': 'Tất cả',
      'en': 'All Masters',
      'zh': '全部大师',
      'ja': 'すべての名人',
      'ko': '모든 마스터',
    },
    'all_difficulties': {
      'vi': 'Tất cả độ khó',
      'en': 'All Difficulties',
      'zh': '全部难度',
      'ja': '全難易度',
      'ko': '모든 난이도',
    },
    'stars_count': {
      'vi': '{stars} Sao',
      'en': '{stars} Stars',
      'zh': '{stars} 星',
      'ja': '{stars} つ星',
      'ko': '{stars} 성',
    },
    'no_trickshot_match': {
      'vi': 'Không tìm thấy thế đánh phù hợp với bộ lọc',
      'en': 'No trickshots found matching filter',
      'zh': '未找到符合筛选条件的绝技',
      'ja': 'フィルターに一致するショットが見つかりません',
      'ko': '필터와 일치하는 트릭샷을 찾을 수 없습니다',
    },
    'reset_filter': {
      'vi': 'Đặt lại bộ lọc',
      'en': 'Reset Filter',
      'zh': '重置筛选',
      'ja': 'フィルターリセット',
      'ko': '필터 초기화',
    },
    'forfeit_trickshot_exit': {
      'vi': 'Thất bại: Đã thoát thế đánh!',
      'en': 'Failed: Exited trickshot challenge!',
      'zh': '挑战失败: 已退出绝技挑战！',
      'ja': '失敗: トリックショットを退出しました！',
      'ko': '실패: 트릭샷 도전을 종료했습니다!',
    },
    'tournament': {
      'vi': 'TOURNAMENT 5 BRACKETS',
      'en': 'TOURNAMENT 5 BRACKETS',
      'zh': '5轮巡回锦标赛',
      'ja': '5段階トーナメント',
      'ko': '5강 토너먼트 대회',
    },
    'tournament_desc': {
      'vi': 'Tranh cúp Quán Quân • Siêu quà',
      'en': 'Win Champion Cup • Mega Rewards',
      'zh': '角逐冠军奖杯 • 豪华大奖',
      'ja': '優勝カップ争奪 • 超豪華報酬',
      'ko': '챔피언 컵 쟁탈 • 대박 보상',
    },
    'local_wifi': {
      'vi': 'ĐẤU MẠNG LOCAL',
      'en': 'LOCAL NETWORK MATCH',
      'zh': '局域网联机对战',
      'ja': 'ローカル通信対戦',
      'ko': '로컬 네트워크 대전',
    },
    'local_wifi_desc': {
      'vi': 'Chung mạng WiFi / Hotspot',
      'en': 'Same WiFi / Hotspot network',
      'zh': '同一WiFi或手机热点',
      'ja': '同一WiFi / テザリング',
      'ko': '동일 WiFi / 핫스팟',
    },
    'bot_stages': {
      'vi': '10 ẢI THỬ THÁCH BOT',
      'en': '10 BOT CHALLENGES',
      'zh': '人机10重试炼',
      'ja': '10段階BOTチャレンジ',
      'ko': '10단계 봇 챌린지',
    },
    'bot_stages_desc': {
      'vi': '4 Hạng: Đồng, Bạc, Vàng, Kim Cương',
      'en': '4 Tiers: Bronze, Silver, Gold, Diamond',
      'zh': '4大段位: 青铜、白银、黄金、钻石',
      'ja': '4階級: ブロンズ、シルバー、ゴールド、ダイヤ',
      'ko': '4등급: 브론즈, 실버, 골드, 다이아몬드',
    },
    'daily_puzzle': {
      'vi': 'THẾ BI HÀNG NGÀY',
      'en': 'DAILY PUZZLE',
      'zh': '每日残局挑战',
      'ja': 'デイリーパズル',
      'ko': '일일 퍼즐 미션',
    },
    'daily_puzzle_desc': {
      'vi': '1 thế bi / ngày • Quà lớn',
      'en': '1 puzzle / day • Big rewards',
      'zh': '每日1局 • 丰厚奖赏',
      'ja': '1日1問 • 豪華プレゼント',
      'ko': '매일 1문제 • 특별 보상',
    },

    // Cài đặt & Ngôn ngữ
    'settings_title': {
      'vi': 'Cài đặt & Âm thanh',
      'en': 'Settings & Audio',
      'zh': '设置与音频',
      'ja': '設定とオーディオ',
      'ko': '설정 및 오디오',
    },
    'language': {
      'vi': 'Ngôn ngữ',
      'en': 'Language',
      'zh': '语言',
      'ja': '言語',
      'ko': '언어',
    },
    'select_language': {
      'vi': 'Chọn ngôn ngữ',
      'en': 'Select Language',
      'zh': '选择语言',
      'ja': '言語を選択',
      'ko': '언어 선택',
    },
    'bgm_title': {
      'vi': 'Nhạc nền Bida (BGM)',
      'en': 'Billiards BGM',
      'zh': '台球背景音乐 (BGM)',
      'ja': 'ビリヤードBGM',
      'ko': '당구 배경음악 (BGM)',
    },
    'sfx_title': {
      'vi': 'Hiệu ứng âm thanh (SFX)',
      'en': 'Sound Effects (SFX)',
      'zh': '打击音效 (SFX)',
      'ja': '効果音 (SFX)',
      'ko': '타격 효과음 (SFX)',
    },
    'match_actions': {
      'vi': 'Thao tác trận đấu:',
      'en': 'Match Actions:',
      'zh': '对局操作:',
      'ja': '試合操作:',
      'ko': '경기 메뉴:',
    },
    'surrender_lan': {
      'vi': 'Xử thua (LAN)',
      'en': 'Declare Loss (LAN)',
      'zh': '认输 (LAN)',
      'ja': '降参 (LAN)',
      'ko': '항복 (LAN)',
    },
    'main_menu': {
      'vi': 'Menu chính',
      'en': 'Main Menu',
      'zh': '主菜单',
      'ja': 'メインメニュー',
      'ko': '메인 메뉴',
    },
    'restart': {
      'vi': 'Bắt đầu lại',
      'en': 'Restart',
      'zh': '重新开局',
      'ja': '最初から',
      'ko': '다시 시작',
    },
    'close': {
      'vi': 'Đóng',
      'en': 'Close',
      'zh': '关闭',
      'ja': '閉じる',
      'ko': '닫기',
    },

    // Bàn đấu & Trạng thái HUD
    'turn': {
      'vi': 'LƯỢT',
      'en': 'TURN',
      'zh': '回合',
      'ja': 'ターン',
      'ko': '턴',
    },
    'turn_p1': {
      'vi': 'Lượt P1',
      'en': 'Player 1 Turn',
      'zh': '玩家1 回合',
      'ja': 'P1のターン',
      'ko': 'P1 턴',
    },
    'turn_p2': {
      'vi': 'Lượt P2',
      'en': 'Player 2 Turn',
      'zh': '玩家2 回合',
      'ja': 'P2のターン',
      'ko': 'P2 턴',
    },
    'turn_you': {
      'vi': 'Lượt của bạn',
      'en': 'Your Turn',
      'zh': '您的回合',
      'ja': 'あなたのターン',
      'ko': '당신의 턴',
    },
    'turn_bot': {
      'vi': 'Lượt của Bot',
      'en': 'Bot Turn',
      'zh': '电脑回合',
      'ja': 'BOTのターン',
      'ko': '봇의 턴',
    },
    'bot_hard': {
      'vi': 'MÁY (KHÓ)',
      'en': 'BOT (HARD)',
      'zh': '电脑 (困难)',
      'ja': 'BOT (上級)',
      'ko': '봇 (어려움)',
    },
    'bot_easy': {
      'vi': 'MÁY (DỄ)',
      'en': 'BOT (EASY)',
      'zh': '电脑 (简单)',
      'ja': 'BOT (初級)',
      'ko': '봇 (쉬움)',
    },
    'you': {
      'vi': 'Bạn',
      'en': 'You',
      'zh': '你',
      'ja': 'あなた',
      'ko': '당신',
    },
    'player_1': {
      'vi': 'Cơ thủ 1',
      'en': 'Player 1',
      'zh': '玩家 1',
      'ja': 'プレイヤー 1',
      'ko': '플레이어 1',
    },
    'player_2': {
      'vi': 'Cơ thủ 2',
      'en': 'Player 2',
      'zh': '玩家 2',
      'ja': 'プレイヤー 2',
      'ko': '플레이어 2',
    },
    'target_balls': {
      'vi': 'Bi mục tiêu',
      'en': 'Target Balls',
      'zh': '目标球',
      'ja': 'ターゲットボール',
      'ko': '목표구',
    },
    'solids': {
      'vi': 'Bi Trơn (1-7)',
      'en': 'Solids (1-7)',
      'zh': '全色球 (1-7)',
      'ja': 'ソリッド (1-7)',
      'ko': '솔리드 (1-7)',
    },
    'stripes': {
      'vi': 'Bi Sọc (9-15)',
      'en': 'Stripes (9-15)',
      'zh': '花色球 (9-15)',
      'ja': 'ストライプ (9-15)',
      'ko': '스트라이프 (9-15)',
    },
    'open_table': {
      'vi': 'Bàn tự do',
      'en': 'Open Table',
      'zh': '开放球局',
      'ja': 'オープン',
      'ko': '오픈 테이블',
    },
    'eight_ball_target': {
      'vi': 'Bi 8 Đen (Ăn để thắng)',
      'en': '8-Ball (Pocket to Win)',
      'zh': '8号黑球 (打进获胜)',
      'ja': '8番ボール (沈めて勝利)',
      'ko': '8번 볼 (넣으면 승리)',
    },
    'cue_stick': {
      'vi': 'Gậy cơ',
      'en': 'Cue Stick',
      'zh': '球杆',
      'ja': 'キュー',
      'ko': '큐',
    },
    'change_cue': {
      'vi': 'Đổi gậy',
      'en': 'Change Cue',
      'zh': '更换球杆',
      'ja': 'キュー変更',
      'ko': '큐 변경',
    },
    'power': {
      'vi': 'LỰC',
      'en': 'POWER',
      'zh': '力度',
      'ja': 'パワー',
      'ko': '파워',
    },
    'victory': {
      'vi': 'CHIẾN THẮNG!',
      'en': 'VICTORY!',
      'zh': '比赛胜利!',
      'ja': '勝利!',
      'ko': '승리!',
    },
    'defeat': {
      'vi': 'THẤT BẠI',
      'en': 'DEFEAT',
      'zh': '对局惜败',
      'ja': '敗北',
      'ko': '패배',
    },
    'foul': {
      'vi': 'PHẠM LỖI!',
      'en': 'FOUL!',
      'zh': '犯规!',
      'ja': 'ファウル!',
      'ko': '파울!',
    },
    'ball_in_hand': {
      'vi': 'Bi trong tay: Đặt bi cái tự do',
      'en': 'Ball in hand: Place cue ball anywhere',
      'zh': '自由球: 可在桌面任意位置放置白球',
      'ja': 'フリーボール: 好きな位置に手球を配置',
      'ko': '프리볼: 원하는 위치에 수구를 배치',
    },
    'cue_ball_scratched': {
      'vi': 'Bi cái vào lỗ!',
      'en': 'Cue ball scratched!',
      'zh': '白球落袋犯规!',
      'ja': 'スクラッチ!',
      'ko': '수구 낙하 파울!',
    },

    // Profile & Shop & Cúp
    'shop': {
      'vi': 'CỬA HÀNG',
      'en': 'SHOP',
      'zh': '商城',
      'ja': 'ショップ',
      'ko': '상점',
    },
    'leaderboard': {
      'vi': 'BXH',
      'en': 'RANK',
      'zh': '排行榜',
      'ja': 'ランキング',
      'ko': '랭킹',
    },
    'medals': {
      'vi': 'HUY CHƯƠNG',
      'en': 'MEDALS',
      'zh': '勋章',
      'ja': 'メダル',
      'ko': '훈장',
    },
    'profile': {
      'vi': 'HỒ SƠ',
      'en': 'PROFILE',
      'zh': '档案',
      'ja': 'プロフィール',
      'ko': '프로필',
    },
    'coins': {
      'vi': 'Vàng',
      'en': 'Coins',
      'zh': '金币',
      'ja': 'コイン',
      'ko': '골드',
    },
    'diamonds': {
      'vi': 'Kim Cương',
      'en': 'Diamonds',
      'zh': '钻石',
      'ja': 'ダイヤ',
      'ko': '다이아',
    },
    'level': {
      'vi': 'Cấp',
      'en': 'Level',
      'zh': '等级',
      'ja': 'レベル',
      'ko': '레벨',
    },
    'guest': {
      'vi': 'Khách',
      'en': 'Guest',
      'zh': '游客',
      'ja': 'ゲスト',
      'ko': '게스트',
    },
    'equip': {
      'vi': 'Trang bị',
      'en': 'Equip',
      'zh': '装备',
      'ja': '装備',
      'ko': '장착',
    },
    'equipped': {
      'vi': 'Đang dùng',
      'en': 'Equipped',
      'zh': '使用中',
      'ja': '使用中',
      'ko': '사용 중',
    },
    'upgrade': {
      'vi': 'Nâng cấp',
      'en': 'Upgrade',
      'zh': '升级',
      'ja': '強化',
      'ko': '업그레이드',
    },
    'cue_selector_title': {
      'vi': 'Chọn Gậy Cơ Thi Đấu',
      'en': 'Select Cue Stick',
      'zh': '选择参赛球杆',
      'ja': '試合用キューを選択',
      'ko': '경기용 큐 선택',
    },
    'turn_banner_p1': {
      'vi': 'Lượt P1',
      'en': 'Turn: P1',
      'zh': '回合: 玩家1',
      'ja': 'ターン: P1',
      'ko': '턴: P1',
    },
    'turn_banner_p2': {
      'vi': 'Lượt P2',
      'en': 'Turn: P2',
      'zh': '回合: 玩家2',
      'ja': 'ターン: P2',
      'ko': '턴: P2',
    },
    'score': {
      'vi': 'Tỷ số',
      'en': 'Score',
      'zh': '比分',
      'ja': 'スコア',
      'ko': '스코어',
    },
    'select_cue_p1': {
      'vi': 'CHỌN GẬY CƠ • PLAYER 1',
      'en': 'SELECT CUE • PLAYER 1',
      'zh': '选择球杆 • 玩家1',
      'ja': 'キュー選択 • P1',
      'ko': '큐 선택 • P1',
    },
    'select_cue_p2': {
      'vi': 'CHỌN GẬY CƠ • PLAYER 2',
      'en': 'SELECT CUE • PLAYER 2',
      'zh': '选择球杆 • 玩家2',
      'ja': 'キュー選択 • P2',
      'ko': '큐 선택 • P2',
    },
    'force': {
      'vi': 'Lực',
      'en': 'Force',
      'zh': '力量',
      'ja': 'パワー',
      'ko': '파워',
    },
    'aim': {
      'vi': 'Ngắm',
      'en': 'Aim',
      'zh': '瞄准',
      'ja': '照準',
      'ko': '조준',
    },
    'spin': {
      'vi': 'Xoáy',
      'en': 'Spin',
      'zh': '加塞',
      'ja': 'スピン',
      'ko': '스핀',
    },
    'select': {
      'vi': 'Chọn',
      'en': 'Select',
      'zh': '选择',
      'ja': '選択',
      'ko': '선택',
    },
    'hint': {
      'vi': 'Gợi ý',
      'en': 'Hint',
      'zh': '提示',
      'ja': 'ヒント',
      'ko': '힌트',
    },
    'reset_shot': {
      'vi': 'ĐẶT LẠI',
      'en': 'RESET',
      'zh': '重置',
      'ja': 'リセット',
      'ko': '재설정',
    },
    'play_again': {
      'vi': 'Chơi lại',
      'en': 'Play Again',
      'zh': '再来一局',
      'ja': 'もう一度',
      'ko': '다시 하기',
    },

    // Dialogs & Chế độ Offline
    'next_stage': {
      'vi': 'Ải tiếp theo ({num})',
      'en': 'Next Stage ({num})',
      'zh': '下一关 ({num})',
      'ja': '次のステージ ({num})',
      'ko': '다음 스테이지 ({num})',
    },
    'next_bracket': {
      'vi': 'Vòng tiếp theo (B{num})',
      'en': 'Next Round (B{num})',
      'zh': '下一轮 (第{num}轮)',
      'ja': '次のラウンド (B{num})',
      'ko': '다음 라운드 (B{num})',
    },
    'finals': {
      'vi': 'Vào Chung Kết',
      'en': 'Grand Finals',
      'zh': '晋级总决赛',
      'ja': '決勝戦へ',
      'ko': '결승전 진출',
    },
    'next_trickshot': {
      'vi': 'Thế tiếp theo',
      'en': 'Next Trickshot',
      'zh': '下一绝技',
      'ja': '次のショット',
      'ko': '다음 트릭샷',
    },
    'progress': {
      'vi': 'Tiến độ: {current} / {total} ải',
      'en': 'Progress: {current} / {total} stages',
      'zh': '进度: {current} / {total} 关',
      'ja': '進捗: {current} / {total} ステージ',
      'ko': '진행도: {current} / {total} 스테이지',
    },
    'stage_cleared': {
      'vi': '★ ĐÃ VƯỢT',
      'en': '★ CLEARED',
      'zh': '★ 已通关',
      'ja': '★ クリア済み',
      'ko': '★ 클리어',
    },
    'first_clear_reward': {
      'vi': 'Quà lần đầu: ',
      'en': 'First Clear: ',
      'zh': '首通奖励: ',
      'ja': '初クリア報酬: ',
      'ko': '첫 클리어 보상: ',
    },
    'challenge': {
      'vi': 'KHIÊU CHIẾN',
      'en': 'CHALLENGE',
      'zh': '挑战',
      'ja': '挑戦',
      'ko': '도전',
    },
    'replay': {
      'vi': 'ĐẤU LẠI',
      'en': 'REMATCH',
      'zh': '再战',
      'ja': '再戦',
      'ko': '다시하기',
    },
    'tournament_title': {
      'vi': 'GIẢI ĐẤU VÔ ĐỊCH 5 BRACKETS (TOURNAMENT)',
      'en': '5 BRACKETS CHAMPIONSHIP TOURNAMENT',
      'zh': '5轮淘汰巡回锦标赛',
      'ja': '5段階トーナメント大会',
      'ko': '5강 챔피언십 토너먼트',
    },
    'tournament_subtitle': {
      'vi': '5 Vòng Đấu Trực Tiếp • Thử Thách Cúp Vô Địch',
      'en': '5 Elimination Rounds • Champion Trophy Challenge',
      'zh': '5轮单败淘汰 • 争夺总冠军奖杯',
      'ja': '5段階勝ち抜き戦 • 優勝トロフィー争奪',
      'ko': '5단계 토너먼트 • 챔피언 트로피 쟁탈전',
    },
    'champion_reward_banner': {
      'vi': '🏆 PHẦN THƯỞNG QUÁN QUÂN ĐẠI CHUNG KẾT BRACKET 5:',
      'en': '🏆 GRAND FINALS CHAMPION REWARDS (BRACKET 5):',
      'zh': '🏆 第5轮总决赛冠军豪华奖励:',
      'ja': '🏆 第5ブラケット決勝戦 優勝賞品:',
      'ko': '🏆 5라운드 그랜드 파이널 챔피언 보상:',
    },
    'champion_reward_desc': {
      'vi': '+15.000 Vàng • +2.500 EXP • Cúp Quán Quân Tournament • Thành Tựu Vua Giải Đấu!',
      'en': '+15,000 Coins • +2,500 EXP • Tournament Trophy • Champion Achievement!',
      'zh': '+15,000 金币 • +2,500 EXP • 锦标赛金杯 • 冠军荣耀成就!',
      'ja': '+15,000 コイン • +2,500 EXP • 優勝トロフィー • 王者実績!',
      'ko': '+15,000 골드 • +2,500 EXP • 토너먼트 트로피 • 챔피언 업적!',
    },
    'reset': {
      'vi': 'LÀM MỚI',
      'en': 'RESET',
      'zh': '重置',
      'ja': 'リセット',
      'ko': '초기화',
    },
    'championship_match': {
      'vi': '👑 TRẬN TRANH CÚP VÔ ĐỊCH',
      'en': '👑 CHAMPIONSHIP CUP MATCH',
      'zh': '👑 争霸总决赛',
      'ja': '👑 優勝決定戦',
      'ko': '👑 챔피언십 결정전',
    },
    'opponent': {
      'vi': 'Đối thủ',
      'en': 'Opponent',
      'zh': '对手',
      'ja': '対戦相手',
      'ko': '상대방',
    },
    'play_bot': {
      'vi': 'ĐẤU VỚI BOT',
      'en': 'VS BOT',
      'zh': '挑战人机',
      'ja': 'BOT対戦',
      'ko': '봇 대전',
    },
    'compete_cup': {
      'vi': 'TRANH CÚP',
      'en': 'FINALS',
      'zh': '争夺奖杯',
      'ja': 'トロフィー戦',
      'ko': '트로피전',
    },
    'won': {
      'vi': 'ĐÃ THẮNG',
      'en': 'WON',
      'zh': '已获胜',
      'ja': '勝利',
      'ko': '승리 완료',
    },
    'trophy_cup': {
      'vi': 'Cúp Quán Quân',
      'en': 'Champion Trophy',
      'zh': '冠军奖杯',
      'ja': '優勝トロフィー',
      'ko': '챔피언 트로피',
    },
    'rewards': {
      'vi': 'PHẦN THƯỞNG',
      'en': 'REWARDS',
      'zh': '奖励结算',
      'ja': '報酬',
      'ko': '보상',
    },
    'shop_title': {
      'vi': 'CỬA HÀNG GẬY CƠ & TIẾN TRÌNH',
      'en': 'CUE SHOP & PROGRESSION',
      'zh': '球杆商城与成长',
      'ja': 'キューショップ＆成長',
      'ko': '큐 상점 및 성장',
    },
    'buy_now': {
      'vi': 'MUA NGAY',
      'en': 'BUY NOW',
      'zh': '立即购买',
      'ja': '今すぐ購入',
      'ko': '지금 구매',
    },
    'insufficient_coins': {
      'vi': 'Bạn không đủ Vàng để mua cây cơ này!',
      'en': 'Not enough Coins to purchase this cue!',
      'zh': '金币不足，无法购买该球杆!',
      'ja': 'コインが不足しています!',
      'ko': '골드가 부족하여 구매할 수 없습니다!',
    },
    'pot_ball': {
      'vi': 'ĂN BI',
      'en': 'POT BALL',
      'zh': '打进目标球',
      'ja': 'ターゲット球',
      'ko': '목표구 넣기',
    },
    'avoid_ball': {
      'vi': 'TRÁNH',
      'en': 'AVOID',
      'zh': '避免打进',
      'ja': '回避',
      'ko': '피하기',
    },
    'shots_taken': {
      'vi': 'Đã dùng: {current} / {max} cơ',
      'en': 'Shots: {current} / {max}',
      'zh': '出杆数: {current} / {max}',
      'ja': 'ショット数: {current} / {max}',
      'ko': '샷 수: {current} / {max}',
    },
    'match_over': {
      'vi': 'Ván đấu kết thúc',
      'en': 'Match Completed',
      'zh': '比赛结束',
      'ja': '試合終了',
      'ko': '경기 종료',
    },
    'daily_puzzle_win': {
      'vi': '🎉 PHÁ GIẢI THẾ BI THÀNH CÔNG!',
      'en': '🎉 DAILY PUZZLE SOLVED!',
      'zh': '🎉 残局破解成功!',
      'ja': '🎉 パズルクリア成功!',
      'ko': '🎉 일일 퍼즐 해결 성공!',
    },
    'daily_puzzle_fail': {
      'vi': '😢 THẾ BI CHƯA HOÀN THÀNH',
      'en': '😢 PUZZLE NOT SOLVED',
      'zh': '😢 残局未完成',
      'ja': '😢 パズル未達成',
      'ko': '😢 퍼즐 미완료',
    },
    'trickshot_win': {
      'vi': '🏆 XUẤT SẮC! TÁI HIỆN THẾ BI CỦA {player}!',
      'en': '🏆 MASTERPIECE! RECREATED {player}\'S SHOT!',
      'zh': '🏆 绝妙! 完美重现 {player} 的巅峰杆法!',
      'ja': '🏆 見事! {player} の神技を完全再現!',
      'ko': '🏆 환상적입니다! {player}의 명샷 재현 성공!',
    },
    'trickshot_fail': {
      'vi': '😢 CHƯA HOÀN THÀNH ĐƯỜNG CƠ!',
      'en': '😢 TRICKSHOT MISSED!',
      'zh': '😢 未能完成名局杆法!',
      'ja': '😢 ショット未達成!',
      'ko': '😢 트릭샷 미완료!',
    },
    'tournament_champion_title': {
      'vi': '🏆 BẠN ĐÃ VÔ ĐỊCH TOURNAMENT GRAND CHAMPION!',
      'en': '🏆 YOU ARE THE TOURNAMENT GRAND CHAMPION!',
      'zh': '🏆 恭喜您荣膺巡回锦标赛总冠军!',
      'ja': '🏆 トーナメント グランドチャンピオン制覇!',
      'ko': '🏆 토너먼트 그랜드 챔피언 등극!',
    },
    'bracket_passed': {
      'vi': '🎉 VƯỢT QUA {stage} (BRACKET {num})!',
      'en': '🎉 PASSED {stage} (BRACKET {num})!',
      'zh': '🎉 成功晋级 {stage} (第{num}轮)!',
      'ja': '🎉 {stage} 突破 (ブラケット {num})!',
      'ko': '🎉 {stage} 통과 (브래킷 {num})!',
    },
    'bracket_failed': {
      'vi': '😢 BẠN ĐÃ BỊ LOẠI TẠI BRACKET {num}!',
      'en': '😢 ELIMINATED AT BRACKET {num}!',
      'zh': '😢 遗憾止步于第{num}轮!',
      'ja': '😢 ブラケット {num} で敗退!',
      'ko': '😢 브래킷 {num}에서 탈락했습니다!',
    },
    'stage_passed_title': {
      'vi': '🎉 VƯỢT ẢI {num} THÀNH CÔNG!',
      'en': '🎉 STAGE {num} CLEARED!',
      'zh': '🎉 突破第 {num} 关成功!',
      'ja': '🎉 ステージ {num} クリア!',
      'ko': '🎉 스테이지 {num} 클리어!',
    },
    'bot_won_title': {
      'vi': '😢 {bot} ĐÃ CHIẾN THẮNG!',
      'en': '😢 {bot} WON THE MATCH!',
      'zh': '😢 {bot} 赢得了比赛!',
      'ja': '😢 {bot} の勝利!',
      'ko': '😢 {bot} 승리!',
    },
    'bot_won': {
      'vi': '🤖 BOT ĐÃ CHIẾN THẮNG!',
      'en': '🤖 BOT WON THE MATCH!',
      'zh': '🤖 电脑赢得了比赛!',
      'ja': '🤖 BOTの勝利!',
      'ko': '🤖 봇이 승리했습니다!',
    },
    'match_win_opp': {
      'vi': '🎉 BẠN ĐÃ CHIẾN THẮNG {opp}!',
      'en': '🎉 YOU DEFEATED {opp}!',
      'zh': '🎉 您战胜了 {opp}!',
      'ja': '🎉 {opp} に勝利しました!',
      'ko': '🎉 {opp} 상대로 승리했습니다!',
    },
    'match_lose_opp': {
      'vi': '😢 {opp} ĐÃ CHIẾN THẮNG!',
      'en': '😢 {opp} WON THE MATCH!',
      'zh': '😢 {opp} 获得了胜利!',
      'ja': '😢 {opp} の勝利!',
      'ko': '😢 {opp} 승리!',
    },
    'locked': {
      'vi': 'Khóa',
      'en': 'Locked',
      'zh': '未解锁',
      'ja': 'ロック',
      'ko': '잠김',
    },
    'daily_puzzle_header': {
      'vi': 'NHIỆM VỤ THẾ BI HÀNG NGÀY',
      'en': 'DAILY PUZZLE CHALLENGE',
      'zh': '每日残局挑战',
      'ja': 'デイリーパズルミッション',
      'ko': '일일 퍼즐 미션',
    },
    'daily_puzzle_badge': {
      'vi': 'THẾ BI MỖI NGÀY',
      'en': 'DAILY PUZZLE',
      'zh': '每日残局',
      'ja': 'デイリーパズル',
      'ko': '일일 퍼즐',
    },
    'puzzle_shot_limit': {
      'vi': 'Giới hạn: Tối đa {max} lượt đánh',
      'en': 'Limit: Max {max} shots',
      'zh': '限制: 最多 {max} 杆',
      'ja': '制限: 最大 {max} ショット',
      'ko': '제한: 최대 {max} 샷',
    },
    'completion_reward': {
      'vi': 'PHẦN THƯỞNG HOÀN THÀNH',
      'en': 'COMPLETION REWARDS',
      'zh': '通关奖励',
      'ja': 'クリア報酬',
      'ko': '완료 보상',
    },
    'daily_reset_note': {
      'vi': 'Chỉ tính hoàn thành trong ngày • Làm mới vào 0h mỗi ngày.',
      'en': 'Daily valid only • Resets at 0:00 every day.',
      'zh': '仅限当日完成有效 • 每日0点重置。',
      'ja': '当日のみ有効 • 毎日午前0時にリセット。',
      'ko': '당일 완료만 인정 • 매일 0시 초기화.',
    },
    'completed_today': {
      'vi': 'ĐÃ HOÀN THÀNH HÔM NAY',
      'en': 'COMPLETED TODAY',
      'zh': '今日已完成',
      'ja': '本日クリア済み',
      'ko': '오늘 완료됨',
    },
    'practice_again': {
      'vi': 'LUYỆN TẬP LẠI',
      'en': 'PRACTICE AGAIN',
      'zh': '再次练习',
      'ja': '再練習',
      'ko': '다시 연습',
    },
    'start_daily_puzzle': {
      'vi': 'BẮT ĐẦU THỬ THÁCH THẾ BI',
      'en': 'START DAILY PUZZLE',
      'zh': '开始残局挑战',
      'ja': 'パズルに挑戦',
      'ko': '퍼즐 도전 시작',
    },
    'legendary_trickshot_header': {
      'vi': 'LUYỆN TẬP THẾ ĐÁNH HUYỀN THOẠI',
      'en': 'LEGENDARY TRICKSHOT PRACTICE',
      'zh': '传奇绝技球练习',
      'ja': '伝説のトリックショット練習',
      'ko': '전설의 트릭샷 연습',
    },
    'conquered_progress': {
      'vi': 'Chinh phục: {current} / {total}',
      'en': 'Cleared: {current} / {total}',
      'zh': '已征服: {current} / {total}',
      'ja': '制覇: {current} / {total}',
      'ko': '정복: {current} / {total}',
    },
    'practice_shot': {
      'vi': 'TẬP THẾ NÀY',
      'en': 'PRACTICE',
      'zh': '练此绝技',
      'ja': 'このショットを練習',
      'ko': '이 샷 연습',
    },
    'avoid_balls_label': {
      'vi': 'Tránh rơi Bi: #{balls}',
      'en': 'Avoid potting: #{balls}',
      'zh': '避免打入球: #{balls}',
      'ja': '回避ボール: #{balls}',
      'ko': '피할 볼: #{balls}',
    },
    'player_pro': {
      'vi': 'Cơ thủ: {name}',
      'en': 'Master: {name}',
      'zh': '大师: {name}',
      'ja': 'プレイヤー: {name}',
      'ko': '선수: {name}',
    },
    'free': {
      'vi': 'Miễn phí',
      'en': 'Free',
      'zh': '免费',
      'ja': '無料',
      'ko': '무료',
    },
    'max_level': {
      'vi': '★ MAX LEVEL',
      'en': '★ MAX LEVEL',
      'zh': '★ 最高等级',
      'ja': '★ 最大レベル',
      'ko': '★ 최고 레벨',
    },
    'time': {
      'vi': 'Thời gian lượt (Time)',
      'en': 'Turn Time',
      'zh': '出杆时间',
      'ja': 'ターン時間',
      'ko': '턴 시간',
    },
    'locked_requires_level': {
      'vi': 'KHÓA • YÊU CẦU ĐẠT CẤP {level}',
      'en': 'LOCKED • REQUIRES LEVEL {level}',
      'zh': '未解锁 • 需达到等级 {level}',
      'ja': 'ロック中 • レベル {level} 到達が必要',
      'ko': '잠김 • 레벨 {level} 달성 필요',
    },
    'audio_on': {
      'vi': 'Âm thanh: Bật',
      'en': 'Audio: ON',
      'zh': '音频: 开启',
      'ja': 'オーディオ: ON',
      'ko': '오디오: 켜짐',
    },
    'audio_off': {
      'vi': 'Âm thanh: Tắt',
      'en': 'Audio: OFF',
      'zh': '音频: 关闭',
      'ja': 'オーディオ: OFF',
      'ko': '오디오: 꺼짐',
    },
    'exit_match_title': {
      'vi': 'Thoát ván đấu',
      'en': 'Exit Match',
      'zh': '退出对局',
      'ja': '試合を退出',
      'ko': '경기 나가기',
    },
    'exit_match_content': {
      'vi': 'Bạn có muốn kết thúc trận đấu và quay về Menu chính không?',
      'en': 'Do you want to forfeit this match and return to Main Menu?',
      'zh': '您确定要退出此比赛并返回主菜单吗？',
      'ja': '試合を終了してメインメニューに戻りますか？',
      'ko': '경기를 종료하고 메인 메뉴로 돌아가시겠습니까?',
    },
    'cancel': {
      'vi': 'Hủy',
      'en': 'Cancel',
      'zh': '取消',
      'ja': 'キャンセル',
      'ko': '취소',
    },
    'confirm': {
      'vi': 'Đồng ý',
      'en': 'Confirm',
      'zh': '确认',
      'ja': '確認',
      'ko': '확인',
    },
    'match_in_progress': {
      'vi': 'Trận đấu đang diễn ra ở thời gian thực',
      'en': 'Match in progress in real-time',
      'zh': '实时对局进行中',
      'ja': 'リアルタイム試合進行中',
      'ko': '실시간 경기 진행 중',
    },
    'return_to_table': {
      'vi': 'QUAY LẠI BÀN',
      'en': 'RETURN TO TABLE',
      'zh': '返回球桌',
      'ja': 'テーブルに戻る',
      'ko': '테이블로 복귀',
    },
    'profile_title': {
      'vi': 'HỒ SƠ CƠ THỦ (PROFILE)',
      'en': 'PLAYER PROFILE',
      'zh': '选手档案',
      'ja': 'プレイヤープロフィール',
      'ko': '선수 프로필',
    },
    'level_progress': {
      'vi': 'Tiến trình cấp độ',
      'en': 'Level Progress',
      'zh': '等级进度',
      'ja': 'レベル進捗',
      'ko': '레벨 진행도',
    },
    'champion_cups': {
      'vi': 'CÚP VÔ ĐỊCH',
      'en': 'CHAMPION CUPS',
      'zh': '冠军奖杯',
      'ja': 'チャンピオンカップ',
      'ko': '우승 트로피',
    },
    'medals_showcase_title': {
      'vi': '5 HUY CHƯƠNG VINH DANH TRÊN HỒ SƠ',
      'en': '5 SHOWCASED MEDALS ON PROFILE',
      'zh': '个人主页展示的5枚荣誉勋章',
      'ja': 'プロフィールに掲示された5つの勲章',
      'ko': '프로필에 전시된 5개의 훈장',
    },
    'manage': {
      'vi': 'Quản Lý',
      'en': 'Manage',
      'zh': '管理',
      'ja': '管理',
      'ko': '관리',
    },
    'add': {
      'vi': 'Thêm',
      'en': 'Add',
      'zh': '添加',
      'ja': '追加',
      'ko': '추가',
    },
    'achievements_list': {
      'vi': 'DANH SÁCH THÀNH TỰU (+XP)',
      'en': 'ACHIEVEMENTS LIST (+XP)',
      'zh': '成就列表 (+XP)',
      'ja': '実績一覧 (+XP)',
      'ko': '업적 목록 (+XP)',
    },
    'account': {
      'vi': 'TÀI KHOẢN',
      'en': 'ACCOUNT',
      'zh': '账号',
      'ja': 'アカウント',
      'ko': '계정',
    },
    'rarity': {
      'vi': 'Độ hiếm',
      'en': 'Rarity',
      'zh': '稀有度',
      'ja': 'レア度',
      'ko': '희귀도',
    },
    'requirement': {
      'vi': 'Điều kiện',
      'en': 'Requirement',
      'zh': '解锁条件',
      'ja': '獲得条件',
      'ko': '획득 조건',
    },
    'guest_offline': {
      'vi': 'KHÁCH (OFFLINE)',
      'en': 'GUEST (OFFLINE)',
      'zh': '游客 (离线)',
      'ja': 'ゲスト (オフライン)',
      'ko': '게스트 (오프라인)',
    },
    'login': {
      'vi': 'ĐĂNG NHẬP',
      'en': 'LOGIN',
      'zh': '登录',
      'ja': 'ログイン',
      'ko': '로그인',
    },
    'leaderboard_header': {
      'vi': 'BẢNG XẾP HẠNG REALTIME',
      'en': 'REAL-TIME LEADERBOARD',
      'zh': '实时排行榜',
      'ja': 'リアルタイムランキング',
      'ko': '실시간 순위표',
    },
    'refresh': {
      'vi': 'Tải lại danh sách',
      'en': 'Refresh list',
      'zh': '刷新列表',
      'ja': 'リストを更新',
      'ko': '목록 새로고침',
    },
    'no_leaderboard_data': {
      'vi': 'Chưa có dữ liệu xếp hạng',
      'en': 'No leaderboard data yet',
      'zh': '暂无排行数据',
      'ja': 'ランキングデータがありません',
      'ko': '순위 데이터가 없습니다',
    },
    'leaderboard_empty_hint': {
      'vi': 'Hãy đăng nhập và chơi để ghi danh lên bảng vàng!',
      'en': 'Sign in and play to earn your place on the board!',
      'zh': '登录并参与对局，名列榜首！',
      'ja': 'ログインしてプレイし、ランキングに名を刻もう！',
      'ko': '로그인하고 플레이하여 순위표에 이름을 올리세요!',
    },
    'player_default': {
      'vi': 'Cơ Thủ',
      'en': 'Player',
      'zh': '球手',
      'ja': 'プレイヤー',
      'ko': '선수',
    },
    'coins_unit': {
      'vi': 'Vàng',
      'en': 'Coins',
      'zh': '金币',
      'ja': 'ゴールド',
      'ko': '골드',
    },
    'wins_unit': {
      'vi': 'Trận',
      'en': 'Wins',
      'zh': '场',
      'ja': '勝',
      'ko': '승',
    },
    'level_short': {
      'vi': 'Cấp',
      'en': 'Lv.',
      'zh': '等级',
      'ja': 'Lv.',
      'ko': 'Lv.',
    },
    'achievements_header': {
      'vi': 'DANH HIỆU & VINH QUANG',
      'en': 'HONORS & GLORY',
      'zh': '头衔与荣耀',
      'ja': '称号と栄光',
      'ko': '칭호와 영예',
    },
    'achievements_sub': {
      'vi': 'Hoàn thành thành tựu nhận EXP • Ghim tối đa 5 huy chương lên Profile',
      'en': 'Complete achievements to earn EXP • Pin up to 5 medals on Profile',
      'zh': '完成成就获得经验 • 最多可在个人主页展示5枚勋章',
      'ja': '実績達成でEXP獲得 • プロフィールに最大5つの勲章を掲示',
      'ko': '업적 완료로 EXP 획득 • 프로필에 최대 5개 훈장 고정',
    },
    'achievements_tab': {
      'vi': 'THÀNH TỰU (+XP)',
      'en': 'ACHIEVEMENTS (+XP)',
      'zh': '成就 (+XP)',
      'ja': '実績 (+XP)',
      'ko': '업적 (+XP)',
    },
    'medals_tab': {
      'vi': 'KHO HUY CHƯƠNG',
      'en': 'MEDALS VAULT',
      'zh': '荣誉勋章库',
      'ja': '勲章保管庫',
      'ko': '훈장 보관소',
    },
    'achievements_progress': {
      'vi': 'Tiến Trình Thành Tựu',
      'en': 'Achievement Progress',
      'zh': '成就进度',
      'ja': '実績の進捗',
      'ko': '업적 진행도',
    },
    'by_difficulty': {
      'vi': 'Theo Độ Khó',
      'en': 'By Difficulty',
      'zh': '按难度分档',
      'ja': '難易度別',
      'ko': '난이도별',
    },
    'difficulty': {
      'vi': 'Độ khó',
      'en': 'Difficulty',
      'zh': '难度',
      'ja': '難易度',
      'ko': '난이도',
    },
    'claimed': {
      'vi': 'Đã nhận',
      'en': 'Claimed',
      'zh': '已领取',
      'ja': '受取済',
      'ko': '수령 완료',
    },
    'medals_pinned_title': {
      'vi': 'HUY CHƯƠNG GHIM TRÊN PROFILE (TỐI ĐA 5)',
      'en': 'PINNED MEDALS ON PROFILE (MAX 5)',
      'zh': '主页展示勋章 (最多5枚)',
      'ja': 'プロフィール掲示勲章 (最大5個)',
      'ko': '프로필 고정 훈장 (최대 5개)',
    },
    'selected': {
      'vi': 'Đã Chọn',
      'en': 'Selected',
      'zh': '已选择',
      'ja': '選択済',
      'ko': '선택됨',
    },
    'tap_to_remove': {
      'vi': '(Chạm để gỡ)',
      'en': '(Tap to unpin)',
      'zh': '(点击卸下)',
      'ja': '(タップで解除)',
      'ko': '(터치하여 해제)',
    },
    'slot': {
      'vi': 'Ô',
      'en': 'Slot',
      'zh': '槽位',
      'ja': 'スロット',
      'ko': '슬롯',
    },
    'all_medals_title': {
      'vi': 'TẤT CẢ HUY CHƯƠNG TRONG GAME',
      'en': 'ALL IN-GAME MEDALS',
      'zh': '所有游戏勋章',
      'ja': '全ゲーム勲章',
      'ko': '모든 인게임 훈장',
    },
    'unpin_from_profile': {
      'vi': 'Gỡ Khỏi Profile',
      'en': 'Unpin from Profile',
      'zh': '从主页卸下',
      'ja': '掲示を解除',
      'ko': '프로필에서 해제',
    },
    'pin_to_profile': {
      'vi': 'Ghim Lên Profile',
      'en': 'Pin to Profile',
      'zh': '展示至主页',
      'ja': 'プロフィールに掲示',
      'ko': '프로필에 고정',
    },
    'local_multiplayer_title': {
      'vi': 'ĐẤU MẠNG CỤC BỘ (WIFI / HOTSPOT)',
      'en': 'LOCAL MULTIPLAYER (WIFI / HOTSPOT)',
      'zh': '局域网对决 (WIFI / 热点)',
      'ja': 'ローカル対戦 (WIFI / ホットスポット)',
      'ko': '로컬 멀티플레이 (와이파이 / 핫스팟)',
    },
    'create_room_host': {
      'vi': 'TẠO PHÒNG (HOST)',
      'en': 'CREATE ROOM (HOST)',
      'zh': '创建房间 (房主)',
      'ja': 'ルーム作成 (ホスト)',
      'ko': '방 만들기 (호스트)',
    },
    'join_room_client': {
      'vi': 'VÀO PHÒNG (JOIN)',
      'en': 'JOIN ROOM (CLIENT)',
      'zh': '加入房间 (访客)',
      'ja': 'ルーム参加 (ゲスト)',
      'ko': '방 참가 (클라이언트)',
    },
    'this_device_ip': {
      'vi': 'IP MÁY NÀY (WIFI / HOTSPOT):',
      'en': 'THIS DEVICE IP (WIFI / HOTSPOT):',
      'zh': '本机 IP (WIFI / 热点):',
      'ja': 'このデバイスのIP (WIFI / ホットスポット):',
      'ko': '이 기기의 IP (와이파이 / 핫스팟):',
    },
    'loading_ip': {
      'vi': 'Đang tải IP...',
      'en': 'Loading IP...',
      'zh': '正在获取IP...',
      'ja': 'IP取得中...',
      'ko': 'IP 로딩 중...',
    },
    'refresh_ip': {
      'vi': 'Tải lại IP',
      'en': 'Refresh IP',
      'zh': '刷新IP',
      'ja': 'IP再取得',
      'ko': 'IP 새로고침',
    },
    'wifi_tip': {
      'vi': 'Mẹo: Nếu WiFi chặn kết nối, 1 máy bật Hotspot cho máy kia bắt là chơi được 100%!',
      'en': 'Tip: If Wi-Fi isolates devices, have one device turn on Hotspot for the other!',
      'zh': '提示: 若局域网隔离设备，一台开启手机热点供另一台连接即可100%畅玩！',
      'ja': 'ヒント: Wi-Fiが機器間接続を遮断する場合、1台がホットスポットを起動して接続すると確実に対戦できます！',
      'ko': '팁: 와이파이가 기기 간 연결을 차단하면, 한 기기에서 핫스팟을 켜서 연결하세요!',
    },
    'broadcasting_room': {
      'vi': 'Đang phát sóng phòng...',
      'en': 'Broadcasting room...',
      'zh': '正在广播房间...',
      'ja': 'ルームをブロードキャスト中...',
      'ko': '방 신호 송출 중...',
    },
    'cancel_room': {
      'vi': 'HỦY PHÒNG',
      'en': 'CANCEL ROOM',
      'zh': '解散房间',
      'ja': 'ルーム解散',
      'ko': '방 취소',
    },
    'open_room_wait_opp': {
      'vi': 'MỞ PHÒNG CHỜ ĐỐI THỦ',
      'en': 'OPEN ROOM FOR OPPONENT',
      'zh': '开房等待对手',
      'ja': 'ルームを開いて相手を待つ',
      'ko': '방 열고 상대 대기',
    },
    'opp_auto_discover': {
      'vi': 'Máy đối thủ sẽ tự động thấy phòng hoặc nhập IP',
      'en': 'Opponent device will auto-discover or enter IP',
      'zh': '对手设备将自动搜索到房间或手动输入IP',
      'ja': '相手の端末は自動検出またはIP入力で参加可能',
      'ko': '상대 기기가 방을 자동 감지하거나 IP를 입력합니다',
    },
    'scanning_wifi_rooms': {
      'vi': 'Đang tự động quét phòng WiFi...',
      'en': 'Scanning for Wi-Fi rooms...',
      'zh': '正在自动扫描局域网房间...',
      'ja': 'Wi-Fiルームを自動スキャン中...',
      'ko': '와이파이 방 자동 검색 중...',
    },
    'room_appear_here': {
      'vi': 'Khi máy Host mở phòng, sẽ hiện ngay tại đây',
      'en': 'When Host creates room, it will appear here',
      'zh': '房主创建房间后将在此实时显示',
      'ja': 'ホストがルームを開くとここに表示されます',
      'ko': '호스트가 방을 열면 여기에 표시됩니다',
    },
    'join_table_now': {
      'vi': 'VÀO BÀN NGAY (1-CHẠM)',
      'en': 'JOIN TABLE NOW',
      'zh': '一键进入球台',
      'ja': 'ワンタップで参加',
      'ko': '즉시 입장 (원터치)',
    },
    'manual_ip_entry': {
      'vi': 'HOẶC NHẬP IP THỦ CÔNG:',
      'en': 'OR ENTER IP MANUALLY:',
      'zh': '或手动输入IP地址:',
      'ja': 'または手動でIPを入力:',
      'ko': '또는 수동으로 IP 입력:',
    },
    'paste': {
      'vi': 'DÁN',
      'en': 'PASTE',
      'zh': '粘贴',
      'ja': '貼付',
      'ko': '붙여넣기',
    },
    'connect_to_room': {
      'vi': 'KẾT NỐI VÀO PHÒNG',
      'en': 'CONNECT TO ROOM',
      'zh': '连接至房间',
      'ja': 'ルームに接続',
      'ko': '방에 연결',
    },
    'guest_p2': {
      'vi': 'Khách (P2)',
      'en': 'Guest (P2)',
      'zh': '访客 (P2)',
      'ja': 'ゲスト (P2)',
      'ko': '게스트 (P2)',
    },
    'host_p1': {
      'vi': 'Chủ phòng (P1)',
      'en': 'Host (P1)',
      'zh': '房主 (P1)',
      'ja': 'ホスト (P1)',
      'ko': '호스트 (P1)',
    },
    'online_multiplayer_title': {
      'vi': 'ĐẤU ONLINE TOÀN CẦU (WEBSOCKET)',
      'en': 'GLOBAL ONLINE MULTIPLAYER (WEBSOCKET)',
      'zh': '全球在线对决 (WEBSOCKET)',
      'ja': 'グローバルオンライン対戦 (WEBSOCKET)',
      'ko': '글로벌 온라인 대전 (WEBSOCKET)',
    },
    'online_multiplayer_sub': {
      'vi': 'Ghép trận ngẫu nhiên hoặc tạo phòng riêng với bạn bè qua Internet',
      'en': 'Random matchmaking or create private rooms with friends over the Internet',
      'zh': '随机匹配或与好友创建专属在线对战房间',
      'ja': 'ランダムマッチまたはインターネットで友達とプライベートルームを作成',
      'ko': '랜덤 매칭 또는 인터넷을 통해 친구와 비공개 방 생성',
    },
    'preset_center': {
      'vi': 'Tâm bi (Chuẩn)',
      'en': 'Center (Standard)',
      'zh': '球心 (标准)',
      'ja': '中心 (標準)',
      'ko': '중심 (기본)',
    },
    'preset_top': {
      'vi': 'Cu-lê (Tiến)',
      'en': 'Top Spin (Follow)',
      'zh': '高杆 (推进)',
      'ja': 'トップスピン (押し球)',
      'ko': '상단 (밀어치기)',
    },
    'preset_bottom': {
      'vi': 'Trô bóng (Lùi)',
      'en': 'Back Spin (Draw)',
      'zh': '低杆 (缩杆)',
      'ja': 'バックスピン (引き球)',
      'ko': '하단 (끌어치기)',
    },
    'preset_left': {
      'vi': 'Áp-phê Trái',
      'en': 'Left English',
      'zh': '左加塞',
      'ja': '左ひねり',
      'ko': '좌측 회전',
    },
    'preset_right': {
      'vi': 'Áp-phê Phải',
      'en': 'Right English',
      'zh': '右加塞',
      'ja': '右ひねり',
      'ko': '우측 회전',
    },
    'spin_control_title': {
      'vi': 'Điểm tác động bi cái (Xoáy)',
      'en': 'Cue Ball Impact Point (Spin)',
      'zh': '母球击球点 (旋转)',
      'ja': '手球インパクトポイント (スピン)',
      'ko': '수구 당점 조절 (스핀)',
    },
    'spin_control_instruction': {
      'vi': 'Kéo chấm đỏ để chỉnh Cu-lê (tiến), Trô bóng (lùi) hoặc Áp-phê (ngang)',
      'en': 'Drag the red dot to adjust Follow, Draw, or English spin',
      'zh': '拖动红点调节高杆、低杆或左右加塞',
      'ja': '赤点をドラッグして押し球、引き球、または左右ひねりを調整',
      'ko': '빨간 점을 드래그하여 밀어치기, 끌어치기, 회전을 조절하세요',
    },
    'done': {
      'vi': 'Xong',
      'en': 'Done',
      'zh': '完成',
      'ja': '完了',
      'ko': '완료',
    },
    'need_level': {
      'vi': 'Cần Cấp',
      'en': 'Requires Lv.',
      'zh': '需要等级',
      'ja': '必要レベル',
      'ko': '필요 레벨',
    },
    'cue_level': {
      'vi': 'Cấp gậy',
      'en': 'Cue Level',
      'zh': '球杆等级',
      'ja': 'キューレベル',
      'ko': '큐 레벨',
    },
    'locked_requires_level_toast': {
      'vi': 'Cây cơ này yêu cầu đạt Cấp {level} để mở khóa!',
      'en': 'This cue requires reaching Level {level} to unlock!',
      'zh': '该球杆需要达到 {level} 级方可解锁！',
      'ja': 'このキューはレベル {level} でアンロックされます！',
      'ko': '이 큐는 레벨 {level}을 달성해야 잠금 해제됩니다!',
    },
    'not_enough_diamonds': {
      'vi': 'Bạn không đủ Kim Cương để mua cây cơ này (còn thiếu {missing} Kim Cương)!',
      'en': 'Not enough Diamonds to buy this cue ({missing} Diamonds missing)!',
      'zh': '钻石不足以购买此球杆（缺少 {missing} 钻石）！',
      'ja': 'ダイヤが不足しています（あと {missing} 個必要）！',
      'ko': '다이아몬드가 부족합니다 ({missing} 다이아몬드 부족)!',
    },
    'not_enough_coins_cue': {
      'vi': 'Bạn không đủ Vàng để mua cây cơ này (còn thiếu {missing} Vàng)!',
      'en': 'Not enough Coins to buy this cue ({missing} Coins missing)!',
      'zh': '金币不足以购买此球杆（缺少 {missing} 金币）！',
      'ja': 'コインが不足しています（あと {missing} コイン必要）！',
      'ko': '골드가 부족합니다 ({missing} 골드 부족)!',
    },
    'cue_purchased_equipped': {
      'vi': 'Chúc mừng! Đã sở hữu và trang bị {name}!',
      'en': 'Congratulations! Owned and equipped {name}!',
      'zh': '恭喜！已拥有并装备 {name}！',
      'ja': 'おめでとうございます！{name} を購入・装備しました！',
      'ko': '축하합니다! {name}을(를) 획득 및 장착했습니다!',
    },
    'cue_buy_failed': {
      'vi': 'Không thể mua cây cơ này. Vui lòng kiểm tra lại số dư!',
      'en': 'Failed to purchase this cue. Please check your balance!',
      'zh': '购买球杆失败，请检查账户余额！',
      'ja': 'キューの購入に失敗しました。残高をご確認ください！',
      'ko': '큐 구매에 실패했습니다. 잔액을 확인해 주세요!',
    },
    'cue_equipped_success': {
      'vi': 'Đã trang bị {name} thành công!',
      'en': 'Successfully equipped {name}!',
      'zh': '已成功装备 {name}！',
      'ja': '{name} を装備しました！',
      'ko': '{name}을(를) 성공적으로 장착했습니다!',
    },
    'cue_upgrade_need_coins': {
      'vi': 'Bạn cần thêm {missing} Vàng để nâng cấp gậy này (tổng {total} Vàng)!',
      'en': 'Need {missing} more Coins to upgrade this cue (total {total} Coins)!',
      'zh': '升级此球杆还需 {missing} 金币（总计 {total} 金币）！',
      'ja': 'このキューの強化にはあと {missing} コイン必要です（合計 {total} コイン）！',
      'ko': '이 큐를 강화하려면 {missing} 골드가 더 필요합니다 (총 {total} 골드)!',
    },
    'cue_upgraded_success': {
      'vi': 'Chúc mừng! Nâng cấp {name} lên Cấp {level} thành công!',
      'en': 'Congratulations! Upgraded {name} to Level {level} successfully!',
      'zh': '恭喜！{name} 已成功升至 {level} 级！',
      'ja': 'おめでとうございます！{name} がレベル {level} に強化されました！',
      'ko': '축하합니다! {name}이(가) 레벨 {level}(으)로 강화되었습니다!',
    },
    'achievement_claimed_toast': {
      'vi': '🎉 Nhận thành công +{xp} EXP!',
      'en': '🎉 Successfully claimed +{xp} EXP!',
      'zh': '🎉 成功领取 +{xp} 经验值！',
      'ja': '🎉 +{xp} EXP を受け取りました！',
      'ko': '🎉 +{xp} EXP를 성공적으로 획득했습니다!',
    },
    'medals_max_toast': {
      'vi': '⚠️ Profile đã đủ tối đa 5 huy chương! Vui lòng gỡ bớt 1 huy chương trước.',
      'en': '⚠️ Profile already has 5 showcased medals! Please unpin one first.',
      'zh': '⚠️ 个人资料展示栏已满5枚勋章！请先取消佩戴1枚勋章。',
      'ja': '⚠️ プロフィールには最大5個まで勲章をピン留めできます。先に1個外してください。',
      'ko': '⚠️ 프로필에 이미 최대 5개의 훈장이 전시되어 있습니다! 먼저 하나를 해제하세요.',
    },
    'login_tab': {
      'vi': 'ĐĂNG NHẬP',
      'en': 'SIGN IN',
      'zh': '登录',
      'ja': 'ログイン',
      'ko': '로그인',
    },
    'register_tab': {
      'vi': 'ĐĂNG KÝ',
      'en': 'REGISTER',
      'zh': '注册',
      'ja': '新規登録',
      'ko': '회원가입',
    },
    'account_field': {
      'vi': 'Tài khoản / Email',
      'en': 'Username / Email',
      'zh': '账号 / 邮箱',
      'ja': 'アカウント / メール',
      'ko': '아이디 / 이메일',
    },
    'password_field': {
      'vi': 'Mật khẩu',
      'en': 'Password',
      'zh': '密码',
      'ja': 'パスワード',
      'ko': '비밀번호',
    },
    'display_name_field': {
      'vi': 'Tên hiển thị (Tối đa 15 ký tự)',
      'en': 'Display Name (Max 15 chars)',
      'zh': '昵称 (最多15字符)',
      'ja': '表示名 (最大15文字)',
      'ko': '표시 이름 (최대 15자)',
    },
    'auth_fill_all': {
      'vi': 'Vui lòng điền đầy đủ tất cả thông tin.',
      'en': 'Please fill in all fields.',
      'zh': '请完整填写所有信息。',
      'ja': 'すべての項目を入力してください。',
      'ko': '모든 정보를 빠짐없이 입력해 주세요.',
    },
    'auth_name_taken': {
      'vi': 'Tên hiển thị này đã được người chơi khác sử dụng. Vui lòng chọn tên khác!',
      'en': 'This display name is already taken. Please choose another name!',
      'zh': '该昵称已被其他玩家使用，请选择其他昵称！',
      'ja': 'この表示名は既に使用されています。別の名前を選択してください！',
      'ko': '이 닉네임은 이미 다른 플레이어가 사용 중입니다. 다른 이름을 선택하세요!',
    },
    'auth_fill_account_pass': {
      'vi': 'Vui lòng điền đầy đủ tài khoản và mật khẩu.',
      'en': 'Please enter both username/email and password.',
      'zh': '请填写账号和密码。',
      'ja': 'アカウントとパスワードを入力してください。',
      'ko': '아이디와 비밀번호를 모두 입력해 주세요.',
    },
    'guest_offline_btn': {
      'vi': 'CHƠI KHÁCH (OFFLINE)',
      'en': 'PLAY AS GUEST (OFFLINE)',
      'zh': '游客畅玩 (离线)',
      'ja': 'ゲストプレイ (オフライン)',
      'ko': '게스트 플레이 (오프라인)',
    },
    'guest_offline_sub': {
      'vi': 'Không cần mạng • Không lưu tiến trình',
      'en': 'No internet required • No cloud sync',
      'zh': '无需网络 • 不上传云端存档',
      'ja': 'ネット不要 • クラウド保存なし',
      'ko': '인터넷 불필요 • 클라우드 동기화 없음',
    },
    'feature_physics': {
      'vi': 'Vật lý bi chuẩn xác, trải nghiệm chân thực',
      'en': 'Realistic ball physics & authentic feel',
      'zh': '精准台球物理模拟，真实击球手感',
      'ja': '正確なボール物理挙動、リアルな打球感',
      'ko': '정교한 당구 물리 엔진, 생생한 손맛',
    },
    'feature_leaderboard': {
      'vi': 'Bảng xếp hạng & thành tích đồng bộ Realtime',
      'en': 'Realtime synchronized rankings & achievements',
      'zh': '排行榜与成就实时全球同步',
      'ja': 'ランキングと実績のリアルタイム同期',
      'ko': '실시간 순위표 및 도전 과제 동기화',
    },
    'feature_modes': {
      'vi': 'Đấu với Bạn bè, Bot AI và Luyện tập nâng cao',
      'en': 'Play with Friends, Smart AI & Advanced Drills',
      'zh': '好友联机、智能人机对战与进阶训练',
      'ja': 'フレンド対戦、スマートAI、高度な練習モード',
      'ko': '친구 대전, 스마트 AI 대전 및 고급 연습 모드',
    },
    'account_info_title': {
      'vi': 'THÔNG TIN TÀI KHOẢN',
      'en': 'ACCOUNT INFORMATION',
      'zh': '账户信息',
      'ja': 'アカウント情報',
      'ko': '계정 정보',
    },
    'admin_role': {
      'vi': 'QUẢN TRỊ VIÊN (ADMIN)',
      'en': 'ADMINISTRATOR',
      'zh': '管理员 (ADMIN)',
      'ja': '管理者 (ADMIN)',
      'ko': '관리자 (ADMIN)',
    },
    'member_role': {
      'vi': 'THÀNH VIÊN CHÍNH THỨC',
      'en': 'VERIFIED MEMBER',
      'zh': '正式会员',
      'ja': '正式メンバー',
      'ko': '정식 멤버',
    },
    'quick_match_1v1': {
      'vi': 'TÌM TRẬN NHANH 1V1 (AUTO MATCHMAKING)',
      'en': 'QUICK 1V1 MATCH (AUTO MATCHMAKING)',
      'zh': '1V1 快速匹配 (自动对战)',
      'ja': '1V1 クイックマッチ (自動マッチング)',
      'ko': '1V1 빠른 매칭 (자동 매칭)',
    },
    'quick_match_sub': {
      'vi': 'Tự động ghép cặp đối thủ trực tuyến qua Internet',
      'en': 'Auto-match with online opponents worldwide',
      'zh': '自动匹配在线对手进行实时对局',
      'ja': 'オンラインの対戦相手と自動マッチング',
      'ko': '온라인 상대와 실시간 자동 매칭',
    },
    'find_match': {
      'vi': 'TÌM TRẬN',
      'en': 'FIND MATCH',
      'zh': '寻找比赛',
      'ja': 'マッチ検索',
      'ko': '매칭 시작',
    },
    'create_room_1v1': {
      'vi': 'TẠO PHÒNG 1V1',
      'en': 'CREATE 1V1 ROOM',
      'zh': '创建1V1房间',
      'ja': '1V1ルーム作成',
      'ko': '1V1 방 만들기',
    },
    'pin_code_for_friends': {
      'vi': 'Mã PIN 6 số cho bạn bè',
      'en': '6-digit PIN code for friends',
      'zh': '生成6位PIN码分享给好友',
      'ja': '友達用の6桁PINコード',
      'ko': '친구 공유용 6자리 PIN 코드',
    },
    'open_room': {
      'vi': 'MỞ PHÒNG',
      'en': 'OPEN ROOM',
      'zh': '开房',
      'ja': 'ルーム開設',
      'ko': '방 생성',
    },
    'enter_room_pin_title': {
      'vi': 'NHẬP MÃ PHÒNG 1V1',
      'en': 'ENTER 1V1 ROOM PIN',
      'zh': '输入1V1房间PIN码',
      'ja': '1V1ルームPINを入力',
      'ko': '1V1 방 PIN 입력',
    },
    'pin_hint': {
      'vi': 'Mã PIN 6 số',
      'en': '6-digit PIN',
      'zh': '6位PIN码',
      'ja': '6桁のPIN',
      'ko': '6자리 PIN',
    },
    'join_room_btn': {
      'vi': 'VÀO PHÒNG',
      'en': 'JOIN ROOM',
      'zh': '加入房间',
      'ja': '入室',
      'ko': '방 입장',
    },
    'active_match_in_progress': {
      'vi': 'ĐANG CÓ TRẬN ĐẤU DỞ DANG (#{room})',
      'en': 'MATCH IN PROGRESS (#{room})',
      'zh': '存在进行中的比赛 (#{room})',
      'ja': '進行中の試合があります (#{room})',
      'ko': '진행 중인 경기가 있습니다 (#{room})',
    },
    'active_match_desc': {
      'vi': 'Đối thủ: {opp} (Cấp {lvl}) • Bàn đấu vẫn đang diễn ra theo thời gian thực!',
      'en': 'Opponent: {opp} (Lv.{lvl}) • Match is still active in real-time!',
      'zh': '对手: {opp} (等级 {lvl}) • 比赛仍在实时进行中！',
      'ja': '対戦相手: {opp} (Lv.{lvl}) • 試合はリアルタイムで進行中です！',
      'ko': '상대: {opp} (Lv.{lvl}) • 경기가 실시간으로 계속 진행 중입니다!',
    },
    'resume_match_now': {
      'vi': 'QUAY LẠI TRẬN ĐẤU NGAY',
      'en': 'RESUME MATCH NOW',
      'zh': '立即返回对局',
      'ja': '今すぐ対局に戻る',
      'ko': '즉시 경기로 복귀',
    },
    'forfeit_match': {
      'vi': 'Hủy Trận',
      'en': 'Forfeit',
      'zh': '认输弃赛',
      'ja': '降伏・棄権',
      'ko': '기권',
    },
    'searching_worthy_opponent': {
      'vi': 'ĐANG TÌM ĐỐI THỦ XỨNG TẦM...',
      'en': 'SEARCHING FOR A WORTHY OPPONENT...',
      'zh': '正在寻找势均力敌的对手...',
      'ja': '好敵手を検索中...',
      'ko': '알맞은 상대를 찾는 중...',
    },
    'cant_start_hosting': {
      'vi': 'Không thể mở phòng. Hãy đảm bảo máy đã bật WiFi hoặc phát Hotspot!',
      'en': 'Unable to host. Ensure Wi-Fi is on or Hotspot is active!',
      'zh': '无法创建房间。请确保已开启局域网Wi-Fi或便携热点！',
      'ja': 'ルームを開けません。Wi-Fiまたはテザリングが有効かご確認ください！',
      'ko': '방을 열 수 없습니다. 와이파이나 핫스팟이 켜져 있는지 확인하세요!',
    },
    'enter_host_ip': {
      'vi': 'Vui lòng nhập địa chỉ IP của máy tạo phòng!',
      'en': 'Please enter the Host device IP address!',
      'zh': '请输入房主设备的IP地址！',
      'ja': 'ホスト端末のIPアドレスを入力してください！',
      'ko': '호스트 기기의 IP 주소를 입력해 주세요!',
    },
    'cant_connect_ip': {
      'vi': 'Không thể kết nối tới {ip}!\n• Đảm bảo 2 máy chung 1 WiFi hoặc 1 máy bật Hotspot cho máy kia bắt.',
      'en': 'Cannot connect to {ip}!\n• Ensure both devices share the same Wi-Fi or one hosts a Hotspot.',
      'zh': '无法连接至 {ip}！\n• 请确保两台设备处于同一Wi-Fi下或一台开启热点。',
      'ja': '{ip} に接続できません！\n• 2台が同じWi-Fiに接続されているか、片方のテザリングに接続してください。',
      'ko': '{ip}에 연결할 수 없습니다!\n• 두 기기가 같은 와이파이에 연결되었거나 한 기기가 핫스팟을 켰는지 확인하세요.',
    },
    'change_port': {
      'vi': 'Đổi Cổng',
      'en': 'Change Port',
      'zh': '更换端口',
      'ja': 'ポート変更',
      'ko': '포트 변경',
    },
    'server_address_hint': {
      'vi': 'Nhập địa chỉ máy chủ (ws:// hoặc wss://)',
      'en': 'Enter server URL (ws:// or wss://)',
      'zh': '输入服务器地址 (ws:// 或 wss://)',
      'ja': 'サーバーURLを入力 (ws:// または wss://)',
      'ko': '서버 주소 입력 (ws:// 또는 wss://)',
    },
    'disconnect_btn': {
      'vi': 'Ngắt',
      'en': 'Disconnect',
      'zh': '断开',
      'ja': '切断',
      'ko': '연결 해제',
    },
    'connect_btn': {
      'vi': 'Kết Nối',
      'en': 'Connect',
      'zh': '连接',
      'ja': '接続',
      'ko': '연결',
    },
    'quick_presets': {
      'vi': 'Chọn nhanh:',
      'en': 'Quick Presets:',
      'zh': '快速选择:',
      'ja': 'クイック選択:',
      'ko': '빠른 선택:',
    },
    'server_connected_ready': {
      'vi': 'Cổng Máy Chủ (Đã kết nối sẵn): {url}',
      'en': 'Server Gateway (Connected): {url}',
      'zh': '服务器网关 (已连接): {url}',
      'ja': 'サーバーゲートウェイ (接続済): {url}',
      'ko': '서버 게이트웨이 (연결 완료): {url}',
    },
    'server_connecting': {
      'vi': 'Đang kết nối cổng máy chủ...',
      'en': 'Connecting to server gateway...',
      'zh': '正在连接服务器...',
      'ja': 'サーバーに接続中...',
      'ko': '서버에 연결 중...',
    },
    'server_not_connected': {
      'vi': 'Chưa kết nối máy chủ',
      'en': 'Server not connected',
      'zh': '未连接服务器',
      'ja': 'サーバー未接続',
      'ko': '서버 연결 안 됨',
    },
    'cant_connect_ws_error': {
      'vi': 'Không thể kết nối đến máy chủ WebSocket!\n• Nếu chạy trên Windows: Chọn "Máy này (127.0.0.1)"\n• Nếu chạy trên Giả lập Android: Chọn "Giả lập Android (10.0.2.2)"\n• Nếu chạy trên Điện thoại qua Wi-Fi: Chọn "Wi-Fi LAN (192.168.1.22)"\n• Server hiện đã được khởi động sẵn trên cổng 8080.',
      'en': 'Unable to connect to WebSocket server!\n• On Windows: Select "This PC (127.0.0.1)"\n• On Android Emulator: Select "Android Emulator (10.0.2.2)"\n• On Physical Phone via Wi-Fi: Select "Wi-Fi LAN (192.168.1.22)"\n• Server is listening on port 8080.',
      'zh': '无法连接到 WebSocket 服务器！\n• Windows 平台: 请选 "本机 (127.0.0.1)"\n• 安卓模拟器: 请选 "安卓模拟器 (10.0.2.2)"\n• 真机 Wi-Fi: 请选 "Wi-Fi LAN (192.168.1.22)"\n• 服务器已启动于端口 8080。',
      'ja': 'WebSocketサーバーに接続できません！\n• Windows実行時:「このPC (127.0.0.1)」を選択\n• Androidエミュレータ:「Androidエミュレータ (10.0.2.2)」を選択\n• 実機Wi-Fi対戦時:「Wi-Fi LAN (192.168.1.22)」を選択\n• サーバーはポート8080で待機しています。',
      'ko': 'WebSocket 서버에 연결할 수 없습니다!\n• Windows 실행 시: "이 PC (127.0.0.1)" 선택\n• 안드로이드 에뮬레이터: "안드로이드 에뮬레이터 (10.0.2.2)" 선택\n• 실물 폰 와이파이: "Wi-Fi LAN (192.168.1.22)" 선택\n• 서버는 포트 8080에서 실행 중입니다.',
    },
    'switch_language': {
      'vi': 'Đổi ngôn ngữ',
      'en': 'Change language',
      'zh': '切换语言',
      'ja': '言語切替',
      'ko': '언어 변경',
    },
    'enter_table': {
      'vi': 'VÀO BÀN CHƠI',
      'en': 'PLAY NOW',
      'zh': '进入球台',
      'ja': 'ゲーム開始',
      'ko': '게임 시작',
    },
    'play_guest_no_save': {
      'vi': 'CHƠI KHÁCH OFFLINE (KHÔNG LƯU)',
      'en': 'PLAY AS GUEST (NO CLOUD SAVE)',
      'zh': '游客畅玩 (不存进度)',
      'ja': 'ゲストプレイ (セーブなし)',
      'ko': '게스트 플레이 (저장 안 됨)',
    },
    'create_account_btn': {
      'vi': 'TẠO TÀI KHOẢN MỚI',
      'en': 'CREATE NEW ACCOUNT',
      'zh': '创建新账号',
      'ja': '新規アカウント作成',
      'ko': '새 계정 생성',
    },
    'password_min_chars': {
      'vi': 'Mật khẩu (tối thiểu 6 ký tự)',
      'en': 'Password (min 6 chars)',
      'zh': '密码 (至少6个字符)',
      'ja': 'パスワード (6文字以上)',
      'ko': '비밀번호 (최소 6자)',
    },
    'please_login_sync': {
      'vi': 'Vui lòng đăng nhập để đồng bộ thành tích',
      'en': 'Please sign in to sync your progress',
      'zh': '请登录以同步您的游戏进度',
      'ja': '進行状況を同期するにはログインしてください',
      'ko': '진행 상황을 동기화하려면 로그인하세요',
    },
    'wins': {
      'vi': 'Chiến Thắng',
      'en': 'Wins',
      'zh': '胜场',
      'ja': '勝利数',
      'ko': '승리',
    },
    'logout': {
      'vi': 'Đăng Xuất',
      'en': 'Logout',
      'zh': '退出登录',
      'ja': 'ログアウト',
      'ko': '로그아웃',
    },
    'guest_account_title': {
      'vi': 'TÀI KHOẢN KHÁCH',
      'en': 'GUEST ACCOUNT',
      'zh': '游客账户',
      'ja': 'ゲストアカウント',
      'ko': '게스트 계정',
    },
    'guest_account_desc': {
      'vi': 'Chưa liên kết tài khoản • Dữ liệu lưu trên máy này',
      'en': 'Not linked to cloud • Data saved locally on this device',
      'zh': '未关联账号 • 数据仅保存在此设备',
      'ja': '未連携アカウント • データはこの端末に保存',
      'ko': '계정 미연동 • 데이터는 이 기기에만 저장됨',
    },
    'login_save_cloud_btn': {
      'vi': 'ĐĂNG NHẬP / LƯU TIẾN TRÌNH CLOUD',
      'en': 'SIGN IN / SAVE TO CLOUD',
      'zh': '登录 / 云端同步进度',
      'ja': 'ログイン / クラウド保存',
      'ko': '로그인 / 클라우드 진행 저장',
    },
    'leave_guest_mode_btn': {
      'vi': 'Rời khỏi chế độ khách',
      'en': 'Exit Guest Mode',
      'zh': '退出游客模式',
      'ja': 'ゲストモードを終了',
      'ko': '게스트 모드 종료',
    },
    'firebase_account_title': {
      'vi': 'TÀI KHOẢN FIREBASE',
      'en': 'FIREBASE ACCOUNT',
      'zh': 'FIREBASE 账户',
      'ja': 'FIREBASE アカウント',
      'ko': 'FIREBASE 계정',
    },
    'login_now_btn': {
      'vi': 'ĐĂNG NHẬP NGAY',
      'en': 'SIGN IN NOW',
      'zh': '立即登录',
      'ja': '今すぐログイン',
      'ko': '지금 로그인',
    },
    'login_success_welcome': {
      'vi': 'Đăng nhập thành công! Chào mừng {name}.',
      'en': 'Login successful! Welcome {name}.',
      'zh': '登录成功！欢迎 {name}。',
      'ja': 'ログインに成功しました！ようこそ {name}。',
      'ko': '로그인 성공! 환영합니다 {name}.',
    },
    'register_success': {
      'vi': 'Tạo tài khoản thành công!',
      'en': 'Account created successfully!',
      'zh': '账号创建成功！',
      'ja': 'アカウントを作成しました！',
      'ko': '계정이 성공적으로 생성되었습니다!',
    },
    'server_host_mode': {
      'vi': 'TẠO PHÒNG (HOST)',
      'en': 'CREATE ROOM (HOST)',
      'zh': '创建房间 (房主)',
      'ja': 'ルーム作成 (ホスト)',
      'ko': '방 만들기 (호스트)',
    },
    'server_join_mode': {
      'vi': 'VÀO PHÒNG (JOIN)',
      'en': 'JOIN ROOM (CLIENT)',
      'zh': '加入房间 (访客)',
      'ja': 'ルーム参加 (ゲスト)',
      'ko': '방 참가 (클라이언트)',
    },
    'cancel_search': {
      'vi': 'HỦY TÌM TRẬN',
      'en': 'CANCEL SEARCH',
      'zh': '取消匹配',
      'ja': '検索をキャンセル',
      'ko': '매칭 취소',
    },
    'room_ready_title': {
      'vi': 'PHÒNG ĐÃ SẴN SÀNG!',
      'en': 'ROOM IS READY!',
      'zh': '房间已就绪！',
      'ja': 'ルームの準備完了！',
      'ko': '방이 준비되었습니다!',
    },
    'share_pin_with_opponent': {
      'vi': 'Chia sẻ mã PIN dưới đây cho đối thủ để cùng vào bàn đấu:',
      'en': 'Share the PIN below with your opponent to enter the table:',
      'zh': '将以下PIN码分享给对手以加入球台：',
      'ja': '対戦相手に以下のPINを共有して入室してください：',
      'ko': '상대방에게 아래 PIN 코드를 공유하여 입장하세요:',
    },
    'waiting_for_opponent_pin': {
      'vi': 'Đang chờ đối thủ nhập mã...',
      'en': 'Waiting for opponent to enter PIN...',
      'zh': '正在等待对手输入PIN码...',
      'ja': '相手のPIN入力を待っています...',
      'ko': '상대방의 PIN 입력을 기다리는 중...',
    },
    'cancel_and_leave_room': {
      'vi': 'Hủy & Rời Phòng',
      'en': 'Cancel & Leave Room',
      'zh': '解散并离开房间',
      'ja': 'キャンセルして退室',
      'ko': '취소 및 방 나가기',
    },
    'fine_tune': {
      'vi': 'Vi chỉnh',
      'en': 'Fine Tune',
      'zh': '微调',
      'ja': '微調整',
      'ko': '미세 조정',
    },
    'fine_tune_left': {
      'vi': 'Nhích trái 1mm',
      'en': 'Nudge left 1mm',
      'zh': '向左微调 1mm',
      'ja': '左に1mm微調整',
      'ko': '왼쪽으로 1mm 미세 조정',
    },
    'fine_tune_right': {
      'vi': 'Nhích phải 1mm',
      'en': 'Nudge right 1mm',
      'zh': '向右微调 1mm',
      'ja': '右に1mm微調整',
      'ko': '오른쪽으로 1mm 미세 조정',
    },
    'power_locked_toast': {
      'vi': '🎯 Đã khóa lực: Thả tay không bắn (Chạm lại nút tròn để bắn hoặc mở khóa)',
      'en': '🎯 Power locked: Release won\'t shoot (Tap round button to shoot or unlock)',
      'zh': '🎯 力度已锁定：松手不击球 (轻按圆钮发力或解锁)',
      'ja': '🎯 パワーロック中: 離しても打ちません (丸ボタンでショットまたは解除)',
      'ko': '🎯 파워 잠금: 손을 떼도 발사되지 않음 (원형 버튼으로 발사 hoặc 해제)',
    },
    'power_unlocked_toast': {
      'vi': '⚡ Đã mở chế độ: Kéo cơ & Thả tay bắn ngay',
      'en': '⚡ Quick release mode: Pull cue & release to shoot',
      'zh': '⚡ 快速击球模式：拉杆并松手立即击球',
      'ja': '⚡ クイックショット: キューを引いて離すと即座に発射',
      'ko': '⚡ 퀵 릴리즈 모드: 큐를 당기고 놓으면 즉시 발사',
    },
    '5_languages_subtitle': {
      'vi': '5 Ngôn ngữ được hỗ trợ',
      'en': '5 Languages Supported',
      'zh': '支持 5 种语言',
      'ja': '5つの言語に対応',
      'ko': '5개 언어 지원',
    },
    'tournament_reset_toast': {
      'vi': '🔄 Đã làm mới giải đấu về Vòng 1!',
      'en': '🔄 Tournament reset to Round 1!',
      'zh': '🔄 锦标赛已重置为第1轮!',
      'ja': '🔄 トーナメントを第1ラウンドにリセットしました!',
      'ko': '🔄 토너먼트를 1라운드로 초기화했습니다!',
    },
    'host': {
      'vi': 'Chủ phòng',
      'en': 'Host',
      'zh': '房主',
      'ja': 'ホスト',
      'ko': '호스트',
    },
    'stay_in_match': {
      'vi': 'Ở lại trận đấu',
      'en': 'Stay in Match',
      'zh': '留在比赛中',
      'ja': '試合を続ける',
      'ko': '경기에 남기',
    },
    'confirm_forfeit_exit': {
      'vi': 'Xác nhận rời bàn & Xử thua',
      'en': 'Confirm Forfeit & Exit',
      'zh': '确认认输并退出',
      'ja': '降伏して退出する',
      'ko': '기권 확인 및 퇴장',
    },
    'rank': {
      'vi': 'Hạng',
      'en': 'Rank',
      'zh': '段位',
      'ja': 'ランク',
      'ko': '랭크',
    },
  };
}

/// Extension tiện lợi cho String để dịch nhanh: 'key'.tr
extension StringTranslationExtension on String {
  String get tr => LanguageService.instance.t(this);
}
