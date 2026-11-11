import '../models/user_model.dart';

/// Сервис аутентификации.
///
/// Пользователи хранятся локально (позже — запрос к Node.js серверу).
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const List<UserModel> _users = [
    UserModel(
      username: 'admin',
      password: '14monitor6010zxX+',
      role: UserRole.admin,
    ),
    UserModel(
      username: 'operator',
      password: '112233',
      role: UserRole.operator,
    ),
  ];

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<UserModel?> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final user = _users.firstWhere(
            (u) => u.username == username && u.password == password,
      );
      _currentUser = user;
      return user;
    } catch (_) {
      _currentUser = null;
      return null;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
  }
}