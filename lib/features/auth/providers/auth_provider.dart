import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  authenticating,
  unauthenticated
}

class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;
  User? _user;
  AuthStatus _status = AuthStatus.uninitialized;
  String _errorMessage = '';

  User? get user => _user;
  AuthStatus get status => _status;
  bool get isAuthenticated => _user != null;
  String get errorMessage => _errorMessage;

  String get displayName {
    if (_user == null) return 'Khách';
    if (_user!.displayName != null && _user!.displayName!.isNotEmpty) {
      return _user!.displayName!;
    }
    if (_user!.email != null && _user!.email!.isNotEmpty) {
      return _user!.email!.split('@').first;
    }
    return 'Người dùng';
  }

  String get email => _user?.email ?? '';

  bool get isAdmin {
    if (_user == null) return false;
    final userEmail = _user!.email?.toLowerCase() ?? '';
    return userEmail.contains('admin') ||
        userEmail == 'linh@admin.com' ||
        userEmail == 'admin@gmail.com' ||
        userEmail.endsWith('@admin.portal');
  }

  /// Tự động đăng nhập hoặc tạo tài khoản Admin mặc định
  Future<bool> signInAsAdmin() async {
    const adminEmail = 'admin@gmail.com';
    const adminPass = 'Admin@123456';
    const adminName = 'Quản trị viên Hệ thống';

    // 1. Thử đăng nhập trước
    bool ok = await signIn(adminEmail, adminPass);
    if (ok) return true;

    // 2. Nếu chưa có trên Firebase Auth, tự tạo mới
    ok = await register(adminEmail, adminPass, name: adminName);
    return ok;
  }

  AuthProvider() {
    try {
      _auth = FirebaseAuth.instance;
      _auth?.authStateChanges().listen(_onAuthStateChanged);
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
  }

  void _onAuthStateChanged(User? firebaseUser) {
    _user = firebaseUser;
    _status = firebaseUser == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    final auth = _auth;
    if (auth == null) {
      _errorMessage = 'Dịch vụ xác thực chưa sẵn sàng.';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getVietnameseErrorMessage(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String email, String password, {String? name}) async {
    final auth = _auth;
    if (auth == null) {
      _errorMessage = 'Dịch vụ xác thực chưa sẵn sàng.';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (name != null && name.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(name.trim());
        await credential.user?.reload();
        _user = auth.currentUser;
      }
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getVietnameseErrorMessage(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    final auth = _auth;
    if (auth == null) {
      _errorMessage = 'Dịch vụ xác thực chưa sẵn sàng.';
      notifyListeners();
      return false;
    }

    _errorMessage = '';
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getVietnameseErrorMessage(e.code);
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      _errorMessage = 'Dịch vụ xác thực chưa sẵn sàng.';
      notifyListeners();
      return false;
    }

    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // Người dùng hủy đăng nhập
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getVietnameseErrorMessage(e.code);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi đăng nhập Google: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await _auth?.signOut();
    } catch (_) {}
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _getVietnameseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng bởi một tài khoản khác.';
      case 'invalid-email':
        return 'Định dạng email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
      case 'too-many-requests':
        return 'Quá nhiều lần thử thất bại. Vui lòng thử lại sau ít phút.';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
      default:
        return 'Đã có lỗi xảy ra ($code). Vui lòng thử lại.';
    }
  }
}
