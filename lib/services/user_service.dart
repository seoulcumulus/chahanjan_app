import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:math';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. 찻잎 사용 (Transaction으로 안전하게 차감)
  Future<bool> useTeaLeaf(String userId, int amount) async {
    final userRef = _firestore.collection('users').doc(userId);

    try {
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return false;

        final data = snapshot.data();
        int currentLeaves = data?['tea_leaves'] ?? 0;

        if (currentLeaves < amount) {
          return false; // 찻잎 부족
        }

        // 차감 실행
        transaction.update(userRef, {'tea_leaves': currentLeaves - amount});
        return true;
      });
    } catch (e) {
      print("❌ 찻잎 사용 오류: $e");
      return false;
    }
  }

  // 2. 반경 내 유저 찾기 (Client-side Filtering)
  // MVP 단계에서는 전체/다수 유저를 가져와서 거리 계산 (Haversine 공식)
  Future<List<Map<String, dynamic>>> fetchNearbyUsers(
      String myUserId, LatLng center, double radiusInMeters) async {
    try {
      // 모든 유저 가져오기 (실무에서는 Geohash나 Lat/Lng 범위 쿼리 필수)
      // 여기서는 간단히 구현함
      final querySnapshot = await _firestore.collection('users').get();
      
      List<Map<String, dynamic>> nearbyUsers = [];

      for (var doc in querySnapshot.docs) {
        if (doc.id == myUserId) continue; // 나는 제외

        final data = doc.data();
        if (data['location'] is GeoPoint) {
          GeoPoint userLoc = data['location'];
          
          double distance = _getDistance(
            center.latitude, center.longitude, 
            userLoc.latitude, userLoc.longitude
          );

          if (distance <= radiusInMeters) {
            // 거리 내에 있으면 추가
            Map<String, dynamic> userData = Map.from(data);
            userData['id'] = doc.id; // ID 추가
            userData['distance'] = distance;
            nearbyUsers.add(userData);
          }
        }
      }
      
      return nearbyUsers;

    } catch (e) {
      print("❌ 주변 유저 검색 오류: $e");
      return [];
    }
  }

  // Haversine 거리 계산 (미터 단위)
  double _getDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // 지구 반지름 (미터)
    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) * cos(_degToRad(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) {
    return deg * (pi / 180);
  }
}
