// BẢN ĐỊA HÓA TOÀN BỘ NỘI DUNG GẬY CƠ, THÀNH TỰU, HUY CHƯƠNG VÀ ĐIỀU KHIỂN BIDA
// Hỗ trợ 5 ngôn ngữ: Tiếng Việt (vi), English (en), 中文 (zh), 日本語 (ja), 한국어 (ko)

import 'dart:ui';

class GameContentLocalization {
  // =========================================================================
  // 1. TÊN GẬY CƠ (CUE NAMES)
  // =========================================================================
  static const Map<String, Map<String, String>> cueNames = {
    'standard_cue': {
      'vi': 'Gậy Gỗ Tân Thủ',
      'en': 'Standard Maple Cue',
      'zh': '新手枫木杆',
      'ja': '初心者メープルキュー',
      'ko': '초보자 메이플 큐',
    },
    'titan_striker': {
      'vi': 'Cơ Titan Thép',
      'en': 'Titan Steel Striker',
      'zh': '泰坦钢铁杆',
      'ja': 'タイタンストライカー',
      'ko': '타이탄 스틸 스트라이커',
    },
    'frostbite': {
      'vi': 'Cơ Băng Phong',
      'en': 'Frostbite Glacier',
      'zh': '寒冰霜冻杆',
      'ja': 'フロストバイト',
      'ko': '프로스트바이트 큐',
    },
    'golden_bull': {
      'vi': 'Cơ Kim Ngưu',
      'en': 'Golden Bull 24K',
      'zh': '金牛神殿杆',
      'ja': 'ゴールデンブル',
      'ko': '황금 황소자리 큐',
    },
    'cyber_neo': {
      'vi': 'Cơ Cyberpunk Neo',
      'en': 'Cyberpunk Neo 2077',
      'zh': '赛博新纪元 2077',
      'ja': 'サイバーネオ 2077',
      'ko': '사이버 네오 2077',
    },
    'phoenix_flame': {
      'vi': 'Cơ Hỏa Phụng',
      'en': 'Phoenix Flame Cue',
      'zh': '烈焰凤凰杆',
      'ja': '不死鳥の焔',
      'ko': '피닉스 플레임',
    },
    'dragon_god': {
      'vi': 'Cơ Đế Vương Rồng Vàng',
      'en': 'Imperial Golden Dragon',
      'zh': '至尊黄金神龙',
      'ja': '帝王金龍キュー',
      'ko': '황금 용 황제 큐',
    },
  };

  // =========================================================================
  // 2. MÔ TẢ GẬY CƠ (CUE DESCRIPTIONS)
  // =========================================================================
  static const Map<String, Map<String, String>> cueDescriptions = {
    'standard_cue': {
      'vi': 'Cây gậy khởi đầu bằng gỗ phong tự nhiên, đầm tay và dễ làm quen.',
      'en': 'Natural maple starter cue, solid grip and beginner-friendly.',
      'zh': '天然枫木新手入门球杆，手感扎实且容易上手。',
      'ja': '初心者向けの天然メープル製キュー。安定感があり扱いやすい。',
      'ko': '초보자용 천연 메이플 큐. 그립감이 안정적이며 다루기 쉽습니다.',
    },
    'titan_striker': {
      'vi': 'Lõi kim loại đúc nguyên khối chịu lực cao, gia cố đầu ngọn siêu cứng.',
      'en': 'Solid cast metal core with hardened tip for powerful strikes.',
      'zh': '高强度铸造一体金属核心，超硬杆头加固。',
      'ja': '高耐久の一体成型金属コアと超硬チップ。',
      'ko': '강력한 타구를 위한 견고한 일체형 금속 코어와 강화 팁.',
    },
    'frostbite': {
      'vi': 'Chế tác từ tinh thể băng vĩnh cửu Bắc Cực, tỏa ra hàn khí xanh lạnh ngắt.',
      'en': 'Crafted from Arctic permafrost crystals with chilled cyan aura.',
      'zh': '采用北极永冻冰晶打造，散发冰蓝冷冽寒芒。',
      'ja': '北極の永久凍土の氷晶から作られた冷気のキュー。',
      'ko': '북극의 영구 동토 결정으로 제작된 냉기 어린 큐.',
    },
    'golden_bull': {
      'vi': 'Dát vàng 24K nguyên chất chạm khắc biểu tượng cung hoàng đạo Kim Ngưu.',
      'en': '24K gold plated engraved with the celestial Taurus zodiac emblem.',
      'zh': '纯正24K镀金雕刻金牛座黄道星象图腾。',
      'ja': '純金24Kメッキと牡牛座の紋章が刻まれたキュー。',
      'ko': '순금 24K 도금과 황소자리 성좌 문양이 조각된 큐.',
    },
    'cyber_neo': {
      'vi': 'Công nghệ tương lai năm 2077 với vi mạch bán dẫn và đèn LED tím neon.',
      'en': 'Futuristic 2077 tech with semiconductor chips and violet neon glow.',
      'zh': '2077未来科技结合半导体微芯片与紫光霓虹。',
      'ja': '半導体回路とネオンパープルの2077年未来テクノロジー。',
      'ko': '반도체 회로와 퍼플 네온의 2077년 미래 기술.',
    },
    'phoenix_flame': {
      'vi': 'Được rèn từ tro tàn của Phượng Hoàng Lửa, thân gậy bốc cháy ngọn lửa bất tử.',
      'en': 'Forged from phoenix ashes, radiating undying mythical blaze.',
      'zh': '浴火重生的火凤凰遗灰淬炼而成，附带不灭神焰。',
      'ja': '不死鳥の灰から鍛えられた不滅の炎をまとうキュー。',
      'ko': '불사조의 재에서 벼려낸 불멸의 화염을 두른 큐.',
    },
    'dragon_god': {
      'vi': 'Báu vật hoàng gia ngàn năm tuổi, mang sức mạnh thần long chấn động thiên địa.',
      'en': 'Millennium royal treasure bearing dragon spirit of heaven and earth.',
      'zh': '千年皇室御用圣物，蕴含撼天动地的神龙威能。',
      'ja': '千年の皇室の秘宝、天地を揺るがす神龍の力。',
      'ko': '천년 황실의 보물, 천지를 뒤흔드는 황금 신룡의 힘.',
    },
  };

  // =========================================================================
  // 3. KỸ NĂNG NỘI TẠI GẬY CƠ (CUE PERKS)
  // =========================================================================
  static const Map<String, Map<String, String>> cuePerks = {
    'standard_cue': {
      'vi': 'Cân bằng cơ bản, không có nội tại phụ.',
      'en': 'Standard balance, no special perks.',
      'zh': '基础平衡，无特殊被动。',
      'ja': '基本バランス、特殊能力なし。',
      'ko': '기본 밸런스, 특수 효과 없음.',
    },
    'titan_striker': {
      'vi': 'Heavy Break: Tăng thêm 15% xung lực khi đánh vỡ cụm bi khai cuộc.',
      'en': 'Heavy Break: +15% impact force on break shot.',
      'zh': '强力开球: 开球冲杆冲击力提升15%。',
      'ja': 'ヘビーブレイク: ブレイクショットの衝撃力+15%。',
      'ko': '헤비 브레이크: 브레이크 샷 충격력 +15%.',
    },
    'frostbite': {
      'vi': 'Ice Aim: Tia ngắm cực kỳ ổn định, làm chậm nhịp rung khi căn lực.',
      'en': 'Ice Aim: Ultra-stable aim guide, reduced jitter while aiming.',
      'zh': '冰霜瞄准: 瞄准导线极度稳定，蓄力时大幅防抖。',
      'ja': 'アイスエイム: 照準ガイドが極めて安定、エイムのブレを軽減。',
      'ko': '아이스 에임: 조준선이 흔들림 없이 극도로 안정됩니다.',
    },
    'golden_bull': {
      'vi': 'Jackpot Touch: Nhận thêm 10% Vàng thưởng sau mỗi trận thắng.',
      'en': 'Jackpot Touch: +10% bonus Coins on match victory.',
      'zh': '财运眷顾: 获胜时额外获得10%金币奖励。',
      'ja': 'ジャックポット: 勝利時に獲得コイン+10%。',
      'ko': '잭팟 터치: 경기 승리 시 추가 골드 +10%.',
    },
    'cyber_neo': {
      'vi': 'Laser Line: Kéo dài tia ngắm thêm 20% và hiển thị đường rẽ bi rực sáng.',
      'en': 'Laser Line: +20% Aim guideline length with glowing reflection lines.',
      'zh': '激光瞄准: 瞄准线延长20%并高亮反弹折射轨迹。',
      'ja': 'レーザーライン: 照準ガイドが20%延長、反射ラインが鮮明に表示。',
      'ko': '레이저 라인: 조준선 20% 연장 및 반사 궤적 발광 표시.',
    },
    'phoenix_flame': {
      'vi': 'Inferno Spin: Tăng vọt 25% độ giật trô bóng lùi và cu-lê tiến tới.',
      'en': 'Inferno Spin: +25% Topspin follow and extreme draw surge.',
      'zh': '炼狱旋转: 强力低杆拉杆与高杆推杆效能暴增25%。',
      'ja': 'インフェルノスピン: トップスピンとドローの威力が25%上昇。',
      'ko': '인페르노 스핀: 밀어치기와 끌어치기 회전 효과가 25% 급증.',
    },
    'dragon_god': {
      'vi': 'Dragon Heart: Hoàn lại 50% tiền cược nếu thua ván; Vệt lửa rồng hộ mệnh.',
      'en': 'Dragon Heart: Refund 50% wager on defeat; Guardian dragon fire trail.',
      'zh': '龙之心魄: 惜败时退还50%金币筹码; 神龙守护焰痕。',
      'ja': 'ドラゴンハート: 敗北時に参加費の50%を返還、守護龍の軌跡。',
      'ko': '드래곤 하트: 패배 시 참가비 50% 환급, 수호룡 화염 궤적.',
    },
  };

  // =========================================================================
  // 4. PHẨM CẤP GẬY CƠ (CUE RARITY)
  // =========================================================================
  static const Map<String, Map<String, String>> cueRarities = {
    'common': {
      'vi': 'Thường',
      'en': 'Common',
      'zh': '普通',
      'ja': 'ノーマル',
      'ko': '일반',
    },
    'rare': {
      'vi': 'Hiếm',
      'en': 'Rare',
      'zh': '稀有',
      'ja': 'レア',
      'ko': '희귀',
    },
    'epic': {
      'vi': 'Sử Thi',
      'en': 'Epic',
      'zh': '史诗',
      'ja': 'エピック',
      'ko': '에픽',
    },
    'legendary': {
      'vi': 'Huyền Thoại',
      'en': 'Legendary',
      'zh': '传说',
      'ja': 'レジェンド',
      'ko': '전설',
    },
  };

