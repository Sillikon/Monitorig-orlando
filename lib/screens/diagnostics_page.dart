import 'package:flutter/material.dart';

import '../widgets/simple_page.dart';

class DiagnosticsPage extends StatelessWidget {
  const DiagnosticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      icon: Icons.terminal,
      title: 'Диагностика',
      description:
          'HEX-пакеты, Sequence Number, Uptime '
          'и история получения данных.',
    );
  }
}
