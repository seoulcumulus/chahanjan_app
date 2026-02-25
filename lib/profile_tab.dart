import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
// import '../utils/app_strings.dart'; // ⚠️ 주의: 사용자님의 AppStrings 파일 경로가 맞는지 확인해주세요!

// (혹시 AppStrings 파일이 없어서 에러가 난다면, 임시로 아래 클래스를 주석 해제해서 쓰세요)
class AppStrings {
  static const List<String> animalsKeys = ['cat', 'dog', 'lion', 'tiger', 'bear', 'rabbit'];
  static String getByLang(String lang, String key) {
    if (key == 'profile_title') return "내 정보";
    if (key == 'inventory') return "나의 아바타 컬렉션";
    if (key == 'nickname') return "닉네임";
    if (key == 'save') return "프로필 저장";
    if (key.startsWith('adj')) return "신성한";
    if (key.startsWith('bio')) return "커피 한잔의 여유를 아는 품격 있는 사람";
    return key; // 기본값 리턴
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  // 🎨 성스러운 컬러 팔레트 정의
  final Color _holyGold = const Color(0xFFD4AF37); // 메탈릭 골드
  final Color _holyPurple = const Color(0xFF2E003E); // 딥 퍼플 (교황청 느낌)
  final Color _creamyWhite = const Color(0xFFF9F9F9); // 크림색 배경

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _selectedAvatar = 'rat.png';
  List<dynamic> _myInventory = ['rat.png', 'cat.png', 'dog.png']; // (테스트용 기본값 추가함)

  String _selectedLanguage = 'Korean';
  String _gender = '남성';
  double _age = 25;
  List<String> _selectedInterests = [];
  bool _isLoading = true;

  // MBTI
  String _mbti = ''; 
  final List<String> _mbtiList = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP', 'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ', 'ISTP', 'ISFP', 'ESTP', 'ESFP'
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
          _nicknameController.text = data['nickname'] ?? user.displayName ?? '';
          _bioController.text = data['status'] ?? ''; // 'bio' 대신 'status'로 통일하는 게 좋습니다
          _selectedAvatar = data['avatar_image'] ?? 'rat.png';
          // 보관함이 비어있으면 기본값 사용 (테스트용)
          _myInventory = (data['owned_avatars'] != null && (data['owned_avatars'] as List).isNotEmpty) 
              ? data['owned_avatars'] 
              : ['rat.png', 'cat.png', 'dog.png']; 
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
      print("에러 발생: $e");
      setState(() => _isLoading = false);
    }
  }

  // 🎲 랜덤 닉네임 (기존 로직 유지)
  void _rollDiceNickname() {
    final rand = Random();
    String adjKey = 'adj_${rand.nextInt(20)}';
    String adj = AppStrings.getByLang(_selectedLanguage, adjKey);
    // animalsKeys가 없는 경우 대비
    String animalKey = (AppStrings.animalsKeys.isNotEmpty) 
        ? AppStrings.animalsKeys[rand.nextInt(AppStrings.animalsKeys.length)] 
        : 'lion';
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

  // 🧪 MBTI 약식 테스트
  void _startMBTITest() {
    String result = "";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          title: const Text("MBTI 약식 테스트 🧐", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMbtiRow("나는 쉴 때...", "친구 만남(E)", "혼자 쉼(I)", (val) => result += val),
                const Divider(),
                _buildMbtiRow("나는 생각할 때...", "현실적(S)", "상상력(N)", (val) => result += val),
                const Divider(),
                _buildMbtiRow("나는 결정할 때...", "논리(T)", "감정(F)", (val) => result += val),
                const Divider(),
                _buildMbtiRow("나는 계획을...", "철저히(J)", "유연하게(P)", (val) {
                  result += val;
                  if (result.length >= 4) {
                     setState(() => _mbti = result);
                     Navigator.pop(context);
                  }
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMbtiRow(String title, String opt1, String opt2, Function(String) onSelect) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          ElevatedButton(
            onPressed: () => onSelect(opt1.contains("E") || opt1.contains("S") || opt1.contains("T") || opt1.contains("J") ? opt1.substring(opt1.length-2, opt1.length-1) : opt1), // 단순화
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[100], foregroundColor: Colors.black, elevation: 0),
            child: Text(opt1),
          ),
          ElevatedButton(
            onPressed: () => onSelect(opt2.contains("I") || opt2.contains("N") || opt2.contains("F") || opt2.contains("P") ? opt2.substring(opt2.length-2, opt2.length-1) : opt2),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[100], foregroundColor: Colors.black, elevation: 0),
            child: Text(opt2),
          ),
        ]),
      ],
    );
  }

  // 💾 프로필 저장 (안전장치 강화)
  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    setState(() => _isLoading = true);
    try {
      // .set(..., merge: true)를 사용하여 문서가 없으면 생성, 있으면 업데이트
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'nickname': _nicknameController.text.trim(),
        'status': _bioController.text.trim(), // 지도 화면에서 쓰기 편하게 'status'로 저장
        'bio': _bioController.text.trim(),    // 혹시 몰라 'bio'로도 저장
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
            content: Text("✅ ${AppStrings.getByLang(_selectedLanguage, 'save')} 완료!"),
            backgroundColor: _holyPurple,
          )
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("저장 실패: $e")));
    } finally {
       setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamyWhite,
      appBar: AppBar(
        title: Text(AppStrings.getByLang(_selectedLanguage, 'profile_title'), 
          style: TextStyle(fontWeight: FontWeight.bold, color: _holyGold)),
        backgroundColor: _holyPurple, // 성스러운 보라색 헤더
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _holyGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. [나의 아바타 컬렉션] - 카드 스타일 적용
                  _buildSectionTitle(AppStrings.getByLang(_selectedLanguage, 'inventory')),
                  Container(
                    height: 130,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
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
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: isSelected ? Border.all(color: _holyGold, width: 3) : Border.all(color: Colors.grey[200]!, width: 1),
                                    boxShadow: isSelected ? [BoxShadow(color: _holyGold.withOpacity(0.4), blurRadius: 10)] : null,
                                  ),
                                  child: CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Colors.white,
                                    // 🌟 8방향 스프라이트 시트에서 '정면'만 잘라서 보여주기
                                    child: ClipOval(
                                      child: SizedBox(
                                        width: 60, height: 60,
                                        child: FittedBox( 
                                          fit: BoxFit.cover, // 자른 이미지를 동그라미에 꽉 차게 확대
                                          child: ClipRect( 
                                            child: Align(
                                              alignment: Alignment.topLeft, // 왼쪽 맨 위 기준
                                              widthFactor: 0.25, // 가로를 4등분 한 것 중 1개
                                              heightFactor: 0.5, // 세로를 2등분 한 것 중 1개
                                              child: Image.asset(
                                                'assets/avatars/$avatar', 
                                                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30, color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(height: 5),
                                  const Icon(Icons.check_circle, size: 16, color: Colors.green)
                                ]
                              ],
                            ),
                          );
                        },
                      ),
                  ),
                  const SizedBox(height: 30),

                  // 2. 닉네임
                  _buildSectionTitle(AppStrings.getByLang(_selectedLanguage, 'nickname')),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nicknameController,
                          decoration: InputDecoration(
                            filled: true, fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _holyGold)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildDiceButton(_rollDiceNickname),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 3. MBTI
                  _buildSectionTitle("MBTI"),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _startMBTITest,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            decoration: BoxDecoration(
                              color: _mbti.isEmpty ? Colors.white : _holyPurple.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _mbti.isEmpty ? Colors.grey[300]! : _holyPurple),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_mbti.isEmpty ? "나의 MBTI는? (클릭)" : _mbti, 
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _mbti.isEmpty ? Colors.grey : _holyPurple)),
                                Icon(Icons.psychology, color: _holyPurple),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_mbti.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Wrap(
                        spacing: 8,
                        children: _mbtiList.map((m) => ChoiceChip(
                          label: Text(m),
                          selected: _mbti == m,
                          onSelected: (val) => setState(() => _mbti = m),
                          selectedColor: _holyGold.withOpacity(0.3),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: _mbti == m ? _holyGold : Colors.grey[300]!),
                        )).toList(),
                      ),
                    )
                  ],
                  const SizedBox(height: 25),

                  // 4. 성별 & 나이 (카드 스타일)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("성별", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)),
                              child: Row(
                                children: [
                                  Expanded(child: _buildGenderBtn('남성', "Male")),
                                  Container(width: 1, height: 20, color: Colors.grey[300]),
                                  Expanded(child: _buildGenderBtn('여성', "Female")),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                              Text("나이", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                              Text("${_age.toInt()}세", style: TextStyle(fontWeight: FontWeight.bold, color: _holyGold)),
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

                  // 5. 한줄 소개
                  _buildSectionTitle("한줄 소개"),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _bioController,
                          maxLength: 30,
                          decoration: InputDecoration(
                            hintText: "나를 표현하는 한 마디...",
                            counterText: "",
                            filled: true, fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _holyGold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _buildDiceButton(_rollDiceBio),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 6. 관심사
                  _buildSectionTitle("관심사 (최대 3개)"),
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
                        foregroundColor: Colors.white, // 글자색 흰색
                        elevation: 5,
                        shadowColor: _holyGold.withOpacity(0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

  // 헬퍼 위젯: 섹션 타이틀
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _holyPurple)),
    );
  }

  // 헬퍼 위젯: 주사위 버튼
  Widget _buildDiceButton(VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _holyPurple, // 보라색 버튼
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: _holyPurple.withOpacity(0.3), blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: const Icon(Icons.casino, color: Colors.white), // 흰색 아이콘
      ),
    );
  }

  // 헬퍼 위젯: 성별 버튼
  Widget _buildGenderBtn(String genderVal, String label) {
    final isSelected = _gender == genderVal;
    return GestureDetector(
      onTap: () => setState(() => _gender = genderVal),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _holyPurple.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(
          fontWeight: FontWeight.bold, 
          color: isSelected ? _holyPurple : Colors.grey
        )),
      ),
    );
  }
}
