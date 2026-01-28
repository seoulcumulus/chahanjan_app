import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // 🔔 초기화 및 권한 요청
  Future<void> initialize() async {
    // 1. 알림 권한 요청 (iOS 필수)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('🔔 알림 권한 허용됨');
      // 2. 토큰 가져오기 및 저장
      String? token = await _fcm.getToken();
      if (token != null) {
        _saveTokenToDB(token);
      }

      // 3. 토큰 갱신 감지
      _fcm.onTokenRefresh.listen(_saveTokenToDB);
    } else {
      print('🔔 알림 권한 거부됨');
    }

    // 4. 앱이 켜져있을 때 알림 처리 (선택사항: 스낵바 띄우기 등)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔔 포그라운드 알림 도착: ${message.notification?.title}');
      // 여기서 Get.snackbar 등을 띄울 수 있음
    });
  }

  // 💾 내 DB에 FCM 토큰 저장 (그래야 서버가 나한테 알림을 보냄)
  Future<void> _saveTokenToDB(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': token});
      print("🔔 FCM 토큰 저장 완료");
    }
  }
}
