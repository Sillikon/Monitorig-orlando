import '../models/user_model.dart';
import 'activity_service.dart';

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
      username: 'operator1',
      password: '1111',
      role: UserRole.operator,
    ),
    UserModel(
      username: 'operator2',
      password: '2222',
      role: UserRole.operator,
    ),
    UserModel(
      username: 'operator3',
      password: '3333',
      role: UserRole.operator,
    ),
  ];

  /// Список всех пользователей (для экрана «Пользователи»).
  static List<UserModel> get users => _users;

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
      ActivityService.instance.log(user.username, ActivityEvent.login);
      return user;
    } catch (_) {
      _currentUser = null;
      return null;
    }
  }

  Future<void> logout() async {
    final user = _currentUser;
    if (user != null) {
      ActivityService.instance.log(user.username, ActivityEvent.logout);
    }
    _currentUser = null;
  }
}
