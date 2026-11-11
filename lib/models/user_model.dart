enum UserRole { admin, operator }

class UserModel {
  final String username;
  final String password;
  final UserRole role;

  const UserModel({
    required this.username,
    required this.password,
    required this.role,
  });
}