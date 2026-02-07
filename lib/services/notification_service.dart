import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // 마지막으로 알림 보낸 시간 (중복 방지용)
  DateTime _lastNotifiedTime = DateTime.now();

  // 1. 초기화 (앱 켜질 때 실행)
  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // 앱 아이콘 사용

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // 2. 알림 띄우기 함수
  Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'chahanjan_channel', // 채널 ID
      '채팅 알림', // 채널 이름
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // 고유 ID
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // 📡 3. [핵심] 파이어베이스 감시자 (로그인 직후 실행)
  void startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print("👂 알림 리스너가 켜졌습니다!");

    // 내 채팅방의 변화를 실시간 감시
    FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('participants', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) {
      
      for (var change in snapshot.docChanges) {
        // 데이터 가져오기
        final data = change.doc.data() as Map<String, dynamic>;
        final Timestamp? updatedAt = data['updatedAt'];
        
        // 시간 체크 (앱 켜기 전의 옛날 메시지는 알림 X)
        if (updatedAt == null) continue;
        if (updatedAt.toDate().isBefore(_lastNotifiedTime)) continue;

        // 🟢 1. 새 메시지 도착 (Modified)
        if (change.type == DocumentChangeType.modified) {
          final lastMsg = data['lastMessage'] ?? '';
          final senderId = data['lastMessageSenderId'] ?? '';

          // 내가 보낸 게 아닐 때만 알림
          if (senderId != user.uid && lastMsg.isNotEmpty) {
            showNotification("새 메시지 💌", lastMsg);
            _lastNotifiedTime = DateTime.now(); // 시간 갱신
          }
        }

        // 🟡 2. 새 채팅 요청 도착 (Added)
        if (change.type == DocumentChangeType.added) {
          final status = data['status'] ?? 'pending';
          final initiatorId = data['initiatorId'] ?? '';

          // 내가 요청한 게 아니고, 상태가 대기중일 때
          if (initiatorId != user.uid && status == 'pending') {
            showNotification("새로운 대화 요청! 👋", "누군가 찻잎을 건넸습니다. 확인해보세요!");
            _lastNotifiedTime = DateTime.now(); // 시간 갱신
          }
        }
      }
    });
  }
}
