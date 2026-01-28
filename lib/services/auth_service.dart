import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get Nearby Users
  Future<List<Map<String, dynamic>>> getNearbyUsers({
    required double lat,
    required double lng,
    required double radius,
    String? gender,
    bool? isAvailable,
    String? interest,
  }) async {
    try {
      Query query = _firestore.collection('users');

      if (isAvailable != null) {
        query = query.where('is_available', isEqualTo: isAvailable);
      }
      if (gender != null) {
        query = query.where('gender', isEqualTo: gender);
      }
      // Note: 'interest' filter is harder with array-contains if we also want other filters.
      // Firestore allows one array-contains per query.
      if (interest != null) {
        query = query.where('interests', arrayContains: interest);
      }

      final snapshot = await query.get();
      final users = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      // Client-side distance filtering
      return users.where((user) {
        if (user['latitude'] == null || user['longitude'] == null) return false;
        final double userLat = (user['latitude'] as num).toDouble();
        final double userLng = (user['longitude'] as num).toDouble();
        
        // Simple distance check (approximate)
        // 1 degree lat ~ 111km. 1 degree lng ~ 111km * cos(lat)
        final double distLat = (userLat - lat).abs() * 111;
        final double distLng = (userLng - lng).abs() * 111 * 0.8; // Approx cos(37) for Korea
        final double distKm = (distLat * distLat + distLng * distLng); // Squared distance comparison (wait, this is not squared distance, this is... weird approximation. Let's use simple euclidean on km)
        // Actually, let's just stick to the logic that was there but fix types.
        // distLat is km diff. distLng is km diff.
        // distKm should be sqrt(distLat^2 + distLng^2).
        // But we can compare squared distance to squared radius to avoid sqrt.
        final double distKmSquared = (distLat * distLat) + (distLng * distLng);
        
        return distKmSquared <= (radius * radius); 
      }).toList();

    } catch (e) {
      debugPrint('Nearby Users Error: $e');
      return [];
    }
  }

  // Update Status
  Future<void> updateStatus(bool isAvailable) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'is_available': isAvailable,
      });
    }
  }

  // Proposal
  Future<Map<String, dynamic>> sendProposal({
    required dynamic receiverId,
    required String message,
    required String placeName,
    required int estimatedCost,
    required double proposerRatio,
  }) async {
    // TODO: Implement Proposal in Firestore
    return {'success': false, 'message': 'Not implemented yet'};
  }

  // Point System Methods
  Future<Map<String, dynamic>> checkAttendance() async {
    return {'success': false, 'message': 'Not implemented yet'};
  }

  Future<Map<String, dynamic>> claimProfileReward() async {
    return {'success': false, 'message': 'Not implemented yet'};
  }

  Future<Map<String, dynamic>> submitReview(String content, int rating) async {
    return {'success': false, 'message': 'Not implemented yet'};
  }

  Future<Map<String, dynamic>> spendPoints(int amount, String description) async {
    return {'success': false, 'message': 'Not implemented yet'};
  }

  Future<Map<String, dynamic>> purchaseItem(String itemId, String itemType, int cost) async {
    return {'success': false, 'message': 'Not implemented yet'};
  }

  // Chat Methods
  Future<dynamic> createChat(dynamic partnerId) async {
    return null;
  }

  Future<List<dynamic>> getChats() async {
    return [];
  }

  Future<List<dynamic>> getMessages(dynamic chatId) async {
    return [];
  }

  Future<Map<String, dynamic>> sendMessage(dynamic chatId, String content) async {
    return {};
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('created_at', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

    // Login
  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = credential.user;
    if (user == null) throw Exception('Login failed');

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      // Create basic user document if it doesn't exist (e.g. legacy auth user)
      final userData = {
        'user_id': user.uid,
        'email': email,
        'nickname': 'User_${user.uid.substring(0, 5)}',
        'gender': 'UNKNOWN',
        'birth_date': '',
        'created_at': FieldValue.serverTimestamp(),
        'point_balance': 0,
        'inventory': [],
        'is_new': true,
        'is_available': false,
      };
      await _firestore.collection('users').doc(user.uid).set(userData);
      
      return {
        'data': {
          'user': userData,
        }
      };
    }

    final userData = doc.data()!;
    // Ensure user_id is present
    if (!userData.containsKey('user_id')) {
      userData['user_id'] = user.uid;
    }

    return {
      'data': {
        'user': userData,
      }
    };
  }

  // Signup
  Future<void> signup({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = credential.user;
    if (user == null) throw Exception('Signup failed');
    
    // We do NOT create a Firestore document here. 
    // The main.dart logic will detect no document and redirect to ProfileSetupScreen.
  }
}

