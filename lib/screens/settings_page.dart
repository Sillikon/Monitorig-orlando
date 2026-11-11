import 'package:flutter/material.dart';

import '../widgets/simple_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      icon: Icons.settings_outlined,
      title: 'Настройки',
      description:
          'Настройки подключения, уведомлений и приложения.',
    );
  }
}