  // =========================================================================
  // 5. TIÊU ĐỀ THÀNH TỰU (ACHIEVEMENT TITLES)
  // =========================================================================
  static const Map<String, Map<String, String>> achievementTitles = {
    // 1. DỄ (EASY)
    'first_win': {'vi': 'Phát Cơ Đầu Tiên', 'en': 'First Strike', 'zh': '初战告捷', 'ja': '初勝利の一撃', 'ko': '첫 번째 승리'},
    'cue_enthusiast': {'vi': 'Tín Đồ Bida', 'en': 'Cue Enthusiast', 'zh': '球杆爱好者', 'ja': 'キュー愛好家', 'ko': '큐 마니아'},
    'spin_trick': {'vi': 'Biến Hóa Điểm Chạm', 'en': 'Spin Mastermind', 'zh': '变幻击球点', 'ja': 'スピンの魔術師', 'ko': '스핀 마스터'},
    'first_wealth': {'vi': 'Đồng Tiền Đầu Tiên', 'en': 'First Fortune', 'zh': '第一桶金', 'ja': '最初の財産', 'ko': '첫 번째 재산'},
    'reach_level_3': {'vi': 'Tân Binh Triển Vọng', 'en': 'Promising Rookie', 'zh': '潜力新秀', 'ja': '有望なルーキー', 'ko': '유망한 신예'},
    'reach_level_5': {'vi': 'Nhập Môn Xuất Sắc', 'en': 'Outstanding Novice', 'zh': '出色入门', 'ja': '卓越の入門者', 'ko': '뛰어난 입문자'},
    'cue_upgrade_first': {'vi': 'Khởi Đầu Rèn Giũa', 'en': 'First Refinement', 'zh': '初度锻造', 'ja': '最初の強化', 'ko': '첫 번째 단련'},
    'cue_upgrade_level_3': {'vi': 'Tôi Luyện Thép Tinh', 'en': 'Tempered Steel', 'zh': '百炼精钢', 'ja': '研ぎ澄まされた鋼', 'ko': '담금질된 강철'},
    'bot_stage_1': {'vi': 'Thử Thách Khởi Khởi', 'en': 'First AI Trial', 'zh': '初试人机', 'ja': '最初のBOT試練', 'ko': '첫 봇 시련'},
    'bot_stage_2': {'vi': 'Đấu Sĩ Tự Tin', 'en': 'Confident Striker', 'zh': '自信斗士', 'ja': '自信に満ちた撃ち手', 'ko': '자신감 넘치는 전사'},
    'tournament_entry': {'vi': 'Chào Sân Tournament', 'en': 'Tournament Debut', 'zh': '亮相巡回赛', 'ja': 'トーナメント開幕', 'ko': '토너먼트 첫 출전'},
    'trickshot_first': {'vi': 'Phát Cơ Nghệ Thuật', 'en': 'Artistic Strike', 'zh': '艺术击球', 'ja': '芸術的な一撃', 'ko': '예술적인 일격'},
    'first_diamond': {'vi': 'Thợ Săn Bảo Thạch', 'en': 'Gem Seeker', 'zh': '宝石猎手', 'ja': '宝石ハンター', 'ko': '보석 사냥꾼'},
    'change_profile_cue': {'vi': 'Phong Cách Cơ Thủ', 'en': 'Cueist Style', 'zh': '球手个性', 'ja': 'キュースタイル', 'ko': '큐이스트 스타일'},
    'explore_daily_puzzle': {'vi': 'Khám Phá Thế Bi', 'en': 'Puzzle Explorer', 'zh': '探索残局', 'ja': 'パズル探索', 'ko': '퍼즐 탐험'},

    // 2. TRUNG BÌNH (MEDIUM)
    'combo_hunter': {'vi': 'Thợ Săn Combo', 'en': 'Combo Hunter', 'zh': '连环捕手', 'ja': 'コンボハンター', 'ko': '콤보 헌터'},
    'daily_puzzle_clear': {'vi': 'Bậc Thầy Giải Thế', 'en': 'Puzzle Solver', 'zh': '残局破解大师', 'ja': 'パズルマスター', 'ko': '퍼즐 해결사'},
    'win_streak_3': {'vi': 'Tam Liên Thắng', 'en': 'Triple Triumph', 'zh': '三连绝胜', 'ja': '3連勝の栄光', 'ko': '3연승의 주역'},
    'win_10': {'vi': 'Thập Trận Thăng Hoa', 'en': 'Tenfold Victory', 'zh': '十战十捷', 'ja': '10勝の輝き', 'ko': '10승의 환희'},
    'coins_10k': {'vi': 'Phú Hào Tập Sự', 'en': 'Apprentice Tycoon', 'zh': '见习富豪', 'ja': '見習い富豪', 'ko': '수습 갑부'},
    'coins_20k': {'vi': 'Đại Lợi Kim Ngân', 'en': 'Golden Prosperity', 'zh': '金玉满堂', 'ja': '黄金の繁栄', 'ko': '황금의 번영'},
    'reach_level_8': {'vi': 'Chiến Binh Dày Dạn', 'en': 'Seasoned Fighter', 'zh': '历战勇士', 'ja': '歴戦の戦士', 'ko': '노련한 전사'},
    'cue_upgrade_level_5': {'vi': 'Thần Khí Xuất Thế', 'en': 'Artifact Awakening', 'zh': '神器觉醒', 'ja': '神器覚醒', 'ko': '신기 각성'},
    'bot_stage_3': {'vi': 'Vượt Khó Vươn Lên', 'en': 'Overcoming Odds', 'zh': '乘风破浪', 'ja': '困難突破', 'ko': '난관 극복'},
    'bot_stage_4': {'vi': 'Tay Cơ Bản Lĩnh', 'en': 'Courageous Cueist', 'zh': '沉着球手', 'ja': '気迫のプレイヤー', 'ko': '배짱 있는 당구인'},
    'bot_stage_5': {'vi': 'Bứt Phá Giới Hạn', 'en': 'Breaking Limits', 'zh': '突破极限', 'ja': '限界突破', 'ko': '한계 돌파'},
    'tournament_bracket_2': {'vi': 'Vé Vào Tứ Kết', 'en': 'Quarter-Final Ticket', 'zh': '挺进前八', 'ja': '準々決勝への切符', 'ko': '8강 진출권'},
    'tournament_bracket_3': {'vi': 'Anh Hùng Tứ Cường', 'en': 'Semi-Final Hero', 'zh': '四强英豪', 'ja': 'ベスト4の英雄', 'ko': '4강의 영웅'},
    'trickshot_master_5': {'vi': 'Bàn Tay Phù Thủy', 'en': 'Magic Touch', 'zh': '巧夺天工', 'ja': '魔法の手腕', 'ko': '마법의 손길'},
    'medals_showcase_3': {'vi': 'Vinh Danh Tam Bảo', 'en': 'Trinity of Medals', 'zh': '三光徽耀', 'ja': '三光の栄誉', 'ko': '삼색의 영예'},

    // 3. KHÓ (HARD)
    'cue_collector': {'vi': 'Nhà Sưu Tập Cơ Thủ', 'en': 'Arsenal Collector', 'zh': '球杆收藏家', 'ja': 'キューコレクター', 'ko': '큐 수집가'},
    'rich_player': {'vi': 'Đại Gia Phố Bida', 'en': 'Billiards Tycoon', 'zh': '台球街大亨', 'ja': 'ビリヤード大富豪', 'ko': '당구장 재벌'},
    'multiplayer_veteran': {'vi': 'Sát Thủ Đối Kháng', 'en': 'Multiplayer Veteran', 'zh': '联机老手', 'ja': 'マルチプレイヤーの覇者', 'ko': '멀티플레이 베테랑'},
    'win_25': {'vi': 'Cao Thủ Lão Luyện', 'en': 'Master Cueist', 'zh': '资深名宿', 'ja': '熟練の名手', 'ko': '노련한 명인'},
    'win_50': {'vi': 'Chiến Tướng Bàn Xanh', 'en': 'Green Felt Warlord', 'zh': '绿台战将', 'ja': 'グリーンフェルトの闘将', 'ko': '녹색 당구대의 맹장'},
    'reach_level_15': {'vi': 'Bậc Thầy Bàn Bida', 'en': 'Pool Master', 'zh': '台球宗师', 'ja': 'プールマスター', 'ko': '포켓볼 마스터'},
    'reach_level_20': {'vi': 'Danh Chấn Giang Hồ', 'en': 'World-Renowned', 'zh': '威名远播', 'ja': '名声轟く覇者', 'ko': '강호를 뒤흔든 명성'},
    'coins_50k': {'vi': 'Thương Gia Phố Cổ', 'en': 'Guild Merchant', 'zh': '富贾名门', 'ja': '豪商の風格', 'ko': '거상 가문'},
    'coins_75k': {'vi': 'Kim Khố Đầy Ắp', 'en': 'Treasury Overflow', 'zh': '金库盈满', 'ja': '溢れる金庫', 'ko': '넘쳐나는 금고'},
    'cue_upgrade_level_7': {'vi': 'Đỉnh Cao Chế Tác', 'en': 'Mastercraft', 'zh': '精工极境', 'ja': '名工の極致', 'ko': '명장 제작의 극치'},
    'cue_upgrade_level_8': {'vi': 'Tuyệt Sắc Thần Cơ', 'en': 'Peerless Weapon', 'zh': '绝品灵器', 'ja': '比類なき霊杖', 'ko': '무쌍의 신기'},
    'bot_stage_6': {'vi': 'Phá Vỡ Chiến Thuật', 'en': 'Tactic Breaker', 'zh': '破阵惊雷', 'ja': '戦術ブレイカー', 'ko': '전술 파쇄자'},
    'tournament_bracket_4': {'vi': 'Bước Vào Chung Kết', 'en': 'Grand Finalist', 'zh': '终局决战', 'ja': '決勝進出', 'ko': '결승전 진출'},
    'trickshot_master_10': {'vi': 'Bách Nghệ Kỳ Tài', 'en': 'Master of Ten', 'zh': '十项全能', 'ja': '百芸の奇才', 'ko': '백예의 기재'},
    'medals_showcase_5': {'vi': 'Phòng Danh Dự Tỏa Sáng', 'en': 'Hall of 5 Stars', 'zh': '五星光辉', 'ja': '五つ星の名誉', 'ko': '5성 명예의 전당'},

    // 4. SIÊU KHÓ (EXPERT)
    'bot_campaign_clear': {'vi': 'Khuất Phục Cao Thủ Bot', 'en': 'AI Conqueror', 'zh': '智破人机试炼', 'ja': 'BOT完全制覇', 'ko': '봇 군단 정복자'},
    'cue_level_max': {'vi': 'Tuyệt Đỉnh Thần Binh', 'en': 'Master Weapon Max', 'zh': '绝世神兵 MAX', 'ja': '究極の神話キュー', 'ko': '최강 신병 MAX'},
    'reach_level_10': {'vi': 'Cơ Thủ Kỳ Cựu', 'en': 'Seasoned Veteran', 'zh': '身经百战', 'ja': '熟練のベテラン', 'ko': '숙련된 베테랑'},
    'win_100': {'vi': 'Trăm Trận Trăm Thắng', 'en': 'Century of Victories', 'zh': '百胜霸王', 'ja': '百戦百勝', 'ko': '백전백승'},
    'win_200': {'vi': 'Bách Chiến Thần Binh', 'en': 'Double Century Hero', 'zh': '双百胜名将', 'ja': '200勝の覇者', 'ko': '200승의 거장'},
    'reach_level_30': {'vi': 'Tinh Anh Quốc Tế', 'en': 'Global Elite', 'zh': '国际菁英', 'ja': '世界のエリート', 'ko': '글로벌 엘리트'},
    'reach_level_50': {'vi': 'Siêu Cấp Huyền Thoại', 'en': 'Supreme Legend', 'zh': '超绝传奇', 'ja': 'スプリームレジェンド', 'ko': '수프림 레전드'},
    'coins_200k': {'vi': 'Triệu Phú Đại Tài', 'en': 'Talented Millionaire', 'zh': '盖世富商', 'ja': '天才ミリオネア', 'ko': '천재 밀리어네어'},
    'bot_stage_9': {'vi': 'Khắc Tinh Bot Thượng Đẳng', 'en': 'Nemesis of Elite AI', 'zh': '顶级AI克星', 'ja': 'エリートBOTの天敵', 'ko': '엘리트 봇의 천적'},
    'bot_stage_10': {'vi': 'Đại Thắng Boss Cuối', 'en': 'Final Boss Defeated', 'zh': '终焉裁决', 'ja': '最終ボス討伐', 'ko': '최종 보스 격파'},

    // 5. HUYỀN THOẠI (LEGENDARY)
    'tournament_champion_legend': {'vi': 'Vua Giải Đấu 5 Brackets', 'en': 'Tournament Supreme King', 'zh': '锦标赛无冕之王', 'ja': 'トーナメント覇王', 'ko': '토너먼트의 제왕'},
    'billiard_god': {'vi': 'Huyền Thoại Bida Toàn Năng', 'en': 'All-Round Billiard Legend', 'zh': '全能台球传奇', 'ja': '全能のビリヤードレジェンド', 'ko': '올라운드 당구 전설'},
    'cue_arsenal_full': {'vi': 'Bộ Sưu Tập Thần Khí', 'en': 'Supreme Arsenal', 'zh': '神兵宝库', 'ja': '至高の神兵庫', 'ko': '지고의 신병고'},
    'tournament_multi_champ': {'vi': 'Tam Quan Vương Tournament', 'en': 'Triple Tournament Champion', 'zh': '三冠霸王', 'ja': 'トリプルクラウン', 'ko': '3관왕 챔피언'},
    'billiard_emperor': {'vi': 'Đấng Tối Cao Bàn Bida', 'en': 'Billiards Emperor', 'zh': '台球大帝', 'ja': 'ビリヤードの覇王帝', 'ko': '당구 황제'},
  };

