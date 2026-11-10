import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/main_menu_screen.dart';
import 'ui/screens/game_play_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  runApp(const BlockOdysseyApp());
}

class BlockOdysseyApp extends StatelessWidget {
  const BlockOdysseyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Odyssey: Pet Express',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1B1B1B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFB300),
          secondary: Color(0xFF81D4FA),
          surface: Color(0xFF263238),
        ),
        fontFamily: 'Roboto',
      ),
      home: const RootNavigator(),
    );
  }
}

class RootNavigator extends StatefulWidget {
  const RootNavigator({super.key});

  @override
  State<RootNavigator> createState() => _RootNavigatorState();
}

class _RootNavigatorState extends State<RootNavigator> {
  int? _activePlayingLevel; // null means on MainMenu

  void _launchLevel(int level) {
    setState(() {
      _activePlayingLevel = level;
    });
  }

  void _returnToMenu() {
    setState(() {
      _activePlayingLevel = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activePlayingLevel != null) {
      return GamePlayScreen(
        initialLevel: _activePlayingLevel!,
        onBackToMenu: _returnToMenu,
      );
    }

    return MainMenuScreen(
      onSelectLevel: _launchLevel,
    );
  }
}

