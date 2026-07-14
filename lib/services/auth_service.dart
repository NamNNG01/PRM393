import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Đăng ký tài khoản mới
  Future<UserCredential> registerWithEmailAndPassword({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật tên hiển thị trong Firebase Auth
      await credential.user?.updateDisplayName(username);

      // Kiểm tra xem thời gian đăng ký có trong khoảng từ 13/7 đến 26/7 năm 2026 hay không
      final DateTime now = DateTime.now();
      final DateTime startDate = DateTime(2026, 7, 13, 0, 0, 0);
      final DateTime endDate = DateTime(2026, 7, 26, 23, 59, 59);

      DateTime? premiumUntil;
      if (now.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          now.isBefore(endDate.add(const Duration(seconds: 1)))) {
        // Tặng 30 ngày Premium
        premiumUntil = now.add(const Duration(days: 30));
      }

      // Lưu thông tin người dùng vào Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'premiumUntil': premiumUntil != null ? Timestamp.fromDate(premiumUntil) : null,
      });

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Đăng nhập
  Future<UserCredential> loginWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Kiểm tra tài khoản có Premium còn hạn hay không
  Future<Map<String, dynamic>> checkPremiumStatus() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return {
        'isPremium': false,
        'reason': 'Chưa đăng nhập',
        'expiryDate': null,
      };
    }

    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return {
          'isPremium': false,
          'reason': 'Không tìm thấy thông tin tài khoản',
          'expiryDate': null,
        };
      }

      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      final Timestamp? premiumUntilTimestamp = data['premiumUntil'] as Timestamp?;

      if (premiumUntilTimestamp == null) {
        return {
          'isPremium': false,
          'reason': 'Tài khoản thường (Cần nâng cấp Premium)',
          'expiryDate': null,
        };
      }

      final DateTime expiryDate = premiumUntilTimestamp.toDate();
      final DateTime now = DateTime.now();

      if (expiryDate.isBefore(now)) {
        return {
          'isPremium': false,
          'reason': 'Tài khoản Premium đã hết hạn',
          'expiryDate': expiryDate,
        };
      }

      return {
        'isPremium': true,
        'reason': 'Premium hoạt động',
        'expiryDate': expiryDate,
      };
    } catch (e) {
      return {
        'isPremium': false,
        'reason': 'Lỗi kiểm tra trạng thái Premium: $e',
        'expiryDate': null,
      };
    }
  }
}
