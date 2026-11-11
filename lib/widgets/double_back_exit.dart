import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Обёртка, реализующая выход из приложения по двойному
/// нажатию системной кнопки «Назад».
///
/// При первом нажатии показывает подсказку, при повторном
/// в течение [_exitTimeout] закрывает приложение.
class DoubleBackExit extends StatefulWidget {
  final Widget child;
  final Duration exitTimeout;

  const DoubleBackExit({
    super.key,
    required this.child,
    this.exitTimeout = const Duration(seconds: 2),
  });

  @override
  State<DoubleBackExit> createState() => _DoubleBackExitState();
}

class _DoubleBackExitState extends State<DoubleBackExit> {
  DateTime? _lastBackPress;

  void _handleBackPressed() {
    final now = DateTime.now();
    final last = _lastBackPress;

    if (last != null && now.difference(last) < widget.exitTimeout) {
      // Второе нажатие в пределах таймаута — выходим из приложения.
      SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Нажмите «Назад» ещё раз, чтобы выйти'),
        duration: widget.exitTimeout,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPressed();
      },
      child: widget.child,
    );
  }
}