  // =========================================================================
  // 6. MÔ TẢ THÀNH TỰU (ACHIEVEMENT DESCRIPTIONS)
  // =========================================================================
  static const Map<String, Map<String, String>> achievementDescriptions = {
    // 1. DỄ (EASY)
    'first_win': {
      'vi': 'Giành chiến thắng trận đấu bida đầu tiên của bạn.',
      'en': 'Win your very first billiard match.',
      'zh': '赢得您的第一场台球比赛。',
      'ja': '最初のビリヤードマッチで勝利を収めよう。',
      'ko': '첫 번째 당구 경기에서 승리하세요.',
    },
    'cue_enthusiast': {
      'vi': 'Sở hữu ít nhất 2 cây gậy cơ trong Cửa Hàng.',
      'en': 'Own at least 2 cue sticks in the Shop.',
      'zh': '在商城中拥有至少2支球杆。',
      'ja': 'ショップで2本以上のキューを所持しよう。',
      'ko': '상점에서 2개 이상의 큐를 소유하세요.',
    },
    'spin_trick': {
      'vi': 'Tùy chỉnh kỹ thuật Áp-phê (Cu-lê hoặc Trô bóng) trong trận đấu.',
      'en': 'Customize cue ball spin (Follow or Draw) during a match.',
      'zh': '在对局中自定义加塞击球点 (高杆或低杆)。',
      'ja': '試合中にスピン（トップスピンまたはドロー）を調整しよう。',
      'ko': '경기 중 스핀(밀어치기 또는 끌어치기)을 조정하세요.',
    },
    'first_wealth': {
      'vi': 'Tích lũy đạt mốc 5.000 Vàng trong tài khoản.',
      'en': 'Accumulate 5,000 Coins in your account.',
      'zh': '账户累计积攒达到5,000金币。',
      'ja': '所持金5,000コインを達成しよう。',
      'ko': '계정에 5,000 골드를 모으세요.',
    },
    'reach_level_3': {
      'vi': 'Nâng cấp nhân vật đạt Cấp độ 3 trong sự nghiệp.',
      'en': 'Raise player Level to Level 3.',
      'zh': '角色生涯升级至3级。',
      'ja': 'プレイヤーレベル3に到達しよう。',
      'ko': '플레이어 레벨 3을 달성하세요.',
    },
    'reach_level_5': {
      'vi': 'Nâng cấp nhân vật đạt Cấp độ 5.',
      'en': 'Raise player Level to Level 5.',
      'zh': '角色升级至5级。',
      'ja': 'プレイヤーレベル5に到達しよう。',
      'ko': '플레이어 레벨 5에 도달하세요.',
    },
    'cue_upgrade_first': {
      'vi': 'Nâng cấp một cây gậy cơ bất kỳ lên Cấp 2 lần đầu tiên.',
      'en': 'Upgrade any cue stick to Level 2 for the first time.',
      'zh': '首次将任意球杆升级至2级。',
      'ja': 'いずれかのキューを初めてLv.2に強化しよう。',
      'ko': '아무 큐나 처음으로 레벨 2로 강화하세요.',
    },
    'cue_upgrade_level_3': {
      'vi': 'Nâng cấp bất kỳ cây gậy cơ nào đạt Cấp độ 3.',
      'en': 'Upgrade any cue stick to Level 3.',
      'zh': '将任意球杆强化至3级。',
      'ja': 'いずれかのキューをLv.3に強化しよう。',
      'ko': '아무 큐나 레벨 3으로 강화하세요.',
    },
    'bot_stage_1': {
      'vi': 'Vượt qua Ải 1 trong Chiến Dịch Thử Thách Bot.',
      'en': 'Clear Stage 1 in the Bot Campaign.',
      'zh': '通过人机战役第1关。',
      'ja': 'BOTキャンペーン第1ステージをクリアしよう。',
      'ko': '봇 캠페인 1단계를 클리어하세요.',
    },
    'bot_stage_2': {
      'vi': 'Vượt qua Ải 2 trong Chiến Dịch Thử Thách Bot.',
      'en': 'Clear Stage 2 in the Bot Campaign.',
      'zh': '通过人机战役第2关。',
      'ja': 'BOTキャンペーン第2ステージをクリアしよう。',
      'ko': '봇 캠페인 2단계를 클리어하세요.',
    },
    'tournament_entry': {
      'vi': 'Chiến thắng trận mở màn Bracket 1 của Giải đấu Tournament.',
      'en': 'Win the opening Bracket 1 match of Tournament.',
      'zh': '赢得锦标赛第1轮揭幕战。',
      'ja': 'トーナメント第1ブラケットの初戦で勝利しよう。',
      'ko': '토너먼트 브래킷 1 개막전에서 승리하세요.',
    },
    'trickshot_first': {
      'vi': 'Chinh phục thành công 1 Thế Đánh Huyền Thoại của cao thủ thế giới.',
      'en': 'Successfully clear 1 Legendary Master Trickshot.',
      'zh': '成功破解1个世界名宿传奇花式残局。',
      'ja': '伝説の世界マスター・トリックショットを1つ成功させよう。',
      'ko': '전설적인 마스터 트릭샷 1개를 성공시키세요.',
    },
    'first_diamond': {
      'vi': 'Tích lũy đạt từ 30 Kim Cương trở lên.',
      'en': 'Accumulate 30 Diamonds or more.',
      'zh': '累计积攒30颗或更多钻石。',
      'ja': 'ダイヤを30個以上集めよう。',
      'ko': '다이아몬드를 30개 이상 모으세요.',
    },
    'change_profile_cue': {
      'vi': 'Trang bị một cây gậy cơ mới khác với gậy mặc định.',
      'en': 'Equip a new cue stick different from default.',
      'zh': '装备一支不同于默认球杆的新球杆。',
      'ja': '初期キュー以外の新しいキューを装備しよう。',
      'ko': '기본 큐와 다른 새로운 큐를 장착하세요.',
    },
    'explore_daily_puzzle': {
      'vi': 'Thử sức giải bài toán Thế Bi Hàng Ngày (Daily Puzzle).',
      'en': 'Try out a Daily Puzzle challenge.',
      'zh': '体验每日残局解谜挑战。',
      'ja': 'デイリーパズルに挑戦してみよう。',
      'ko': '일일 퍼즐 도전에 참여해 보세요.',
    },

    // 2. TRUNG BÌNH (MEDIUM)
    'combo_hunter': {
      'vi': 'Thực hiện chuỗi ăn Combo từ 2 bi cùng nhóm trở lên trong 1 cơ.',
      'en': 'Perform a combo by potting 2+ balls of your group in a single shot.',
      'zh': '一杆内击落2颗或以上同组目标球达成连击。',
      'ja': '1ショットで同グループのボールを2個以上沈めてコンボを決めよう。',
      'ko': '한 번의 샷으로 같은 그룹 공을 2개 이상 연속으로 넣으세요.',
    },
    'daily_puzzle_clear': {
      'vi': 'Hoàn thành thử thách Thế Bi Hàng Ngày (Daily Trickshot).',
      'en': 'Clear the Daily Puzzle challenge.',
      'zh': '成功通过每日残局挑战。',
      'ja': 'デイリーパズルチャレンジをクリアしよう。',
      'ko': '일일 퍼즐 챌린지를 클리어하세요.',
    },
    'win_streak_3': {
      'vi': 'Giành tổng cộng từ 3 trận thắng trở lên.',
      'en': 'Accumulate 3 or more match victories.',
      'zh': '累计获得至少3场比赛胜利。',
      'ja': '通算3勝以上を達成しよう。',
      'ko': '누적 3승 이상을 달성하세요.',
    },
    'win_10': {
      'vi': 'Giành tổng cộng từ 10 trận thắng vẻ vang trở lên.',
      'en': 'Accumulate 10 or more glorious match victories.',
      'zh': '累计斩获10场以上辉煌胜利。',
      'ja': '通算10勝以上の栄冠を掴み取ろう。',
      'ko': '누적 10승 이상의 영광을 달성하세요.',
    },
    'coins_10k': {
      'vi': 'Tích lũy tài sản đạt từ 10.000 Vàng trong két sắt.',
      'en': 'Accumulate 10,000 Coins in your vault.',
      'zh': '金库中财富累计达到10,000金币。',
      'ja': '金庫に10,000コイン以上を蓄えよう。',
      'ko': '금고에 10,000 골드 이상을 모으세요.',
    },
    'coins_20k': {
      'vi': 'Tích lũy tài sản đạt từ 20.000 Vàng trong két sắt.',
      'en': 'Accumulate 20,000 Coins in your vault.',
      'zh': '金库中财富累计达到20,000金币。',
      'ja': '金庫に20,000コイン以上を蓄えよう。',
      'ko': '금고에 20,000 골드 이상을 모으세요.',
    },
    'reach_level_8': {
      'vi': 'Nâng cấp trình độ nhân vật đạt từ Cấp 8 trở lên.',
      'en': 'Reach player Level 8 or higher.',
      'zh': '角色等级提升至8级或以上。',
      'ja': 'プレイヤーレベル8に到達しよう。',
      'ko': '플레이어 레벨 8 이상에 도달하세요.',
    },
    'cue_upgrade_level_5': {
      'vi': 'Nâng cấp bất kỳ cây gậy cơ nào đạt Cấp độ 5.',
      'en': 'Upgrade any cue stick to Level 5.',
      'zh': '将任意球杆强化升至5级。',
      'ja': 'いずれかのキューをLv.5に強化しよう。',
      'ko': '아무 큐나 레벨 5로 강화하세요.',
    },
    'bot_stage_3': {
      'vi': 'Vượt qua Ải 3 trong Chiến Dịch Thử Thách Bot.',
      'en': 'Clear Stage 3 in the Bot Campaign.',
      'zh': '通过人机战役第3关。',
      'ja': 'BOTキャンペーン第3ステージを突破しよう。',
      'ko': '봇 캠페인 3단계를 돌파하세요.',
    },
    'bot_stage_4': {
      'vi': 'Vượt qua Ải 4 trong Chiến Dịch Thử Thách Bot.',
      'en': 'Clear Stage 4 in the Bot Campaign.',
      'zh': '通过人机战役第4关。',
      'ja': 'BOTキャンペーン第4ステージを突破しよう。',
      'ko': '봇 캠페인 4단계를 돌파하세요.',
    },
    'bot_stage_5': {
      'vi': 'Bứt Phá Giới Hạn - Vượt qua Ải 5 trong Chiến Dịch Thử Thách Bot.',
      'en': 'Break your limits by clearing Stage 5 in the Bot Campaign.',
      'zh': '突破极限，通过人机战役第5关。',
      'ja': '限界を超え、BOTキャンペーン第5ステージをクリアしよう。',
      'ko': '한계를 돌파하여 봇 캠페인 5단계를 클리어하세요.',
    },
    'tournament_bracket_2': {
      'vi': 'Vượt qua Bracket 2 trong Giải đấu Tournament.',
      'en': 'Pass Bracket 2 in Tournament.',
      'zh': '通过锦标赛第2轮晋级赛。',
      'ja': 'トーナメント第2ブラケットを突破しよう。',
      'ko': '토너먼트 브래킷 2를 통과하세요.',
    },
    'tournament_bracket_3': {
      'vi': 'Vượt qua Bracket 3 để ghi tên vào Top 4 Tournament.',
      'en': 'Pass Bracket 3 to enter Tournament Top 4.',
      'zh': '通过第3轮昂首迈进锦标赛四强。',
      'ja': '第3ブラケットを突破してベスト4進出を果たそう。',
      'ko': '브래킷 3을 통과하여 4강에 진출하세요.',
    },
    'trickshot_master_5': {
      'vi': 'Chinh phục thành công 5 Thế Đánh Huyền Thoại thế giới.',
      'en': 'Conquer 5 Legendary Master Trickshots.',
      'zh': '成功征服5个传奇大师花式球局。',
      'ja': '5つの伝説的マスタートリックショットを制覇しよう。',
      'ko': '5개의 전설 마스터 트릭샷을 정복하세요.',
    },
    'medals_showcase_3': {
      'vi': 'Ghim đủ 3 Huy chương danh dự lên Profile cá nhân.',
      'en': 'Showcase 3 honor medals on your Profile.',
      'zh': '在个人资料上佩戴展示3枚荣誉勋章。',
      'ja': 'プロフィールに3つの栄誉メダルをピン留めしよう。',
      'ko': '프로필에 3개의 명예 메달을 고정하세요.',
    },

    // 3. KHÓ (HARD)
    'cue_collector': {
      'vi': 'Mở khóa và sở hữu từ 4 cây gậy cơ trở lên trong bộ sưu tập.',
      'en': 'Unlock and own 4 or more cue sticks in your collection.',
      'zh': '在收藏中解锁并拥有4支或以上球杆。',
      'ja': 'コレクションで4本以上のキューをアンロックしよう。',
      'ko': '컬렉션에서 4개 이상의 큐를 잠금 해제하세요.',
    },
    'rich_player': {
      'vi': 'Tích lũy tài sản đạt từ 25.000 Vàng trở lên.',
      'en': 'Accumulate a balance of 25,000 Coins or more.',
      'zh': '财富积累达到25,000金币以上。',
      'ja': '所持金を25,000コイン以上貯めよう。',
      'ko': '누적 자산 25,000 골드 이상을 달성하세요.',
    },
    'multiplayer_veteran': {
      'vi': 'Chiến thắng trận đấu mạng nhiều người chơi (Local/Online).',
      'en': 'Win a multiplayer match (Local Network or Online).',
      'zh': '赢得一场多人对战 (局域网或在线网络)。',
      'ja': 'マルチプレイヤーマッチ（ローカルまたはオンライン）で勝利しよう。',
      'ko': '멀티플레이 경기(로컬 또는 온라인)에서 승리하세요.',
    },
    'win_25': {
      'vi': 'Giành tổng cộng từ 25 trận thắng vẻ vang.',
      'en': 'Accumulate 25 glorious match victories.',
      'zh': '累计赢得25场辉煌胜利。',
      'ja': '通算25勝の栄光を掴み取ろう。',
      'ko': '누적 25승의 영광을 달성하세요.',
    },
    'win_50': {
      'vi': 'Giành tổng cộng từ 50 trận thắng vẻ vang.',
      'en': 'Accumulate 50 glorious match victories.',
      'zh': '累计赢得50场辉煌胜利。',
      'ja': '通算50勝の金字塔を打ち立てよう。',
      'ko': '누적 50승의 대기록을 수립하세요.',
    },
    'reach_level_15': {
      'vi': 'Nâng cấp nhân vật đạt Cấp 15 (Lv.15).',
      'en': 'Reach player Level 15.',
      'zh': '角色升级至15级。',
      'ja': 'プレイヤーレベル15に到達しよう。',
      'ko': '플레이어 레벨 15에 도달하세요.',
    },
    'reach_level_20': {
      'vi': 'Nâng cấp nhân vật đạt Cấp 20 (Lv.20).',
      'en': 'Reach player Level 20.',
      'zh': '角色升级至20级。',
      'ja': 'プレイヤーレベル20に到達しよう。',
      'ko': '플레이어 레벨 20에 도달하세요.',
    },
    'coins_50k': {
      'vi': 'Tích lũy tài sản đạt từ 50.000 Vàng trong két sắt.',
      'en': 'Accumulate 50,000 Coins in your vault.',
      'zh': '金库中财富累计达到50,000金币。',
      'ja': '金庫に50,000コイン以上を蓄えよう。',
      'ko': '금고에 50,000 골드 이상을 모으세요.',
    },
    'coins_75k': {
      'vi': 'Tích lũy tài sản đạt từ 75.000 Vàng trong két sắt.',
      'en': 'Accumulate 75,000 Coins in your vault.',
      'zh': '金库中财富累计达到75,000金币。',
      'ja': '金庫に75,000コイン以上を蓄えよう。',
      'ko': '금고에 75,000 골드 이상을 모으세요.',
    },
    'cue_upgrade_level_7': {
      'vi': 'Nâng cấp bất kỳ cây gậy cơ nào đạt Cấp độ 7.',
      'en': 'Upgrade any cue stick to Level 7.',
      'zh': '将任意球杆强化升至7级。',
      'ja': 'いずれかのキューをLv.7に強化しよう。',
      'ko': '아무 큐나 레벨 7로 강화하세요.',
    },
    'cue_upgrade_level_8': {
      'vi': 'Nâng cấp bất kỳ cây gậy cơ nào đạt Cấp độ 8.',
      'en': 'Upgrade any cue stick to Level 8.',
      'zh': '将任意球杆强化升至8级。',
      'ja': 'いずれかのキューをLv.8に強化しよう。',
      'ko': '아무 큐나 레벨 8로 강화하세요.',
    },
    'bot_stage_6': {
      'vi': 'Vượt qua Ải 6 trong Chiến Dịch Thử Thách Bot.',
      'en': 'Clear Stage 6 in the Bot Campaign.',
      'zh': '通过人机战役第6关。',
      'ja': 'BOTキャンペーン第6ステージを突破しよう。',
      'ko': '봇 캠페인 6단계를 돌파하세요.',
    },
    'tournament_bracket_4': {
      'vi': 'Chiến thắng Bán Kết Bracket 4 để tiến vào Chung Kết Tournament.',
      'en': 'Win Semi-Final Bracket 4 to advance to Tournament Grand Finals.',
      'zh': '赢得半决赛第4轮挺进锦标赛巅峰总决赛。',
      'ja': '準決勝第4ブラケットを制し、決勝戦へ進出を果たそう。',
      'ko': '준결승 브래킷 4에서 승리하여 결승에 진출하세요.',
    },
    'trickshot_master_10': {
      'vi': 'Chinh phục từ 10 Thế Đánh Huyền Thoại trở lên.',
      'en': 'Conquer 10 or more Legendary Master Trickshots.',
      'zh': '成功征服10个或以上传奇大师花式球局。',
      'ja': '10個以上の伝説的マスタートリックショットを制覇しよう。',
      'ko': '10개 이상의 전설 마스터 트릭샷을 정복하세요.',
    },
    'medals_showcase_5': {
      'vi': 'Ghim trọn vẹn đủ 5 Huy chương danh giá trên Profile.',
      'en': 'Showcase a full set of 5 medals on your Profile.',
      'zh': '在个人资料上挂满全部5枚顶级荣誉勋章。',
      'ja': 'プロフィールに5つの最高峰メダルを完全装着しよう。',
      'ko': '프로필에 5개의 명예 메달을 모두 장착하세요.',
    },

    // 4. SIÊU KHÓ (EXPERT)
    'bot_campaign_clear': {
      'vi': 'Vượt qua trọn vẹn 7 Ải Thử Thách Bot Campaign.',
      'en': 'Conquer all 7 stages in the Bot Campaign.',
      'zh': '成功通关人机战役全部7关考验。',
      'ja': 'BOTキャンペーン全7ステージを突破しよう。',
      'ko': '봇 캠페인 7개 스테이지를 모두 돌파하세요.',
    },
    'cue_level_max': {
      'vi': 'Nâng cấp bất kỳ cây gậy cơ nào đạt cấp độ tối đa (Level 10).',
      'en': 'Upgrade any cue stick to maximum level (Level 10).',
      'zh': '将任意球杆升至满级 (10级)。',
      'ja': 'いずれかのキューを最大レベル（Lv.10）まで強化しよう。',
      'ko': '아무 큐나 최대 레벨(레벨 10)까지 강화하세요.',
    },
    'reach_level_10': {
      'vi': 'Nâng cấp trình độ nhân vật đạt từ Cấp 10 (Lv.10) trở lên.',
      'en': 'Reach player Level 10 or higher.',
      'zh': '玩家角色等级提升至10级或以上。',
      'ja': 'プレイヤーレベルをLv.10以上に到達させよう。',
      'ko': '플레이어 레벨 10 이상에 도달하세요.',
    },
    'win_100': {
      'vi': 'Đạt tổng cộng từ 100 trận thắng trong sự nghiệp.',
      'en': 'Reach a landmark of 100 career match victories.',
      'zh': '职业生涯斩获100场辉煌胜利大关。',
      'ja': 'キャリア通算100勝の金字塔を打ち立てよう。',
      'ko': '통산 100승의 위업을 달성하세요.',
    },
    'win_200': {
      'vi': 'Đạt tổng cộng từ 200 trận thắng oanh liệt.',
      'en': 'Reach an extraordinary 200 match victories.',
      'zh': '生涯斩获惊世骇俗的200场大胜。',
      'ja': '通算200勝という偉大なる覇業を成し遂げよう。',
      'ko': '통산 200승의 찬란한 대기록을 세우세요.',
    },
    'reach_level_30': {
      'vi': 'Đạt Cấp độ người chơi Lv.30 trở lên.',
      'en': 'Reach player Level 30 or higher.',
      'zh': '玩家角色等级达到30级或以上。',
      'ja': 'プレイヤーレベル30に到達しよう。',
      'ko': '플레이어 레벨 30에 도달하세요.',
    },
    'reach_level_50': {
      'vi': 'Đạt Cấp độ người chơi Lv.50 trở lên.',
      'en': 'Reach player Level 50 or higher.',
      'zh': '玩家角色等级达到50级或以上。',
      'ja': 'プレイヤーレベル50に到達しよう。',
      'ko': '플레이어 레벨 50에 도달하세요.',
    },
    'coins_200k': {
      'vi': 'Tích lũy tài sản đạt từ 200.000 Vàng trong két sắt.',
      'en': 'Accumulate 200,000 Coins in your vault.',
      'zh': '金库中财富累计达到200,000金币。',
      'ja': '金庫に200,000コイン以上を蓄えよう。',
      'ko': '금고에 200,000 골드 이상을 모으세요.',
    },
    'bot_stage_9': {
      'vi': 'Vượt qua Ải 9 khó khăn trong Chiến Dịch Bot Campaign.',
      'en': 'Conquer the daunting Stage 9 in the Bot Campaign.',
      'zh': '突破极难的人机战役第9关考验。',
      'ja': 'BOTキャンペーン屈指の難関・第9ステージを突破しよう。',
      'ko': '봇 캠페인 9단계 난관을 극복하세요.',
    },
    'bot_stage_10': {
      'vi': 'Vượt qua Ải 10 Thử Thách Bot Tối Thượng.',
      'en': 'Defeat the Ultimate Boss in Stage 10 Bot Campaign.',
      'zh': '击溃第10关人机终极首领，平定战役。',
      'ja': 'BOTキャンペーン第10ステージの究極ボスを討伐しよう。',
      'ko': '봇 캠페인 10단계 최종 보스를 물리치세요.',
    },

    // 5. HUYỀN THOẠI (LEGENDARY)
    'tournament_champion_legend': {
      'vi': 'Vượt qua toàn bộ các vòng đấu Brackets khốc liệt và nâng cao cúp Vô Địch!',
      'en': 'Triumph over all Tournament Brackets and hoist the Champion Cup!',
      'zh': '通过全部巡回锦标赛轮次，高举冠军奖杯！',
      'ja': '激闘の全ブラケットを制覇し、優勝カップを掲げよう！',
      'ko': '치열한 토너먼트 모든 브래킷을 제패하고 우승컵을 들어 올리세요!',
    },
    'billiard_god': {
      'vi': 'Sở hữu trên 100.000 Vàng và đạt 50 trận thắng vẻ vang.',
      'en': 'Hold over 100,000 Coins and achieve 50 glorious victories.',
      'zh': '坐拥100,000以上金币并斩获50场辉煌胜利。',
      'ja': '100,000コイン以上を保有し、栄光の50勝を達成しよう。',
      'ko': '100,000 이상의 골드를 보유하고 50승의 영광을 달성하세요.',
    },
    'cue_arsenal_full': {
      'vi': 'Mở khóa và sở hữu toàn bộ 7 cây gậy cơ trong Cửa hàng.',
      'en': 'Unlock and own all 7 cue sticks in the Shop.',
      'zh': '解锁并拥有商城中全部7支传奇球杆。',
      'ja': 'ショップにある全7本の神話キューを完全制覇しよう。',
      'ko': '상점의 모든 7개 전설 큐를 소유하세요.',
    },
    'tournament_multi_champ': {
      'vi': 'Giành chức Vô Địch Giải Đấu Tournament từ 3 lần trở lên.',
      'en': 'Win the Tournament Championship 3 or more times.',
      'zh': '斩获3次及以上巡回锦标赛总冠军。',
      'ja': 'トーナメント優勝を3回以上達成し王朝を築こう。',
      'ko': '토너먼트 대회 우승을 3회 이상 달성하세요.',
    },
    'billiard_emperor': {
      'vi': 'Đạt Cấp 70+, sở hữu trên 500.000 Vàng và 100 trận thắng.',
      'en': 'Reach Level 70+, hold 500,000+ Coins and 100 victories.',
      'zh': '等级达70级以上、坐拥50万金币并斩获100胜。',
      'ja': 'Lv.70到達、500,000コイン保有、100勝達成の神域へ。',
      'ko': '레벨 70 달성, 50만 골드 보유, 통산 100승의 신역에 도달하세요.',
    },
  };

