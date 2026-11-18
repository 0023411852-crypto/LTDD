import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../../../auth/providers/auth_provider.dart';

/// Controller xử lý nghiệp vụ quản lý người dùng và phân quyền tài khoản
class AdminUsersController {
  final AuthProvider authProvider;

  AdminUsersController({required this.authProvider});

  User? get user => authProvider.user;
  bool get isAuthenticated => authProvider.isAuthenticated;
  String get displayName => authProvider.displayName;
  String get email => authProvider.email;
  String get uid => authProvider.uid;
  bool get isAdmin => authProvider.isAdmin;

  Future<List<Map<String, dynamic>>> getRegisteredUsers() async {
    return authProvider.getRegisteredUsersList();
  }
}
