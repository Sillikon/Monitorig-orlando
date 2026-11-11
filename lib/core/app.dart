import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/dashboard_page.dart';
import '../screens/diagnostics_page.dart';
import '../screens/login_page.dart';
import '../screens/settings_page.dart';
import '../screens/users_page.dart';
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
/// В исходной структуре отдельного файла для неё не было,
/// поэтому она находится здесь, рядом с [BMMonitorApp].
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
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

    return Scaffold(
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
    );
  }
}
