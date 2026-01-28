import 'package:flutter/material.dart';
import 'terms_screen.dart'; // 👈 이 줄을 파일 맨 위에 추가하세요
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/social_login_service.dart';
import '../providers/user_provider.dart';
import '../widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _socialLoginService = SocialLoginService();
  bool _isKakaoLoading = false;
  bool _isGoogleLoading = false;

  Future<void> _handleSocialLogin(
    Future<Map<String, dynamic>> Function() loginMethod,
    Function(bool) setLoading,
  ) async {
    setLoading(true);
    try {
      await loginMethod();
      if (!mounted) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("로그인 정보를 찾을 수 없습니다.");

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (!mounted) return;

      if (userDoc.exists) {
        Navigator.of(context).pushReplacementNamed('/map');
      } else {
        // 신규 유저는 약관 동의 화면으로 이동
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const TermsScreen())
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 오류: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text('ChaHanJan', textAlign: TextAlign.center, style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.deepPurple)),
              const SizedBox(height: 8),
              const Text('Coffee & Chat in 3 Seconds', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey)),
              const Spacer(),
              
              // 카카오 로그인
              SocialLoginButton(
                text: 'Login with Kakao',
                backgroundColor: const Color(0xFFFEE500),
                textColor: const Color(0xFF191919),
                isLoading: _isKakaoLoading,
                onPressed: () => _handleSocialLogin(_socialLoginService.loginWithKakao, (val) => setState(() => _isKakaoLoading = val)),
              ),
              const SizedBox(height: 12),
              
              // 구글 로그인
              SocialLoginButton(
                text: 'Login with Google',
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                isLoading: _isGoogleLoading,
                onPressed: () => _handleSocialLogin(_socialLoginService.loginWithGoogle, (val) => setState(() => _isGoogleLoading = val)),
              ),
              const SizedBox(height: 12),
              
              // 키 해시 확인용 빨간 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red), // 잘 보이게 빨간색
                onPressed: () async {
                  // ⭐️ 내 앱의 진짜 키 해시(Key Hash)를 가져오는 코드
                  String keyHash = await KakaoSdk.origin; 
                  
                  if (!context.mounted) return;
                  
                  // 팝업으로 띄우기
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("🔑 이 코드를 복사하세요!"),
                      content: SelectableText(keyHash), // 꾹 눌러서 복사 가능
                      actions: [
                        TextButton(
                          onPressed: () {
                            // 클립보드에 복사하기
                            Clipboard.setData(ClipboardData(text: keyHash));
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("복사완료!")));
                          }, 
                          child: const Text("복사 & 닫기")
                        ),
                      ],
                    ),
                  );
                },
                child: const Text("🔑 키 해시 확인하기 (임시)"),
              ),
              
              // 애플 로그인 버튼 삭제됨!
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
