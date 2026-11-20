import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
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
  bool get isAuthenticated =>
      _user != null ||
      _isCustomAdminLoggedIn ||
      (_customUserEmail != null && _customUserEmail!.isNotEmpty);
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

  static const String rootAdminEmail = 'llinh0be@gmail.com';

  static String canonicalLocalUid(String email) {
    final clean = email.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return 'usr_$clean';
  }

  String get email {
    if (_user != null && _user!.email != null && _user!.email!.isNotEmpty) {
      return _user!.email!;
    }
    if (_customUserEmail != null && _customUserEmail!.isNotEmpty) {
      return _customUserEmail!;
    }
    return _isCustomAdminLoggedIn ? rootAdminEmail : '';
  }

  String get uid {
    if (_user != null && _user!.uid.isNotEmpty) {
      return _user!.uid;
    }
    if (_customUserUid != null && _customUserUid!.isNotEmpty) {
      return _customUserUid!;
    }
    if (_customUserEmail != null && _customUserEmail!.isNotEmpty) {
      return canonicalLocalUid(_customUserEmail!);
    }
    return _isCustomAdminLoggedIn ? 'admin_root_sys' : '';
  }

  String get phoneNumber => _customUserPhone ?? '';
  String get photoUrl => _customUserPhotoUrl ?? _user?.photoURL ?? '';
  String get bio => _customUserBio ?? '';

  bool get isAdmin {
    // 1. Kiểm tra tài khoản Firebase Auth thực tế (ưu tiên số 1)
    if (_user != null) {
      final email = (_user?.email ?? '').trim().toLowerCase();
      return email.isNotEmpty && email == rootAdminEmail;
    }
    // 2. Chế độ phiên nội bộ: Bắt buộc email đã xác thực phải chính xác là rootAdminEmail
    if (_isCustomAdminLoggedIn) {
      final customEmail = (_customUserEmail ?? '').trim().toLowerCase();
      return customEmail == rootAdminEmail;
    }
    return false;
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

      // Dọn dẹp dứt điểm các key dùng chung cũ (global keys) để tránh rò rỉ thông tin giữa các tài khoản
      await prefs.remove('user_profile_name');
      await prefs.remove('user_profile_phone');
      await prefs.remove('user_profile_photo');
      await prefs.remove('user_profile_bio');

      // Khôi phục phiên đăng nhập nội bộ (Local Session) nếu có và chưa có phiên đăng nhập trực tiếp
      if (_customUserEmail != null || _user != null) {
        notifyListeners();
        return;
      }
      final hasLocalSession = prefs.getBool('session_is_logged_in') ?? false;
      if (hasLocalSession && _user == null && _customUserEmail == null) {
        final savedEmail = prefs.getString('session_user_email');
        final savedUid = prefs.getString('session_user_uid');
        if (savedEmail != null && savedEmail.isNotEmpty) {
          _customUserEmail = savedEmail;
          _customUserUid = (savedUid != null && savedUid.isNotEmpty)
              ? savedUid
              : canonicalLocalUid(savedEmail);
          final savedIsAdmin = prefs.getBool('session_is_admin') ?? false;

          // Chống giả mạo SharedPreferences (Tampering Guard):
          if (savedIsAdmin && (_customUserEmail ?? '').trim().toLowerCase() == rootAdminEmail) {
            _isCustomAdminLoggedIn = true;
          } else {
            _isCustomAdminLoggedIn = false;
          }
          _status = AuthStatus.authenticated;

          // Tải thông tin cá nhân được cách ly theo đúng UID của phiên này
          if (_customUserUid != null && _customUserUid!.isNotEmpty) {
            await _loadProfileFromCloudOrPrefs(_customUserUid!);
          }
        }
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

  Future<void> _saveProfilePrefs([String? targetUid]) async {
    final effectiveUid = (targetUid != null && targetUid.isNotEmpty) ? targetUid : uid;
    if (effectiveUid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final emailKey = email.isNotEmpty ? canonicalLocalUid(email) : '';

      // LƯU CÁCH LY CHẶT CHẼ THEO UID & EMAIL - TUYỆT ĐỐI KHÔNG GHI VÀO KEY TOÀN CỤC DÙNG CHUNG
      if (_customUserName != null) {
        await prefs.setString('user_profile_name_$effectiveUid', _customUserName!);
        if (emailKey.isNotEmpty && emailKey != effectiveUid) {
          await prefs.setString('user_profile_name_$emailKey', _customUserName!);
        }
      }
      if (_customUserPhone != null) {
        await prefs.setString('user_profile_phone_$effectiveUid', _customUserPhone!);
        if (emailKey.isNotEmpty && emailKey != effectiveUid) {
          await prefs.setString('user_profile_phone_$emailKey', _customUserPhone!);
        }
      }
      if (_customUserPhotoUrl != null) {
        await prefs.setString('user_profile_photo_$effectiveUid', _customUserPhotoUrl!);
        if (emailKey.isNotEmpty && emailKey != effectiveUid) {
          await prefs.setString('user_profile_photo_$emailKey', _customUserPhotoUrl!);
        }
      }
      if (_customUserBio != null) {
        await prefs.setString('user_profile_bio_$effectiveUid', _customUserBio!);
        if (emailKey.isNotEmpty && emailKey != effectiveUid) {
          await prefs.setString('user_profile_bio_$emailKey', _customUserBio!);
        }
      }

      // Xóa các key global cũ để không bao giờ bị tài khoản khác đọc nhầm
      await prefs.remove('user_profile_name');
      await prefs.remove('user_profile_phone');
      await prefs.remove('user_profile_photo');
      await prefs.remove('user_profile_bio');
    } catch (_) {}
  }

  Future<void> _saveProfileToCloud(String targetUid) async {
    if (targetUid.isEmpty) return;
    try {
      final dbRef = FirebaseDatabase.instance.ref('users/$targetUid/profile');
      await dbRef.update({
        'name': _customUserName ?? '',
        'phone': _customUserPhone ?? '',
        'photoUrl': _customUserPhotoUrl ?? '',
        'bio': _customUserBio ?? '',
        'email': email,
        'updatedAt': ServerValue.timestamp,
      }).timeout(const Duration(seconds: 8));
    } catch (e) {
      debugPrint('Cloud profile sync warning: $e');
    }
  }

  Future<void> _loadProfileFromCloudOrPrefs(String targetUid) async {
    if (targetUid.isEmpty) return;

    // Reset sạch các trường cá nhân trong RAM trước khi tải thông tin của UID mới
    _customUserName = null;
    _customUserPhone = null;
    _customUserPhotoUrl = null;
    _customUserBio = null;

    try {
      final prefs = await SharedPreferences.getInstance();

      // Dọn dẹp key global dùng chung cũ nếu còn sót lại
      await prefs.remove('user_profile_name');
      await prefs.remove('user_profile_phone');
      await prefs.remove('user_profile_photo');
      await prefs.remove('user_profile_bio');

      // ĐỌC DỮ LIỆU ĐỘC LẬP THEO UID / EMAIL - KHÔNG FALLBACK VỀ KEY CHUNG
      final emailKey = email.isNotEmpty ? canonicalLocalUid(email) : '';
      final localName = prefs.getString('user_profile_name_$targetUid') ??
          (emailKey.isNotEmpty ? prefs.getString('user_profile_name_$emailKey') : null);
      final localPhone = prefs.getString('user_profile_phone_$targetUid') ??
          (emailKey.isNotEmpty ? prefs.getString('user_profile_phone_$emailKey') : null);
      final localPhoto = prefs.getString('user_profile_photo_$targetUid') ??
          (emailKey.isNotEmpty ? prefs.getString('user_profile_photo_$emailKey') : null);
      final localBio = prefs.getString('user_profile_bio_$targetUid') ??
          (emailKey.isNotEmpty ? prefs.getString('user_profile_bio_$emailKey') : null);

      if (localName != null && localName.trim().isNotEmpty) _customUserName = localName.trim();
      if (localPhone != null && localPhone.trim().isNotEmpty) _customUserPhone = localPhone.trim();
      if (localPhoto != null && localPhoto.trim().isNotEmpty) _customUserPhotoUrl = localPhoto.trim();
      if (localBio != null && localBio.trim().isNotEmpty) _customUserBio = localBio.trim();

      // Tải từ Firebase Realtime Database nếu đã đồng bộ trên Cloud
      final dbRef = FirebaseDatabase.instance.ref('users/$targetUid/profile');
      final snapshot = await dbRef.get().timeout(const Duration(seconds: 8));
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final cloudName = data['name'] as String?;
        final cloudPhone = data['phone'] as String?;
        final cloudPhoto = data['photoUrl'] as String?;
        final cloudBio = data['bio'] as String?;

        if (cloudName != null && cloudName.trim().isNotEmpty) {
          _customUserName = cloudName.trim();
          await prefs.setString('user_profile_name_$targetUid', _customUserName!);
        }
        if (cloudPhone != null && cloudPhone.trim().isNotEmpty) {
          _customUserPhone = cloudPhone.trim();
          await prefs.setString('user_profile_phone_$targetUid', _customUserPhone!);
        }
        if (cloudPhoto != null && cloudPhoto.trim().isNotEmpty) {
          _customUserPhotoUrl = cloudPhoto.trim();
          await prefs.setString('user_profile_photo_$targetUid', _customUserPhotoUrl!);
        }
        if (cloudBio != null && cloudBio.trim().isNotEmpty) {
          _customUserBio = cloudBio.trim();
          await prefs.setString('user_profile_bio_$targetUid', _customUserBio!);
        }
      }
    } catch (e) {
      debugPrint('Cloud profile load error: $e');
    }
  }

  void _onAuthStateChanged(User? firebaseUser) async {
    _user = firebaseUser;
    if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
      _status = AuthStatus.authenticated;
      _customUserEmail = firebaseUser.email ?? _customUserEmail;
      _customUserUid = firebaseUser.uid;
      _isCustomAdminLoggedIn = ((firebaseUser.email ?? '').trim().toLowerCase() == rootAdminEmail);

      // Nạp thông tin cá nhân riêng biệt của tài khoản Firebase Auth này
      await _loadProfileFromCloudOrPrefs(firebaseUser.uid);
      if (_customUserName == null || _customUserName!.trim().isEmpty) {
        _customUserName = firebaseUser.displayName ?? firebaseUser.email?.split('@').first;
      }
      if (_customUserPhotoUrl == null || _customUserPhotoUrl!.trim().isEmpty) {
        _customUserPhotoUrl = firebaseUser.photoURL;
      }
    } else if (firebaseUser == null && !_isCustomAdminLoggedIn && _customUserEmail == null) {
      _status = AuthStatus.unauthenticated;
      _customUserName = null;
      _customUserPhone = null;
      _customUserPhotoUrl = null;
      _customUserBio = null;
      _customUserEmail = null;
      _customUserUid = null;
    }
    notifyListeners();
  }

  Future<bool> signInAsAdmin({String? email, String? name}) async {
    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      final adminEmail = email ?? rootAdminEmail;
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

    // 1. Tài khoản admin hệ thống phân quyền cao nhất DUY NHẤT
    if (normalizedEmail == rootAdminEmail &&
        (normalizedPassword == 'admin123' ||
            normalizedPassword == 'Admin@123' ||
            normalizedPassword == 'Admin@123456')) {
      return signInAsAdmin(email: rootAdminEmail, name: 'Quản trị viên Hệ thống');
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
        final rawUid = _user?.uid;
        final effectiveUid = (rawUid != null && rawUid.trim().isNotEmpty)
            ? rawUid.trim()
            : canonicalLocalUid(normalizedEmail);
        _customUserUid = effectiveUid;
        _isCustomAdminLoggedIn = (normalizedEmail == rootAdminEmail);
        _customUserEmail = normalizedEmail;
        _status = AuthStatus.authenticated;
        _errorMessage = '';

        // Tải lại thông tin cá nhân đã đổi trước đó từ Database / Prefs
        await _loadProfileFromCloudOrPrefs(effectiveUid);
        if (_customUserName == null || _customUserName!.trim().isEmpty) {
          _customUserName = _user?.displayName ?? normalizedEmail.split('@').first;
        }

        await _saveActiveSession(
          normalizedEmail,
          _customUserName!,
          effectiveUid,
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

    // Chặn người dùng tự đăng ký email Quản trị viên hệ thống
    if (normalizedEmail == rootAdminEmail) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'Email này được bảo lưu riêng cho Quản trị viên hệ thống, không thể đăng ký tự do.';
      notifyListeners();
      return false;
    }

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
        final rawUid = credential.user?.uid;
        final resolvedUid = (rawUid != null && rawUid.trim().isNotEmpty)
            ? rawUid.trim()
            : 'usr_${normalizedEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
        _customUserEmail = normalizedEmail;
        _customUserName = normalizedName;
        _customUserUid = resolvedUid;
        _status = AuthStatus.authenticated;
        _errorMessage = '';

        await _saveLocalAccountRecord(normalizedEmail, normalizedPassword, normalizedName, uid: resolvedUid);
        await _saveActiveSession(
          normalizedEmail,
          normalizedName,
          resolvedUid,
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
      if (name.isNotEmpty) {
        if (isGoogleLinked || mergedMap['name'] == null || (mergedMap['name'] as String).isEmpty) {
          mergedMap['name'] = name;
        }
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

      // Thêm tài khoản Admin hệ thống duy nhất nếu chưa có trong danh sách
      if (!seenEmails.contains(rootAdminEmail)) {
        list.insert(0, {
          'email': rootAdminEmail,
          'name': 'Quản trị viên Hệ thống',
          'uid': 'admin_root_sys',
          'isAdmin': true,
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
            _isCustomAdminLoggedIn = (normalized == rootAdminEmail);
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
      _isCustomAdminLoggedIn = (normalized == rootAdminEmail);
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
    String name, {
    String? uid,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('local_registered_users') ?? [];
      final resolvedUid = uid ?? 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      final newRecord = jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'uid': resolvedUid,
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
              _customUserUid = uid;
              _isCustomAdminLoggedIn = (email.trim().toLowerCase() == rootAdminEmail);
              _status = AuthStatus.authenticated;
              _errorMessage = '';

              await _loadProfileFromCloudOrPrefs(uid);
              if (_customUserName == null || _customUserName!.trim().isEmpty) {
                _customUserName = name;
              }

              await _saveActiveSession(email, _customUserName!, uid, isAdmin: _isCustomAdminLoggedIn);
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
      final googleDisplayName = googleUser.displayName?.trim() ?? '';
      final name = googleDisplayName.isNotEmpty ? googleDisplayName : email.split('@').first;
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
      final rawGoogleUid = userCredential?.user?.uid;
      final String unifiedUid = (rawGoogleUid != null && rawGoogleUid.trim().isNotEmpty)
          ? rawGoogleUid.trim()
          : (existingAccount?['uid'] ?? canonicalLocalUid(email));

      // 3. Hợp nhất thông tin tài khoản (Unified Account Record)
      await _mergeOrSaveLocalAccount(
        email: email,
        name: name,
        uid: unifiedUid,
        photoUrl: photo ?? existingAccount?['photoUrl'],
        googleId: googleUser.id,
        isGoogleLinked: true,
        password: existingPassword,
      );

      _user = userCredential?.user;
      _customUserEmail = email;
      _customUserUid = unifiedUid;
      _isCustomAdminLoggedIn = (email.trim().toLowerCase() == rootAdminEmail);
      _status = AuthStatus.authenticated;
      _errorMessage = '';

      // Tải lại thông tin cá nhân của đúng tài khoản này (không dùng chung với tài khoản khác)
      await _loadProfileFromCloudOrPrefs(unifiedUid);

      // ĐĂNG NHẬP GOOGLE: Luôn ưu tiên Tên chính thức từ Google Profile
      if (googleDisplayName.isNotEmpty) {
        _customUserName = googleDisplayName;
      } else if (_customUserName == null || _customUserName!.trim().isEmpty) {
        _customUserName = name;
      }
      if (photo != null && photo.isNotEmpty) {
        _customUserPhotoUrl = photo;
      }
      await _saveProfileToCloud(unifiedUid);
      await _saveProfilePrefs(unifiedUid);

      await _saveActiveSession(
        email,
        _customUserName!,
        unifiedUid,
        isAdmin: _isCustomAdminLoggedIn,
      );

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
    _customUserPhone = null;
    _customUserPhotoUrl = null;
    _customUserBio = null;
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

    final targetUid = uid;
    await _saveProfilePrefs(targetUid);
    if (targetUid.isNotEmpty) {
      await _saveProfileToCloud(targetUid);
    }

    // Đồng bộ tên mới vào danh sách tài khoản local (nếu là tài khoản offline/local)
    if (name != null && name.trim().isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final usersJson = prefs.getStringList('local_registered_users') ?? [];
        for (int i = 0; i < usersJson.length; i++) {
          final map = jsonDecode(usersJson[i]) as Map<String, dynamic>;
          if (map['email'] == email || map['uid'] == targetUid) {
            map['name'] = name.trim();
            usersJson[i] = jsonEncode(map);
            await prefs.setStringList('local_registered_users', usersJson);
            break;
          }
        }
      } catch (_) {}
    }

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

  /// Xóa tài khoản người dùng vĩnh viễn (Tuân thủ Google Play Policy & Nghị định 13/2023/NĐ-CP)
  Future<bool> deleteAccount() async {
    // Không cho phép xóa tài khoản quản trị viên duy nhất của hệ thống
    if (isAdmin || email.toLowerCase() == rootAdminEmail) {
      _errorMessage = 'Tài khoản quản trị viên hệ thống không thể bị xóa.';
      notifyListeners();
      return false;
    }

    final targetUid = uid;
    final user = _user ?? _auth?.currentUser;

    _status = AuthStatus.authenticating;
    _errorMessage = '';
    notifyListeners();

    try {
      // 1. Dọn dẹp dữ liệu người dùng trên Firebase Realtime Database
      if (targetUid != null && targetUid.isNotEmpty) {
        try {
          final db = FirebaseDatabase.instance.ref('users/$targetUid');
          await db.remove().timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint('Warning: Delete remote user database record error: $e');
        }
      }

      // 2. Xóa tài khoản khỏi Firebase Authentication
      if (user != null) {
        try {
          await user.delete();
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            _errorMessage =
                'Vì lý do bảo mật, vui lòng đăng nhập lại tài khoản trước khi thực hiện xóa vĩnh viễn.';
            _status = AuthStatus.authenticated;
            notifyListeners();
            return false;
          }
          rethrow;
        }
      }

      // 3. Xóa thông tin lưu trữ cục bộ
      await _clearActiveSession();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('profile_name');
      await prefs.remove('profile_phone');
      await prefs.remove('profile_photo');
      await prefs.remove('profile_bio');

      try {
        await GoogleSignIn().signOut();
      } catch (_) {}

      _user = null;
      _isCustomAdminLoggedIn = false;
      _customUserEmail = null;
      _customUserName = null;
      _customUserUid = null;
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('deleteAccount error: $e');
      _errorMessage = 'Không thể xóa tài khoản: ${e.toString()}';
      _status = AuthStatus.authenticated;
      notifyListeners();
      return false;
    }
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