  // =========================================================================
  // 7. ĐỘ KHÓ THÀNH TỰU (ACHIEVEMENT DIFFICULTY)
  // =========================================================================
  static const Map<String, Map<String, String>> achievementDifficulties = {
    'easy': {'vi': 'Dễ', 'en': 'Easy', 'zh': '简单', 'ja': 'イージー', 'ko': '쉬움'},
    'medium': {'vi': 'Trung Bình', 'en': 'Medium', 'zh': '中等', 'ja': 'ノーマル', 'ko': '보통'},
    'hard': {'vi': 'Khó', 'en': 'Hard', 'zh': '困难', 'ja': 'ハード', 'ko': '어려움'},
    'expert': {'vi': 'Siêu Khó', 'en': 'Expert', 'zh': '专家', 'ja': 'エキスパート', 'ko': '전문가'},
    'legendary': {'vi': 'Huyền Thoại', 'en': 'Legendary', 'zh': '传奇', 'ja': 'レジェンド', 'ko': '전설'},
  };

  // =========================================================================
  // 8. TÊN HUY CHƯƠNG (MEDAL NAMES)
  // =========================================================================
  static const Map<String, Map<String, String>> medalNames = {
    // 1. ĐỒNG (BRONZE)
    'bronze_champion': {'vi': 'Cơ Thủ Tinh Anh', 'en': 'Elite Striker', 'zh': '精英新星', 'ja': 'エリートストライカー', 'ko': '엘리트 당구인'},
    'bot_cadet': {'vi': 'Huy Hiệu Tân Binh Bot', 'en': 'Bot Cadet Crest', 'zh': '初阶人机徽章', 'ja': 'BOT見習いバッジ', 'ko': '봇 견습생 휘장'},
    'bot_fighter': {'vi': 'Huy Hiệu Chiến Sĩ Bot', 'en': 'Bot Fighter Crest', 'zh': '进阶人机徽章', 'ja': 'BOTファイターバッジ', 'ko': '봇 파이터 휘장'},
    'tournament_quarter': {'vi': 'Huy Hiệu Tứ Trụ', 'en': 'Quarter-Finalist Crest', 'zh': '八强精英徽章', 'ja': 'ベスト8バッジ', 'ko': '8강 엘리트 휘장'},
    'cue_apprentice': {'vi': 'Thợ Rèn Cơ Tập Sự', 'en': 'Apprentice Cue Smith', 'zh': '锻造学徒勋章', 'ja': 'キュー見習い職人', 'ko': '큐 견습 대장장이'},
    'trickshot_apprentice': {'vi': 'Khám Phá Thế Bi', 'en': 'Trickshot Scout', 'zh': '残局先锋勋章', 'ja': 'トリックショット見習い', 'ko': '트릭샷 개척자'},
    'rising_star': {'vi': 'Ngôi Sao Đang Lên', 'en': 'Rising Star Medal', 'zh': '冉冉新星奖章', 'ja': '新星メダル', 'ko': '라이징 스타 메달'},
    'cue_collector_bronze': {'vi': 'Bộ Sưu Tập Đồng', 'en': 'Bronze Collector', 'zh': '青铜收藏勋章', 'ja': 'ブロンズコレクター', 'ko': '브론즈 컬렉터'},

    // 2. BẠC (SILVER)
    'tournament_semis': {'vi': 'Huy Chương Tứ Cường', 'en': 'Semi-Finalist Medal', 'zh': '四强殿堂奖牌', 'ja': 'セミファイナルメダル', 'ko': '4강 진출 메달'},
    'wealthy_striker': {'vi': 'Triệu Phú Phố Bida', 'en': 'Billiards Millionaire', 'zh': '百万金库大亨', 'ja': 'ミリオネアストライカー', 'ko': '당구장 백만장자'},
    'bot_challenger': {'vi': 'Huy Hiệu Thách Đấu Bot', 'en': 'Bot Challenger Crest', 'zh': '战役试炼之证', 'ja': 'BOTチャレンジャー', 'ko': '봇 도전자 휘장'},
    'trickshot_virtuoso': {'vi': 'Bậc Thầy Đường Cơ', 'en': 'Trickshot Virtuoso', 'zh': '精妙走位大师', 'ja': 'トリックショット名手', 'ko': '트릭샷 거장'},
    'veteran_striker': {'vi': 'Cơ Thủ Lão Thành', 'en': 'Veteran Cueist', 'zh': '稳健老将奖牌', 'ja': 'ベテラン撃ち手', 'ko': '베테랑 당구인'},
    'cue_artisan': {'vi': 'Thợ Thủ Công Bida', 'en': 'Master Cue Artisan', 'zh': '巧手工匠勋章', 'ja': 'キュー工芸職人', 'ko': '큐 공예 장인'},
    'silver_treasury': {'vi': 'Ngân Khố Hoàng Kim', 'en': 'Silver Treasury', 'zh': '白银金库奖章', 'ja': 'シルバー宝物庫', 'ko': '실버 보물고'},
    'english_spin_master': {'vi': 'Thần Xoáy Áp-Phê', 'en': 'English Spin Master', 'zh': '旋转掌控大师', 'ja': 'スピンマスター', 'ko': '스핀의 제왕'},

    // 3. VÀNG (GOLD)
    'tournament_runner_up': {'vi': 'Huy Chương Á Quân', 'en': 'Tournament Runner-Up', 'zh': '锦标赛亚军奖牌', 'ja': '準優勝メダル', 'ko': '준우승 메달'},
    'sharpshooter': {'vi': 'Huy Chương Thiện Xạ', 'en': 'Sharpshooter Medal', 'zh': '神准神枪手', 'ja': 'スナイパーメダル', 'ko': '명사수 메달'},
    'cue_master': {'vi': 'Bậc Thầy Gậy Cơ', 'en': 'Cue Craftmaster', 'zh': '球杆宗师', 'ja': 'キュー職人', 'ko': '큐 마스터 장인'},
    'grandmaster': {'vi': 'Đại Kiện Tướng Bida', 'en': 'Billiard Grandmaster', 'zh': '台球特级大师', 'ja': 'グランドマスター', 'ko': '당구 대기수'},
    'undefeated_spree': {'vi': 'Bất Khả Chiến Bại', 'en': 'Undefeated Spree', 'zh': '连胜破浪之证', 'ja': '連勝の覇者', 'ko': '연승의 패자'},
    'centurion_victor': {'vi': 'Cơ Thủ Bách Thắng', 'en': 'Centurion Victor', 'zh': '三十胜名将', 'ja': '30勝の英傑', 'ko': '30승의 영웅'},
    'cue_collector_gold': {'vi': 'Nhà Sưu Tập Vàng', 'en': 'Gold Arsenal Collector', 'zh': '黄金收藏大家', 'ja': 'ゴールドコレクター', 'ko': '골드 컬렉터'},
    'master_duel_victor': {'vi': 'Khắc Tinh Bot Thượng Thừa', 'en': 'Elite AI Slayer', 'zh': '破阵降魔徽章', 'ja': 'エリートBOTキラー', 'ko': '엘리트 봇 슬레이어'},
    'golden_treasury': {'vi': 'Đại Phú Hào Bàn Xanh', 'en': 'Golden Treasury', 'zh': '黄金财阀勋章', 'ja': '黄金の宝物庫', 'ko': '황금의 보고'},
    'profile_perfection': {'vi': 'Vinh Dự Ngũ Tinh', 'en': '5-Star Honor Medal', 'zh': '五星满誉勋章', 'ja': '五つ星の名誉メダル', 'ko': '5성 영예 훈장'},

    // 4. KIM CƯƠNG (DIAMOND)
    'trickshot_master': {'vi': 'Thần Cơ Diệu Toán', 'en': 'Master Trickshot', 'zh': '神机妙算', 'ja': 'トリックショットマスター', 'ko': '신기묘산 마스터'},
    'bot_slayer': {'vi': 'Huy Hiệu Trùm Bot', 'en': 'Bot Slayer Crest', 'zh': '击破者勋章', 'ja': 'BOTスレイヤー紋章', 'ko': '봇 슬레이어 훈장'},
    'bot_annihilator': {'vi': 'Kẻ Hủy Diệt Bot', 'en': 'Bot Annihilator', 'zh': '绝域歼灭勋章', 'ja': 'BOTアナイアレイター', 'ko': '봇 파괴자 훈장'},
    'trickshot_legend': {'vi': 'Huân Chương Phù Thủy Bi', 'en': 'Trickshot Legend', 'zh': '魔幻球手勋章', 'ja': 'トリックショットレジェンド', 'ko': '마구의 전설 훈장'},
    'cue_god_forge': {'vi': 'Bậc Thầy Đúc Thần Khí', 'en': 'God-Forge Master', 'zh': '神铸造化勋章', 'ja': '神話の鍛冶師', 'ko': '신의 대장장이'},
    'hall_of_fame': {'vi': 'Đại Sảnh Danh Vọng', 'en': 'Hall of Fame Crest', 'zh': '荣耀殿堂奖牌', 'ja': '殿堂入りメダル', 'ko': '명예의 전당 메달'},
    'legendary_champion': {'vi': 'Quán Quân Trăm Trận', 'en': 'Champion of 75', 'zh': '75战金勋', 'ja': '75勝の覇業', 'ko': '75승의 패업'},
    'diamond_royalty': {'vi': 'Hoàng Gia Kim Cương', 'en': 'Diamond Royalty', 'zh': '璀璨钻石皇室', 'ja': 'ダイヤモンドロイヤル', 'ko': '다이아몬드 로열티'},

    // 5. THẦN THOẠI (MYTHIC)
    'tournament_champion': {'vi': 'Cúp Quán Quân Tournament', 'en': 'Tournament Champion Cup', 'zh': '锦标赛总冠军杯', 'ja': 'トーナメント優勝カップ', 'ko': '토너먼트 챔피언 컵'},
    'tournament_dynasty': {'vi': 'Cúp Hoàng Triều Tournament', 'en': 'Tournament Dynasty Trophy', 'zh': '锦标赛王朝巨杯', 'ja': 'トーナメント王朝トロフィー', 'ko': '토너먼트 왕조 트로피'},
    'bot_overlord': {'vi': 'Huân Chương Bá Chủ AI', 'en': 'Bot Overlord Medal', 'zh': '人机终极霸主', 'ja': 'BOT覇王勲章', 'ko': '봇 절대패왕 훈장'},
    'cue_collector_mythic': {'vi': 'Kho Báu Vạn Cây', 'en': 'Mythic Arsenal Hoard', 'zh': '万兵至尊宝库', 'ja': '神話の全キュー制覇', 'ko': '신화의 큐 제패'},
    'immortal_sovereign': {'vi': 'Đấng Tối Cao Bida', 'en': 'Immortal Sovereign', 'zh': '不朽台球至尊', 'ja': '不滅のビリヤード覇王', 'ko': '불멸의 당구 지존'},
    'trickshot_immortal': {'vi': 'Vương Huy Hoàng Gia Trickshot', 'en': 'Royal Trickshot Sovereign', 'zh': '皇家花式至尊', 'ja': 'ロイヤルトリックショット覇王', 'ko': '로열 트릭샷 지존'},
  };

