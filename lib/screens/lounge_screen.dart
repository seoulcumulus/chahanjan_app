import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../services/matching_service.dart';
import 'chat_screen.dart';
import '../utils/app_strings.dart';

class LoungeScreen extends StatefulWidget {
  const LoungeScreen({super.key});

  @override
  State<LoungeScreen> createState() => _LoungeScreenState();
}

class _LoungeScreenState extends State<LoungeScreen> {
  final MatchingService _matchingService = MatchingService();
  bool _isSearching = false;
  String _statusText = "";
  StreamSubscription? _matchSubscription; // 👈 채팅방 감지용

  // 내 정보 가져오기 (필터링용)
  List<String> _myInterests = [];
  int _myAge = 20;
  // String _myNickname = "";

  @override
  void initState() {
    super.initState();
    _loadMyInfo();
  }

  Future<void> _loadMyInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _myInterests = List<String>.from(data['interests'] ?? []);
          _myAge = data['age'] ?? 20;
          // _myNickname = data['nickname'] ?? "나";
        });
      }
    }
    // Initialize status text after loading
    setState(() {
      _statusText = AppStrings.get('lounge_desc');
    });
  }

  // 🎛️ 필터 선택 팝업
  void _showFilterDialog(bool isGlobal) {
    String? selectedGender; // 'male', 'female', 또는 null(무관)
    String? selectedInterest; // 'Gaming', 'Coffee'...
    // 나이 범위 (예: 20~30세)
    RangeValues selectedAgeRange = const RangeValues(20, 40);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder( // 팝업 내부 상태 갱신용
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              height: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("상세 조건 설정", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // 1. 성별 선택
                  const Text("상대방 성별"),
                  Row(
                    children: [
                      _filterChip("상관없음", selectedGender == null, () => setModalState(() => selectedGender = null)),
                      _filterChip("남성", selectedGender == 'male', () => setModalState(() => selectedGender = 'male')),
                      _filterChip("여성", selectedGender == 'female', () => setModalState(() => selectedGender = 'female')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. 관심사 (예시: 커피)
                  const Text("같은 관심사"),
                  Wrap(
                    spacing: 8,
                    children: ['Coffee', 'Gaming', 'Travel'].map((interest) {
                      return ChoiceChip(
                        label: Text(interest),
                        selected: selectedInterest == interest,
                        onSelected: (val) {
                          setModalState(() => selectedInterest = val ? interest : null);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 3. 나이 범위
                  Text("나이: ${selectedAgeRange.start.round()}세 ~ ${selectedAgeRange.end.round()}세"),
                  RangeSlider(
                    values: selectedAgeRange,
                    min: 18, max: 60,
                    divisions: 42,
                    labels: RangeLabels("${selectedAgeRange.start.round()}", "${selectedAgeRange.end.round()}"),
                    onChanged: (values) => setModalState(() => selectedAgeRange = values),
                  ),

                  const Spacer(),

                  // 매칭 시작 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // 팝업 닫기
                        
                        // 필터 데이터를 맵으로 포장
                        final filters = {
                          'gender': selectedGender,
                          'interest': selectedInterest,
                          'minAge': selectedAgeRange.start.round(),
                          'maxAge': selectedAgeRange.end.round(),
                        };
                        
                        // 🚀 매칭 시작 함수 호출!
                        _startMatchingWithFilter(isGlobal, filters);
                      },
                      child: const Text("이 조건으로 매칭 시작!"),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 칩 디자인 헬퍼
  Widget _filterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
      ),
    );
  }

  void _startMatchingWithFilter(bool isGlobal, Map<String, dynamic> filters) async {
    setState(() => _isSearching = true); // 로딩 시작

    // 서비스 호출
    String? roomId = await MatchingService().startMatching(
      isGlobal: isGlobal,
      filterOptions: filters,
    );

    if (roomId != null) {
      _enterChatRoom(roomId);
    } else {
      _listenForMatch(); // 대기 모드 진입
    }
  }

  // 👂 누군가 나를 매칭했는지 감시하는 함수
  void _listenForMatch() {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    
    // chat_rooms 컬렉션에서 'participants' 배열에 내 ID가 포함된 방이 생기는지 감시
    _matchSubscription = FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('participants', arrayContains: myUid)
        .orderBy('updatedAt', descending: true) // createdAt -> updatedAt (Schema Unification)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          
      if (snapshot.docs.isNotEmpty) {
        // 방이 생겼다! (매칭 성사)
        final roomData = snapshot.docs.first;
        
        // 방금 만들어진 방인지 확인 (오래된 방 X)
        // (실제로는 createdAt 시간 비교 로직이 더 정교해야 하지만 일단 간략하게)
        _enterChatRoom(roomData.id);
      }
    });
  }

  // 🚪 채팅방 입장 함수
  Future<void> _enterChatRoom(String roomId) async {
    // 리스너 해제 (더 이상 감시 X)
    _matchSubscription?.cancel();
    
    setState(() {
      _isSearching = false; // 로딩 끝
    });

    try {
      final myUid = FirebaseAuth.instance.currentUser?.uid;
      // 방 정보 가져와서 상대방 ID 찾기
      final doc = await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).get();
      if (!doc.exists) return;

      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> participants = data['participants'] ?? [];
      final String peerUid = participants.firstWhere((id) => id != myUid, orElse: () => 'unknown');

      if (!mounted) return;

      // 채팅 화면으로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: roomId, 
            peerUid: peerUid, // 찾은 peerUid 전달
            peerNickname: "운명의 상대", 
            peerAvatar: "rat.png"
          ), 
        ),
      );
    } catch (e) {
      print("❌ 채팅방 입장 오류: $e");
    }
  }

  // 🛑 매칭 취소 버튼
  void _cancelSearch() async {
    await MatchingService().cancelMatching();
    _matchSubscription?.cancel();
    setState(() {
      _isSearching = false;
      _statusText = AppStrings.get('lounge_desc');
    });
  }

  @override
  void dispose() {
    _matchSubscription?.cancel();
    // 화면 나가면 대기열에서 자동 이탈
    _matchingService.cancelMatching(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.get('lounge_title')), elevation: 0, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 애니메이션 아이콘 (로딩 중일 때 뺑글뺑글)
            if (_isSearching)
              const CircularProgressIndicator()
            else
              const Icon(Icons.travel_explore, size: 80, color: Colors.blue),
            
            const SizedBox(height: 30),
            Text(_statusText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),

            if (!_isSearching) ...[
              ElevatedButton(
                onPressed: () => _showFilterDialog(false),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                child: Text(AppStrings.get('btn_domestic')),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _showFilterDialog(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
                child: Text(AppStrings.get('btn_global')),
              ),
            ] else 
              OutlinedButton(
                onPressed: _cancelSearch,
                child: Text(AppStrings.get('cancel_match')),
              )
          ],
        ),
      ),
    );
  }
}
