import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bida_game/services/auth_service.dart';
import 'package:bida_game/services/language_service.dart';
import 'package:bida_game/ui/auth_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LanguageService.instance.setLanguage(AppLanguage.vi);
  });

  group('SpecKit Bug Fix Tests [login-crash]: Empty Password Safety', () {
    test('Unit Test: AuthService.login with empty password returns validation error without throwing', () async {
      final auth = AuthService.instance;

      // 1. Empty string password
      final errorEmpty = await auth.login(
        emailOrUsername: 'player01',
        password: '',
      );
      expect(errorEmpty, equals('auth_fill_account_pass'.tr));
      expect(auth.isLoading, isFalse);

      // 2. Whitespace-only password
      final errorWhitespace = await auth.login(
        emailOrUsername: 'player01',
        password: '    ',
      );
      expect(errorWhitespace, equals('auth_fill_account_pass'.tr));
      expect(auth.isLoading, isFalse);

      // 3. Both empty
      final errorBothEmpty = await auth.login(
        emailOrUsername: '',
        password: '',
      );
      expect(errorBothEmpty, equals('auth_fill_account_pass'.tr));
      expect(auth.isLoading, isFalse);
    });

    testWidgets('Widget Test: Submitting empty or whitespace password on AuthScreen shows error banner without crashing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1000, 600));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find username and password text fields
      final accountField = find.byKey(const ValueKey('login_account_field'));
      final passwordField = find.byKey(const ValueKey('login_password_field'));
      expect(accountField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      // Case 1: Enter account but leave password empty, then tap login button
      await tester.enterText(accountField, 'cool_player_99');
      await tester.pumpAndSettle();

      final loginBtn = find.text('enter_table'.tr);
      expect(loginBtn, findsOneWidget);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // Verify validation error message is rendered without crashing
      final expectedError = 'auth_fill_account_pass'.tr;
      expect(find.text(expectedError), findsOneWidget);

      // Case 2: Enter whitespace-only password, then submit
      await tester.enterText(passwordField, '     ');
      await tester.pumpAndSettle();

      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // Verify still displays validation error cleanly and does not crash
      expect(find.text(expectedError), findsOneWidget);
    });
  });
}
