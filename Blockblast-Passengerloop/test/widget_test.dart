import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:block_odyssey_pet_express/main.dart';
import 'package:block_odyssey_pet_express/ui/painters/board_25d_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'settings_bgm_enabled': false});
    const audioChannel = MethodChannel('xyz.luan/audioplayers');
    const globalAudioChannel = MethodChannel('xyz.luan/audioplayers.global');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(globalAudioChannel, (call) async => null);
  });

  testWidgets('Commercial 4-Tab Main Shell renders all 4 tabs cleanly on 360x780 mobile', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BlockOdysseyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 4 Bottom Navigation Tabs
    expect(find.text('Cửa Hàng'), findsOneWidget);
    expect(find.text('Bản Đồ'), findsOneWidget);
    expect(find.text('Đảo Thú'), findsOneWidget);
    expect(find.text('Đua Top'), findsOneWidget);

    // Tab 1: Saga World Map shows Chapter 1 and Level 1 node
    expect(find.textContaining('Công Viên Nắng Ấm'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // Tab 0: Cửa Hàng & Kho Skin
    await tester.tap(find.text('Cửa Hàng'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('CỬA HÀNG & KHO SKIN'), findsOneWidget);
    expect(find.text('Thú Cưng Kawaii'), findsOneWidget);
    expect(find.text('Thạch Rau Câu Jelly'), findsOneWidget);

    // Tab 2: Đảo Thú Cưng 2.5D
    await tester.tap(find.text('Đảo Thú'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('Thu hoạch Xu thụ động'), findsOneWidget);

    // Tab 3: Đua Top & Daily Quests
    await tester.tap(find.text('Đua Top'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('ĐUA TOP GIỜ CAO ĐIỂM'), findsOneWidget);
    expect(find.text('Đón 10 xe Corgi Đỏ'), findsOneWidget);
    expect(find.text('Đạt Combo x4!'), findsOneWidget);
    expect(find.text('Phá 15 ô Băng Giá'), findsOneWidget);
  });

  testWidgets('GamePlayScreen supports PauseModal, ? Guide, Skip FTUE & 3 Toy tray blocks on 360x780', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BlockOdysseyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap Level 1 node on Saga Map
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify 3 Toy blocks in Next tray
    var trayShapes = tester.widgetList<CustomPaint>(find.byType(CustomPaint)).where(
      (cp) => cp.painter is PolyominoShape25DPainter,
    );
    expect(trayShapes.length, equals(3));

    // Tap Pause button -> PauseModal appears with BGM/SFX/Haptics
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nhạc nền (BGM)'), findsOneWidget);
    expect(find.text('Âm thanh hiệu ứng (SFX)'), findsOneWidget);
    expect(find.text('Rung xúc giác (Haptics)'), findsOneWidget);

    await tester.tap(find.text('TIẾP TỤC CHƠI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Tap '?' button to view FTUE Tutorial Overlay and then Skip FTUE
    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Bỏ qua hướng dẫn (Skip FTUE)'), findsOneWidget);

    await tester.tap(find.text('Bỏ qua hướng dẫn (Skip FTUE)'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bỏ qua hướng dẫn (Skip FTUE)'), findsNothing);
    trayShapes = tester.widgetList<CustomPaint>(find.byType(CustomPaint)).where(
      (cp) => cp.painter is PolyominoShape25DPainter,
    );
    expect(trayShapes.length, equals(3));
  });
}