  // =========================================================================
  // 9. MÔ TẢ HUY CHƯƠNG (MEDAL DESCRIPTIONS)
  // =========================================================================
  static const Map<String, Map<String, String>> medalDescriptions = {
    // 1. ĐỒNG (BRONZE)
    'bronze_champion': {
      'vi': 'Ghi dấu ấn những bước đầu tiên trên đấu trường bi-a chuyên nghiệp.',
      'en': 'Marked your first milestone in competitive billiards.',
      'zh': '在专业竞技台球舞台上迈出坚实的第一步。',
      'ja': '競技ビリヤードの世界で最初の一歩を踏み出した証。',
      'ko': '프로 당구 무대에서 첫 발자국을 남겼습니다.',
    },
    'bot_cadet': {
      'vi': 'Vượt qua ải đầu tiên trong Chiến Dịch Thử Thách Bot.',
      'en': 'Passed the first stage of the Bot Campaign.',
      'zh': '通过人机挑战战役第1关。',
      'ja': 'BOTキャンペーンの第1ステージを突破した証。',
      'ko': '봇 캠페인 1단계를 통과했습니다.',
    },
    'bot_fighter': {
      'vi': 'Thể hiện bản lĩnh kiên cường khi khuất phục Bot ải 3.',
      'en': 'Demonstrated grit by conquering Bot stage 3.',
      'zh': '展现坚韧本色，顺利攻克人机第3关。',
      'ja': '粘り強い闘志でBOT第3ステージを制圧した証。',
      'ko': '불굴의 투지로 봇 3단계를 정복했습니다.',
    },
    'tournament_quarter': {
      'vi': 'Vượt qua Bracket 2 để tiến vào Tứ Kết Tournament danh giá.',
      'en': 'Cleared Bracket 2 to qualify for the prestigious Tournament Quarter-Finals.',
      'zh': '突围第2轮，挺进荣耀的巡回锦标赛前八强。',
      'ja': '第2ブラケットを突破し、名誉ある準々決勝へ進出。',
      'ko': '브래킷 2를 뚫고 영예로운 8강에 진출했습니다.',
    },
    'cue_apprentice': {
      'vi': 'Rèn đúc và nâng cấp một cây gậy cơ đạt mốc Cấp 3.',
      'en': 'Forged and upgraded any cue stick to Level 3.',
      'zh': '将任意球杆锻造强化至3级。',
      'ja': 'キューをLv.3に鍛造・強化した証。',
      'ko': '큐를 레벨 3으로 제련 및 강화했습니다.',
    },
    'trickshot_apprentice': {
      'vi': 'Chinh phục thành công 1 Thế Đánh Huyền Thoại kinh điển.',
      'en': 'Conquered 1 classic Legendary Master Trickshot.',
      'zh': '成功破解1例世界大师经典花式残局。',
      'ja': '1つの伝説的マスタートリックショットを成功させた証。',
      'ko': '1개의 전설적인 클래식 트릭샷을 성공시켰습니다.',
    },
    'rising_star': {
      'vi': 'Minh chứng cho bước tiến vượt bậc đạt Cấp độ 5.',
      'en': 'Proof of rapid advancement reaching player Level 5.',
      'zh': '角色飞速升至5级的实力见证。',
      'ja': 'プレイヤーレベル5に到達した急速な成長の証。',
      'ko': '플레이어 레벨 5에 도달한 눈부신 성장의 증거.',
    },
    'cue_collector_bronze': {
      'vi': 'Bổ sung thêm gậy cơ vào kho vũ khí cá nhân.',
      'en': 'Expanded your personal arsenal with 2 or more cues.',
      'zh': '个人武器库中解锁拥有至少2支球杆。',
      'ja': '個人武器庫に2本以上のキューを収蔵した証。',
      'ko': '개인 무기고에 2개 이상의 큐를 소장했습니다.',
    },

    // 2. BẠC (SILVER)
    'tournament_semis': {
      'vi': 'Vượt qua vòng Tứ Kết và ghi tên mình vào Bán Kết Bracket 4.',
      'en': 'Advanced beyond the Quarter-Finals into the Semi-Finals of Bracket 4.',
      'zh': '突围1/4决赛，成功跻身第4轮半决赛。',
      'ja': '準々決勝を突破し、第4ブラケット準決勝へ進出。',
      'ko': '준준결승을 넘어 브래킷 4 준결승에 진출했습니다.',
    },
    'wealthy_striker': {
      'vi': 'Sở hữu khối tài sản từ 20.000 Vàng trong két sắt cá nhân.',
      'en': 'Hold a fortune of 20,000+ Coins in your personal vault.',
      'zh': '个人金库中坐拥20,000以上金币巨资。',
      'ja': '個人金庫に20,000コイン以上の富を築いた証。',
      'ko': '개인 금고에 20,000 골드 이상의 재산을 축적했습니다.',
    },
    'bot_challenger': {
      'vi': 'Bứt phá vượt qua Ải 5 trong Chiến Dịch Bot.',
      'en': 'Broke through by clearing Stage 5 in the Bot Campaign.',
      'zh': '气势如虹，成功突破人机战役第5关。',
      'ja': '気迫のショットでBOTキャンペーン第5ステージを制覇。',
      'ko': '과감한 샷으로 봇 캠페인 5단계를 돌파했습니다.',
    },
    'trickshot_virtuoso': {
      'vi': 'Chinh phục thành công 5 Thế Đánh Huyền Thoại đỉnh cao.',
      'en': 'Masterfully cleared 5 Legendary Trickshots.',
      'zh': '以绝妙技法连破5项世界传奇残局。',
      'ja': '卓越した技で5つの伝説トリックショットを完全制覇。',
      'ko': '탁월한 기술로 5개의 전설 트릭샷을 정복했습니다.',
    },
    'veteran_striker': {
      'vi': 'Khẳng định sự dày dạn với 15 trận thắng vẻ vang.',
      'en': 'Affirmed your veteran caliber with 15 match victories.',
      'zh': '以15场大捷彰显深厚扎实的球台功力。',
      'ja': '通算15勝を積み上げ、熟練の腕前を証明した証。',
      'ko': '통산 15승을 거두며 노련한 실력을 입증했습니다.',
    },
    'cue_artisan': {
      'vi': 'Nâng cấp bất kỳ cây gậy cơ nào đạt mốc Cấp 4.',
      'en': 'Upgraded any cue stick to Level 4.',
      'zh': '将任意球杆匠心升炼至4级。',
      'ja': 'キューの練度をLv.4へと高めた工芸の証。',
      'ko': '큐를 레벨 4로 장인처럼 연마했습니다.',
    },
    'silver_treasury': {
      'vi': 'Tích lũy khối tài sản trên 50.000 Vàng.',
      'en': 'Accumulated a treasury of over 50,000 Coins.',
      'zh': '个人金库累计突破50,000金币大关。',
      'ja': '所持金50,000コインを突破した裕福の証。',
      'ko': '누적 자산 50,000 골드를 돌파했습니다.',
    },
    'english_spin_master': {
      'vi': 'Tùy chỉnh kỹ thuật Áp-phê (Cu-lê hoặc Trô bóng) điệu nghệ trong thi đấu.',
      'en': 'Executed skillful English spin (Follow or Draw) during a match.',
      'zh': '在比赛中展现精湛绝伦的加塞旋转走位技术。',
      'ja': '実戦で華麗なスピンコントロールを操った証。',
      'ko': '실전에서 화려한 스핀 기술을 구사했습니다.',
    },

    // 3. VÀNG (GOLD)
    'tournament_runner_up': {
      'vi': 'Khẳng định bản lĩnh kiên cường khi bước chân vào trận Đại Chung Kết Bracket 5.',
      'en': 'Testament to resilience in battling through to the Grand Finals of Bracket 5.',
      'zh': '战至巅峰总决赛第5轮的坚韧证明。',
      'ja': '第5ブラケットのグランドファイナルまで勝ち抜いた証。',
      'ko': '브래킷 5 결승전에 진출한 굳건한 실력의 증표.',
    },
    'sharpshooter': {
      'vi': 'Dành cho cơ thủ có nhãn quan siêu phàm, ghi combo ăn nhiều bi liên hoàn.',
      'en': 'Awarded for extraordinary vision, sinking multiple balls in a single combo.',
      'zh': '专属拥有非凡视野、实现多球连环清台的卓越球手。',
      'ja': '1ショットで複数ボールを連続で沈める神技の持ち主へ。',
      'ko': '한 샷으로 여러 공을 연달아 포켓에 넣는 탁월한 시야의 소유자.',
    },
    'cue_master': {
      'vi': 'Sở hữu và rèn đúc gậy cơ đạt mốc nâng cấp Level 5 trở lên.',
      'en': 'Forged and upgraded a cue stick to Level 5 or higher.',
      'zh': '锻造并将任意球杆强化至5级以上。',
      'ja': 'キューをLv.5以上に鍛え上げた証。',
      'ko': '큐를 레벨 5 이상으로 강화 및 단련했습니다.',
    },
    'grandmaster': {
      'vi': 'Minh chứng cho đẳng cấp cơ thủ kỳ cựu đạt Cấp độ 10+.',
      'en': 'Proof of veteran status reaching player Level 10 or higher.',
      'zh': '玩家角色达到10级以上的名宿凭证。',
      'ja': 'プレイヤーレベル10に到達した熟練者の証。',
      'ko': '플레이어 레벨 10 이상에 도달한 베테랑의 증표.',
    },
    'undefeated_spree': {
      'vi': 'Giành chuỗi 5 trận thắng oanh liệt liên tiếp.',
      'en': 'Rode a sensational win streak of 5 consecutive matches.',
      'zh': '豪取势不可挡的连续5场连胜狂潮。',
      'ja': '破竹の5連勝を達成した無敗の誇り。',
      'ko': '파죽지세의 5연승을 달성한 무패의 자부심.',
    },
    'centurion_victor': {
      'vi': 'Đạt mốc 30 trận thắng vẻ vang trong sự nghiệp.',
      'en': 'Achieved a major career milestone of 30 victories.',
      'zh': '生涯战绩突破30场胜利荣耀大关。',
      'ja': 'キャリア通算30勝の大台に達した勇士の証。',
      'ko': '통산 30승의 중요한 고지에 도달했습니다.',
    },
    'cue_collector_gold': {
      'vi': 'Mở khóa và sở hữu từ 4 cây gậy cơ trong tủ đồ.',
      'en': 'Unlocked and assembled 4 or more prestigious cue sticks.',
      'zh': '个人收藏室拥有4支及以上神妙球杆。',
      'ja': '4本以上の名品キューを揃えた収集家の証。',
      'ko': '4개 이상의 명품 큐를 수집했습니다.',
    },
    'master_duel_victor': {
      'vi': 'Vượt qua ải 8 đầy hiểm hóc trong Chiến Dịch Bot.',
      'en': 'Overcame the treacherous Stage 8 of Bot Campaign.',
      'zh': '击溃神准无比的人机第8关强敌。',
      'ja': '超精度のBOT第8ステージを見事に突破した証。',
      'ko': '초정밀 봇 8단계를 멋지게 돌파했습니다.',
    },
    'golden_treasury': {
      'vi': 'Tích lũy khối tài sản trên 100.000 Vàng trong két.',
      'en': 'Amassed a grand treasury exceeding 100,000 Coins.',
      'zh': '金库总资产突破100,000金币超级巨资。',
      'ja': '金庫資産100,000コインを突破した大富豪の証。',
      'ko': '금고 자산 100,000 골드를 돌파한 대부호의 증명.',
    },
    'profile_perfection': {
      'vi': 'Ghim trọn vẹn đủ 5 Huy Chương Danh Dự lên Profile cá nhân.',
      'en': 'Pinned all 5 honor medals onto your Profile showcase.',
      'zh': '在个人战绩名片上挂满全套5枚至尊勋章。',
      'ja': 'プロフィールの全5スロットにメダルを輝かせた証。',
      'ko': '프로필의 5개 슬롯에 메달을 가득 채웠습니다.',
    },

    // 4. KIM CƯƠNG (DIAMOND)
    'trickshot_master': {
      'vi': 'Giải mã thành công thế bi hiểm hóc của nhiệm vụ Hàng Ngày.',
      'en': 'Successfully decoded difficult trickshot layouts in Daily Puzzles.',
      'zh': '成功破解每日任务中刁钻险要的残局阵型。',
      'ja': '難解なデイリーパズルを見事に解き明かした証。',
      'ko': '어려운 일일 트릭샷 퍼즐 배치를 완벽하게 풀어냈습니다.',
    },
    'bot_slayer': {
      'vi': 'Đánh bại Boss Bot cao nhất trong chuỗi 7 Ải Thử Thách Chiến Dịch.',
      'en': 'Defeated the supreme Bot Boss in the 7-stage Campaign.',
      'zh': '在7关人机战役试炼中战胜最高阶首领机器人。',
      'ja': '7段階のBOTキャンペーンで最強ボスを討伐した証。',
      'ko': '7단계 봇 캠페인에서 최상위 보스 봇을 물리쳤습니다.',
    },
    'bot_annihilator': {
      'vi': 'Đánh bại đối thủ Bot ải 9 đỉnh cao của Chiến Dịch.',
      'en': 'Annihilated the elite AI rival in Campaign Stage 9.',
      'zh': '在战役第9关中彻底歼灭最顶级的AI宿敌。',
      'ja': '第9ステージの超高難度BOTを完全に撃破した証。',
      'ko': '9단계의 최상급 엘리트 AI 상대를 격파했습니다.',
    },
    'trickshot_legend': {
      'vi': 'Chinh phục từ 10 Thế Đánh Huyền Thoại kinh điển của các cơ thủ thế giới.',
      'en': 'Conquered 10 classic master trickshots from world champions.',
      'zh': '破译攻克10项世界冠军级经典花式神球。',
      'ja': '世界王者のクラシックトリックショットを10個制覇。',
      'ko': '세계 챔피언들의 클래식 트릭샷 10개를 정복했습니다.',
    },
    'cue_god_forge': {
      'vi': 'Rèn luyện và nâng cấp bất kỳ cây gậy cơ nào đạt cấp độ tối đa (Level 10).',
      'en': 'Forged and upgraded any cue stick to maximum Level 10.',
      'zh': '将任意神兵球杆升至登峰造极的满级 (10级)。',
      'ja': 'キューの能力を極限のLv.10まで解放した神話の鍛冶師。',
      'ko': '큐의 능력을 극한인 레벨 10까지 완전 해방했습니다.',
    },
    'hall_of_fame': {
      'vi': 'Minh chứng cho cơ thủ kiệt xuất đạt Cấp độ Lv.25 trở lên.',
      'en': 'Inducted into the Hall of Fame upon reaching player Level 25+.',
      'zh': '角色达到25级以上，尊荣晋升台球名人堂。',
      'ja': 'プレイヤーレベル25到達により殿堂入りを果たした証。',
      'ko': '플레이어 레벨 25에 도달하여 명예의 전당에 헌액되었습니다.',
    },
    'legendary_champion': {
      'vi': 'Ghi dấu ấn vang dội với 75 trận thắng trong sự nghiệp.',
      'en': 'Carved your legendary name with 75 career victories.',
      'zh': '以75场辉煌胜绩铸造名扬四海的传奇篇章。',
      'ja': '通算75勝の偉業を成し遂げた不朽の王者。',
      'ko': '통산 75승을 달성하며 전설적인 족적을 남겼습니다.',
    },
    'diamond_royalty': {
      'vi': 'Tích lũy đạt trên 100 Kim Cương quý giá.',
      'en': 'Amassed a royal treasury of 100+ sparkling Diamonds.',
      'zh': '积攒收集超过100颗璀璨夺目的稀世钻石。',
      'ja': '100個以上の輝くダイヤモンドを蓄えた王者の証。',
      'ko': '100개 이상의 찬란한 다이아몬드를 모았습니다.',
    },

    // 5. THẦN THOẠI (MYTHIC)
    'tournament_champion': {
      'vi': 'Danh hiệu cao quý nhất dành cho cơ thủ thống trị cả 5 Brackets của giải đấu.',
      'en': 'Highest honor awarded to the player dominating all 5 Tournament Brackets.',
      'zh': '颁发给统领全部5轮巡回锦标赛王者的至高荣耀。',
      'ja': '全5ブラケットを完全制覇したプレイヤーに贈られる最高峰の栄誉。',
      'ko': '토너먼트 5개 브래킷을 모두 제패한 플레이어에게 주어지는 최고 영예.',
    },
    'tournament_dynasty': {
      'vi': 'Thống trị giải đấu với từ 3 lần vô địch Tournament trở lên.',
      'en': 'Built an untouchable dynasty by winning 3+ Tournament Championships.',
      'zh': '豪取3次及以上巡回赛总冠军，开创不可撼动的王朝。',
      'ja': '3回以上のトーナメント制覇により絶対王政を築いた証。',
      'ko': '토너먼트 우승을 3회 이상 달성하며 절대 왕조를 구축했습니다.',
    },
    'bot_overlord': {
      'vi': 'Quét sạch toàn bộ 10 Ải Chiến Dịch Thử Thách Bot.',
      'en': 'Total dominion achieved by sweeping all 10 stages in Bot Campaign.',
      'zh': '全通人机战役全部10大难关，登顶AI征服者之巅。',
      'ja': 'BOTキャンペーン全10ステージを完全制覇した絶対覇者。',
      'ko': '봇 캠페인 10개 전 스테이지를 완벽하게 제패했습니다.',
    },
    'cue_collector_mythic': {
      'vi': 'Mở khóa và sở hữu trọn bộ 7 cây gậy cơ huyền thoại của trò chơi.',
      'en': 'Unlocked and completed the full collection of all 7 legendary cues.',
      'zh': '集齐游戏内全部7柄神话球杆，掌控天下神兵。',
      'ja': '全7本の伝説的キューを完全コンプリートした神話の主。',
      'ko': '게임 내 7개 전설 큐를 모두 수집하여 제패했습니다.',
    },
    'immortal_sovereign': {
      'vi': 'Cơ thủ tối thượng đạt Cấp độ người chơi Lv.50 trở lên.',
      'en': 'Ascended to supreme status by reaching player Level 50+.',
      'zh': '玩家角色破级升至50级，登临不朽之巅。',
      'ja': 'プレイヤーレベル50に到達し、不滅の覇王となった証。',
      'ko': '플레이어 레벨 50에 도달하여 불멸의 제왕으로 등극했습니다.',
    },
    'trickshot_immortal': {
      'vi': 'Chinh phục từ 25 Thế Đánh Huyền Thoại của các huyền thoại thế giới.',
      'en': 'Mastered 25 world-famous trickshots to attain trickshot immortality.',
      'zh': '参悟通晓25项世界巅峰花式球，登顶花式台球至高神域。',
      'ja': '25の世界屈指のマスタートリックショットを極めた神域の証。',
      'ko': '25개의 세계 최고 트릭샷을 마스터하여 신역에 도달했습니다.',
    },
  };

