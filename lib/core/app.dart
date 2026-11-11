import 'package:flutter/material.dart';
import '../screens/dashboard_page.dart';
import '../screens/diagnostics_page.dart';
import '../screens/login_page.dart';
import '../screens/settings_page.dart';
import '../screens/users_page.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../widgets/double_back_exit.dart';
import 'constants.dart';

class BMMonitorApp extends StatelessWidget {
  const BMMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BM Monitor',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundColor,
        colorScheme: const ColorScheme.dark(
          primary: accentColor,
          surface: cardColor,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

// ================= MAIN NAVIGATION =================

/// Оболочка приложения с нижней навигацией.
/// Также отслеживает события жизненного цикла приложения
/// (сворачивание/разворачивание) и пишет их в журнал активности.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int selectedIndex = 0;

  List<Widget> get pages {
    final isAdmin = AuthService.instance.isAdmin;
    return [
      const DashboardPage(),
      if (isAdmin) const DiagnosticsPage(),
      if (isAdmin) const UsersPage(),
      const SettingsPage(),
    ];
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final username = AuthService.instance.currentUser?.username;
    if (username == null) return;

    // Записываем сворачивание/разворачивание приложения в журнал.
    switch (state) {
      case AppLifecycleState.paused:
        ActivityService.instance.log(username, ActivityEvent.appHidden);
        break;
      case AppLifecycleState.resumed:
        ActivityService.instance.log(username, ActivityEvent.appOpened);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.instance.isAdmin;

    final destinations = [
      const NavigationDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: 'Обзор',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.terminal),
          label: 'Диагностика',
        ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.people_outline),
          label: 'Пользователи',
        ),
      const NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        label: 'Настройки',
      ),
    ];

    return DoubleBackExit(
      child: Scaffold(
        body: SafeArea(child: pages[selectedIndex]),
        bottomNavigationBar: NavigationBar(
          backgroundColor: cardColor,
          indicatorColor: accentColor.withValues(alpha: 0.15),
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() => selectedIndex = index);
          },
          destinations: destinations,
        ),
      ),
    );
  }
}
