import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_news_weather_portal/models/article.dart';
import 'package:daily_news_weather_portal/services/weather_service.dart';
import 'package:daily_news_weather_portal/features/favorites/providers/favorites_provider.dart';
import 'package:daily_news_weather_portal/features/search/providers/search_provider.dart';
import 'package:daily_news_weather_portal/features/auth/providers/auth_provider.dart';
import 'package:daily_news_weather_portal/services/news_service.dart';
import 'package:daily_news_weather_portal/features/news/providers/news_provider.dart';

class MockNewsService implements INewsService {
  @override
  Future<List<Article>> fetchCategory(NewsCategory category, {bool forceRefresh = false}) async {
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
      '1. Auto-Merge & Deduplication Test (Khách lưu -> Đăng nhập gộp dữ liệu)',
      () {
    test(
        'Khách lưu 3 bài & 2 thành phố -> Đăng nhập tài khoản có 1 bài trùng + 1 bài mới: Gộp đúng, không trùng, xóa dữ liệu khách',
        () async {
      const guestArticle1 = Article(
        id: 'art_1',
        title: 'Tin tức số 1 của Khách',
        link: 'https://vnexpress.net/tin-1',
        description: 'Mô tả 1',
        source: 'VNExpress',
      );
      const guestArticle2 = Article(
        id: 'art_2',
        title: 'Tin tức số 2 của Khách',
        link: 'https://vnexpress.net/tin-2',
        description: 'Mô tả 2',
        source: 'VNExpress',
      );
      const guestArticle3 = Article(
        id: 'art_3',
        title: 'Tin tức số 3 của Khách (sẽ bị trùng với User)',
        link: 'https://vnexpress.net/tin-trung',
        description: 'Mô tả trùng',
        source: 'VNExpress',
      );

      const guestCity1 = City('Đà Nẵng', 16.0544, 108.2022);
      const guestCity2 = City('Cần Thơ', 10.0452, 105.7469);

      const userArticleDuplicate = Article(
        id: 'art_3_user',
        title: 'Tin trùng đã có sẵn trên tài khoản',
        link: 'https://vnexpress.net/tin-trung',
        description: 'Mô tả trên user',
        source: 'VNExpress',
      );
      const userArticleUnique = Article(
        id: 'art_4',
        title: 'Tin riêng chỉ có ở User',
        link: 'https://vnexpress.net/tin-user-rieng',
        description: 'Mô tả riêng',
        source: 'VNExpress',
      );

      const userCityDuplicate = City('Đà Nẵng', 16.0544, 108.2022);
      const userCityUnique = City('Hà Nội', 21.0285, 105.8542);

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

      final savedUserArticles =
          prefs.getStringList('favorite_articles_$testUid');
      expect(savedUserArticles != null && savedUserArticles.length == 4, true);

      final savedUserCities = prefs.getStringList('favorite_cities_$testUid');
      expect(savedUserCities != null && savedUserCities.length == 3, true);
    });
  });

  group('2. Deduplication Precision (Tiêu chí xác định trùng lặp)', () {
    test(
        'Bài viết: Nhận diện trùng theo URL chuẩn hóa (loại bỏ tracking params, trailing slash)',
        () {
      const a1 = Article(
        title: 'Tiêu đề A',
        link: 'https://vnexpress.net/giai-tri/phim-hay/',
        description: '',
        source: 'VNExpress',
      );
      const a2 = Article(
        title: 'Tiêu đề A khác',
        link:
            'https://vnexpress.net/giai-tri/phim-hay?utm_source=facebook&utm_medium=cpc&ref=feed',
        description: '',
        source: 'VNExpress',
      );

      expect(FavoritesProvider.isSameArticle(a1, a2), true);

      const a3 = Article(
        title: 'Bài khác',
        link: 'https://vnexpress.net/the-thao/bong-da',
        description: '',
        source: 'VNExpress',
      );
      expect(FavoritesProvider.isSameArticle(a1, a3), false);
    });

    test(
        'Thành phố: Trùng tên nhưng tọa độ cách xa (> 500km) coi là 2 thành phố khác nhau, không bị mất bài',
        () {
      const cityA = City('An Phú', 10.7725, 105.0894);
      const cityB = City('An Phú', 21.4312, 104.9812);

      expect(FavoritesProvider.isSameCity(cityA, cityB), false);
    });

    test(
        'Thành phố: Cùng tọa độ (sai số < 2km) được coi là cùng một địa điểm dù tên viết hoa/thường lệch',
        () {
      const city1 = City('Hà Nội', 21.0285, 105.8542);
      const city2 = City('ha noi', 21.0290, 105.8540);

      expect(FavoritesProvider.isSameCity(city1, city2), true);
    });
  });

