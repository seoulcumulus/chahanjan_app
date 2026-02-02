import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../utils/app_strings.dart'; // 다국어 파일

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Color _signatureColor = const Color(0xFF24FCFF);

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _selectedAvatar = 'rat.png'; // 현재 선택된(착용 중인) 아바타
  List<dynamic> _myInventory = ['rat.png']; // 나의 보관함 목록

  String _selectedLanguage = 'Korean';
  String _gender = '남성';
  double _age = 25;
  List<String> _selectedInterests = [];
  bool _isLoading = true;

  // 🆕 MBTI 관련 변수
  String _mbti = ''; 
  final List<String> _mbtiList = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP'
  ];

  final List<String> _interestsOptions = [
    '등산 ⛰️', '골프 ⛳', '헬스 💪', '테니스 🎾', '야구 ⚾', '축구 ⚽', '스키 ⛷️',
    '커피 ☕', '맥주 🍺', '맛집 🍕', '독서 📚', '영화 🎬', '산책 🌿', '게임 🎮', '비즈니스 💼'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nicknameController.text = data['nickname'] ?? '';
          _bioController.text = data['bio'] ?? '';
          _selectedAvatar = data['avatar_image'] ?? 'rat.png';
          _myInventory = data['owned_avatars'] ?? ['rat.png']; 
          _selectedLanguage = data['language'] ?? 'Korean';
          _gender = data['gender'] ?? '남성';
          _age = (data['age'] ?? 25).toDouble();
          _selectedInterests = List<String>.from(data['interests'] ?? []);
          _mbti = data['mbti'] ?? ''; // MBTI 불러오기
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // 🎲 랜덤 닉네임
  void _rollDiceNickname() {
    final rand = Random();
    String adjKey = 'adj_${rand.nextInt(20)}';
    String adj = AppStrings.getByLang(_selectedLanguage, adjKey);
    String animalKey = AppStrings.animalsKeys[rand.nextInt(12)];
    String animal = AppStrings.getByLang(_selectedLanguage, animalKey);
    setState(() {
      _nicknameController.text = "$adj $animal";
    });
  }

  // 🎲 랜덤 한줄 소개
  void _rollDiceBio() {
    int randomIndex = Random().nextInt(30);
    String key = 'bio_$randomIndex';
    String randomBio = AppStrings.getByLang(_selectedLanguage, key);
    setState(() {
      _bioController.text = randomBio;
    });
  }

  // 🧪 MBTI 약식 테스트 다이얼로그
  void _startMBTITest() {
    String result = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("MBTI 약식 테스트 🧐"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("나는 쉴 때..."),
                const SizedBox(height: 5),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  ElevatedButton(onPressed: () => result += "E", style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black), child: const Text("친구 만남")),
                  ElevatedButton(onPressed: () => result += "I", style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black), child: const Text("혼자 쉼")),
                ]),
                const Divider(),
                const Text("나는 생각할 때..."),
                const SizedBox(height: 5),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  ElevatedButton(onPressed: () => result += "S", style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black), child: const Text("현실적")),
                  ElevatedButton(onPressed: () => result += "N", style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black), child: const Text("상상력")),
                ]),
                const Divider(),
                const Text("나는 결정할 때..."),
                const SizedBox(height: 5),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  ElevatedButton(onPressed: () => result += "T", style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black), child: const Text("논리")),
                  ElevatedButton(onPressed: () => result += "F", style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black), child: const Text("감정")),
                ]),
                const Divider(),
                const Text("나는 계획을..."),
                const SizedBox(height: 5),
                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                  ElevatedButton(onPressed: () {
                    if (result.length < 3) return; // 앞 선택지 누락 방지
                    setState(() => _mbti = "${result}J");
                    Navigator.pop(context);
                  }, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black), child: const Text("철저히")),
                  ElevatedButton(onPressed: () {
                    if (result.length < 3) return;
                    setState(() => _mbti = "${result}P");
                    Navigator.pop(context);
                  }, style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black), child: const Text("유연하게")),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🌍 언어 변경 다이얼로그
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: const [Icon(Icons.public), SizedBox(width: 8), Text("Language")]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Korean', 'English', 'Japanese', 'Chinese', 'Spanish', 'Hindi'].map((lang) {
            return ListTile(
              title: Text(lang),
              leading: Radio<String>(
                value: lang,
                groupValue: _selectedLanguage,
                activeColor: _signatureColor,
                onChanged: (val) {
                  setState(() => _selectedLanguage = val!);
                  Navigator.pop(ctx);
                },
              ),
              onTap: () {
                setState(() => _selectedLanguage = lang);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

   Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    // 로딩 시작 (키보드 내리기)
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      // ⚠️ 중요 수정 1: .update() 대신 .set(..., SetOptions(merge: true)) 사용
      // (데이터가 없으면 만들고, 있으면 수정하라는 뜻. 에러가 안 납니다!)
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,            // 유저 ID도 같이 저장해주면 좋습니다
        'email': user.email,        // 이메일도 저장
        'nickname': _nicknameController.text.trim(),
        'bio': _bioController.text.trim(),
        'status': _bioController.text.trim(), // (지도 호환용)
        'avatar_image': _selectedAvatar, 
        'owned_avatars': _myInventory,        // 인벤토리 목록 저장
        'language': _selectedLanguage,
        'gender': _gender,
        'age': _age.toInt(),
        'interests': _selectedInterests,
        'mbti': _mbti,
        'lastActive': FieldValue.serverTimestamp(), // 마지막 접속 시간
      }, SetOptions(merge: true));

      if (mounted) {
        // ⚠️ 중요 수정 2: Navigator.pop(context); <--- 이 줄을 삭제했습니다! (이제 창이 안 닫힙니다)
        
        // 성공 알림창 띄우기
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${AppStrings.getByLang(_selectedLanguage, 'save')} 완료! ✅"),
            backgroundColor: Colors.green, // 성공하면 초록색
            duration: const Duration(seconds: 2),
          )
        );
      }
    } catch (e) {
      // 에러 나면 빨간창 띄우기
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      // 로딩 끝
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.getByLang(_selectedLanguage, 'profile_title')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.public, color: Colors.blue),
            onPressed: _showLanguageDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. [나의 보관함]
                  Text(AppStrings.getByLang(_selectedLanguage, 'inventory'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),
                  Container(
                    height: 110,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: _myInventory.isEmpty 
                      ? const Center(child: Text("보관함이 비었습니다."))
                      : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _myInventory.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 15),
                        itemBuilder: (context, index) {
                          final avatar = _myInventory[index];
                          final isSelected = avatar == _selectedAvatar;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAvatar = avatar),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: isSelected ? Border.all(color: _signatureColor, width: 3) : null,
                                    boxShadow: isSelected ? [BoxShadow(color: _signatureColor.withOpacity(0.5), blurRadius: 8)] : null,
                                  ),
                                  child: CircleAvatar(
                                    radius: 26,
                                    backgroundColor: Colors.white,
                                    child: Image.asset('assets/avatars/$avatar', errorBuilder: (_, __, ___) => const Icon(Icons.pets)),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 2),
                                  const Icon(Icons.check_circle, size: 14, color: Colors.green)
                                ]
                              ],
                            ),
                          );
                        },
                      ),
                  ),
                  const SizedBox(height: 30),

                  // 2. 닉네임 + 주사위
                  Text(AppStrings.getByLang(_selectedLanguage, 'nickname'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            filled: true, fillColor: Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _rollDiceNickname,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: _signatureColor, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.casino, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 🆕 3. MBTI 테스트 버튼 및 선택기
                  Row(
                    children: [
                      Text("MBTI: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: _startMBTITest,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _mbti.isEmpty ? Colors.grey[200] : _signatureColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _signatureColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _mbti.isEmpty ? "테스트 하기 🔍" : _mbti,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (_mbti.isEmpty) ...[
                                const SizedBox(width: 5),
                                const Icon(Icons.touch_app, size: 18),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_mbti.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    // MBTI 수동 수정용 칩
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 6,
                        children: _mbtiList.map((m) => ChoiceChip(
                          label: Text(m, style: const TextStyle(fontSize: 12)),
                          selected: _mbti == m,
                          onSelected: (val) => setState(() => _mbti = m),
                          selectedColor: _signatureColor,
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                        )).toList(),
                      ),
                    )
                  ],

                  const SizedBox(height: 20),

                  // 4. 성별
                  Text(AppStrings.getByLang(_selectedLanguage, 'gender'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _gender = '남성'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(color: _gender == '남성' ? _signatureColor : Colors.grey[200], borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10))),
                            alignment: Alignment.center,
                            child: const Text("Male", style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _gender = '여성'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(color: _gender == '여성' ? Colors.pinkAccent : Colors.grey[200], borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomRight: Radius.circular(10))),
                            alignment: Alignment.center,
                            child: const Text("Female", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 5. 나이
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(AppStrings.getByLang(_selectedLanguage, 'age'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text("${_age.toInt()}", style: TextStyle(fontWeight: FontWeight.bold, color: _signatureColor, fontSize: 18)),
                  ]),
                  Slider(
                    value: _age, min: 10, max: 80, activeColor: _signatureColor, inactiveColor: Colors.grey[300],
                    onChanged: (val) => setState(() => _age = val),
                  ),
                  const SizedBox(height: 20),

                  // 6. 한줄 소개 + 주사위
                  Text(AppStrings.getByLang(_selectedLanguage, 'bio'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bioController,
                          maxLength: 30,
                          decoration: InputDecoration(
                            counterText: "",
                            filled: true, fillColor: Colors.grey[100],
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _rollDiceBio,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.casino, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 7. 관심사
                  Text(AppStrings.getByLang(_selectedLanguage, 'interests'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _interestsOptions.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        selectedColor: _signatureColor.withOpacity(0.6),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) { if (_selectedInterests.length < 3) _selectedInterests.add(interest); }
                            else { _selectedInterests.remove(interest); }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 30),

                  // 8. 저장 버튼
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: _signatureColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: Text(AppStrings.getByLang(_selectedLanguage, 'save'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
