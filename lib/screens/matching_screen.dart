import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/translations.dart'; // [추가] 번역 파일

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final CardSwiperController controller = CardSwiperController();
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  // 파이어베이스에서 가져온 유저들을 담을 리스트
  List<DocumentSnapshot> _candidates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  // 1. 매칭 후보 불러오기 (나 & 이미 본 사람 제외)
  Future<void> _fetchCandidates() async {
    try {
      // 1-1. 내가 이미 '좋아요'나 '싫어요' 한 목록 가져오기
      final myInteractions = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('interactions') // interactions라는 서브 폴더에 기록할 예정
          .get();

      // 이미 본 사람들의 ID 리스트 만들기
      List<String> seenUserIds = myInteractions.docs.map((doc) => doc.id).toList();

      // 1-2. 전체 유저 가져오기
      final allUsers = await FirebaseFirestore.instance.collection('users').get();

      setState(() {
        _candidates = allUsers.docs.where((doc) {
          // 필터링: 나 자신 아니고 && 이미 본 사람이 아니어야 함
          return doc.id != myUid && !seenUserIds.contains(doc.id);
        }).toList();
        
        _isLoading = false;
      });
      
    } catch (e) {
      print("매칭 후보 불러오기 실패: $e");
      setState(() => _isLoading = false);
    }
  }

  // 2. 스와이프 했을 때 (좋아요/싫어요 저장)
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    
     // Index integrity check
    if (previousIndex >= _candidates.length) return false;

    final candidate = _candidates[previousIndex];
    final candidateUid = candidate.id;
    final isLike = direction == CardSwiperDirection.right;

    // 파이어베이스에 기록 (누가, 누구를, 어떻게 생각했는지)
    FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('interactions')
        .doc(candidateUid)
        .set({
          'type': isLike ? 'like' : 'pass',
          'timestamp': FieldValue.serverTimestamp(),
        });

    print(isLike ? "👉 좋아요: ${candidate['email']}" : "👈 패스: ${candidate['email']}");
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.t('matching_title'))),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) // 로딩 중일 때
          : _candidates.isEmpty
              ? Center(child: Text(AppLocale.t('no_more_friends'))) // 다 봤을 때
              : Column(
                  children: [
                    Expanded(
                      child: CardSwiper(
                        controller: controller,
                        cardsCount: _candidates.length,
                        numberOfCardsDisplayed: _candidates.length < 3 ? _candidates.length : 3,
                        cardBuilder: (context, index, x, y) {
                          return _buildCard(_candidates[index]);
                        },
                        onSwipe: _onSwipe,
                        padding: const EdgeInsets.all(24.0),
                      ),
                    ),
                    const SizedBox(height: 50), // 하단 여백
                  ],
                ),
    );
  }

  // 카드 디자인 (실제 데이터 반영)
  Widget _buildCard(DocumentSnapshot doc) {
    // 데이터가 없으면 기본값 사용
    final data = doc.data() as Map<String, dynamic>;
    final String name = data['email']?.split('@')[0] ?? '이름 없음'; // 이메일 앞부분을 이름으로
    // 아바타가 없으면 기본 강아지로 (나중에는 유저가 설정한 대표 아바타를 불러와야 함)
    final String image = 'assets/avatars/dog.png'; 

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(image, fit: BoxFit.cover), // 유저 사진
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
            ),
            Positioned(
              bottom: 20, left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const Text("성스러운 취미: 차 마시기 🍵", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
