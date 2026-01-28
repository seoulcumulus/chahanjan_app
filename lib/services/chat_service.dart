import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_request_model.dart';
import '../models/chat_room_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 💌 대화 요청 or 찌르기 보내기 (내 정보 포함하도록 업데이트)
  Future<void> sendRequest({required String toUid, required String type}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    // 내 정보 가져오기 (상대방에게 보여줄 닉네임/캐릭터)
    final myDoc = await _firestore.collection('users').doc(user.uid).get();
    final myData = myDoc.data();
    
    // 중복 요청 방지
    final existingQuery = await _firestore
        .collection('chat_requests')
        .where('fromId', isEqualTo: user.uid)
        .where('toId', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingQuery.docs.isNotEmpty) {
      throw Exception("이미 요청을 보냈습니다. 응답을 기다려주세요!");
    }

    // 요청 저장
    await _firestore.collection('chat_requests').add({
      'fromId': user.uid,
      'fromNickname': myData?['nickname'] ?? '알 수 없음', // 내 닉네임 추가
      'fromCharacter': myData?['photoUrl'] ?? '❓',    // 내 캐릭터 추가
      'toId': toUid,
      'type': type, // 'chat' or 'poke'
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ 요청 수락하기 (채팅방 생성)
  Future<String> acceptRequest(String requestId, String otherUserId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    // 1. 채팅방(Chat Room) 생성
    // (이미 있는 방인지 체크하는 로직은 생략하고 단순 생성합니다)
    final roomRef = await _firestore.collection('chat_rooms').add({
      'participants': [user.uid, otherUserId], // 나 & 상대방
      'lastMessage': '대화가 시작되었습니다.',
      'updatedAt': FieldValue.serverTimestamp(),
      'type': 'direct', // 1:1 채팅
    });

    // 2. 요청 상태를 'accepted'로 변경
    await _firestore.collection('chat_requests').doc(requestId).update({
      'status': 'accepted',
      'createdRoomId': roomRef.id, // 연결된 방 ID 저장
    });

    return roomRef.id; // 생성된 방 ID 반환
  }

  // ❌ 요청 거절하기
  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection('chat_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  // 받은 요청 목록 가져오기 (Stream)
  Stream<List<ChatRequest>> getChatRequests() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('chat_requests')
        .where('toId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRequest.fromDocument(doc)).toList();
    });
  }

  // 내 채팅방 목록 가져오기 (Stream)
  Stream<List<ChatRoom>> getChatRooms() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ChatRoom.fromDocument(doc)).toList();
    });
  }
}
