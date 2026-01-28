import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../utils/app_strings.dart'; // 👈 다국어 파일 import 필수

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  late AnimationController _rotationController;

  String _selectedCharacter = '🐼';
  String _selectedGender = 'MALE';
  double _age = 20;
  List<String> _selectedInterests = [];
  bool _isLoading = false;
  String _selectedLanguage = '한국어'; // 기본 언어 표시명

  // 🎲 랜덤 닉네임 데이터
  final List<String> _adjectives = [
    'Happy', 'Sleepy', 'Excited', 'Brave', 'Shy', 'Cool', 'Funny', 'Cute', 'Smart', 'Busy'
  ];
  final List<String> _nouns = [
    'Panda', 'Tiger', 'Lion', 'Rabbit', 'Dog', 'Cat', 'Bear', 'Fox', 'Wolf', 'Dragon'
  ];

  final List<String> _characters = [
    '🐼', '🐯', '🦁', '🐰', '🐶', '🐱', '🐻', '🦊', '🐹', '🐭',
    '🦘', '🐷', '🐵', '🐮', '🐲', '🐥', '🐑', '🐐', '🐕', '🐺',
    '🦏', '🐊', '🦜', '🐬', '🐧', '🐨', '🦦', '🐿️', '🐢', '🦒',
    '🐘', '🦓'
  ];

  final List<String> _interestsList = [
    'Coffee ☕', 'Beer 🍺', 'Foodie 🍕', 'Fitness 🏃',
    'Reading 📚', 'Movie 🎬', 'Walk 🌿', 'Gaming 🎮', 'Business 💼'
  ];

  final List<Map<String, String>> _languages = [
    {'code': 'ko', 'label': '한국어'},
    {'code': 'en', 'label': 'English'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'zh', 'label': '中文'},
    {'code': 'ja', 'label': '日本語'},
    {'code': 'hi', 'label': 'हिन्दी'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }



  void _generateRandomNickname() {
    final random = Random();
    String adj = _adjectives[random.nextInt(_adjectives.length)];
    String noun = _nouns[random.nextInt(_nouns.length)];
    setState(() {
      _nicknameController.text = "$adj $noun";
    });
  }

  // 🌐 언어 변경 팝업 띄우기 (6개 국어 지원)
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Language / 언어 선택"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final lang = _languages[index];
                return ListTile(
                  title: Text(lang['label']!),
                  // 🇺🇸 국기 이모지는 윈도우에서 깨지므로 일단 텍스트만
                  onTap: () {
                    setState(() {
                      AppStrings.language = lang['code']!; // ⭐️ 전역 언어 코드 변경 (예: 'hi')
                      _selectedLanguage = lang['label']!;  // 화면 표시용 이름 변경 (예: 'हिन्दी')
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _nicknameController.text = data['nickname'] ?? '';
        _bioController.text = data['bio'] ?? '';
        _selectedCharacter = data['photoUrl'] ?? '🐼';
        _selectedGender = data['gender'] ?? 'MALE';
        if (data['age'] != null) _age = double.tryParse(data['age'].toString()) ?? 20.0;
        if (data['interests'] != null) _selectedInterests = List<String>.from(data['interests']);
        
        // 🔥 저장된 언어 설정 불러오기 (있으면 적용)
        if (data['language'] != null) {
          AppStrings.language = data['language'];
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppStrings.language == 'ko' ? '닉네임을 입력하세요' : 'Please enter nickname')));
      return;
    }
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Login required");

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nickname': _nicknameController.text,
        'photoUrl': _selectedCharacter,
        'bio': _bioController.text,
        'gender': _selectedGender,
        'age': _age.toInt(),
        'interests': _selectedInterests,
        'is_profile_completed': true,
        'language': AppStrings.language, // 💾 언어 설정도 저장!
      });

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/map', (route) => false);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(AppStrings.get('app_title'), style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          // 🌐 지구본 버튼 (누르면 6개 국어 팝업 뜸)
          IconButton(
            icon: const Icon(Icons.language, color: Colors.blueAccent),
            onPressed: _showLanguageDialog, // 👈 팝업 함수 연결
            tooltip: "Change Language",
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🌐 0. 언어 선택 (Language Switcher) - AppBar로 이동됨
            // const SizedBox(height: 32), // Removed old selector space

            // 1. 캐릭터
            const Text('My Character', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _characters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final char = _characters[index];
                  final isSelected = _selectedCharacter == char;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCharacter = char),
                    child: isSelected
                      ? AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) => Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(_rotationController.value * 2 * pi),
                            child: _buildCharContainer(char, true),
                          ),
                        )
                      : _buildCharContainer(char, false),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // 2. 닉네임
            Text(AppStrings.get('nickname'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                hintText: AppStrings.get('nickname'),
                filled: true, fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.casino, color: Color(0xFF29B6F6)), // 🎲 아이콘 확실히 지정
                  onPressed: _generateRandomNickname,
                  tooltip: 'Random Nickname',
                ),
              ),
            ),
            const SizedBox(height: 32),

            // 3. 성별
            Text(AppStrings.get('gender'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'MALE'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'MALE' ? const Color(0xFF29B6F6) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(AppStrings.get('male'), style: TextStyle(color: _selectedGender == 'MALE' ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = 'FEMALE'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _selectedGender == 'FEMALE' ? const Color(0xFFFF80AB) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(AppStrings.get('female'), style: TextStyle(color: _selectedGender == 'FEMALE' ? Colors.white : Colors.grey, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 4. 나이
            // 4. 나이 (Padding으로 감싸서 여백 확보)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0), // 👈 좌우 여백 추가
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.get('age'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      // 말풍선 대신 직관적인 텍스트 표시
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF29B6F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${_age.toInt()}", 
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _age,
                    min: 19,
                    max: 60,
                    activeColor: const Color(0xFF29B6F6),
                    inactiveColor: Colors.grey[200],
                    onChanged: (val) => setState(() => _age = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 5. 한줄 소개
             Text(AppStrings.get('bio'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              decoration: InputDecoration(
                hintText: AppStrings.get('bio'),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),

            const SizedBox(height: 32),
            
            // 6. 관심사
            Text(AppStrings.get('interests'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
             Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _interestsList.map((interest) {
                final isSelected = _selectedInterests.contains(interest);
                return FilterChip(
                  label: Text(interest),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (_selectedInterests.length < 3) _selectedInterests.add(interest);
                      } else {
                        _selectedInterests.remove(interest);
                      }
                    });
                  },
                  selectedColor: const Color(0xFF29B6F6).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF29B6F6),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF29B6F6) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF29B6F6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(AppStrings.get('start_btn'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }



  Widget _buildCharContainer(String char, bool isSelected) {
    return Container(
      width: 70, height: 70, // 크기 살짝 키움
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE1F5FE) : Colors.grey[100], // 선택시 연한 파랑 배경
        shape: BoxShape.circle,
        border: isSelected 
            ? Border.all(color: const Color(0xFF29B6F6), width: 3) // 🔵 선택시 굵은 파란 테두리
            : Border.all(color: Colors.transparent, width: 3),
        boxShadow: isSelected 
            ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] 
            : [],
      ),
      child: Center(child: Text(char, style: const TextStyle(fontSize: 38))), // 이모지 크기 확대
    );
  }
}
