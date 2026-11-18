import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Local Admin session fallback (kích hoạt khi Firebase Auth chưa bật Email/Password trên Console)
  bool _isCustomAdminLoggedIn = false;
  String? _customUserEmail;
  String? _customUserName;
  String? _customUserUid;
  String? _customUserPhone;
  String? _customUserPhotoUrl;
  String? _customUserBio;

  User? get user => _user;
  AuthStatus get status => _status;
  bool get isAuthenticated => _user != null || _isCustomAdminLoggedIn;
  String get errorMessage => _errorMessage;

  String get displayName {
    if (_customUserName != null && _customUserName!.isNotEmpty) {
      return _customUserName!;
    }
    if (_user != null) {
      if (_user!.displayName != null && _user!.displayName!.isNotEmpty) {
        return _user!.displayName!;
      }
      if (_user!.email != null && _user!.email!.isNotEmpty) {
        return _user!.email!.split('@').first;
      }
    }
    return _isCustomAdminLoggedIn ? 'Quản trị viên Hệ thống' : 'Khách';
  }

  String get email => _isCustomAdminLoggedIn
      ? (_customUserEmail ?? 'admin@gmail.com')
      : (_user?.email ?? '');

  String get uid =>
      _user?.uid ??
      (_isCustomAdminLoggedIn ? (_customUserUid ?? 'admin_root_sys') : '');

  String get phoneNumber => _customUserPhone ?? '';
  String get photoUrl => _customUserPhotoUrl ?? _user?.photoURL ?? '';
  String get bio => _customUserBio ?? '';

  bool get isAdmin {
    if (_isCustomAdminLoggedIn) return true;
    final email = (_user?.email ?? _customUserEmail ?? '').toLowerCase();
    if (email.isEmpty) return false;
    return email.contains('admin') ||
        email == 'admin@portal.com' ||
        email == 'admin@gmail.com' ||
        email == 'linh@admin.com' ||
        email.endsWith('@admin.portal');
  }

  StreamSubscription<User?>? _authStateSubscription;

  AuthProvider() {
    _loadProfilePrefs();
    try {
      _auth = FirebaseAuth.instance;
      _authStateSubscription =
          _auth?.authStateChanges().listen(_onAuthStateChanged);
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProfilePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customUserName = prefs.getString('user_profile_name');
      _customUserPhone = prefs.getString('user_profile_phone');
      _customUserPhotoUrl = prefs.getString('user_profile_photo');
      _customUserBio = prefs.getString('user_profile_bio');

      // Khôi phục phiên đăng nhập nội bộ (Local Session) nếu có
      final hasLocalSession = prefs.getBool('session_is_logged_in') ?? false;
      if (hasLocalSession && _user == null) {
        _customUserEmail = prefs.getString('session_user_email');
        _customUserName = prefs.getString('session_user_name') ?? _customUserName;
        _customUserUid = prefs.getString('session_user_uid');
        _isCustomAdminLoggedIn = prefs.getBool('session_is_admin') ?? false;
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveActiveSession(
    String email,
    String name,
    String uid, {
    bool isAdmin = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('session_is_logged_in', true);
      await prefs.setString('session_user_email', email);
      await prefs.setString('session_user_name', name);
      await prefs.setString('session_user_uid', uid);
      await prefs.setBool('session_is_admin', isAdmin);
    } catch (_) {}
  }

  Future<void> _clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('session_is_logged_in');
      await prefs.remove('session_user_email');
      await prefs.remove('session_user_name');
      await prefs.remove('session_user_uid');
      await prefs.remove('session_is_admin');
    } catch (_) {}
  }

  Future<void> _saveProfilePrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customUserName != null) {
        await prefs.setString('user_profile_name', _customUserName!);
      }
      if (_customUserPhone != null) {
        await prefs.setString('user_profile_phone', _customUserPhone!);
      }
      if (_customUserPhotoUrl != null) {
        await prefs.setString('user_profile_photo', _customUserPhotoUrl!);
      }
      if (_customUserBio != null) {
        await prefs.setString('user_profile_bio', _customUserBio!);
      }
    } catch (_) {}
  }

  void _onAuthStateChanged(User? firebaseUser) {
    _user = firebaseUser;
    if (firebaseUser != null) {
      _status = AuthStatus.authenticated;
    } else if (!_isCustomAdminLoggedIn && _customUserEmail == null) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signInAsAdmin({String? email, String? name}) async {
    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      final adminEmail = email ?? 'admin@portal.com';
      final adminName = name ?? 'Quản trị viên Hệ thống';
      _customUserEmail = adminEmail;
      _customUserName = adminName;
      _customUserUid = 'admin_root_sys';
      _customUserPhone = '0987654321';
      _isCustomAdminLoggedIn = true;
      _status = AuthStatus.authenticated;
      _errorMessage = '';

      await _saveActiveSession(
        adminEmail,
        adminName,
        'admin_root_sys',
        isAdmin: true,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Lỗi đăng nhập admin: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();

    // 1. Tài khoản admin hệ thống phân quyền cao nhất
    if ((normalizedEmail == 'admin@portal.com' || normalizedEmail == 'admin@gmail.com') &&
        (normalizedPassword == 'admin123' ||
            normalizedPassword == 'Admin@123' ||
            normalizedPassword == 'Admin@123456')) {
      return signInAsAdmin(email: normalizedEmail, name: 'Quản trị viên Hệ thống');
    }

    // 2. Tài khoản người dùng mẫu phân quyền thông thường (User role)
    if ((normalizedEmail == 'user@portal.com' || normalizedEmail == 'user@gmail.com') &&
        (normalizedPassword == 'user123' ||
            normalizedPassword == 'User@123' ||
            normalizedPassword == 'User@123456')) {
      _customUserEmail = normalizedEmail;
      _customUserName = 'Người Dùng Portal';
      _customUserUid = 'usr_portal_demo';
      _customUserPhone = '0912345678';
      _isCustomAdminLoggedIn = false;
      _status = AuthStatus.authenticated;
      _errorMessage = '';
      await _saveActiveSession(
        normalizedEmail,
        'Người Dùng Portal',
        'usr_portal_demo',
        isAdmin: false,
      );
      notifyListeners();
      return true;
    }

    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    // 2. Thử đăng nhập qua Firebase Auth
    final auth = _auth;
    if (auth != null) {
      try {
        await auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: normalizedPassword,
        );
        _isCustomAdminLoggedIn = false;
        _customUserEmail = normalizedEmail;
        _customUserName = _user?.displayName ?? normalizedEmail.split('@').first;
        _customUserUid = _user?.uid;
        _status = AuthStatus.authenticated;
        _errorMessage = '';
        await _saveActiveSession(
          normalizedEmail,
          _customUserName!,
          _user?.uid ?? 'uid_$normalizedEmail',
          isAdmin: isAdmin,
        );
        notifyListeners();
        return true;
      } on FirebaseAuthException catch (e) {
        // Nếu là sai mật khẩu
        if (e.code == 'wrong-password') {
          _errorMessage = 'Mật khẩu không chính xác.';
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return false;
        }

        // Nếu gặp unknown / configuration-not-found / user-not-found -> Thử đăng nhập tài khoản nội bộ (Local fallback)
        final localSuccess = await _signInLocalAccount(normalizedEmail, normalizedPassword);
        if (localSuccess) return true;

        _errorMessage = _getVietnameseErrorMessage(e.code, e.message);
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      } catch (e) {
        final localSuccess = await _signInLocalAccount(normalizedEmail, normalizedPassword);
        if (localSuccess) return true;

        _errorMessage = 'Lỗi kết nối: ${e.toString()}';
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } else {
      return _signInLocalAccount(normalizedEmail, normalizedPassword);
    }
  }

  Future<bool> register(String email, String password, {String? name}) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPassword = password.trim();
    final normalizedName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : normalizedEmail.split('@').first;

    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    final auth = _auth;
    if (auth != null) {
      try {
        final credential = await auth.createUserWithEmailAndPassword(
          email: normalizedEmail,
          password: normalizedPassword,
        );
        if (normalizedName.isNotEmpty) {
          try {
            await credential.user?.updateDisplayName(normalizedName);
            await credential.user?.reload();
            _user = auth.currentUser;
          } catch (_) {}
        }
        _customUserEmail = normalizedEmail;
        _customUserName = normalizedName;
        _customUserUid = credential.user?.uid;
        _status = AuthStatus.authenticated;
        _errorMessage = '';

        await _saveLocalAccountRecord(normalizedEmail, normalizedPassword, normalizedName);
        await _saveActiveSession(
          normalizedEmail,
          normalizedName,
          credential.user?.uid ?? 'uid_$normalizedEmail',
        );
        notifyListeners();
        return true;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          _errorMessage = 'Email này đã được sử dụng bởi một tài khoản khác.';
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return false;
        }
        if (e.code == 'invalid-email') {
          _errorMessage = 'Định dạng email không hợp lệ.';
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return false;
        }
        if (e.code == 'weak-password') {
          _errorMessage = 'Mật khẩu quá yếu (tối thiểu 6 ký tự).';
          _status = AuthStatus.unauthenticated;
          notifyListeners();
          return false;
        }

        // Khi gặp lỗi configuration-not-found hoặc unknown (do Firebase Console chưa kích hoạt Email/Password)
        // -> Tự động chuyển tiếp đăng ký tài khoản nội bộ mượt mà, không chặn người dùng!
        return _registerLocalAccount(normalizedEmail, normalizedPassword, normalizedName);
      } catch (e) {
        return _registerLocalAccount(normalizedEmail, normalizedPassword, normalizedName);
      }
    } else {
      return _registerLocalAccount(normalizedEmail, normalizedPassword, normalizedName);
    }
  }

  Future<String?> _getLocalPasswordForEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('local_registered_users') ?? [];
      final normalized = email.trim().toLowerCase();
      for (final u in usersJson) {
        try {
          final map = jsonDecode(u) as Map<String, dynamic>;
          if ((map['email'] as String?)?.trim().toLowerCase() == normalized) {
            final pass = map['password'] as String?;
            if (pass != null && pass.isNotEmpty) return pass;
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>?> _getLocalAccountByEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('local_registered_users') ?? [];
      final normalized = email.trim().toLowerCase();
      for (final u in usersJson) {
        try {
          final map = jsonDecode(u) as Map<String, dynamic>;
          if ((map['email'] as String?)?.trim().toLowerCase() == normalized) {
            return Map<String, dynamic>.from(map);
          }
        } catch (_) {}
      }
    } catch (_) {}
    return null;
  }

  Future<void> _mergeOrSaveLocalAccount({
    required String email,
    required String name,
    required String uid,
    String? password,
    String? photoUrl,
    String? googleId,
    bool isGoogleLinked = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('local_registered_users') ?? [];
      final normalized = email.trim().toLowerCase();

      int existingIndex = -1;
      Map<String, dynamic> mergedMap = {
        'email': normalized,
        'name': name,
        'uid': uid,
        'isGoogleLinked': isGoogleLinked,
      };

      for (int i = 0; i < usersJson.length; i++) {
        try {
          final map = jsonDecode(usersJson[i]) as Map<String, dynamic>;
          if ((map['email'] as String?)?.trim().toLowerCase() == normalized) {
            existingIndex = i;
            mergedMap = Map<String, dynamic>.from(map);
            break;
          }
        } catch (_) {}
      }

      // Hợp nhất dữ liệu vào 1 tài khoản duy nhất (Merge Data)
      mergedMap['email'] = normalized;
      mergedMap['uid'] = mergedMap['uid'] ?? uid;
      if (name.isNotEmpty && (mergedMap['name'] == null || (mergedMap['name'] as String).isEmpty)) {
        mergedMap['name'] = name;
      }
      if (password != null && password.isNotEmpty) {
        mergedMap['password'] = password;
      }
      if (photoUrl != null && photoUrl.isNotEmpty) {
        mergedMap['photoUrl'] = photoUrl;
      }
      if (googleId != null && googleId.isNotEmpty) {
        mergedMap['googleId'] = googleId;
      }
      if (isGoogleLinked) {
        mergedMap['isGoogleLinked'] = true;
      }

      final encoded = jsonEncode(mergedMap);
      if (existingIndex != -1) {
        usersJson[existingIndex] = encoded;
      } else {
        usersJson.add(encoded);
      }
      await prefs.setStringList('local_registered_users', usersJson);
    } catch (_) {}
  }

  Future<List<Map<String, dynamic>>> getRegisteredUsersList() async {
    final list = <Map<String, dynamic>>[];
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('local_registered_users') ?? [];
      final seenEmails = <String>{};

      for (final u in usersJson) {
        try {
          final map = jsonDecode(u) as Map<String, dynamic>;
          final email = (map['email'] as String?)?.toLowerCase() ?? '';
          if (email.isNotEmpty && !seenEmails.contains(email)) {
            seenEmails.add(email);
            list.add(Map<String, dynamic>.from(map));
          }
        } catch (_) {}
      }

      // Thêm tài khoản Admin và User mẫu mặc định nếu chưa có trong danh sách
      if (!seenEmails.contains('admin@portal.com')) {
        list.insert(0, {
          'email': 'admin@portal.com',
          'name': 'Quản trị viên Hệ thống',
          'uid': 'admin_root_sys',
          'isAdmin': true,
          'hasPassword': true,
        });
      }
      if (!seenEmails.contains('user@portal.com')) {
        list.add({
          'email': 'user@portal.com',
          'name': 'Người Dùng Portal',
          'uid': 'usr_portal_demo',
          'isAdmin': false,
          'hasPassword': true,
        });
      }
    } catch (_) {}
    return list;
  }

  Future<bool> _registerLocalAccount(
    String email,
    String password,
    String name,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('local_registered_users') ?? [];
      final normalized = email.trim().toLowerCase();

      for (int i = 0; i < usersJson.length; i++) {
        try {
          final map = jsonDecode(usersJson[i]) as Map<String, dynamic>;
          if ((map['email'] as String?)?.trim().toLowerCase() == normalized) {
            // NẾU TÀI KHOẢN NÀY ĐÃ TỒN TẠI (VD: từ Google trước đó):
            // Hợp nhất mật khẩu vào cùng 1 user, KHÔNG TẠO USER THỨ HAI!
            map['password'] = password;
            if (name.isNotEmpty) map['name'] = name;
            usersJson[i] = jsonEncode(map);
            await prefs.setStringList('local_registered_users', usersJson);

            final targetUid = map['uid'] as String? ??
                'usr_${normalized.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
            _customUserEmail = normalized;
            _customUserName = map['name'] ?? name;
            _customUserUid = targetUid;
            _isCustomAdminLoggedIn = normalized.contains('admin');
            _status = AuthStatus.authenticated;
            _errorMessage = '';

            await _saveActiveSession(normalized, _customUserName!, targetUid,
                isAdmin: _isCustomAdminLoggedIn);
            notifyListeners();
            return true;
          }
        } catch (_) {}
      }

      final newUid =
          'usr_${normalized.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      final newRecord = jsonEncode({
        'email': normalized,
        'password': password,
        'name': name,
        'uid': newUid,
        'isGoogleLinked': false,
      });

      usersJson.add(newRecord);
      await prefs.setStringList('local_registered_users', usersJson);

      _customUserEmail = normalized;
      _customUserName = name;
      _customUserUid = newUid;
      _isCustomAdminLoggedIn = normalized.contains('admin');
      _status = AuthStatus.authenticated;
      _errorMessage = '';

      await _saveActiveSession(normalized, name, newUid,
          isAdmin: _isCustomAdminLoggedIn);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Không thể đăng ký: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveLocalAccountRecord(
    String email,
    String password,
    String name,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('local_registered_users') ?? [];
      final newRecord = jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'uid': 'fb_${email.hashCode}',
      });
      usersJson.removeWhere((item) {
        try {
          return (jsonDecode(item) as Map)['email'] == email;
        } catch (_) {
          return false;
        }
      });
      usersJson.add(newRecord);
      await prefs.setStringList('local_registered_users', usersJson);
    } catch (_) {}
  }

  Future<bool> _signInLocalAccount(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('local_registered_users') ?? [];

      for (final u in usersJson) {
        try {
          final map = jsonDecode(u) as Map<String, dynamic>;
          if (map['email'] == email) {
            if (map['password'] == password) {
              final name = map['name'] as String? ?? email.split('@').first;
              final uid = map['uid'] as String? ?? 'local_${email.hashCode}';

              _customUserEmail = email;
              _customUserName = name;
              _customUserUid = uid;
              _isCustomAdminLoggedIn = email.contains('admin');
              _status = AuthStatus.authenticated;
              _errorMessage = '';

              await _saveActiveSession(email, name, uid, isAdmin: _isCustomAdminLoggedIn);
              notifyListeners();
              return true;
            } else {
              _errorMessage = 'Mật khẩu không chính xác.';
              _status = AuthStatus.unauthenticated;
              notifyListeners();
              return false;
            }
          }
        } catch (_) {}
      }

      _errorMessage = 'Không tìm thấy tài khoản với email này.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (_) {
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
    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'profile',
        ],
      );

      // Đăng xuất bộ nhớ tạm để luôn hiện hộp thoại chọn tài khoản & bảng xác nhận của Google
      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // Người dùng đã hủy chọn tài khoản Google
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

      final email = googleUser.email.trim().toLowerCase();
      final name = googleUser.displayName ?? email.split('@').first;
      final photo = googleUser.photoUrl;

      // 1. Kiểm tra tài khoản đã tồn tại trước đó chưa (Đăng ký bằng Email trước đó)
      final existingAccount = await _getLocalAccountByEmail(email);
      final existingPassword = await _getLocalPasswordForEmail(email);

      final auth = _auth;
      UserCredential? userCredential;

      if (auth != null) {
        try {
          // A. Nếu tài khoản đã được đăng ký bằng Email & Password trước đó trong phiên hoặc Firebase:
          // Đăng nhập vào tài khoản gốc và Liên kết (Link) với Google Credential để Firebase Auth KHÔNG TẠO 2 USER!
          if (existingPassword != null) {
            try {
              final emailAuth = await auth.signInWithEmailAndPassword(
                email: email,
                password: existingPassword,
              );
              if (emailAuth.user != null) {
                try {
                  await emailAuth.user!.linkWithCredential(credential);
                } catch (_) {}
                userCredential = emailAuth;
              }
            } catch (_) {
              userCredential = await auth.signInWithCredential(credential);
            }
          } else {
            userCredential = await auth.signInWithCredential(credential);
          }
        } on FirebaseAuthException catch (e) {
          // B. Nếu gặp lỗi account-exists-with-different-credential:
          // Tự động liên kết mượt mà với tài khoản email/mật khẩu sẵn có
          if (e.code == 'account-exists-with-different-credential' &&
              existingPassword != null) {
            try {
              final emailAuth = await auth.signInWithEmailAndPassword(
                email: email,
                password: existingPassword,
              );
              if (emailAuth.user != null) {
                try {
                  await emailAuth.user!.linkWithCredential(credential);
                } catch (_) {}
                userCredential = emailAuth;
              }
            } catch (_) {}
          } else {
            rethrow;
          }
        }
      }

      // 2. Đồng nhất User ID (Canonical UID) duy nhất theo Email:
      // Giữ nguyên UID đã đăng ký bằng Email trước đó để KHÔNG BỊ TÁCH THÀNH 2 USER
      final String unifiedUid = userCredential?.user?.uid ??
          existingAccount?['uid'] ??
          'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

      // 3. Hợp nhất thông tin tài khoản (Unified Account Record)
      await _mergeOrSaveLocalAccount(
        email: email,
        name: existingAccount?['name'] ?? name,
        uid: unifiedUid,
        photoUrl: photo ?? existingAccount?['photoUrl'],
        googleId: googleUser.id,
        isGoogleLinked: true,
        password: existingPassword,
      );

      _user = userCredential?.user;
      _customUserEmail = email;
      _customUserName = existingAccount?['name'] ?? name;
      _customUserPhotoUrl = photo ?? existingAccount?['photoUrl'];
      _customUserUid = unifiedUid;
      _isCustomAdminLoggedIn = email.contains('admin');
      _status = AuthStatus.authenticated;
      _errorMessage = '';

      await _saveActiveSession(
        email,
        _customUserName!,
        unifiedUid,
        isAdmin: _isCustomAdminLoggedIn,
      );
      if (photo != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_profile_photo', photo);
        await prefs.setString('user_profile_name', _customUserName!);
      }

      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _getVietnameseErrorMessage(e.code, e.message);
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      final err = e.toString();
      if (err.contains('ApiException: 10') || err.contains('sign_in_failed')) {
        _errorMessage =
            'Lỗi Google Sign-In (Code 10): Chưa thêm mã SHA-1 vào Firebase Console (Project Settings > Your Apps).';
      } else {
        _errorMessage = 'Đăng nhập Google thất bại: $e';
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithFacebook() async {
    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    final auth = _auth;
    if (auth == null) {
      _errorMessage = 'Dịch vụ xác thực Firebase chưa sẵn sàng.';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }

    try {
      // Cách chuẩn của Firebase Auth SDK: mở cửa sổ xác thực Facebook OAuth
      final facebookProvider = FacebookAuthProvider();
      final userCredential = await auth.signInWithProvider(facebookProvider);
      final user = userCredential.user;

      if (user != null) {
        _user = user;
        final email = user.email ?? 'fb_${user.uid}@facebook.com';
        final name = user.displayName ?? 'Facebook User';
        final photo = user.photoURL;

        _customUserEmail = email;
        _customUserName = name;
        _customUserPhotoUrl = photo;
        _customUserUid = user.uid;
        _isCustomAdminLoggedIn = false;
        _status = AuthStatus.authenticated;
        _errorMessage = '';

        await _saveActiveSession(email, name, user.uid, isAdmin: false);
        if (photo != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_profile_photo', photo);
          await prefs.setString('user_profile_name', name);
        }

        notifyListeners();
        return true;
      }

      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed' ||
          e.code == 'admin-restricted-operation') {
        _errorMessage =
            'Chưa bật Facebook Sign-In trên Firebase Console. Cần vào Authentication > Sign-in method > Facebook để bật và cấu hình App ID/Secret.';
      } else {
        _errorMessage = _getVietnameseErrorMessage(e.code, e.message);
      }
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Đăng nhập Facebook thất bại: $e';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isCustomAdminLoggedIn = false;
    _customUserEmail = null;
    _customUserName = null;
    _customUserUid = null;
    await _clearActiveSession();
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

  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? photoUrl,
    String? bio,
  }) async {
    if (name != null && name.trim().isNotEmpty) {
      _customUserName = name.trim();
    }
    if (phone != null) {
      _customUserPhone = phone.trim();
    }
    if (photoUrl != null) {
      _customUserPhotoUrl = photoUrl.trim();
    }
    if (bio != null) {
      _customUserBio = bio.trim();
    }

    await _saveProfilePrefs();

    final user = _user;
    if (user != null) {
      try {
        if (name != null && name.trim().isNotEmpty) {
          await user.updateDisplayName(name.trim());
        }
        if (photoUrl != null && photoUrl.trim().isNotEmpty) {
          await user.updatePhotoURL(photoUrl.trim());
        }
        await user.reload();
        _user = _auth?.currentUser ?? user;
      } catch (_) {}
    }

    _errorMessage = '';
    notifyListeners();
    return true;
  }

  Future<bool> updateDisplayName(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Tên hiển thị không được để trống.';
      notifyListeners();
      return false;
    }

    return updateProfile(name: trimmedName);
  }

  String _getVietnameseErrorMessage(String code, [String? message]) {
    switch (code) {
      case 'configuration-not-found':
        return 'Chưa bật tính năng Xác thực Email/Password trên Firebase Console.';
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
      case 'unknown':
        return 'Chưa bật tính năng Xác thực Email/Password trên Firebase Console (Vào Console > Authentication > Sign-in method để bật).';
      default:
        return message != null && message.isNotEmpty
            ? '$message ($code)'
            : 'Đã có lỗi xảy ra ($code). Vui lòng thử lại.';
    }
  }
}
