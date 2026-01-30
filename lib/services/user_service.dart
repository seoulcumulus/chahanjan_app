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
  Future<bool> deductTeaLeaf(String uid, {int amount = 1}) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return false;

      int currentTea = (doc.data() as Map<String, dynamic>)['tea_leaves'] ?? 0;

      if (currentTea >= amount) {
        await _firestore.collection('users').doc(uid).update({
          'tea_leaves': FieldValue.increment(-amount),
        });
        return true; 
      } else {
        return false;
      }
    } catch (e) {
      print("❌ 찻잎 차감 오류: $e");
      return false; 
    }
  }
}
