import 'package:flutter/material.dart';

import 'database_helper.dart';
import 'screens/checkin_screen.dart';
import 'screens/habit_form_screen.dart';
import 'screens/history_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseHelper.instance.init();
    await SettingsStore.instance.load();
    runApp(const HabitLeagueApp());
  } catch (error) {
    debugPrint('app start failed: $error');
    runApp(const StartErrorApp());
  }
}

class StartErrorApp extends StatelessWidget {
  const StartErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'The app could not open the local database. Please close it and try again.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class HabitLeagueApp extends StatelessWidget {
  const HabitLeagueApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Green felt like a school league color to me.
    const seed = Color(0xFF1F6B4A);

    return ListenableBuilder(
      listenable: SettingsStore.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Habit Mastery League',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: seed),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seed,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: SettingsStore.instance.darkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          home: const AppShell(),
        );
      },
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  int _reloadToken = 0;
  int? _checkInHabitId;

  Future<void> _addHabit() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HabitFormScreen()),
    );
    if (saved == true) {
      setState(() => _reloadToken++);
    }
  }

  void _openCheckIn(int habitId) {
    setState(() {
      _checkInHabitId = habitId;
      _index = 1;
      _reloadToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final name = SettingsStore.instance.displayName;
    final titles = [
      name.isEmpty ? 'Habit League' : 'Hi, $name',
      'Check-In',
      'History',
      'Settings',
    ];

    final pages = [
      HomeScreen(reloadToken: _reloadToken, onCheckIn: _openCheckIn),
      CheckInScreen(
        reloadToken: _reloadToken,
        selectedHabitId: _checkInHabitId,
        onHabitChanged: (habitId) => _checkInHabitId = habitId,
      ),
      HistoryScreen(reloadToken: _reloadToken),
      const SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: SafeArea(child: pages[_index]),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: _addHabit,
              icon: const Icon(Icons.add),
              label: const Text('Add habit'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) {
          setState(() {
            _index = value;
            _reloadToken++;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.check_circle_outline),
            selectedIcon: Icon(Icons.check_circle),
            label: 'Check-In',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
