import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 📡 내 위치를 서버에 업데이트 (광장에 깃발 꽂기)
  Future<void> updateMyLocation(String uid, LatLng location) async {
    await _firestore.collection('users').doc(uid).update({
      'latitude': location.latitude,
      'longitude': location.longitude,
      'is_online': true, // 접속 중 표시
      'last_active': FieldValue.serverTimestamp(), // 마지막 활동 시간
    });
  }

  // 🔍 주변 유저 데이터 가져오기 (광장 명부 뒤지기)
  // (실제로는 GeoFlutterFire 등을 쓰지만, 지금은 간단하게 다 가져와서 필터링)
  Future<List<Map<String, dynamic>>> fetchAllUsers() async {
    QuerySnapshot snapshot = await _firestore.collection('users').get();
    
    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>
      };
    }).toList();
  }
  // 🍵 찻잎 차감 (결제 처리)
  // 🍵 찻잎 차감 (결제 처리) - 트랜잭션 적용
  Future<bool> deductTeaLeaf(String uid) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      
      // 트랜잭션으로 안전하게 차감 (동시성 문제 해결)
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return false;

        final int currentTea = snapshot.data()?['tea_leaves'] ?? 0;
        
        if (currentTea >= 1) {
          transaction.update(userRef, {'tea_leaves': currentTea - 1});
          return true; // 성공
        } else {
          return false; // 잔액 부족
        }
      });
    } catch (e) {
      print("❌ 찻잎 차감 오류: $e");
      return false;
    }
  }

  // 1. 방 만들기 (신청자 ID 기록 추가)
  Future<void> createChatRoom({
    required String chatId,
    required String myUid,
    required String peerUid,
  }) async {
    final chatDoc = _firestore.collection('chat_rooms').doc(chatId);

    // 이미 존재하는지 확인 (덮어쓰기 방지 옵션 고려 가능)
    // 여기서는 요청대로 merge: true를 사용하여 업데이트하거나 생성합니다.
    await chatDoc.set({
      'participants': [myUid, peerUid],
      'initiatorId': myUid, // 👈 누가 신청했는지 기록!
      'lastMessage': '대화를 요청했습니다. ✉️',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending', 
    }, SetOptions(merge: true));
  }

  // 2. 수락하기 기능
  Future<void> acceptChatRequest(String chatId) async {
    await _firestore.collection('chat_rooms').doc(chatId).update({
      'status': 'accepted',
      'lastMessage': '대화 요청이 수락되었습니다! 🎉',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // 3. 차단/삭제 기능
  Future<void> blockChatRoom(String chatId) async {
    await _firestore.collection('chat_rooms').doc(chatId).delete();
  }
}
