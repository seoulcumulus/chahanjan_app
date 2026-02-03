import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../utils/app_strings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // 🎨 성스러운 컬러 팔레트
  final Color _holyGold = const Color(0xFFD4AF37);
  final Color _holyPurple = const Color(0xFF2E003E);
  final Color _creamyWhite = const Color(0xFFF9F9F9);

  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  String _selectedAvatar = 'rat.png';
  List<dynamic> _myInventory = ['rat.png', 'cat.png', 'dog.png', 'lion.png', 'bear.png'];

  String _selectedLanguage = 'Korean';
  String _gender = '남성';
  double _age = 25;
  List<String> _selectedInterests = [];
  bool _isLoading = true;

  String _mbti = ''; 
  final List<String> _mbtiList = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP', 'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ', 'ISTP', 'ISFP', 'ESTP', 'ESFP'
  ];

  // 📖 MBTI 성격 설명서 (데이터베이스)
  final Map<String, String> _mbtiDescriptions = {
    'INTJ': '용의주도한 전략가',
    'INTP': '논리적인 사색가',
    'ENTJ': '대담한 통솔자',
    'ENTP': '뜨거운 논쟁을 즐기는 변론가',
    'INFJ': '선의의 옹호자',
    'INFP': '열정적인 중재자',
    'ENFJ': '정의로운 사회운동가',
    'ENFP': '재기발랄한 활동가',
    'ISTJ': '청렴결백한 논리주의자',
    'ISFJ': '용감한 수호자',
    'ESTJ': '엄격한 관리자',
    'ESFJ': '사교적인 외교관',
    'ISTP': '만능 재주꾼',
    'ISFP': '호기심 많은 예술가',
    'ESTP': '모험을 즐기는 사업가',
    'ESFP': '자유로운 영혼의 연예인',
  };

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
          _bioController.text = data['bio'] ?? data['status'] ?? '';
          _selectedAvatar = data['avatar_image'] ?? 'rat.png';
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

  // 🎲 주사위 로직들 (생략 없이 유지)
  void _rollDiceNickname() {
    final rand = Random();
    try {
      String adjKey = 'adj_${rand.nextInt(20)}';
      String adj = AppStrings.getByLang(_selectedLanguage, adjKey);
      String animalKey = AppStrings.animalsKeys[rand.nextInt(AppStrings.animalsKeys.length)];
      String animal = AppStrings.getByLang(_selectedLanguage, animalKey);
      if (adj.startsWith('adj_')) adj = (_selectedLanguage == 'Korean') ? '성스러운' : 'Holy';
      setState(() => _nicknameController.text = "$adj $animal");
    } catch (e) {
      setState(() => _nicknameController.text = "Lucky User ${rand.nextInt(999)}");
    }
  }

  void _rollDiceBio() {
    int randomIndex = Random().nextInt(10);
    String key = 'bio_$randomIndex';
    String randomBio = AppStrings.getByLang(_selectedLanguage, key);
    if (randomBio.startsWith('bio_')) randomBio = "Carpe Diem ✨";
    setState(() => _bioController.text = randomBio);
  }

  // 🕵️♂️ MBTI 테스트 시작하기
  void _startMbtiTest() {
    String resIE = '', resSN = '', resTF = '', resJP = '';
    
    showDialog(
      context: context,
      builder: (ctx) {
        // StatefulBuilder를 써야 다이얼로그 안에서 상태가 바뀝니다!
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                children: [
                  Icon(Icons.psychology, color: _holyPurple),
                  const SizedBox(width: 10),
                  const Text("성향 테스트", style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Q1. 에너지를 얻는 방향은?", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _buildTestBtn("혼자가 편해 (I)", resIE == 'I', () => setDialogState(() => resIE = 'I')),
                        const SizedBox(width: 5),
                        _buildTestBtn("사람들과 함께 (E)", resIE == 'E', () => setDialogState(() => resIE = 'E')),
                      ],
                    ),
                    const Divider(height: 30),

                    const Text("Q2. 인식하는 방식은?", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _buildTestBtn("현실과 경험 (S)", resSN == 'S', () => setDialogState(() => resSN = 'S')),
                        const SizedBox(width: 5),
                        _buildTestBtn("직관과 상상 (N)", resSN == 'N', () => setDialogState(() => resSN = 'N')),
                      ],
                    ),
                    const Divider(height: 30),

                    const Text("Q3. 판단의 근거는?", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _buildTestBtn("사실과 논리 (T)", resTF == 'T', () => setDialogState(() => resTF = 'T')),
                        const SizedBox(width: 5),
                        _buildTestBtn("사람과 관계 (F)", resTF == 'F', () => setDialogState(() => resTF = 'F')),
                      ],
                    ),
                    const Divider(height: 30),

                    const Text("Q4. 생활 양식은?", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _buildTestBtn("계획적으로 (J)", resJP == 'J', () => setDialogState(() => resJP = 'J')),
                        const SizedBox(width: 5),
                        _buildTestBtn("유동적으로 (P)", resJP == 'P', () => setDialogState(() => resJP = 'P')),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("취소", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: (resIE.isEmpty || resSN.isEmpty || resTF.isEmpty || resJP.isEmpty)
                      ? null // 다 안 고르면 비활성화
                      : () {
                          String result = "$resIE$resSN$resTF$resJP";
                          Navigator.pop(ctx); // 테스트 창 닫고
                          _showMbtiResult(result); // 결과 창 보여주기
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: _holyGold, foregroundColor: Colors.white),
                  child: const Text("결과 확인"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 🏆 MBTI 결과 및 설명 보여주기
  void _showMbtiResult(String result) {
    String description = _mbtiDescriptions[result] ?? "알 수 없는 유형";
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          children: [
            Icon(Icons.emoji_events, size: 50, color: _holyGold),
            const SizedBox(height: 10),
            Text(result, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _holyPurple)),
            const SizedBox(height: 5),
            Text(description, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
        content: const Text(
          "이 유형이 맞으신가요?\n프로필에 바로 적용할 수 있습니다.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("다시 하기"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _mbti = result); // 결과 적용!
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _holyPurple, foregroundColor: Colors.white),
            child: const Text("적용하기"),
          ),
        ],
      ),
    );
  }

  // 🧪 MBTI 선택기 (팝업)
  void _showMbtiSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _creamyWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 450,
          child: Column(
            children: [
              Text("MBTI 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _holyPurple)),
              const SizedBox(height: 10),
              // 모르면 테스트하러 가기 버튼
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _startMbtiTest(); // 테스트 시작!
                },
                icon: const Icon(Icons.help_outline, color: Colors.blue),
                label: const Text("내 MBTI를 모르겠나요? (테스트)", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10, crossAxisSpacing: 10,
                  children: _mbtiList.map((m) => ElevatedButton(
                    onPressed: () { 
                      setState(() => _mbti = m); 
                      Navigator.pop(ctx); 
                      // 선택 후 설명 보여주기 (선택사항)
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$m: ${_mbtiDescriptions[m]}"), duration: const Duration(seconds: 1)));
                    },
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

  // ... (기타 함수들: 언어 변경, 저장 등은 기존과 동일) ...
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
        'status': _bioController.text.trim(),
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("저장 완료! ✅"), backgroundColor: _holyPurple));
      }
    } catch (e) { 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } 
    finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _creamyWhite,
      appBar: AppBar(
        title: Text("내 정보", style: TextStyle(fontWeight: FontWeight.bold, color: _holyGold)),
        backgroundColor: _holyPurple,
        centerTitle: true,
        actions: [IconButton(icon: Icon(Icons.language, color: _holyGold), onPressed: _showLanguageDialog)],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _holyGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 아바타
                  _buildSectionTitle("나의 아바타"),
                  _buildInventory(), // (아래 헬퍼 함수 참고)
                  const SizedBox(height: 30),

                  // 2. 닉네임
                  _buildSectionTitle("닉네임"),
                  Row(children: [Expanded(child: TextField(controller: _nicknameController, decoration: _inputDeco())), const SizedBox(width: 10), _buildDiceButton(_rollDiceNickname)]),
                  const SizedBox(height: 25),

                  // 3. MBTI (여기가 핵심!)
                  _buildSectionTitle("MBTI"),
                  GestureDetector(
                    onTap: _showMbtiSelector, // 클릭하면 선택창+테스트 버튼 뜸
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_mbti.isEmpty ? "터치하여 선택 또는 테스트" : _mbti, 
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _mbti.isEmpty ? Colors.grey : _holyPurple)),
                              if (_mbti.isNotEmpty)
                                Text(_mbtiDescriptions[_mbti] ?? "", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Icon(Icons.psychology, color: _holyPurple),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ... (성별, 나이, 한줄소개, 관심사 UI는 이전과 동일) ...
                  _buildSectionTitle("성별 & 나이"),
                  Row(children: [
                    Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)), child: Row(children: [Expanded(child: _buildGenderBtn('남성', "Male")), Container(width: 1, height: 20, color: Colors.grey[300]), Expanded(child: _buildGenderBtn('여성', "Female"))]))),
                    const SizedBox(width: 20),
                    Expanded(child: Column(children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("나이", style: const TextStyle(fontWeight: FontWeight.bold)), Text("${_age.toInt()}", style: TextStyle(fontWeight: FontWeight.bold, color: _holyGold))]), Slider(value: _age, min: 10, max: 80, activeColor: _holyGold, inactiveColor: Colors.grey[200], onChanged: (val) => setState(() => _age = val))]))
                  ]),
                  const SizedBox(height: 25),

                  _buildSectionTitle("한줄 소개"),
                  Row(children: [Expanded(child: TextField(controller: _bioController, maxLength: 30, decoration: _inputDeco().copyWith(counterText: ""))), const SizedBox(width: 10), _buildDiceButton(_rollDiceBio)]),
                  const SizedBox(height: 25),

                  _buildSectionTitle("관심사"),
                  Wrap(spacing: 8, runSpacing: 8, children: _interestsOptions.map((interest) {
                    final isSelected = _selectedInterests.contains(interest);
                    return FilterChip(label: Text(interest), selected: isSelected, selectedColor: _holyGold.withOpacity(0.2), checkmarkColor: _holyPurple, backgroundColor: Colors.white, onSelected: (selected) { setState(() { if (selected) { if (_selectedInterests.length < 3) _selectedInterests.add(interest); } else { _selectedInterests.remove(interest); } }); });
                  }).toList()),
                  const SizedBox(height: 40),

                  SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _saveProfile, style: ElevatedButton.styleFrom(backgroundColor: _holyGold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text("프로필 저장", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // --- 헬퍼 위젯들 ---
  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.only(bottom: 8, left: 4), child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: _holyPurple)));
  }
  InputDecoration _inputDeco() => InputDecoration(filled: true, fillColor: Colors.white, enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _holyGold)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14));
  Widget _buildDiceButton(VoidCallback onTap) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _holyPurple, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.casino, color: Colors.white)));
  Widget _buildGenderBtn(String val, String label) => GestureDetector(onTap: () => setState(() => _gender = val), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), color: _gender == val ? _holyPurple.withOpacity(0.1) : Colors.transparent, alignment: Alignment.center, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: _gender == val ? _holyPurple : Colors.grey))));
  
  // 테스트용 버튼 스타일 위젯
  Widget _buildTestBtn(String text, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? _holyPurple : Colors.grey[100],
          foregroundColor: isSelected ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  // 인벤토리 위젯 (기존 성스러운 디자인 유지)
  Widget _buildInventory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("보유 아바타 창고 (${_myInventory.length})", style: TextStyle(fontWeight: FontWeight.bold, color: _holyPurple)),
            Icon(Icons.inventory_2, color: _holyPurple.withOpacity(0.5)),
          ],
        ),
        const SizedBox(height: 10),
        
        // ✨ 여기가 핵심! 가로 스크롤(ListView)을 -> 격자(GridView)로 변경
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: _holyPurple.withOpacity(0.05), blurRadius: 10)],
            border: Border.all(color: _holyPurple.withOpacity(0.1)),
          ),
          child: GridView.builder(
            shrinkWrap: true, // 이게 있어야 스크롤 에러가 안 납니다
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _myInventory.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 한 줄에 3개씩!
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8, // 세로로 길쭉한 카드 비율
            ),
            itemBuilder: (context, index) {
              final avatar = _myInventory[index];
              final isSelected = avatar == _selectedAvatar;
              return GestureDetector(
                onTap: () => setState(() => _selectedAvatar = avatar),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? _holyGold.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? _holyGold : Colors.grey[200]!, 
                      width: isSelected ? 2 : 1
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/avatars/$avatar', height: 50, errorBuilder: (_,__,___)=>const Icon(Icons.person)),
                          const SizedBox(height: 5),
                          Text(avatar.split('.')[0], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      if (isSelected)
                        const Positioned(top: 5, right: 5, child: Icon(Icons.check_circle, color: Colors.green, size: 16)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
