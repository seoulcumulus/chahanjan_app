import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart'; // 웹에서는 필요 없을 수 있음, 필요시 주석 해제
import 'package:flutter/foundation.dart'; // kIsWeb 사용을 위해 필요

class SocialLoginService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // 🟡 [핵심 수정] 카카오 로그인 (OIDC 방식)
  Future<Map<String, dynamic>> loginWithKakao() async {
    try {
      // 우리가 설정한 'kakao' 제공업체를 불러옵니다.
      // 파이어베이스는 자동으로 앞에 'oidc.'을 붙입니다.
      OAuthProvider provider = OAuthProvider('oidc.kakao');

      // 로그인 동작 설정
      provider.setCustomParameters({
        'prompt': 'login',
      });

      UserCredential userCredential;

      // 웹(Web)과 앱(App)을 구분해서 실행
      if (kIsWeb) {
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        userCredential = await _auth.signInWithProvider(provider);
      }

      // 로그인 성공! 유저 정보 처리
      return _handleUserDoc(
        userCredential.user!,
        'kakao',
        userCredential.user?.email,
        userCredential.user?.displayName
      );

    } catch (e) {
      debugPrint('Kakao Login Error: $e');
      rethrow;
    }
  }

  // 🔴 구글 로그인
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      if (kIsWeb) {
         // 웹에서는 구글도 Provider 방식으로 하는 게 더 안정적입니다.
         GoogleAuthProvider googleProvider = GoogleAuthProvider();
         UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
         return _handleUserDoc(userCredential.user!, 'google', userCredential.user?.email, userCredential.user?.displayName);
      } else {
        // 모바일 앱 방식
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) throw Exception('Login cancelled');

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        UserCredential userCredential = await _auth.signInWithCredential(credential);
        return _handleUserDoc(userCredential.user!, 'google', googleUser.email, googleUser.displayName);
      }
    } catch (e) {
      debugPrint('Google Login Error: $e');
      rethrow;
    }
  }

  // 🍎 애플 로그인 (기존 코드 유지)
  // Future<Map<String, dynamic>> loginWithApple() async { ... } 
  // (애플 로그인은 현재 테스트 중이 아니므로 생략하거나 기존 코드를 그대로 두셔도 됩니다)

  // 💾 유저 정보 저장/불러오기 (기존 로직 유지)
  Future<Map<String, dynamic>> _handleUserDoc(User user, String provider, String? email, String? nickname) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userDocRef.get();

    if (userDoc.exists) {
      return {
        'success': true,
        'data': {
          'user': userDoc.data(),
          'token': await user.getIdToken(),
        }
      };
    } else {
      // 신규 회원 생성
      final userData = {
        'user_id': user.uid,
        'email': email ?? user.email ?? '', // 이메일이 없을 경우 대비
        'nickname': nickname ?? user.displayName ?? '친구',
        'gender': 'UNKNOWN',
        'birth_date': '',
        'created_at': FieldValue.serverTimestamp(),
        'point_balance': 0,
        'interests': [], // 관심사 필드 추가
        'photoUrl': user.photoURL ?? '🐶', // 기본 프로필
        'provider': provider,
        'is_new': true,
      };
      await userDocRef.set(userData);
      return {
        'success': true,
        'data': {
          'user': userData,
          'token': await user.getIdToken(),
        }
      };
    }
  }
}
