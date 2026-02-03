// lib/screens/matching_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart'; // 패키지 불러오기

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  // 매칭 후보들 (가짜 데이터) - 나중에는 서버에서 불러옵니다!
  final List<Map<String, String>> candidates = [
    {'name': '도지 1호', 'image': 'assets/avatars/dog.png', 'desc': '산책을 좋아하는 댕댕이'},
    {'name': '시크냥', 'image': 'assets/avatars/cat.png', 'desc': '츄르 주면 친해짐'},
    {'name': '헬창 곰돌이', 'image': 'assets/avatars/bear.png', 'desc': '3대 500 치는 곰'},
    {'name': '힙합 토끼', 'image': 'assets/avatars/rabbit.png', 'desc': '쇼미더머니 우승 후보'},
    {'name': '여우 도사', 'image': 'assets/avatars/fox.png', 'desc': '천년 묵은 여우'},
  ];

  final CardSwiperController controller = CardSwiperController();

  // 성스러운 색상 정의
  final Color _holyPurple = const Color(0xFF6A1B9A);
  final Color _holyGold = const Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("성스러운 매칭", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 1. 스와이프 카드 영역
          Expanded(
            child: CardSwiper(
              controller: controller,
              cardsCount: candidates.length,
              numberOfCardsDisplayed: 3, // 뒤에 3장까지 보이게
              backCardOffset: const Offset(0, 40), // 뒤에 카드들이 살짝 아래로 보이게
              padding: const EdgeInsets.all(24.0),
              cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                final candidate = candidates[index];
                return _buildCard(candidate);
              },
              // 스와이프 했을 때 동작
              onSwipe: _onSwipe,
            ),
          ),
          
          // 2. 하단 컨트롤 버튼 (X / O)
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(Icons.close, Colors.red, () => controller.swipe(CardSwiperDirection.left)),
                const SizedBox(width: 40),
                _buildActionButton(Icons.favorite, _holyPurple, () => controller.swipe(CardSwiperDirection.right)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 카드 디자인 (성스러운 테두리 + 이미지)
  Widget _buildCard(Map<String, String> candidate) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
        ],
        border: Border.all(color: _holyGold.withOpacity(0.5), width: 2), // 골드 테두리
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 아바타 이미지 (꽉 차게)
            Image.asset(
              candidate['image']!,
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Container(color: Colors.grey[300], child: const Icon(Icons.person, size: 100)),
            ),
            
            // 하단 그라데이션 (글씨 잘 보이게)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      candidate['name']!,
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      candidate['desc']!,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 하단 버튼 디자인
  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  // 스와이프 결과 처리
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.right) {
      debugPrint('👉 좋아요! (${candidates[previousIndex]['name']})');
      // 여기에 '매칭 성공' 로직을 넣으면 됩니다!
    } else {
      debugPrint('👈 패스... (${candidates[previousIndex]['name']})');
    }
    return true;
  }
}
