import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🤝 매칭 시작 (필터 포함)
  // filterOptions: { 'gender': 'female', 'minAge': 20, 'maxAge': 29, 'interest': 'Gaming' }
  Future<String?> startMatching({
    required bool isGlobal,
    Map<String, dynamic>? filterOptions,
  }) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return null;

    // 1. 내 최신 정보 가져오기 (나이, 성별 등 대기열 등록용)
    final myProfileSnapshot = await _firestore.collection('users').doc(myUid).get();
    if (!myProfileSnapshot.exists) return null; // 프로필 없으면 불가
    final myData = myProfileSnapshot.data()!;

    final collectionName = isGlobal ? 'queue_global' : 'queue_domestic';
    final queueRef = _firestore.collection(collectionName);
    String? roomId;

    await _firestore.runTransaction((transaction) async {
      // 🔍 A. 필터 조건을 적용하여 대기자 찾기
      Query query = queueRef.where('uid', isNotEqualTo: myUid); // 나는 제외

      // [필터 1] 성별 (원하는 성별이 있다면)
      if (filterOptions?['gender'] != null) {
        query = query.where('gender', isEqualTo: filterOptions!['gender']);
      }

      // [필터 2] 관심사 (원하는 관심사가 있다면)
      if (filterOptions?['interest'] != null) {
        query = query.where('interest', isEqualTo: filterOptions!['interest']);
      }

      // [필터 3] 나이 (최소/최대)
      // 주의: Firestore 쿼리 제약상 'uid' 정렬과 범위 검색(>, <)을 동시에 쓰기 까다로울 수 있음.
      // 여기서는 필터링된 후보 중 1명을 가져오는 방식으로 구현합니다.
      if (filterOptions?['minAge'] != null) {
        query = query.where('age', isGreaterThanOrEqualTo: filterOptions!['minAge']);
      }
      if (filterOptions?['maxAge'] != null) {
        query = query.where('age', isLessThanOrEqualTo: filterOptions!['maxAge']);
      }
      
      // 정렬 (오래 기다린 순) - 복합 색인 필요!
      query = query.orderBy('createdAt', descending: false).limit(1);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        // 🎉 매칭 성공!
        final targetDoc = snapshot.docs.first;
        transaction.delete(targetDoc.reference); // 상대방 채가기

        // 방 생성
        final newRoomRef = _firestore.collection('chat_rooms').doc();
        roomId = newRoomRef.id;
        
        transaction.set(newRoomRef, {
          'roomId': roomId,
          'users': [myUid, targetDoc['uid']],
          'createdAt': FieldValue.serverTimestamp(),
          'isOpen': true,
        });

      } else {
        // ⏳ 매칭 실패 -> 대기열에 '내 정보' 등록하고 기다리기
        final myDocRef = queueRef.doc(myUid);
        
        // 내 프로필에서 필요한 정보만 뽑아서 저장 (남들이 나를 검색할 수 있게)
        transaction.set(myDocRef, {
          'uid': myUid,
          'createdAt': FieldValue.serverTimestamp(),
          'gender': myData['gender'] ?? 'male', 
          'age': myData['age'] ?? 20,
          // 내 관심사 중 첫 번째를 대표 관심사로 등록 (단순화를 위해)
          'interest': (myData['interests'] as List?)?.first ?? 'General',
        });
      }
    });

    return roomId;
  }

  // 매칭 취소 함수는 기존과 동일...
   Future<void> cancelMatching() async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return;
    await _firestore.collection('queue_global').doc(myUid).delete();
    await _firestore.collection('queue_domestic').doc(myUid).delete();
  }
}
