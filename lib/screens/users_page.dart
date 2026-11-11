import 'package:flutter/material.dart';

import '../widgets/simple_page.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SimplePage(
      icon: Icons.people_outline,
      title: 'Пользователи',
      description:
          'Управление аккаунтами и ролями пользователей.',
    );
  }
}
