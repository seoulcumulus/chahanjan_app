import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../utils/app_strings.dart';
import '../utils/translations.dart'; // [추가] 번역 파일
import 'package:chahanjan_app/screens/shop_screen.dart'; // [추가] 상점 화면 import

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

  double _mannerTemp = 36.5; // 👈 매너 온도 저장
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

  final List<String> _interestKeys = [
    'hiking', 'golf', 'gym', 'tennis', 'baseball', 'soccer', 'wine',
    'coffee', 'whiskey', 'foodie', 'reading', 'finance', 'meditation', 'gaming', 'business'
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
          _mannerTemp = (data['manner_temp'] ?? 36.5).toDouble(); // 👈 온도 로드
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

  // MBTI 약식 테스트 다이얼로그 (수정됨: 6개 국어 지원)
  void _showMbtiTestDialog() {
    String _currentEorI = '', _currentNorS = '', _currentForT = '', _currentPorJ = '';
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.psychology, color: Colors.purple),
                  const SizedBox(width: 10),
                  Text(AppLocale.t('mbti_test_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Q1
                    Text(AppLocale.t('q1_text'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(child: _buildOptionButton("I", AppLocale.t('q1_opt1'), _currentEorI, (val) => setState(() => _currentEorI = val))),
                        Expanded(child: _buildOptionButton("E", AppLocale.t('q1_opt2'), _currentEorI, (val) => setState(() => _currentEorI = val))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Q2
                    Text(AppLocale.t('q2_text'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(child: _buildOptionButton("S", AppLocale.t('q2_opt1'), _currentNorS, (val) => setState(() => _currentNorS = val))),
                        Expanded(child: _buildOptionButton("N", AppLocale.t('q2_opt2'), _currentNorS, (val) => setState(() => _currentNorS = val))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Q3
                    Text(AppLocale.t('q3_text'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(child: _buildOptionButton("T", AppLocale.t('q3_opt1'), _currentForT, (val) => setState(() => _currentForT = val))),
                        Expanded(child: _buildOptionButton("F", AppLocale.t('q3_opt2'), _currentForT, (val) => setState(() => _currentForT = val))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Q4
                    Text(AppLocale.t('q4_text'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(child: _buildOptionButton("J", AppLocale.t('q4_opt1'), _currentPorJ, (val) => setState(() => _currentPorJ = val))),
                        Expanded(child: _buildOptionButton("P", AppLocale.t('q4_opt2'), _currentPorJ, (val) => setState(() => _currentPorJ = val))),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocale.t('btn_cancel'), style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                  onPressed: (_currentEorI.isEmpty || _currentNorS.isEmpty || _currentForT.isEmpty || _currentPorJ.isEmpty)
                      ? null 
                      : () {
                          // 결과 조합 (예: INTJ)
                          String result = "$_currentEorI$_currentNorS$_currentForT$_currentPorJ";
                          Navigator.pop(context);
                          _updateMbti(result); // DB 업데이트 & 결과창
                        },
                  child: Text(AppLocale.t('btn_confirm')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 헬퍼: 옵션 버튼
  Widget _buildOptionButton(String value, String text, String groupValue, Function(String) onChanged) {
    bool isSelected = groupValue == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  // 헬퍼: MBTI 업데이트
  void _updateMbti(String result) {
    setState(() => _mbti = result);
    _showMbtiResult(result); // 결과 설명 팝업 호출
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
              Text(AppLocale.t('mbti_select_title'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _holyPurple)),
              const SizedBox(height: 10),
              // 모르면 테스트하러 가기 버튼
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showMbtiTestDialog(); // 테스트 시작 (수정됨)
                },
                icon: const Icon(Icons.help_outline, color: Colors.blue),
                label: Text(AppLocale.t('mbti_unknown_link'), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
  // 언어 선택 다이얼로그 (수정됨: 힌디 추가, 프랑스어 삭제)
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Language / भाषा'), // 제목에도 힌디 느낌 살짝 추가
        children: [
          _buildLangOption(context, '한국어', 'ko'),
          _buildLangOption(context, 'English', 'en'),
          _buildLangOption(context, '日本語', 'ja'),
          _buildLangOption(context, '中文', 'zh'),
          _buildLangOption(context, 'Español', 'es'),
          
          // 👇 프랑스어 삭제하고 인도어(Hindi) 추가!
          _buildLangOption(context, 'हिन्दी (Hindi)', 'hi'), 
        ],
      ),
    );
  }

  // 언어 선택 옵션 위젯 (추가됨)
  Widget _buildLangOption(BuildContext context, String label, String code) {
    return SimpleDialogOption(
      onPressed: () {
        // 🚨 기존: AppLocale.current = code; (X) 이거 안 됨
        
        // ✅ 수정: 확성기로 변경 알리기! (O)
        AppLocale.changeLanguage(code); 
        
        Navigator.pop(context); // 창 닫기
        
        // (setState는 이제 없어도 됩니다. main.dart가 알아서 처리합니다!)
      },
      child: ValueListenableBuilder<String>(
        valueListenable: AppLocale.currentNotifier,
        builder: (context, currentCode, child) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label, 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: currentCode == code ? FontWeight.bold : FontWeight.normal,
                    color: currentCode == code ? _holyPurple : Colors.black87,
                  ),
                ),
                if (currentCode == code) Icon(Icons.check, color: _holyGold),
              ],
            ),
          );
        }
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
        title: Text(AppLocale.t('nav_profile'), style: TextStyle(fontWeight: FontWeight.bold, color: _holyGold)),
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
                  _buildSectionTitle(AppLocale.t('my_avatar')),
                  _buildInventory(), // (아래 헬퍼 함수 참고)
                  const SizedBox(height: 20),

                  // 🌡️ 1.5. 매너 온도 표시
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40), // 양옆 여백
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text("나의 매너 온도 🌡️", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        _buildMannerBar(_mannerTemp),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 2. 닉네임
                  _buildSectionTitle(AppLocale.t('nickname')),
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
                                Text(AppLocale.t('${_mbti}_desc'), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          Icon(Icons.psychology, color: _holyPurple),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // ... (성별, 나이, 한줄소개, 관심사 UI는 이전과 동일) ...
                  Text(AppLocale.t('gender_age'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(children: [
                    Expanded(child: Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[300]!)), child: Row(children: [Expanded(child: _buildGenderBtn('남성', AppLocale.t('male'))), Container(width: 1, height: 20, color: Colors.grey[300]), Expanded(child: _buildGenderBtn('여성', AppLocale.t('female')))]))),
                    const SizedBox(width: 20),
                    Expanded(child: Column(children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                        children: [
                          Text(AppLocale.t('age'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), 
                          Text("${_age.toInt()}", style: TextStyle(fontWeight: FontWeight.bold, color: _holyGold))
                        ]
                      ), 
                      Slider(value: _age, min: 10, max: 80, activeColor: _holyGold, inactiveColor: Colors.grey[200], onChanged: (val) => setState(() => _age = val))
                    ]))
                  ]),
                  const SizedBox(height: 25),

                  // _buildSectionTitle("한줄 소개"), // 라벨 사용으로 인해 제목 제거
                  Row(children: [
                    Expanded(child: TextField(
                      controller: _bioController, 
                      maxLength: 30, 
                      decoration: _inputDeco().copyWith(
                        counterText: "",
                        labelText: AppLocale.t('bio'), 
                        hintText: "...",
                      )
                    )), 
                    const SizedBox(width: 10), 
                    _buildDiceButton(_rollDiceBio)
                  ]),
                  const SizedBox(height: 25),

                  _buildSectionTitle(AppLocale.t('interests')),
                  Wrap(spacing: 8, runSpacing: 8, children: _interestKeys.map((key) {
                    final isSelected = _selectedInterests.contains(key);
                    return FilterChip(
                      label: Text(AppLocale.t(key)), 
                      selected: isSelected, 
                      selectedColor: _holyGold.withOpacity(0.2), 
                      checkmarkColor: _holyPurple, 
                      backgroundColor: Colors.white, 
                      onSelected: (selected) { 
                        setState(() { 
                          if (selected) { 
                            if (_selectedInterests.length < 3) _selectedInterests.add(key); 
                          } else { 
                            _selectedInterests.remove(key); 
                          } 
                        }); 
                      }
                    );
                  }).toList()),
                  const SizedBox(height: 40),

                  SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _saveProfile, style: ElevatedButton.styleFrom(backgroundColor: _holyGold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text(AppLocale.t('save_profile'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)))),
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
            Text("${AppLocale.t('inventory')} (${_myInventory.length})", style: TextStyle(fontWeight: FontWeight.bold, color: _holyPurple)),
            // Icon(Icons.inventory_2, color: _holyPurple.withOpacity(0.5)), // 기존 아이콘 주석 처리
            IconButton(
              icon: const Icon(Icons.storefront, color: Colors.blue, size: 28),
              
              // 1. 여기에 async를 꼭 붙여야 await를 쓸 수 있습니다!
              onPressed: () async {
                
                // 2. 상점으로 이동 (갔다 올 때까지 기다림 = await)
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    // ShopScreen에는 이제 복잡한 onBuy가 없어도 됩니다. 
                    // (단, ShopScreen 내부에서 구매 시 Firebase에 저장은 해야 함!)
                    builder: (context) => ShopScreen(
                      myInventory: List<String>.from(_myInventory),
                      onBuy: (newItem) {
                         // ShopScreen 구조상 이 함수가 필요하다면 비워두거나,
                         // 단순히 'print' 정도만 해도 됩니다. 
                         // 왜냐? 돌아오면 어차피 서버에서 다시 불러올 거니까요!
                      },
                    ),
                  ),
                );

                // 3. 상점에서 돌아오면 이 줄이 실행됩니다.
                // 서버(Firebase)에서 최신 데이터를 다시 싹 긁어옵니다.
                print("📢 상점에서 복귀! 인벤토리 새로고침 중...");
                _loadUserProfile(); 
              },
            ),
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

  // 🌡️ [추가] 매너 온도 막대 위젯 헬퍼 함수
  Widget _buildMannerBar(double temp) {
    // 🎨 온도 디자인 로직 (70도 기준)
    final bool isHighManner = temp >= 70.0;
    final Color barColor = isHighManner ? const Color(0xFF24FCFF) : const Color(0xFFFFD700);
    final double barHeight = isHighManner ? 12.0 : 8.0;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: temp / 100.0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: barHeight, // 두께 적용
            ),
          ),
        ),
        const SizedBox(width: 15),
        Text(
          "$temp℃",
          style: TextStyle(
            color: barColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
