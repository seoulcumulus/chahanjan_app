import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../utils/app_strings.dart'; // 기존 다국어 파일 연결

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 🎨 성스러운 컬러 팔레트 (Holy Palette)
  final Color _holyGold = const Color(0xFFD4AF37);   // 메탈릭 골드 (강조색)
  final Color _holyPurple = const Color(0xFF2E003E); // 딥 퍼플 (교황청 느낌)
  final Color _creamyWhite = const Color(0xFFF9F9F9); // 크림색 배경

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _selectedAvatar = 'rat.png'; // 현재 선택된 아바타
  // 기본 아바타 목록 (이미지가 없어도 에러 안 나게 처리함)
  List<dynamic> _myInventory = ['rat.png', 'cat.png', 'dog.png', 'lion.png', 'bear.png']; 

  String _selectedLanguage = 'Korean';
  String _gender = '남성';
  double _age = 25;
  List<String> _selectedInterests = [];
  bool _isLoading = true;

  // MBTI
  String _mbti = ''; 
  final List<String> _mbtiList = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP'
  ];

  final List<String> _interestsOptions = [
    '등산 ⛰️', '골프 ⛳', '헬스 💪', '테니스 🎾', '야구 ⚾', '축구 ⚽', '와인 🍷',
    '커피 ☕', '위스키 🥃', '맛집 🍕', '독서 📚', '재테크 💰', '명상 🧘', '게임 🎮', '비즈니스 💼'
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
          _bioController.text = data['bio'] ?? data['status'] ?? ''; // 호환성 유지
          _selectedAvatar = data['avatar_image'] ?? 'rat.png';
          
          // 저장된 인벤토리가 있으면 가져오고, 없으면 기본값 유지
          if (data['owned_avatars'] != null && (data['owned_avatars'] as List).isNotEmpty) {
            _myInventory = data['owned_avatars'];
          }
          
          _selectedLanguage = data['language'] ?? 'Korean';
          _gender = data['gender'] ?? '남성';
          _age = (data['age'] ?? 25).toDouble();
          _selectedInterests = List<String>.from(data['interests'] ?? []);
          _mbti = data['mbti'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // 🎲 랜덤 닉네임
  void _rollDiceNickname() {
    final rand = Random();
    // (AppStrings에 키가 없을 경우를 대비한 안전장치)
    try {
      String adjKey = 'adj_${rand.nextInt(20)}';
      String adj = AppStrings.getByLang(_selectedLanguage, adjKey);
      String animalKey = AppStrings.animalsKeys[rand.nextInt(AppStrings.animalsKeys.length)];
      String animal = AppStrings.getByLang(_selectedLanguage, animalKey);
      
      // 만약 가져온 텍스트가 키 그대로라면(번역 실패), 기본값 사용
      if (adj.startsWith('adj_')) adj = (_selectedLanguage == 'Korean') ? '성스러운' : 'Holy';
      
      setState(() {
        _nicknameController.text = "$adj $animal";
      });
    } catch (e) {
      // 에러 시 기본값
      setState(() => _nicknameController.text = "Lucky User ${rand.nextInt(999)}");
    }
  }

  // 🎲 랜덤 한줄 소개
  void _rollDiceBio() {
    int randomIndex = Random().nextInt(10); // 개수 조절
    String key = 'bio_$randomIndex';
    String randomBio = AppStrings.getByLang(_selectedLanguage, key);
    if (randomBio.startsWith('bio_')) randomBio = "Carpe Diem ✨"; // 기본값
    setState(() {
      _bioController.text = randomBio;
    });
  }

  // 🧪 MBTI 선택기 (성스러운 디자인)
  void _showMbtiSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _creamyWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 400,
          child: Column(
            children: [
              Text("MBTI 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _holyPurple)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10, crossAxisSpacing: 10,
                  children: _mbtiList.map((m) => ElevatedButton(
                    onPressed: () { setState(() => _mbti = m); Navigator.pop(ctx); },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _mbti == m ? _holyPurple : Colors.white,
                      foregroundColor: _mbti == m ? _holyGold : Colors.black,
                      elevation: _mbti == m ? 5 : 1,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: _mbti == m ? _holyGold : Colors.transparent)),
                    ),
                    child: Text(m, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🌍 언어 변경 다이얼로그
  void _showLanguageDialog() {
    final languages = ['Korean', 'English', 'Japanese', 'Chinese', 'Spanish', 'Hindi'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(children: [Icon(Icons.public, color: _holyPurple), const SizedBox(width: 8), const Text("Language")]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: languages.map((lang) {
            return ListTile(
              title: Text(lang),
              leading: Radio<String>(
                value: lang,
                groupValue: _selectedLanguage,
                activeColor: _holyGold,
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

  // 💾 저장 기능 (안전장치 + 안 닫힘)
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'nickname': _nicknameController.text.trim(),
        'bio': _bioController.text.trim(),
        'status': _bioController.text.trim(), // 호환성
        'avatar_image': _selectedAvatar, 
        'owned_avatars': _myInventory,
        'language': _selectedLanguage,
        'gender': _gender,
        'age': _age.toInt(),
        'interests': _selectedInterests,
        'mbti': _mbti,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${AppStrings.getByLang(_selectedLanguage, 'save')} 완료! ✅"),
            backgroundColor: _holyPurple,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamyWhite,
      appBar: AppBar(
        title: Text(AppStrings.getByLang(_selectedLanguage, 'profile_title'), 
          style: TextStyle(fontWeight: FontWeight.bold, color: _holyGold)),
        backgroundColor: _holyPurple,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.language, color: _holyGold),
            onPressed: _showLanguageDialog,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _holyGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 🏰 성스러운 인벤토리 (카드형)
                  _buildSectionTitle(AppStrings.getByLang(_selectedLanguage, 'inventory')),
                  Container(
                    height: 140,
                    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                      border: Border.all(color: _holyPurple.withOpacity(0.1)),
                    ),
                    child: _myInventory.isEmpty 
                      ? const Center(child: Text("보관함이 비었습니다."))
                      : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _myInventory.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 20),
                        itemBuilder: (context, index) {
                          final avatar = _myInventory[index];
                          final isSelected = avatar == _selectedAvatar;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAvatar = avatar),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // 아바타 원형
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        // 선택되면 골드 테두리 + 그림자
                                        border: isSelected ? Border.all(color: _holyGold, width: 3) : Border.all(color: Colors.grey[200]!, width: 1),
                                        boxShadow: isSelected ? [BoxShadow(color: _holyGold.withOpacity(0.5), blurRadius: 15, spreadRadius: 2)] : null,
                                        color: Colors.white,
                                      ),
                                      child: CircleAvatar(
                                        radius: 32,
                                        backgroundColor: Colors.grey[50],
                                        child: ClipOval(
                                          child: Image.asset(
                                            'assets/avatars/$avatar', 
                                            fit: BoxFit.cover,
                                            // 이미지 없으면 기본 아이콘 표시
                                            errorBuilder: (_, __, ___) => Icon(Icons.person, size: 30, color: Colors.grey[400]),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // 선택됐을 때 체크 표시 (오른쪽 아래)
                                    if (isSelected)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // 파일명(이름) 살짝 보여주기
                                Text(
                                  avatar.toString().split('.').first.toUpperCase(), 
                                  style: TextStyle(
                                    fontSize: 10, 
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? _holyPurple : Colors.grey
                                  )
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ),
                  const SizedBox(height: 30),

                  // 2. 닉네임 + 주사위
                  _buildSectionTitle(AppStrings.getByLang(_selectedLanguage, 'nickname')),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nicknameController,
                          decoration: _inputDeco(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildDiceButton(_rollDiceNickname),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 3. MBTI
                  _buildSectionTitle("MBTI"),
                  GestureDetector(
                    onTap: _showMbtiSelector,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _mbti.isEmpty ? Colors.grey[300]! : _holyGold),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_mbti.isEmpty ? "터치하여 선택하세요" : _mbti, 
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold, 
                              color: _mbti.isEmpty ? Colors.grey : _holyPurple
                            )
                          ),
                          Icon(Icons.arrow_drop_down_circle, color: _holyPurple),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 4. 성별 & 나이
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionTitle(AppStrings.getByLang(_selectedLanguage, 'gender')),
                            Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                              child: Row(
                                children: [
                                  Expanded(child: _buildGenderBtn('남성', "Male")),
                                  Container(width: 1, height: 20, color: Colors.grey[300]),
                                  Expanded(child: _buildGenderBtn('여성', "Female")),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              _buildSectionTitle(AppStrings.getByLang(_selectedLanguage, 'age')),
                              Text("${_age.toInt()}", style: TextStyle(fontWeight: FontWeight.bold, color: _holyGold)),
                            ]),
                            Slider(
                              value: _age, min: 10, max: 80, 
                              activeColor: _holyGold, inactiveColor: Colors.grey[200],
                              onChanged: (val) => setState(() => _age = val),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 5. 한줄 소개 + 주사위
                  _buildSectionTitle(AppStrings.getByLang(_selectedLanguage, 'bio')),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bioController,
                          maxLength: 30,
                          decoration: _inputDeco().copyWith(counterText: ""),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildDiceButton(_rollDiceBio),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 6. 관심사
                  _buildSectionTitle(AppStrings.getByLang(_selectedLanguage, 'interests')),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _interestsOptions.map((interest) {
                      final isSelected = _selectedInterests.contains(interest);
                      return FilterChip(
                        label: Text(interest),
                        selected: isSelected,
                        selectedColor: _holyGold.withOpacity(0.2),
                        checkmarkColor: _holyPurple,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: isSelected ? _holyGold : Colors.grey[300]!),
                        labelStyle: TextStyle(color: isSelected ? _holyPurple : Colors.black),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) { if (_selectedInterests.length < 3) _selectedInterests.add(interest); }
                            else { _selectedInterests.remove(interest); }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 40),

                  // 7. 저장 버튼 (성스러운 골드 버튼)
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _holyGold, 
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: _holyGold.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(AppStrings.getByLang(_selectedLanguage, 'save'), 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- 헬퍼 위젯들 ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _holyPurple)),
    );
  }

  InputDecoration _inputDeco() {
    return InputDecoration(
      filled: true, fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _holyGold)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildDiceButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _holyPurple, 
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: _holyPurple.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.casino, color: Colors.white),
      ),
    );
  }

  Widget _buildGenderBtn(String val, String label) {
    bool isSel = _gender == val;
    return GestureDetector(
      onTap: () => setState(() => _gender = val),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: isSel ? _holyPurple.withOpacity(0.1) : Colors.transparent,
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? _holyPurple : Colors.grey)),
      ),
    );
  }
}
