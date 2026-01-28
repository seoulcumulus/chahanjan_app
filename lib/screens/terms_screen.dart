import 'package:flutter/material.dart';
import 'profile_setup_screen.dart'; // 동의 후 넘어갈 화면

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _agreed1 = false; // 이용약관
  bool _agreed2 = false; // 개인정보 처리방침

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("이용약관 동의")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("환영합니다! 👋", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("안전한 커뮤니티를 위해 약관에 동의해주세요."),
            const SizedBox(height: 30),
            
            // 약관 1
            _buildTermItem("서비스 이용약관 (필수)", _agreed1, (val) => setState(() => _agreed1 = val!)),
            const SizedBox(height: 10),
            // 약관 2
            _buildTermItem("개인정보 처리방침 (필수)", _agreed2, (val) => setState(() => _agreed2 = val!)),
            
            const Spacer(),
            
            // 확인 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_agreed1 && _agreed2) 
                  ? () {
                      // 모두 동의하면 프로필 설정으로 이동 (pushReplacement로 뒤로가기 방지)
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (context) => const ProfileSetupScreen())
                      );
                    } 
                  : null, // 동의 안 하면 버튼 비활성화
                child: const Text("동의하고 시작하기"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem(String title, bool value, Function(bool?) onChanged) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: CheckboxListTile(
        title: Text(title, style: const TextStyle(fontSize: 14)),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