  // =========================================================================
  // 10. ĐIỀU KIỆN MỞ KHÓA HUY CHƯƠNG (MEDAL REQUIREMENTS)
  // =========================================================================
  static const Map<String, Map<String, String>> medalRequirements = {
    // 1. ĐỒNG (BRONZE)
    'bronze_champion': {
      'vi': 'Chiến thắng trận đấu đầu tiên',
      'en': 'Win your first match',
      'zh': '获得第一场比赛胜利',
      'ja': '初マッチで勝利',
      'ko': '첫 경기 승리',
    },
    'bot_cadet': {
      'vi': 'Vượt qua ải 1 trong Chiến Dịch Bot',
      'en': 'Clear Stage 1 in Bot Campaign',
      'zh': '通过人机战役第1关',
      'ja': 'BOTキャンペーン第1ステージをクリア',
      'ko': '봇 캠페인 1단계 클리어',
    },
    'bot_fighter': {
      'vi': 'Vượt qua ải 3 trong Chiến Dịch Bot',
      'en': 'Clear Stage 3 in Bot Campaign',
      'zh': '通过人机战役第3关',
      'ja': 'BOTキャンペーン第3ステージをクリア',
      'ko': '봇 캠페인 3단계 클리어',
    },
    'tournament_quarter': {
      'vi': 'Vượt qua Bracket 2 của Tournament',
      'en': 'Pass Bracket 2 in Tournament',
      'zh': '通过锦标赛第2轮',
      'ja': '第2ブラケットを突破',
      'ko': '토너먼트 브래킷 2 통과',
    },
    'cue_apprentice': {
      'vi': 'Nâng cấp bất kỳ cây gậy nào lên Cấp 3',
      'en': 'Upgrade any cue to Level 3',
      'zh': '将任意球杆升级至3级',
      'ja': 'いずれかのキューをLv.3に強化',
      'ko': '아무 큐나 레벨 3으로 강화',
    },
    'trickshot_apprentice': {
      'vi': 'Hoàn thành 1 Thế Đánh Huyền Thoại',
      'en': 'Clear 1 Legendary Trickshot',
      'zh': '完成1个传奇大师残局',
      'ja': '伝説のトリックショットを1つクリア',
      'ko': '전설 트릭샷 1개 클리어',
    },
    'rising_star': {
      'vi': 'Đạt Cấp độ người chơi Lv.5 trở lên',
      'en': 'Reach player Level 5 or higher',
      'zh': '角色达到5级或以上',
      'ja': 'プレイヤーレベル5に到達',
      'ko': '플레이어 레벨 5 이상 달성',
    },
    'cue_collector_bronze': {
      'vi': 'Sở hữu từ 2 cây gậy cơ trở lên',
      'en': 'Own 2 or more cue sticks',
      'zh': '拥有至少2支球杆',
      'ja': '2本以上のキューを所持',
      'ko': '2개 이상의 큐 소유',
    },

    // 2. BẠC (SILVER)
    'tournament_semis': {
      'vi': 'Vượt qua Bracket 3 để tiến vào Bán Kết Tournament',
      'en': 'Pass Bracket 3 to enter Tournament Semi-Finals',
      'zh': '通过第3轮晋级锦标赛半决赛',
      'ja': '第3ブラケットを突破して準決勝へ進出',
      'ko': '브래킷 3을 통과하여 준결승 진출',
    },
    'wealthy_striker': {
      'vi': 'Tích lũy đạt trên 20.000 Vàng',
      'en': 'Accumulate over 20,000 Coins',
      'zh': '财富累计突破20,000金币',
      'ja': '所持金20,000コイン以上を達成',
      'ko': '누적 20,000 골드 이상 달성',
    },
    'bot_challenger': {
      'vi': 'Vượt qua ải 5 trong Chiến Dịch Bot',
      'en': 'Clear Stage 5 in Bot Campaign',
      'zh': '通过人机战役第5关',
      'ja': 'BOTキャンペーン第5ステージをクリア',
      'ko': '봇 캠페인 5단계 클리어',
    },
    'trickshot_virtuoso': {
      'vi': 'Hoàn thành 5 Thế Đánh Huyền Thoại',
      'en': 'Clear 5 Legendary Trickshots',
      'zh': '完成5个传奇大师残局',
      'ja': '伝説のトリックショットを5つクリア',
      'ko': '전설 트릭샷 5개 클리어',
    },
    'veteran_striker': {
      'vi': 'Đạt từ 15 trận thắng trở lên',
      'en': 'Achieve 15 or more match victories',
      'zh': '获得至少15场比赛胜利',
      'ja': '通算15勝以上を達成',
      'ko': '통산 15승 이상 달성',
    },
    'cue_artisan': {
      'vi': 'Nâng cấp bất kỳ cây gậy nào lên Cấp 4',
      'en': 'Upgrade any cue to Level 4',
      'zh': '将任意球杆升级至4级',
      'ja': 'いずれかのキューをLv.4に強化',
      'ko': '아무 큐나 레벨 4로 강화',
    },
    'silver_treasury': {
      'vi': 'Tích lũy đạt trên 50.000 Vàng',
      'en': 'Accumulate over 50,000 Coins',
      'zh': '财富累计突破50,000金币',
      'ja': '所持金50,000コイン以上を達成',
      'ko': '누적 50,000 골드 이상 달성',
    },
    'english_spin_master': {
      'vi': 'Sử dụng kỹ thuật xoáy bóng Áp-phê trong trận đấu',
      'en': 'Use English cue spin during a match',
      'zh': '在比赛中使用加塞旋转击球',
      'ja': '試合中にスピンショットを使用',
      'ko': '경기 중 스핀 샷 사용',
    },

    // 3. VÀNG (GOLD)
    'tournament_runner_up': {
      'vi': 'Lọt vào trận Chung Kết Bracket 5 của Tournament',
      'en': 'Reach the Grand Finals (Bracket 5) of Tournament',
      'zh': '打入锦标赛第5轮巅峰总决赛',
      'ja': '第5ブラケット決勝戦に進出',
      'ko': '토너먼트 브래킷 5 결승전 진출',
    },
    'sharpshooter': {
      'vi': 'Thực hiện chuỗi ăn Combo bi trong trận đấu',
      'en': 'Perform a ball combo pocket in a match',
      'zh': '在对局中达成目标球连击进袋',
      'ja': '試合中にボールコンボを成功させる',
      'ko': '경기 중 콤보 샷 성공',
    },
    'cue_master': {
      'vi': 'Nâng cấp bất kỳ cây gậy nào lên cấp 5+',
      'en': 'Upgrade any cue to Level 5 or higher',
      'zh': '将任意球杆升级至5级或以上',
      'ja': 'いずれかのキューをLv.5以上に強化',
      'ko': '아무 큐나 레벨 5 이상으로 강화',
    },
    'grandmaster': {
      'vi': 'Đạt Cấp độ người chơi Lv.10 trở lên',
      'en': 'Reach player Level 10 or higher',
      'zh': '达到玩家角色10级或以上',
      'ja': 'プレイヤーレベル10に到達',
      'ko': '플레이어 레벨 10 이상 달성',
    },
    'undefeated_spree': {
      'vi': 'Giành từ 5 trận thắng liên tiếp',
      'en': 'Achieve a win streak of 5 matches',
      'zh': '取得5连胜战绩',
      'ja': '5連勝を達成',
      'ko': '5연승 달성',
    },
    'centurion_victor': {
      'vi': 'Đạt từ 30 trận thắng trở lên',
      'en': 'Achieve 30 or more match victories',
      'zh': '获得至少30场比赛胜利',
      'ja': '通算30勝以上を達成',
      'ko': '통산 30승 이상 달성',
    },
    'cue_collector_gold': {
      'vi': 'Sở hữu từ 4 cây gậy cơ trở lên',
      'en': 'Own 4 or more cue sticks',
      'zh': '拥有至少4支球杆',
      'ja': '4本以上のキューを所持',
      'ko': '4개 이상의 큐 소유',
    },
    'master_duel_victor': {
      'vi': 'Vượt qua ải 8 trong Chiến Dịch Bot',
      'en': 'Clear Stage 8 in Bot Campaign',
      'zh': '通过人机战役第8关',
      'ja': 'BOTキャンペーン第8ステージをクリア',
      'ko': '봇 캠페인 8단계 클리어',
    },
    'golden_treasury': {
      'vi': 'Tích lũy đạt trên 100.000 Vàng',
      'en': 'Accumulate over 100,000 Coins',
      'zh': '财富累计突破100,000金币',
      'ja': '所持金100,000コイン以上を達成',
      'ko': '누적 100,000 골드 이상 달성',
    },
    'profile_perfection': {
      'vi': 'Ghim đủ 5 Huy Chương trên Profile',
      'en': 'Pin all 5 Medals on your Profile',
      'zh': '在个人资料上挂满5枚勋章',
      'ja': 'プロフィールに5つのメダルをピン留め',
      'ko': '프로필에 메달 5개 고정',
    },

    // 4. KIM CƯƠNG (DIAMOND)
    'trickshot_master': {
      'vi': 'Chiến thắng chế độ Thế Bi Hàng Ngày',
      'en': 'Clear Daily Puzzle Mode',
      'zh': '通关每日残局挑战模式',
      'ja': 'デイリーパズルモードをクリア',
      'ko': '일일 퍼즐 모드 클리어',
    },
    'bot_slayer': {
      'vi': 'Vượt qua ải 7 trong Chiến Dịch Bot',
      'en': 'Clear Stage 7 in Bot Campaign',
      'zh': '通过人机战役第7关',
      'ja': 'BOTキャンペーン第7ステージをクリア',
      'ko': '봇 캠페인 7단계 클리어',
    },
    'bot_annihilator': {
      'vi': 'Vượt qua ải 9 trong Chiến Dịch Bot',
      'en': 'Clear Stage 9 in Bot Campaign',
      'zh': '通过人机战役第9关',
      'ja': 'BOTキャンペーン第9ステージをクリア',
      'ko': '봇 캠페인 9단계 클리어',
    },
    'trickshot_legend': {
      'vi': 'Hoàn thành 10 Thế Đánh Huyền Thoại',
      'en': 'Clear 10 Legendary Trickshots',
      'zh': '完成10个传奇大师残局',
      'ja': '伝説のトリックショットを10個クリア',
      'ko': '전설 트릭샷 10개 클리어',
    },
    'cue_god_forge': {
      'vi': 'Nâng cấp bất kỳ cây gậy nào lên Cấp tối đa (Level 10)',
      'en': 'Upgrade any cue to max level (Level 10)',
      'zh': '将任意球杆升至满级 (10级)',
      'ja': 'いずれかのキューを最大Lv.10まで強化',
      'ko': '아무 큐나 최대 레벨(레벨 10)까지 강화',
    },
    'hall_of_fame': {
      'vi': 'Đạt Cấp độ người chơi Lv.25 trở lên',
      'en': 'Reach player Level 25 or higher',
      'zh': '达到角色25级或以上',
      'ja': 'プレイヤーレベル25に到達',
      'ko': '플레이어 레벨 25 이상 달성',
    },
    'legendary_champion': {
      'vi': 'Đạt từ 75 trận thắng trở lên',
      'en': 'Achieve 75 or more match victories',
      'zh': '获得至少75场比赛胜利',
      'ja': '通算75勝以上を達成',
      'ko': '통산 75승 이상 달성',
    },
    'diamond_royalty': {
      'vi': 'Tích lũy đạt trên 100 Kim Cương',
      'en': 'Accumulate over 100 Diamonds',
      'zh': '累计积攒100颗以上钻石',
      'ja': 'ダイヤ100個以上を蓄積',
      'ko': '다이아몬드 100개 이상 달성',
    },

    // 5. THẦN THOẠI (MYTHIC)
    'tournament_champion': {
      'vi': 'Vô địch chế độ Giải Đấu Tournament 5 Brackets',
      'en': 'Win the 5-Bracket Tournament Championship',
      'zh': '夺得5轮巡回锦标赛总冠军',
      'ja': '全5ブラケットトーナメントで優勝',
      'ko': '5강 토너먼트 대회 우승',
    },
    'tournament_dynasty': {
      'vi': 'Vô địch Tournament từ 3 lần trở lên',
      'en': 'Win Tournament Championship 3 or more times',
      'zh': '夺得3次以上锦标赛总冠军',
      'ja': 'トーナメント優勝を3回以上達成',
      'ko': '토너먼트 대회 우승 3회 이상',
    },
    'bot_overlord': {
      'vi': 'Vượt qua trọn vẹn Ải 10 Bot Campaign',
      'en': 'Clear Stage 10 in Bot Campaign',
      'zh': '完全通关人机战役第10关',
      'ja': 'BOTキャンペーン第10ステージを完全制覇',
      'ko': '봇 캠페인 10단계 완전 정복',
    },
    'cue_collector_mythic': {
      'vi': 'Sở hữu trọn bộ 7 cây gậy cơ',
      'en': 'Own all 7 cue sticks',
      'zh': '拥有全部7支球杆',
      'ja': '全7本のキューを所持',
      'ko': '모든 7개 큐 소유',
    },
    'immortal_sovereign': {
      'vi': 'Đạt Cấp độ người chơi Lv.50 trở lên',
      'en': 'Reach player Level 50 or higher',
      'zh': '达到玩家角色50级或以上',
      'ja': 'プレイヤーレベル50に到達',
      'ko': '플레이어 레벨 50 이상 달성',
    },
    'trickshot_immortal': {
      'vi': 'Hoàn thành 25 Thế Đánh Huyền Thoại',
      'en': 'Clear 25 Legendary Trickshots',
      'zh': '完成25个传奇大师残局',
      'ja': '伝説のトリックショットを25個クリア',
      'ko': '전설 트릭샷 25개 클리어',
    },
  };

