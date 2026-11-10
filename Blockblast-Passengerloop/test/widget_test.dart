import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:block_odyssey_pet_express/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    const audioChannel = MethodChannel('xyz.luan/audioplayers');
    const globalAudioChannel = MethodChannel('xyz.luan/audioplayers.global');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(audioChannel, (call) async => null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(globalAudioChannel, (call) async => null);
  });

  testWidgets('BlockOdysseyApp renders cleanly on mobile portrait 360x780 without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const BlockOdysseyApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('BLOCK ODYSSEY'), findsOneWidget);
    expect(find.text('Bản Đồ 200 Màn'), findsOneWidget);
    expect(find.text('Đảo Thú Cưng'), findsOneWidget);
    expect(find.text('Đua Xe Buýt'), findsOneWidget);

    // Verify tapping Level 1 opens GamePlayScreen cleanly on mobile
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('BÚA'), findsNothing); // Canvas/skill buttons check
    expect(find.text('SẴN SÀNG'), findsNothing); // Starting charges are 0 without streak
    expect(find.text('0/3'), findsOneWidget); // Hammer charge UI
    expect(find.text('0/2'), findsOneWidget); // Compass charge UI
  });
}
