import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _userData;

  User? get user => _user;
  Map<String, dynamic>? get userData => _userData;

  // 🐶 지도가 읽어가는 캐릭터 (DB의 'photoUrl' 필드)
  String get character => _userData?['photoUrl'] ?? '🐶';

  // 📝 지도가 읽어가는 관심사 텍스트 (DB의 'interests' 필드)
  String get interestText {
    final List<dynamic>? interests = _userData?['interests'];
    if (interests == null || interests.isEmpty) return '';
    return interests.join(', ');
  }

  UserProvider() {
    _init();
  }

  void _init() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      if (user != null) {
        _fetchUserData(user.uid);
      } else {
        _userData = null;
        notifyListeners();
      }
    });
  }

  void _fetchUserData(String uid) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots() // 🔥 실시간 감시 (DB 바뀌면 즉시 반영)
        .listen((snapshot) {
      if (snapshot.exists) {
        _userData = snapshot.data();
        print("✅ DB 데이터 수신: ${_userData?['nickname']}, ${_userData?['photoUrl']}"); // 디버깅용 로그
        notifyListeners(); // 화면 갱신 신호 발사!
      }
    });
  }
}