  group(
      '3. Search History Privacy Isolation (Cách ly lịch sử tìm kiếm theo tài khoản)',
      () {
    test(
        'Người A đăng xuất, Người B hoặc Khách đăng nhập không được thấy lịch sử của Người A',
        () async {
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
      expect(
          searchProvider.history.contains('tin bóng đá ngoại hạng anh'), true);

      await searchProvider.updateUserContext('user_A');
      expect(searchProvider.history.contains('khám bệnh da liễu'), true);
      expect(
          searchProvider.history.contains('tin bóng đá ngoại hạng anh'), false);
    });
  });

  group('4. Admin Security & Tampering Resistance Test', () {
    test(
        'Giả lập hacker sửa file SharedPreferences đổi session_is_admin=true với email thường: Hệ thống từ chối quyền Admin',
        () async {
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

    test(
        'Người dùng thường cố ý đăng ký email llinh0be@gmail.com: Hệ thống chặn ngay lập tức',
        () async {
      SharedPreferences.setMockInitialValues({});
      final authProvider = AuthProvider();

      final registered = await authProvider
          .register('llinh0be@gmail.com', '123456', name: 'Fake Admin');
      expect(registered, false);
      expect(authProvider.isAdmin, false);
      expect(
          authProvider.errorMessage.contains('bảo lưu riêng cho Quản trị viên'),
          true);
    });

    test(
        'Chỉ tài khoản có email llinh0be@gmail.com mới được công nhận quyền Admin',
        () async {
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
    test(
        'Khi mất mạng / Firebase không kết nối: Bấm tim vẫn lưu an toàn vào cache máy mà không crash',
        () async {
      SharedPreferences.setMockInitialValues({});
      final favProvider = FavoritesProvider();
      await favProvider.updateUserContext(
          isAuthenticated: true, uid: 'offline_user');

      const article = Article(
        title: 'Tin tức đọc offline',
        link: 'https://vnexpress.net/offline-reading',
        description: 'Mô tả offline',
        source: 'VNExpress',
      );

      const city = City('Hải Phòng', 20.8449, 106.6881);

      final articleSuccess = await favProvider.toggleFavorite(article);
      final citySuccess = await favProvider.toggleFavoriteCity(city);

      expect(articleSuccess, true);
      expect(citySuccess, true);
      expect(favProvider.isFavorite(article), true);
      expect(favProvider.isFavoriteCity(city), true);

      final prefs = await SharedPreferences.getInstance();
      final savedArticles =
          prefs.getStringList('favorite_articles_offline_user');
      final savedCities = prefs.getStringList('favorite_cities_offline_user');

      expect(savedArticles != null && savedArticles.isNotEmpty, true);
      expect(savedCities != null && savedCities.isNotEmpty, true);
    });
  });

  group(
      '6. Profile Privacy & Account Isolation Test (Mỗi tài khoản độc lập, không dùng chung thông tin cá nhân)',
      () {
    test(
        'Người dùng A cập nhật SĐT -> Đăng xuất -> Người dùng B / Google đăng nhập: Không bị rò rỉ SĐT hay Tên của A',
        () async {
      SharedPreferences.setMockInitialValues({});
      final authProvider = AuthProvider();

      // 1. Tài khoản A đăng ký và cập nhật SĐT & Tên
      final regA = await authProvider
          .register('usera@example.com', 'Pass123456', name: 'Người Dùng A');
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
      final regB = await authProvider.register(
          'userb_google@gmail.com', 'PassB123456',
          name: 'Google User B');
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
      final loginA =
          await authProvider.signIn('usera@example.com', 'Pass123456');
      expect(loginA, true);
      expect(authProvider.displayName, 'Người Dùng A Chính Chủ');
      expect(authProvider.phoneNumber, '0912345678');
      expect(authProvider.bio, 'Bio của A');
    });

    test(
        'Xóa tài khoản: Dọn sạch hoàn toàn khỏi danh sách hệ thống, Admin không còn thấy tài khoản đã xóa',
        () async {
      SharedPreferences.setMockInitialValues({});
      final authProvider = AuthProvider();

      // Đăng ký tài khoản User X
      await authProvider.register('userx@example.com', 'Pass123456',
          name: 'User X');
      var list = await authProvider.getRegisteredUsersList();
      expect(list.any((u) => u['email'] == 'userx@example.com'), true);

      // User X thực hiện xóa tài khoản
      final deleted = await authProvider.deleteAccount();
      expect(deleted, true);

      // Kiểm tra: Admin nạp danh sách không còn User X
      list = await authProvider.getRegisteredUsersList();
      expect(list.any((u) => u['email'] == 'userx@example.com'), false);
    });

    test('Quản trị viên xóa tài khoản người dùng trực tiếp qua Admin Panel',
        () async {
      SharedPreferences.setMockInitialValues({});
      final authProvider = AuthProvider();

      // Đăng nhập Admin
      await authProvider.signInAsAdmin();
      expect(authProvider.isAdmin, true);

      // Giả lập hệ thống có 1 user thường
      await authProvider.register('baduser@example.com', 'Pass123456',
          name: 'Bad User');
      await authProvider.signInAsAdmin();

      var list = await authProvider.getRegisteredUsersList();
      expect(list.any((u) => u['email'] == 'baduser@example.com'), true);

      // Admin bấm xóa user
      final adminDeleted =
          await authProvider.deleteUserByAdmin('baduser@example.com');
      expect(adminDeleted, true);

      list = await authProvider.getRegisteredUsersList();
      expect(list.any((u) => u['email'] == 'baduser@example.com'), false);
    });

    test(
        'HttpDateParser parse chuẩn xác năm 2 chữ số (Thanh Niên) và năm 4 chữ số (VnExpress, Tuổi Trẻ)',
        () {
      // 1. Thanh Niên dạng năm 2 chữ số '26' -> 2026
      final tnDate = HttpDateParser.parse('Sat, 21 Nov 26 14:07:00 +0700');
      expect(tnDate.year, 2026);
      expect(tnDate.month, 11);
      expect(tnDate.day, 21);

      // 2. VnExpress dạng năm 4 chữ số '2026'
      final vneDate = HttpDateParser.parse('Fri, 20 Nov 2026 15:30:00 +0700');
      expect(vneDate.year, 2026);
      expect(vneDate.month, 11);
      expect(vneDate.day, 20);

      // 3. Tuổi Trẻ dạng GMT
      final ttDate = HttpDateParser.parse('Sat, 21 Nov 2026 07:15:22 GMT');
      expect(ttDate.year, 2026);
      expect(ttDate.month, 11);
      expect(ttDate.day, 21);
    });

    test(
        'Article.fromRssItem giải mã chuẩn xác ký tự HTML entities và hình ảnh',
        () {
      final article = Article.fromRssItem(
        title:
            'Th&#7911; t&#432;&#7899;ng ch&#7881; &#273;&#7841;o &amp; ph&#225;t bi&#7875;u &quot;N&oacute;ng&quot;',
        link: 'https://tuoitre.vn/bai-viet-123.htm',
        description:
            '<a href="https://tuoitre.vn/bai-viet-123.htm"><img src="https://cdn.tuoitre.vn/image.jpg"/></a>N&#7897;i dung tin t&#7913;c',
        source: 'Tuổi Trẻ',
      );

      // Kiểm tra giải mã ký tự tiếng Việt entity
      expect(article.title.contains('&#'), false);
      expect(article.title.contains('&amp;'), false);
      expect(article.imageUrl, 'https://cdn.tuoitre.vn/image.jpg');
    });

    test(
        'NewsCategory hỗ trợ cờ isEnabled và NewsService.categories khởi đầu rỗng',
        () {
      expect(NewsService.categories.isEmpty, true);

      const cat = NewsCategory('tuoi-tre', 'Tuổi Trẻ',
          'https://tuoitre.vn/rss/tin-moi-nhat.rss', 'Tuổi Trẻ');
      expect(cat.isEnabled, true);

      final toggled = cat.copyWith(isEnabled: false);
      expect(toggled.isEnabled, false);

      final json = toggled.toJson();
      expect(json['isEnabled'], false);

      final restored = NewsCategory.fromJson(json);
      expect(restored.isEnabled, false);
    });

    test('NewsProvider toggleAllCategoriesEnabled và bảo vệ giữ lại ít nhất 1 nguồn', () async {
      final mockService = MockNewsService();
      final provider = NewsProvider(service: mockService);

      // Thêm 2 nguồn tin test
      await provider.addCategory(
        label: 'Nguồn 1',
        rssUrl: 'https://test1.vn/rss',
        source: 'Test 1',
      );
      await provider.addCategory(
        label: 'Nguồn 2',
        rssUrl: 'https://test2.vn/rss',
        source: 'Test 2',
      );

      expect(provider.allCategories.length, 2);
      expect(provider.allCategories.every((c) => c.isEnabled), true);

      // Bấm toggleAllCategoriesEnabled khi cả 2 đang bật -> Tắt nguồn 2, giữ lại nguồn 1
      final result1 = await provider.toggleAllCategoriesEnabled();
      expect(result1, false); // Vừa tắt chừa 1 nguồn
      expect(provider.allCategories[0].isEnabled, true);
      expect(provider.allCategories[1].isEnabled, false);
      expect(provider.categories.length, 1);

      // Cố tình tắt nguồn 1 khi nó là nguồn duy nhất còn lại -> Phải trả về false và không tắt
      final toggleLastResult = await provider.toggleCategoryEnabled(provider.allCategories[0].id);
      expect(toggleLastResult, false);
      expect(provider.allCategories[0].isEnabled, true); // Vẫn bật

      // Bấm toggleAllCategoriesEnabled lại -> Bật cả 2
      final result2 = await provider.toggleAllCategoriesEnabled();
      expect(result2, true); // Vừa bật tất cả
      expect(provider.allCategories.every((c) => c.isEnabled), true);
      expect(provider.categories.length, 2);
    });
  });
}
