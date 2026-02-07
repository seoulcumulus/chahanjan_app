import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/translations.dart';
import '../services/user_service.dart'; // Ensure this import exists for deducting tea leaves
import 'chat_screen.dart'; // Ensure this import exists for navigation
import '../widgets/manner_avatar.dart'; // 👈 매너 아바타 위젯

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> {
  final CardSwiperController controller = CardSwiperController();
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  List<DocumentSnapshot> _candidates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCandidates();
  }

  // 1. Fetch Candidates (Exclude self and already interacted users)
  Future<void> _fetchCandidates() async {
    try {
      final myInteractions = await FirebaseFirestore.instance
          .collection('users')
          .doc(myUid)
          .collection('interactions')
          .get();

      List<String> seenUserIds = myInteractions.docs.map((doc) => doc.id).toList();
      final allUsers = await FirebaseFirestore.instance.collection('users').get();

      setState(() {
        _candidates = allUsers.docs.where((doc) {
          return doc.id != myUid && !seenUserIds.contains(doc.id);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching candidates: $e");
      setState(() => _isLoading = false);
    }
  }

  // 2. Handle Swipe Actions
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (previousIndex >= _candidates.length) return false;

    final candidate = _candidates[previousIndex];
    final candidateUid = candidate.id;
    final candidateData = candidate.data() as Map<String, dynamic>;

    String type = 'pass';
    if (direction == CardSwiperDirection.right) {
      type = 'like';
      _recordInteraction(candidateUid, 'like');
    } else if (direction == CardSwiperDirection.left) {
      type = 'pass';
      _recordInteraction(candidateUid, 'pass');
    } else if (direction == CardSwiperDirection.top) {
      // Swipe Up = Super Like / Chat Now
      type = 'super_like';
      _recordInteraction(candidateUid, 'super_like');
      _startChat(candidateUid, candidateData); // Immediate Chat
    }

    print("Swiped $type on ${candidate['email']}");
    return true;
  }

  // Record interaction in Firestore
  void _recordInteraction(String targetUid, String type) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(myUid)
        .collection('interactions')
        .doc(targetUid)
        .set({
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 3. Logic to Start Chat (Costs 1 Tea Leaf)
  Future<void> _startChat(String peerUid, Map<String, dynamic> peerData) async {
    bool success = await UserService().deductTeaLeaf(myUid);
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.t('tea_low'))),
        );
      }
      return;
    }

    String peerNickname = peerData['nickname'] ?? 'Unknown';
    String peerAvatar = peerData['avatar_image'] ?? 'rat.png';

    // Create unique chat ID
    final chatId = myUid.hashCode <= peerUid.hashCode
        ? '$myUid-$peerUid'
        : '$peerUid-$myUid';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.t('search_start'))), // "Using 1 tea leaf..."
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatRoomId: chatId,
            peerUid: peerUid,
            peerNickname: peerNickname,
            peerAvatar: peerAvatar,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.t('matching_title'))),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _candidates.isEmpty
              ? Center(child: Text(AppLocale.t('no_more_friends')))
              : Column(
                  children: [
                    // Card Swiper Area
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
                        allowedSwipeDirection: const AllowedSwipeDirection.all(), // Allow Up/Down/Left/Right
                      ),
                    ),
                    
                    // Control Buttons Area
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Pass Button (Left)
                          _buildCircleButton(
                            icon: Icons.close,
                            color: Colors.red,
                            onPressed: () => controller.swipe(CardSwiperDirection.left),
                          ),
                          // Super Like / Chat Button (Up/Center)
                          _buildCircleButton(
                            icon: Icons.chat_bubble, // Chat icon for direct connection
                            color: const Color(0xFF24FCFF), // Signature color
                            size: 70, // Slightly larger
                            onPressed: () => controller.swipe(CardSwiperDirection.top),
                          ),
                          // Like Button (Right)
                          _buildCircleButton(
                            icon: Icons.favorite,
                            color: Colors.green,
                            onPressed: () => controller.swipe(CardSwiperDirection.right),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  // Helper widget for buttons
  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 60,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.5),
        onPressed: onPressed,
      ),
    );
  }

  // 🎨 카드 디자인 (상세 프로필 적용)
  Widget _buildCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // 데이터 가져오기 (없으면 기본값)
    final String name = data['nickname'] ?? '알 수 없음';
    final String avatarFile = data['avatar_image'] ?? 'rat.png';
    final String mbti = data['mbti'] ?? '???';
    final String gender = data['gender'] ?? 'unknown'; // 'male', 'female'
    final String bio = data['bio'] ?? AppLocale.t('map_snippet'); // 한줄 소개 (없으면 기본 문구)
    final List<dynamic> interests = data['interests'] ?? ['차 마시기 🍵', '대화하기 🗣️']; // 관심사 태그
    final double temp = (data['manner_temp'] ?? 36.5).toDouble(); // 👈 매너 온도 가져오기

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 배경 (MannerAvatar로 교체)
            Center(
              child: MannerAvatar(
                imagePath: avatarFile,
                temp: temp,
                size: 250, // 카드니까 크게!
              ),
            ),

            // 2. 그라데이션 (글씨 잘 보이게)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black54, // 중간부터 어두워짐
                    Colors.black87,
                  ],
                  stops: [0.0, 0.5, 0.7, 1.0],
                ),
              ),
            ),

            // 3. 정보 텍스트 (하단 배치)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // [이름 + 성별 + MBTI]
                  Row(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _getGenderIcon(gender), // 성별 아이콘
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF24FCFF), // 시그니처 민트색
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          mbti,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // [관심사 태그] (가로로 나열)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: interests.map((tag) => _buildChip(tag.toString())).toList(),
                  ),
                  const SizedBox(height: 10),

                  // [한줄 소개]
                  Text(
                    bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🚻 성별 아이콘 변환 함수
  Widget _getGenderIcon(String gender) {
    if (gender == 'male' || gender == '남성') {
      return const Icon(Icons.male, color: Colors.blueAccent, size: 28);
    } else if (gender == 'female' || gender == '여성') {
      return const Icon(Icons.female, color: Colors.pinkAccent, size: 28);
    }
    return const Icon(Icons.person, color: Colors.grey, size: 28); // 알 수 없음
  }

  // 🏷️ 관심사 칩(태그) 디자인
  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), // 반투명 흰색
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