  // =========================================================================
  // 11. PHẨM CẤP HUY CHƯƠNG (MEDAL RARITY)
  // =========================================================================
  static const Map<String, Map<String, String>> medalRarities = {
    'bronze': {
      'vi': 'Đồng',
      'en': 'Bronze',
      'zh': '青铜',
      'ja': 'ブロンズ',
      'ko': '브론즈',
    },
    'silver': {
      'vi': 'Bạc',
      'en': 'Silver',
      'zh': '白银',
      'ja': 'シルバー',
      'ko': '실버',
    },
    'gold': {
      'vi': 'Vàng',
      'en': 'Gold',
      'zh': '黄金',
      'ja': 'ゴールド',
      'ko': '골드',
    },
    'diamond': {
      'vi': 'Kim Cương',
      'en': 'Diamond',
      'zh': '钻石',
      'ja': 'ダイヤ',
      'ko': '다이아몬드',
    },
    'mythic': {
      'vi': 'Thần Thoại',
      'en': 'Mythic',
      'zh': '神话',
      'ja': 'ミシック',
      'ko': '신화',
    },
  };

  // =========================================================================
  // 12. DIỄN GIẢI ĐIỂM XOÁY BI CÁI (SPIN DESCRIPTION)
  // =========================================================================
  static String describeSpin(Offset spin, String lang) {
    if (spin.distance < 0.08) {
      return switch (lang) {
        'en' => 'Center ball (No spin)',
        'zh' => '球心 (标准击球, 无旋转)',
        'ja' => '中心 (無回転)',
        'ko' => '수구 중심 (무회전)',
        _ => 'Tâm bi (Đánh thường, không xoáy)',
      };
    }
    final parts = <String>[];
    if (spin.dy < -0.15) {
      final p = (-spin.dy * 100).round();
      final text = switch (lang) {
        'en' => 'Follow (Top) $p%',
        'zh' => '高杆推杆 $p%',
        'ja' => 'トップスピン $p%',
        'ko' => '상단 밀어치기 $p%',
        _ => 'Cu-lê $p%',
      };
      parts.add(text);
    } else if (spin.dy > 0.15) {
      final p = (spin.dy * 100).round();
      final text = switch (lang) {
        'en' => 'Draw (Bottom) $p%',
        'zh' => '低杆拉杆 $p%',
        'ja' => 'ドロースピン $p%',
        'ko' => '하단 끌어치기 $p%',
        _ => 'Trô bóng $p%',
      };
      parts.add(text);
    }
    if (spin.dx < -0.15) {
      final p = (-spin.dx * 100).round();
      final text = switch (lang) {
        'en' => 'Left English $p%',
        'zh' => '左加塞 $p%',
        'ja' => '左スピン $p%',
        'ko' => '좌측 회전 $p%',
        _ => 'Áp-phê Trái $p%',
      };
      parts.add(text);
    } else if (spin.dx > 0.15) {
      final p = (spin.dx * 100).round();
      final text = switch (lang) {
        'en' => 'Right English $p%',
        'zh' => '右加塞 $p%',
        'ja' => '右スピン $p%',
        'ko' => '우측 회전 $p%',
        _ => 'Áp-phê Phải $p%',
      };
      parts.add(text);
    }
    if (parts.isEmpty) {
      return switch (lang) {
        'en' => 'Near center',
        'zh' => '接近球心',
        'ja' => '中心付近',
        'ko' => '중심 근처',
        _ => 'Gần tâm bi',
      };
    }
    return parts.join(' • ');
  }

  static String getCueName(String id, String lang, [String fallback = '']) {
    return cueNames[id]?[lang] ?? cueNames[id]?['en'] ?? cueNames[id]?['vi'] ?? fallback;
  }

  static String getCueDescription(String id, String lang, [String fallback = '']) {
    return cueDescriptions[id]?[lang] ?? cueDescriptions[id]?['en'] ?? cueDescriptions[id]?['vi'] ?? fallback;
  }

  static String getCuePerk(String id, String lang, [String fallback = '']) {
    return cuePerks[id]?[lang] ?? cuePerks[id]?['en'] ?? cuePerks[id]?['vi'] ?? fallback;
  }

  static String getCueRarity(String key, String lang, [String fallback = '']) {
    return cueRarities[key]?[lang] ?? cueRarities[key]?['en'] ?? cueRarities[key]?['vi'] ?? fallback;
  }

  static String getAchievementTitle(String id, String lang, [String fallback = '']) {
    return achievementTitles[id]?[lang] ?? achievementTitles[id]?['en'] ?? achievementTitles[id]?['vi'] ?? fallback;
  }

  static String getAchievementDescription(String id, String lang, [String fallback = '']) {
    return achievementDescriptions[id]?[lang] ?? achievementDescriptions[id]?['en'] ?? achievementDescriptions[id]?['vi'] ?? fallback;
  }

  static String getAchievementDifficulty(String key, String lang, [String fallback = '']) {
    return achievementDifficulties[key]?[lang] ?? achievementDifficulties[key]?['en'] ?? achievementDifficulties[key]?['vi'] ?? fallback;
  }

  static String getMedalName(String id, String lang, [String fallback = '']) {
    return medalNames[id]?[lang] ?? medalNames[id]?['en'] ?? medalNames[id]?['vi'] ?? fallback;
  }

  static String getMedalDescription(String id, String lang, [String fallback = '']) {
    return medalDescriptions[id]?[lang] ?? medalDescriptions[id]?['en'] ?? medalDescriptions[id]?['vi'] ?? fallback;
  }

  static String getMedalRequirement(String id, String lang, [String fallback = '']) {
    return medalRequirements[id]?[lang] ?? medalRequirements[id]?['en'] ?? medalRequirements[id]?['vi'] ?? fallback;
  }

  // =========================================================================
  // 13. PHẨM CẤP BÀN BIDA (TABLE RARITY)
  // =========================================================================
  static const Map<String, Map<String, String>> tableRarities = {
    'standard': {
      'vi': 'Tiêu Chuẩn',
      'en': 'Standard',
      'zh': '标准',
      'ja': '標準',
      'ko': '표준',
    },
    'rare': {
      'vi': 'Hiếm',
      'en': 'Rare',
      'zh': '稀有',
      'ja': 'レア',
      'ko': '희귀',
    },
    'epic': {
      'vi': 'Sử Thi',
      'en': 'Epic',
      'zh': '史诗',
      'ja': 'エピック',
      'ko': '에픽',
    },
    'legendary': {
      'vi': 'Huyền Thoại',
      'en': 'Legendary',
      'zh': '传奇',
      'ja': 'レジェンド',
      'ko': '전설',
    },
    'mythic': {
      'vi': 'Thần Thoại',
      'en': 'Mythic',
      'zh': '神话',
      'ja': 'ミシック',
      'ko': '신화',
    },
  };

  static String getTableRarity(String key, String lang, [String fallback = '']) {
    return tableRarities[key]?[lang] ?? tableRarities[key]?['en'] ?? tableRarities[key]?['vi'] ?? fallback;
  }

  static String getMedalRarity(String key, String lang, [String fallback = '']) {
    return medalRarities[key]?[lang] ?? medalRarities[key]?['en'] ?? medalRarities[key]?['vi'] ?? fallback;
  }

  // ================= 20 BÀN BIDA (TABLE SKINS) =================
  static const Map<String, Map<String, String>> tableSkinNames = {
    'classic_green': {
      'vi': 'Bàn Nỉ Xanh Cổ Điển',
      'en': 'Classic Green Felt',
      'zh': '经典绿呢台面',
      'ja': 'クラシックグリーン台',
      'ko': '클래식 그린 당구대',
    },
    'royal_navy': {
      'vi': 'Hải Quân Hoàng Gia',
      'en': 'Royal Navy Felt',
      'zh': '皇家海军蓝台面',
      'ja': 'ロイヤルネイビー台',
      'ko': '로열 네이비 당구대',
    },
    'crimson_velvet': {
      'vi': 'Nhung Đỏ Quý Tộc',
      'en': 'Crimson Velvet',
      'zh': '贵族绯红丝绒',
      'ja': 'クリムゾンベルベット',
      'ko': '크림슨 벨벳 당구대',
    },
    'sand_dune': {
      'vi': 'Bão Cát Sa Mạc',
      'en': 'Desert Sand Dune',
      'zh': '沙漠沙丘',
      'ja': 'デザートサンド',
      'ko': '데저트 샌드 당구대',
    },
    'emerald_master': {
      'vi': 'Ngọc Lục Bảo Đại Sư',
      'en': 'Emerald Master',
      'zh': '宗师祖母绿',
      'ja': 'エメラルドマスター',
      'ko': '에메랄드 마스터',
    },
    'midnight_shadow': {
      'vi': 'Bóng Đêm Huyền Bí',
      'en': 'Midnight Shadow',
      'zh': '午夜幽影',
      'ja': 'ミッドナイトシャドウ',
      'ko': '미드나잇 섀도우',
    },
    'sakura_blossom': {
      'vi': 'Hoa Anh Đào Nhật Bản',
      'en': 'Sakura Blossom',
      'zh': '东瀛樱花',
      'ja': '桜吹雪',
      'ko': '사쿠라 블라썸',
    },
    'copper_vintage': {
      'vi': 'Đồng Đỏ Cổ Điển',
      'en': 'Vintage Copper',
      'zh': '复古古铜',
      'ja': 'ヴィンテージカッパー',
      'ko': '빈티지 코퍼 당구대',
    },
    'cyber_neon': {
      'vi': 'Cyber Neon 2077',
      'en': 'Cyber Neon 2077',
      'zh': '赛博霓虹 2077',
      'ja': 'サイバーネオン 2077',
      'ko': '사이버 네온 2077',
    },
    'volcanic_magma': {
      'vi': 'Dung Nham Núi Lửa',
      'en': 'Volcanic Magma',
      'zh': '火山熔岩',
      'ja': 'ヴォルカニックマグマ',
      'ko': '볼케이노 마그마',
    },
    'amethyst_galaxy': {
      'vi': 'Tinh Vân Thạch Anh',
      'en': 'Amethyst Galaxy',
      'zh': '紫晶星系',
      'ja': 'アメジストギャラクシー',
      'ko': '아메시스트 갤럭시',
    },
    'electric_violet': {
      'vi': 'Tia Sét Tím',
      'en': 'Electric Violet',
      'zh': '电光紫刃',
      'ja': 'エレクトリックバイオレット',
      'ko': '일렉트릭 바이올렛',
    },
    'carbon_stealth': {
      'vi': 'Carbon Tàng Hình',
      'en': 'Stealth Carbon',
      'zh': '隐形碳纤',
      'ja': 'ステルスカーボン',
      'ko': '스텔스 카본 당구대',
    },
    'ice_glacier': {
      'vi': 'Băng Giá Bắc Cực',
      'en': 'Arctic Glacier',
      'zh': '极地冰川',
      'ja': 'アークティックグレイシャー',
      'ko': '아틱 글래시어',
    },
    'ruby_royale': {
      'vi': 'Hồng Ngọc Hoàng Tộc',
      'en': 'Ruby Royale',
      'zh': '皇家红宝',
      'ja': 'ルビーロワイヤル',
      'ko': '루비 로열 당구대',
    },
    'golden_luxury': {
      'vi': 'Hoàng Kim Vạn Lượng',
      'en': 'Golden Luxury',
      'zh': '万两黄金',
      'ja': 'ゴールデンラグジュアリー',
      'ko': '골든 럭셔리 당구대',
    },
    'jade_dynasty': {
      'vi': 'Hoàng Triều Ngọc Bích',
      'en': 'Jade Dynasty',
      'zh': '翡翠皇朝',
      'ja': '翡翠の王朝',
      'ko': '비취 왕조 당구대',
    },
    'phantom_black': {
      'vi': 'Bóng Ma Hư Vô',
      'en': 'Phantom Void',
      'zh': '虚空幽灵',
      'ja': 'ファントムヴォイド',
      'ko': '팬텀 보이드 당구대',
    },
    'dragon_emperor': {
      'vi': 'Long Hoàng Bá Chủ',
      'en': 'Dragon Emperor',
      'zh': '龙皇霸主',
      'ja': '龍皇覇王',
      'ko': '용황 패왕 당구대',
    },
    'celestial_olympus': {
      'vi': 'Đỉnh Cao Olympus',
      'en': 'Celestial Olympus',
      'zh': '奥林匹斯之巅',
      'ja': 'セレスティアルオリンポス',
      'ko': '천상의 올림푸스',
    },
  };

