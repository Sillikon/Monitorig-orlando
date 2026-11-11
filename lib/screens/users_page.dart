import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../models/user_model.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';

/// Экран «Пользователи» (только для администратора):
/// список аккаунтов и журнал активности — кто и когда входил,
/// сворачивал/открывал приложение и выходил.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  String? _expandedUser;

  @override
  void initState() {
    super.initState();
    ActivityService.instance.addListener(_onActivityChanged);
  }

  @override
  void dispose() {
    ActivityService.instance.removeListener(_onActivityChanged);
    super.dispose();
  }

  void _onActivityChanged() {
    if (mounted) setState(() {});
  }

  IconData _iconFor(ActivityEvent event) => switch (event) {
        ActivityEvent.login => Icons.login,
        ActivityEvent.logout => Icons.logout,
        ActivityEvent.appOpened => Icons.visibility_outlined,
        ActivityEvent.appHidden => Icons.visibility_off_outlined,
      };

  Color _colorFor(ActivityEvent event) => switch (event) {
        ActivityEvent.login => accentColor,
        ActivityEvent.logout => Colors.redAccent,
        ActivityEvent.appOpened => Colors.blueAccent,
        ActivityEvent.appHidden => Colors.orangeAccent,
      };

  String _formatTime(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(time.day)}.${two(time.month)}.${time.year} '
        '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final users = AuthService.users;
    final entries = ActivityService.instance.entries;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Пользователи',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Аккаунты и история активности',
          style: TextStyle(color: secondaryText),
        ),
        const SizedBox(height: 20),

        // ---- Список пользователей ----
        for (final user in users) ...[
          _UserTile(
            user: user,
            expanded: _expandedUser == user.username,
            onTap: () => setState(
              () => _expandedUser =
                  _expandedUser == user.username ? null : user.username,
            ),
          ),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 16),

        // ---- Журнал активности ----
        const Text(
          'Журнал активности',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (entries.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.history, color: secondaryText),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Записей пока нет. События появятся после '
                    'первого входа пользователя.',
                    style: TextStyle(color: secondaryText, fontSize: 13),
                  ),
                ),
              ],
            ),
          )
        else
          for (final entry in entries)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _iconFor(entry.event),
                    size: 20,
                    color: _colorFor(entry.event),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${entry.username} — ${entry.eventLabel}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(entry.timestamp),
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserModel user;
  final bool expanded;
  final VoidCallback onTap;

  const _UserTile({
    required this.user,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = user.role == UserRole.admin;
    final sessions = ActivityService.instance.entriesFor(user.username);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: (isAdmin ? Colors.amber : accentColor)
                      .withValues(alpha: 0.15),
                  child: Icon(
                    isAdmin ? Icons.shield_outlined : Icons.person_outline,
                    color: isAdmin ? Colors.amber : accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        isAdmin ? 'Администратор' : 'Оператор',
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: secondaryText,
                ),
              ],
            ),
            if (expanded) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Colors.white10),
              const SizedBox(height: 10),
              if (sessions.isEmpty)
                const Text(
                  'Активности нет',
                  style: TextStyle(color: secondaryText, fontSize: 12),
                )
              else
                for (final s in sessions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.eventLabel,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        Text(
                          '${s.timestamp.day.toString().padLeft(2, '0')}.'
                          '${s.timestamp.month.toString().padLeft(2, '0')} '
                          '${s.timestamp.hour.toString().padLeft(2, '0')}:'
                          '${s.timestamp.minute.toString().padLeft(2, '0')}:'
                          '${s.timestamp.second.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
