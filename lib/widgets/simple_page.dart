import 'package:flutter/material.dart';

import '../core/constants.dart';

/// Заглушка-страница с иконкой и описанием.
/// Используется на страницах, которые ещё не реализованы.
class SimplePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const SimplePage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 65, color: accentColor),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryText,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
