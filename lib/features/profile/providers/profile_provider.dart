import 'package:flutter/foundation.dart';
import '../../auth/providers/auth_provider.dart';

/// ProfileProvider quản lý trạng thái của module Thông tin cá nhân & Hồ sơ (Profile),
/// bao gồm lựa chọn avatar đại diện, trạng thái lưu hồ sơ, và các preset hình ảnh.
class ProfileProvider extends ChangeNotifier {
  String _selectedAvatar = '';
  bool _isSaving = false;
  String? _errorMessage;

  final List<String> _avatarPresets = const [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
  ];

  String get selectedAvatar => _selectedAvatar;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<String> get avatarPresets => _avatarPresets;

  /// Khởi tạo avatar ban đầu từ AuthProvider
  void initAvatar(String currentAvatar) {
    _selectedAvatar = currentAvatar;
    _errorMessage = null;
  }

  /// Chọn một avatar đại diện
  void selectAvatar(String url) {
    if (_selectedAvatar == url) return;
    _selectedAvatar = url;
    notifyListeners();
  }

  /// Cập nhật hồ sơ người dùng qua AuthProvider
  Future<bool> saveProfile({
    required AuthProvider authProvider,
    required String name,
    required String phone,
    required String bio,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await authProvider.updateProfile(
        name: name.trim(),
        phone: phone.trim(),
        photoUrl: _selectedAvatar.trim(),
        bio: bio.trim(),
      );

      if (!success) {
        _errorMessage = authProvider.errorMessage;
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
