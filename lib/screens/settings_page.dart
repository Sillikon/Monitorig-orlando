import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../services/activity_service.dart';
import '../services/auth_service.dart';
import '../services/mqtt_service.dart';
import '../services/settings_service.dart';

/// Экран настроек приложения.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    MqttService.instance.addListener(_onChanged);
    SettingsService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    MqttService.instance.removeListener(_onChanged);
    SettingsService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.instance.isAdmin;
    final mqtt = MqttService.instance;
    final settings = SettingsService.instance;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Настройки',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Подключение, уведомления и приложение',
          style: TextStyle(color: secondaryText),
        ),
        const SizedBox(height: 20),

        // ---- Подключение ----
        const _SectionTitle('Подключение'),
        _SettingsCard(
          children: [
            _ActionTile(
              icon: Icons.cloud_outlined,
              title: 'MQTT-сервер',
              subtitle: '${MqttService.host}:${MqttService.port}',
              onTap: _showServerDetails,
            ),
            const Divider(height: 1, color: Colors.white10),
            _ActionTile(
              icon: Icons.link,
              title: 'Статус подключения',
              subtitle: mqtt.isConnected
                  ? 'Подключено'
                  : (mqtt.lastConnectedAt == null
                      ? 'Не подключено'
                      : 'Отключено — переподключение...'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    size: 12,
                    color: mqtt.isConnected
                        ? accentColor
                        : Colors.redAccent,
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 20),
                ],
              ),
              onTap: () async {
                await mqtt.checkConnection();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ---- Уведомления ----
        const _SectionTitle('Уведомления'),
        _SettingsCard(
          children: [
            _SwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Push-уведомления',
              subtitle: 'Сервер, устройства ESP32, входы операторов',
              value: settings.notificationsEnabled,
              onChanged: settings.setNotificationsEnabled,
            ),
            const Divider(height: 1, color: Colors.white10),
            _SwitchTile(
              icon: Icons.volume_up_outlined,
              title: 'Звуковые оповещения',
              subtitle: 'Сигнал при событиях',
              value: settings.soundAlerts,
              onChanged: settings.setSoundAlerts,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ---- Данные ----
        const _SectionTitle('Данные'),
        _SettingsCard(
          children: [
            _SwitchTile(
              icon: Icons.autorenew,
              title: 'Автообновление',
              subtitle: 'Проверка соединения и данных каждые 10 секунд',
              value: settings.autoRefresh,
              onChanged: settings.setAutoRefresh,
            ),
            const Divider(height: 1, color: Colors.white10),
            _ActionTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Очистить историю пакетов',
              subtitle: 'Удалить сырые данные диагностики',
              onTap: () {
                MqttService.instance.clearHistory();
                _showSnack('История пакетов очищена');
              },
            ),
            if (isAdmin) ...[
              const Divider(height: 1, color: Colors.white10),
              _ActionTile(
                icon: Icons.history,
                title: 'Очистить журнал активности',
                subtitle: 'Удалить записи о входах и действиях',
                onTap: () {
                  ActivityService.instance.clear();
                  _showSnack('Журнал активности очищен');
                },
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // ---- О приложении ----
        const _SectionTitle('О приложении'),
        const _SettingsCard(
          children: [
            _InfoTile(icon: Icons.info_outline, text: 'BM Monitor'),
            Divider(height: 1, color: Colors.white10),
            _InfoTile(
              icon: Icons.verified_outlined,
              text: 'Версия 1.0.3',
            ),
            Divider(height: 1, color: Colors.white10),
            _InfoTile(
              icon: Icons.memory,
              text: 'Мониторинг контроллеров BM по MQTT',
            ),
          ],
        ),
      ],
    );
  }

  /// Окно с параметрами сервера (пароль скрыт).
  void _showServerDetails() {
    final lastConnected = MqttService.instance.lastConnectedAt;
    String two(int v) => v.toString().padLeft(2, '0');
    final lastText = lastConnected == null
        ? 'никогда'
        : '${two(lastConnected.day)}.${two(lastConnected.month)} '
            '${two(lastConnected.hour)}:${two(lastConnected.minute)}';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.cloud_outlined, color: accentColor),
              SizedBox(width: 10),
              Text('MQTT-сервер', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ServerParam('Хост', MqttService.host),
              _ServerParam('Порт', '${MqttService.port} (TLS)'),
              _ServerParam('Протокол', 'MQTT over TCP, TLS'),
              _ServerParam('Логин', MqttService.username),
              const _ServerParam('Пароль', '••••••••'),
              _ServerParam('Последнее подключение', lastText),
              _ServerParam(
                'Статус',
                MqttService.instance.isConnected
                    ? 'Подключено'
                    : 'Не подключено',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Закрыть',
                style: TextStyle(color: accentColor),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

// ================= Виджеты =================

class _ServerParam extends StatelessWidget {
  final String title;
  final String value;
  const _ServerParam(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              title,
              style:
                  const TextStyle(color: secondaryText, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: secondaryText,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon, color: secondaryText),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: secondaryText, fontSize: 12),
      ),
      value: value,
      activeColor: accentColor,
      onChanged: onChanged,
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: secondaryText),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: secondaryText, fontSize: 12),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: secondaryText, size: 20),
      title: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
