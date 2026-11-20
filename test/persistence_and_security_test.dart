import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_news_weather_portal/models/article.dart';
import 'package:daily_news_weather_portal/services/weather_service.dart';
import 'package:daily_news_weather_portal/features/favorites/providers/favorites_provider.dart';
import 'package:daily_news_weather_portal/features/search/providers/search_provider.dart';
import 'package:daily_news_weather_portal/features/auth/providers/auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Auto-Merge & Deduplication Test (Khách lưu -> Đăng nhập gộp dữ liệu)', () {
    test('Khách lưu 3 bài & 2 thành phố -> Đăng nhập tài khoản có 1 bài trùng + 1 bài mới: Gộp đúng, không trùng, xóa dữ liệu khách', () async {
      final guestArticle1 = const Article(
        id: 'art_1',
        title: 'Tin tức số 1 của Khách',
        link: 'https://vnexpress.net/tin-1',
        description: 'Mô tả 1',
        source: 'VNExpress',
      );
      final guestArticle2 = const Article(
        id: 'art_2',
        title: 'Tin tức số 2 của Khách',
        link: 'https://vnexpress.net/tin-2',
        description: 'Mô tả 2',
        source: 'VNExpress',
      );
      final guestArticle3 = const Article(
        id: 'art_3',
        title: 'Tin tức số 3 của Khách (sẽ bị trùng với User)',
        link: 'https://vnexpress.net/tin-trung',
        description: 'Mô tả trùng',
        source: 'VNExpress',
      );

      final guestCity1 = const City('Đà Nẵng', 16.0544, 108.2022);
      final guestCity2 = const City('Cần Thơ', 10.0452, 105.7469);

      final userArticleDuplicate = const Article(
        id: 'art_3_user',
        title: 'Tin trùng đã có sẵn trên tài khoản',
        link: 'https://vnexpress.net/tin-trung',
        description: 'Mô tả trên user',
        source: 'VNExpress',
      );
      final userArticleUnique = const Article(
        id: 'art_4',
        title: 'Tin riêng chỉ có ở User',
        link: 'https://vnexpress.net/tin-user-rieng',
        description: 'Mô tả riêng',
        source: 'VNExpress',
      );

      final userCityDuplicate = const City('Đà Nẵng', 16.0544, 108.2022);
      final userCityUnique = const City('Hà Nội', 21.0285, 105.8542);

      const testUid = 'user_audit_test_999';

      SharedPreferences.setMockInitialValues({
        'guest_favorite_articles': [
          jsonEncode(guestArticle1.toJson()),
          jsonEncode(guestArticle2.toJson()),
          jsonEncode(guestArticle3.toJson()),
        ],
        'guest_favorite_cities': [
          jsonEncode(guestCity1.toJson()),
          jsonEncode(guestCity2.toJson()),
        ],
        'favorite_articles_$testUid': [
          jsonEncode(userArticleDuplicate.toJson()),
          jsonEncode(userArticleUnique.toJson()),
        ],
        'favorite_cities_$testUid': [
          jsonEncode(userCityDuplicate.toJson()),
          jsonEncode(userCityUnique.toJson()),
        ],
      });

      final favProvider = FavoritesProvider();
      await favProvider.updateUserContext(isAuthenticated: true, uid: testUid);

      final prefs = await SharedPreferences.getInstance();

      expect(favProvider.favorites.length, 4);
      final links = favProvider.favorites.map((a) => a.link).toSet();
      expect(links.contains('https://vnexpress.net/tin-1'), true);
      expect(links.contains('https://vnexpress.net/tin-2'), true);
      expect(links.contains('https://vnexpress.net/tin-trung'), true);
      expect(links.contains('https://vnexpress.net/tin-user-rieng'), true);

      expect(favProvider.favoriteCities.length, 3);
      final cityNames = favProvider.favoriteCities.map((c) => c.name).toSet();
      expect(cityNames.contains('Đà Nẵng'), true);
      expect(cityNames.contains('Cần Thơ'), true);
      expect(cityNames.contains('Hà Nội'), true);

      expect(prefs.getStringList('guest_favorite_articles'), isNull);
      expect(prefs.getStringList('guest_favorite_cities'), isNull);

      final savedUserArticles = prefs.getStringList('favorite_articles_$testUid');
      expect(savedUserArticles != null && savedUserArticles.length == 4, true);

      final savedUserCities = prefs.getStringList('favorite_cities_$testUid');
      expect(savedUserCities != null && savedUserCities.length == 3, true);
    });
  });

  group('2. Deduplication Precision (Tiêu chí xác định trùng lặp)', () {
    test('Bài viết: Nhận diện trùng theo URL chuẩn hóa (loại bỏ tracking params, trailing slash)', () {
      final a1 = const Article(
        title: 'Tiêu đề A',
        link: 'https://vnexpress.net/giai-tri/phim-hay/',
        description: '',
        source: 'VNExpress',
      );
      final a2 = const Article(
        title: 'Tiêu đề A khác',
        link: 'https://vnexpress.net/giai-tri/phim-hay?utm_source=facebook&utm_medium=cpc&ref=feed',
        description: '',
        source: 'VNExpress',
      );

      expect(FavoritesProvider.isSameArticle(a1, a2), true);

      final a3 = const Article(
        title: 'Bài khác',
        link: 'https://vnexpress.net/the-thao/bong-da',
        description: '',
        source: 'VNExpress',
      );
      expect(FavoritesProvider.isSameArticle(a1, a3), false);
    });

    test('Thành phố: Trùng tên nhưng tọa độ cách xa (> 500km) coi là 2 thành phố khác nhau, không bị mất bài', () {
      final cityA = const City('An Phú', 10.7725, 105.0894);
      final cityB = const City('An Phú', 21.4312, 104.9812);

      expect(FavoritesProvider.isSameCity(cityA, cityB), false);
    });

    test('Thành phố: Cùng tọa độ (sai số < 2km) được coi là cùng một địa điểm dù tên viết hoa/thường lệch', () {
      final city1 = const City('Hà Nội', 21.0285, 105.8542);
      final city2 = const City('ha noi', 21.0290, 105.8540);

      expect(FavoritesProvider.isSameCity(city1, city2), true);
    });
  });

  group('3. Search History Privacy Isolation (Cách ly lịch sử tìm kiếm theo tài khoản)', () {
    test('Người A đăng xuất, Người B hoặc Khách đăng nhập không được thấy lịch sử của Người A', () async {
      SharedPreferences.setMockInitialValues({});
      final searchProvider = SearchProvider();

      await searchProvider.updateUserContext(null);
      await searchProvider.saveHistory('thời tiết ngày mai');
      expect(searchProvider.history.contains('thời tiết ngày mai'), true);

      await searchProvider.updateUserContext('user_A');
      await searchProvider.saveHistory('khám bệnh da liễu');
      await searchProvider.saveHistory('thuốc hạ sốt trẻ em');
      expect(searchProvider.history.contains('khám bệnh da liễu'), true);
      expect(searchProvider.history.contains('thuốc hạ sốt trẻ em'), true);

      await searchProvider.updateUserContext(null);
      expect(searchProvider.history.contains('khám bệnh da liễu'), false);
      expect(searchProvider.history.contains('thuốc hạ sốt trẻ em'), false);
      expect(searchProvider.history.contains('thời tiết ngày mai'), true);

      await searchProvider.updateUserContext('user_B');
      expect(searchProvider.history.contains('khám bệnh da liễu'), false);
      expect(searchProvider.history.contains('thời tiết ngày mai'), false);

      await searchProvider.saveHistory('tin bóng đá ngoại hạng anh');
      expect(searchProvider.history.contains('tin bóng đá ngoại hạng anh'), true);

      await searchProvider.updateUserContext('user_A');
      expect(searchProvider.history.contains('khám bệnh da liễu'), true);
      expect(searchProvider.history.contains('tin bóng đá ngoại hạng anh'), false);
    });
  });

  group('4. Admin Security & Tampering Resistance Test', () {
    test('Giả lập hacker sửa file SharedPreferences đổi session_is_admin=true với email thường: Hệ thống từ chối quyền Admin', () async {
      SharedPreferences.setMockInitialValues({
        'session_is_logged_in': true,
        'session_is_admin': true,
        'session_user_email': 'hacker@malicious.com',
        'session_user_uid': 'hacker_123',
      });

      final authProvider = AuthProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(authProvider.isAdmin, false);
    });

    test('Người dùng thường cố ý đăng ký email llinh0be@gmail.com: Hệ thống chặn ngay lập tức', () async {
      SharedPreferences.setMockInitialValues({});
      final authProvider = AuthProvider();

      final registered = await authProvider.register('llinh0be@gmail.com', '123456', name: 'Fake Admin');
      expect(registered, false);
      expect(authProvider.isAdmin, false);
      expect(authProvider.errorMessage.contains('bảo lưu riêng cho Quản trị viên'), true);
    });

    test('Chỉ tài khoản có email llinh0be@gmail.com mới được công nhận quyền Admin', () async {
      SharedPreferences.setMockInitialValues({
        'session_is_logged_in': true,
        'session_is_admin': true,
        'session_user_email': 'llinh0be@gmail.com',
        'session_user_uid': 'admin_root_sys',
      });

      final authProvider = AuthProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(authProvider.isAdmin, true);
    });
  });

  group('5. Offline-first Resilience & Local Fallback Test', () {
    test('Khi mất mạng / Firebase không kết nối: Bấm tim vẫn lưu an toàn vào cache máy mà không crash', () async {
      SharedPreferences.setMockInitialValues({});
      final favProvider = FavoritesProvider();
      await favProvider.updateUserContext(isAuthenticated: true, uid: 'offline_user');

      final article = const Article(
        title: 'Tin tức đọc offline',
        link: 'https://vnexpress.net/offline-reading',
        description: 'Mô tả offline',
        source: 'VNExpress',
      );

      final city = const City('Hải Phòng', 20.8449, 106.6881);

      final articleSuccess = await favProvider.toggleFavorite(article);
      final citySuccess = await favProvider.toggleFavoriteCity(city);

      expect(articleSuccess, true);
      expect(citySuccess, true);
      expect(favProvider.isFavorite(article), true);
      expect(favProvider.isFavoriteCity(city), true);

      final prefs = await SharedPreferences.getInstance();
      final savedArticles = prefs.getStringList('favorite_articles_offline_user');
      final savedCities = prefs.getStringList('favorite_cities_offline_user');

      expect(savedArticles != null && savedArticles.isNotEmpty, true);
      expect(savedCities != null && savedCities.isNotEmpty, true);
    });
  });

  group('6. Profile Privacy & Account Isolation Test (Mỗi tài khoản độc lập, không dùng chung thông tin cá nhân)', () {
    test('Người dùng A cập nhật SĐT -> Đăng xuất -> Người dùng B / Google đăng nhập: Không bị rò rỉ SĐT hay Tên của A', () async {
      SharedPreferences.setMockInitialValues({});
      final authProvider = AuthProvider();

      // 1. Tài khoản A đăng ký và cập nhật SĐT & Tên
      final regA = await authProvider.register('usera@example.com', 'Pass123456', name: 'Người Dùng A');
      expect(regA, true);
      expect(authProvider.displayName, 'Người Dùng A');

      await authProvider.updateProfile(
        name: 'Người Dùng A Chính Chủ',
        phone: '0912345678',
        bio: 'Bio của A',
      );
      expect(authProvider.phoneNumber, '0912345678');

      // 2. A đăng xuất
      await authProvider.signOut();
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.phoneNumber, '');

      // 3. Tài khoản B (hoặc tài khoản Google mới) đăng ký/đăng nhập
      final regB = await authProvider.register('userb_google@gmail.com', 'PassB123456', name: 'Google User B');
      expect(regB, true);

      // Bắt buộc: Tài khoản B KHÔNG ĐƯỢC kế thừa SĐT hay Bio của A
      expect(authProvider.displayName, 'Google User B');
      expect(authProvider.phoneNumber, '');
      expect(authProvider.bio, '');

      // 4. B cập nhật SĐT riêng của B
      await authProvider.updateProfile(phone: '0999888777');
      expect(authProvider.phoneNumber, '0999888777');

      // 5. B đăng xuất -> A đăng nhập lại: Mỗi tài khoản giữ nguyên thông tin riêng của mình
      await authProvider.signOut();
      final loginA = await authProvider.signIn('usera@example.com', 'Pass123456');
      expect(loginA, true);
      expect(authProvider.displayName, 'Người Dùng A Chính Chủ');
      expect(authProvider.phoneNumber, '0912345678');
      expect(authProvider.bio, 'Bio của A');
    });

    test('Xóa tài khoản: Dọn sạch hoàn toàn khỏi danh sách hệ thống, Admin không còn thấy tài khoản đã xóa', () async {
      SharedPreferences.setMockInitialValues({});
      final authProvider = AuthProvider();

      // Đăng ký tài khoản User X
      await authProvider.register('userx@example.com', 'Pass123456', name: 'User X');
      var list = await authProvider.getRegisteredUsersList();
      expect(list.any((u) => u['email'] == 'userx@example.com'), true);

      // User X thực hiện xóa tài khoản
      final deleted = await authProvider.deleteAccount();
      expect(deleted, true);

      // Kiểm tra: Admin nạp danh sách không còn User X
      list = await authProvider.getRegisteredUsersList();
      expect(list.any((u) => u['email'] == 'userx@example.com'), false);
    });

    test('Quản trị viên xóa tài khoản người dùng trực tiếp qua Admin Panel', () async {
      SharedPreferences.setMockInitialValues({});
      final authProvider = AuthProvider();

      // Đăng nhập Admin
      await authProvider.signInAsAdmin();
      expect(authProvider.isAdmin, true);

      // Giả lập hệ thống có 1 user thường
      await authProvider.register('baduser@example.com', 'Pass123456', name: 'Bad User');
      await authProvider.signInAsAdmin();

      var list = await authProvider.getRegisteredUsersList();
      expect(list.any((u) => u['email'] == 'baduser@example.com'), true);

      // Admin bấm xóa user
      final adminDeleted = await authProvider.deleteUserByAdmin('baduser@example.com');
      expect(adminDeleted, true);

      list = await authProvider.getRegisteredUsersList();
      expect(list.any((u) => u['email'] == 'baduser@example.com'), false);
    });
  });
}
