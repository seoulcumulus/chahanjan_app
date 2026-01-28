import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SafetyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🚨 1. 신고하기 (Report)
  Future<void> reportUser({required String targetUid, required String reason, String? description}) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return;

    await _firestore.collection('reports').add({
      'reporterId': myUid,        // 신고자
      'reportedId': targetUid,    // 신고 대상
      'reason': reason,           // 신고 사유 (예: 욕설, 불쾌감 조성)
      'description': description ?? '', // 상세 내용
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',        // 처리 대기중
    });
  }

  // 🚫 2. 차단하기 (Block)
  Future<void> blockUser(String targetUid) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return;

    // 내 차단 목록에 추가
    await _firestore.collection('users').doc(myUid).collection('blocked_users').doc(targetUid).set({
      'blockedAt': FieldValue.serverTimestamp(),
    });
  }

  // 🔓 3. 차단 해제 (Unblock)
  Future<void> unblockUser(String targetUid) async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return;

    await _firestore.collection('users').doc(myUid).collection('blocked_users').doc(targetUid).delete();
  }

  // 🕵️ 4. 내가 차단한 사람 목록 가져오기 (필터링용)
  Future<List<String>> getBlockedUserIds() async {
    final myUid = _auth.currentUser?.uid;
    if (myUid == null) return [];

    final snapshot = await _firestore.collection('users').doc(myUid).collection('blocked_users').get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }
}
