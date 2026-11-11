import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../core/app.dart';
import '../core/constants.dart';
import '../services/auth_service.dart';
import '../widgets/double_back_exit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;
  bool _rememberDevice = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  Future<void> _checkSavedLogin() async {
    final saved = await StorageService.instance.read('saved_login');
    if (saved != null && mounted) {
      setState(() {
        _usernameController.text = saved;
        _rememberDevice = true;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final user = await AuthService.instance.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (user == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Неверный логин или пароль'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_rememberDevice) {
      await StorageService.instance.save(
        'saved_login',
        _usernameController.text.trim(),
      );
    } else {
      await StorageService.instance.delete('saved_login');
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainScreen(),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: secondaryText),
      prefixIcon: Icon(icon, color: secondaryText),
      suffixIcon: suffix,
      filled: true,
      fillColor: cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: accentColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DoubleBackExit(
      child: Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 30,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 25),

                  Center(
                    child: Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.memory,
                        size: 45,
                        color: accentColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'BM MONITOR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Equipment Monitoring System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 55),

                  const Text(
                    'Логин',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _usernameController,
                    decoration: _inputDecoration(
                      hint: 'Введите логин',
                      icon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введите логин';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Пароль',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _inputDecoration(
                      hint: 'Введите пароль',
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: secondaryText,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _rememberDevice,
                          onChanged: (value) {
                            setState(() {
                              _rememberDevice = value ?? false;
                            });
                          },
                          activeColor: accentColor,
                          checkColor: backgroundColor,
                          side: const BorderSide(color: secondaryText),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Запомнить устройство',
                        style: TextStyle(color: secondaryText, fontSize: 13),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: backgroundColor,
                        disabledBackgroundColor:
                            accentColor.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: backgroundColor,
                              ),
                            )
                          : const Text(
                              'ВОЙТИ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 35),

                  const Row(
                    children: [
                      Expanded(child: Divider(color: cardColor)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'BM MONITOR',
                          style: TextStyle(
                            color: secondaryText,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: cardColor)),
                    ],
                  ),

                  const SizedBox(height: 22),

                  const Text(
                    'Secure Equipment Monitoring',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 11,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Version 1.0.3',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF536174),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}