  static const Map<String, Map<String, String>> tableSkinDescriptions = {
    'classic_green': {
      'vi': 'Bàn nỉ xanh truyền thống chuẩn thi đấu quốc tế với viền gỗ mun trầm ấm.',
      'en': 'Traditional tournament-standard green cloth with warm ebony rails.',
      'zh': '国际赛事标准传统绿呢，搭配温润沉稳的黑檀木边框。',
      'ja': '国際大会基準の伝統的グリーンラシャと重厚な黒檀レール。',
      'ko': '따뜻한 흑단 레일과 국제 대회 표준의 전통 녹색 나사천.',
    },
    'royal_navy': {
      'vi': 'Vải nỉ xanh Navy hoàng gia sang trọng kết hợp thành băng gỗ gụ và điểm ngắm bạc.',
      'en': 'Luxurious royal navy cloth paired with rich mahogany rails and silver sights.',
      'zh': '奢华皇家海军蓝台呢，配以名贵红木库边与纯银瞄准点。',
      'ja': '重厚なマホガニーレールと銀の照準点を備えた高貴なネイビーラシャ。',
      'ko': '고급스러운 마호가니 레일과 은색 조준점이 어우러진 네이비 나사천.',
    },
    'crimson_velvet': {
      'vi': 'Nỉ nhung đỏ thắm cao cấp phong cách quý tộc châu Âu với giác cắt vàng kim rực rỡ.',
      'en': 'Aristocratic crimson velvet cloth with brilliant gold-plated corner castings.',
      'zh': '欧洲贵族级高级深红丝绒台呢，镶嵌璀璨夺目的金边包角。',
      'ja': '輝く金メッキコーナーを備えた欧州貴族風の深紅ベルベットラシャ。',
      'ko': '화려한 금빛 코너 마감과 유럽 귀족풍의 깊은 진홍색 벨벳 나사천.',
    },
    'sand_dune': {
      'vi': 'Sắc vàng cát sa mạc ấm cúng cùng thành băng gỗ thông tuyết mộc mạc và đinh tán đồng.',
      'en': 'Warm golden desert sands cloth with rustic pine rails and bronze rivets.',
      'zh': '温暖的沙漠金沙色台呢，搭配质朴雪松木库边与青铜铆钉。',
      'ja': '素朴な松木レールと青銅リベットを備えた温かみのある砂漠色ラシャ。',
      'ko': '소박한 소나무 레일과 청동 리벳이 어우러진 따뜻한 모래빛 나사천.',
    },
    'emerald_master': {
      'vi': 'Màu xanh lục bảo lấp lánh phản chiếu hào quang của các bậc thầy bi-a thế giới.',
      'en': 'Gleaming emerald green felt radiating the aura of world pool masters.',
      'zh': '璀璨祖母绿宝石色台呢，折射出世界级台球宗师的威严光环。',
      'ja': '世界最高峰のマスターの風格を放つ輝くエメラルドラシャ。',
      'ko': '세계적인 당구 거장의 아우라를 뿜어내는 에메랄드빛 나사천.',
    },
    'midnight_shadow': {
      'vi': 'Tông màu xám than chì huyền ảo với viền carbon đen mờ và điểm ngắm xanh cyan.',
      'en': 'Mystic charcoal graphite cloth with matte black carbon rails and cyan sights.',
      'zh': '玄奥石墨炭灰台呢，配以哑光黑色碳纤维库边与青色瞄准点。',
      'ja': 'マットブラックカーボンレールとシアンサイトを備えた神秘的な木炭色。',
      'ko': '무광 블랙 카본 레일과 시안색 조준점이 돋보이는 흑연색 나사천.',
    },
    'sakura_blossom': {
      'vi': 'Sắc hồng cánh hoa anh đào dịu dàng kết hợp gỗ anh đào sáng và hoa văn phương Đông.',
      'en': 'Gentle cherry blossom petal pink felt with light cherry rails and oriental accents.',
      'zh': '柔美温柔的粉樱台呢，融汇明亮樱花木框与典雅东方韵味。',
      'ja': '淡い桜色のラシャに明るい桜材レールと和風の気品を融合。',
      'ko': '화사한 벚꽃 핑크 나사천과 밝은 벚나무 레일의 동양적인 미.',
    },
    'copper_vintage': {
      'vi': 'Vải nỉ màu đồng đỏ cổ kính đậm chất hoài niệm với góc bàn ốp đồng tán đinh thủ công.',
      'en': 'Nostalgic antique copper cloth with handcrafted hammered brass corner plates.',
      'zh': '怀旧沉稳的古铜红台呢，点缀手工锻打铜质包角与复古皮革。',
      'ja': '手打ち真鍮コーナープレートを備えたノスタルジックな赤銅色ラシャ。',
      'ko': '수작업 단조 황동 코너와 향수를 자극하는 앤틱 구릿빛 나사천.',
    },
    'cyber_neon': {
      'vi': 'Bàn thi đấu phong cách tương lai với các dải phát quang neon xanh lơ và tím rực rỡ.',
      'en': 'Futuristic high-tech table with pulsing electric cyan and magenta neon grids.',
      'zh': '未来主义高科技台面，流转着脉冲青蓝与赛博洋红的绚烂霓虹。',
      'ja': '脈動するシアンとマゼンタのネオングリッドを宿した未来型テーブル。',
      'ko': '청록색과 마젠타 네온 그리드가 번쩍이는 미래형 사이버 당구대.',
    },
    'volcanic_magma': {
      'vi': 'Mặt bàn rực lửa nham thạch với sắc đỏ cam bốc khói cùng thành bàn đá bazan đen.',
      'en': 'Scorching fiery magma orange cloth framed with charred black basalt rails.',
      'zh': '滚烫炽热的橙红熔岩台呢，伴以焦黑玄武岩边框与炽热余烬。',
      'ja': '黒曜石レールに縁取られた灼熱のオレンジレッド溶岩ラシャ。',
      'ko': '검은 현무암 레일로 둘러싸인 이글거리는 오렌지빛 용암 나사천.',
    },
    'amethyst_galaxy': {
      'vi': 'Sắc tím tinh vân huyền ảo đưa bạn vào không gian vũ trụ sâu thẳm đầy mê hoặc.',
      'en': 'Enchanting celestial violet nebula cloth taking you into the cosmic abyss.',
      'zh': '摄人心魄的宇宙紫晶星云台呢，仿佛置身无垠星空与璀璨星河。',
      'ja': '深淵なる宇宙へと誘う魅惑の紫水晶ネビュララシャ。',
      'ko': '끝없는 우주의 심연으로 빠져드는 몽환적인 자수정 성운 나사천.',
    },
    'electric_violet': {
      'vi': 'Năng lượng điện trường tím sẫm chớp nhoáng với thành bàn mạ crom phản chiếu sắc sảo.',
      'en': 'Surging deep violet plasma cloth surrounded by gleaming sharp chrome rails.',
      'zh': '深紫电浆高能充盈的电弧台面，搭配冷冽锐利的镜面镀铬库边。',
      'ja': '鋭いクロムレールに囲まれた深紫のプラズマ放電ラシャ。',
      'ko': '날카로운 크롬 레일과 강력한 보랏빛 플라스마 에너지가 흐르는 나사천.',
    },
    'carbon_stealth': {
      'vi': 'Sợi carbon dệt đan siêu nhẹ phủ toàn bộ khung bàn cùng họa tiết hình học tinh tế.',
      'en': 'Ultralight woven carbon fiber composite frame with geometric tactical textures.',
      'zh': '超轻碳纤维交织高科技台架，辅以隐形战术几何微纹理。',
      'ja': '幾何学テクスチャを施した超軽量織り込みカーボン複合フレーム。',
      'ko': '기하학적 텍스처와 초경량 우븐 카본 파이버 복합 프레임.',
    },
    'ice_glacier': {
      'vi': 'Mặt bàn trắng ngọc băng giá như hồ nước đóng băng ngàn năm tại cực bắc địa cầu.',
      'en': 'Arctic glacier ice cloth resembling a pristine ancient frozen polar lake.',
      'zh': '晶莹透彻的极地冰蓝台面，如同北极万年不化的纯净冰封圣湖。',
      'ja': '北極の太古の氷結湖を思わせる透明感ある氷藍色の氷河ラシャ。',
      'ko': '북극의 태고적 얼음 호수처럼 투명하고 시원한 빙하빛 나사천.',
    },
    'ruby_royale': {
      'vi': 'Sắc đỏ hồng ngọc lấp lánh như vương miện hoàng gia với thành bàn gỗ trắc chạm khảm.',
      'en': 'Glistening imperial ruby red cloth with intricately inlaid rosewood rails.',
      'zh': '如帝王冠冕般璀璨耀眼的红宝石台呢，辅以精雕细琢的黄花梨木边。',
      'ja': '象嵌細工のローズウッドレールを備えた王冠のごとく輝く紅玉ラシャ。',
      'ko': '상감 로즈우드 레일과 왕관처럼 눈부시게 빛나는 루비빛 나사천.',
    },
    'golden_luxury': {
      'vi': 'Vải nỉ dệt ánh kim champagne lộng lẫy và thành băng dát vàng 24K quyền lực tối thượng.',
      'en': 'Opulent champagne gold shimmering cloth with sovereign 24K gold-plated rails.',
      'zh': '尊贵香槟金流光溢彩织锦台呢，镶嵌至尊24K纯金镀层库边。',
      'ja': '至高の24金メッキレールを纏った煌びやかなシャンパンゴールドラシャ。',
      'ko': '압도적인 24K 순금 도금 레일과 화려한 샴페인 골드빛 나사천.',
    },
    'jade_dynasty': {
      'vi': 'Ngọc bích hoàng gia thuần khiết kết hợp thành băng gỗ tử đàn khảm rồng vàng quyền quý.',
      'en': 'Pure imperial emerald jade cloth bordered by red sandalwood with gold dragon motifs.',
      'zh': '温润无瑕的至尊皇家翡翠台面，嵌合名贵小叶紫檀与金龙图腾。',
      'ja': '金龍の意匠を施した紫檀レールと純白無瑕の宮廷翡翠ラシャ。',
      'ko': '금룡 문양 자단목 레일과 순수하고 고귀한 황실 비취빛 나사천.',
    },
    'phantom_black': {
      'vi': 'Mặt nỉ đen huyền ảo tuyệt đối hấp thụ ánh sáng, chỉ để lại viền sáng tím ma mị.',
      'en': 'Absolute abyssal obsidian black cloth absorbing all light with ethereal violet aura.',
      'zh': '吞噬一切光线的纯黑虚空台面，唯留边缘若隐若现的空灵紫晕。',
      'ja': 'すべての光を吸い込む極黒ラシャに漂う妖艶な紫のオーラ。',
      'ko': '모든 빛을 흡수하는 절대 흑요석 나사천과 은은한 보랏빛 오라.',
    },
    'dragon_emperor': {
      'vi': 'Vảy rồng uy nghiêm khắc nổi trên nền lụa đỏ thẫm với năng lượng rồng cuộn bảo hộ.',
      'en': 'Imperial dragon scale relief across blood-crimson silk with coiled dragon energy.',
      'zh': '浴血深红锦缎上盘卧神龙鳞纹，激荡着吞吐天地的霸皇真龙之气。',
      'ja': '血紅の絹地に刻まれた威厳ある龍鱗と天を統べる覇気のテーブル。',
      'ko': '붉은 비단 위로 용의 비늘이 새겨진 패왕의 기운이 깃든 당구대.',
    },
    'celestial_olympus': {
      'vi': 'Đỉnh Cao Olympus',
      'en': 'Celestial Olympus',
      'zh': '奥林匹斯之巅',
      'ja': 'セレスティアルオリンポス',
      'ko': '천상의 올림푸스',
    },
  };

  static String getTableSkinName(String id, String lang, [String fallback = '']) {
    return tableSkinNames[id]?[lang] ?? tableSkinNames[id]?['en'] ?? tableSkinNames[id]?['vi'] ?? fallback;
  }

  static String getTableSkinDescription(String id, String lang, [String fallback = '']) {
    return tableSkinDescriptions[id]?[lang] ?? tableSkinDescriptions[id]?['en'] ?? tableSkinDescriptions[id]?['vi'] ?? fallback;
  }
}

