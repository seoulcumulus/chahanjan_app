import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MatchingScreen extends StatefulWidget {
  const MatchingScreen({super.key});

  @override
  State<MatchingScreen> createState() => _MatchingScreenState();
}

class _MatchingScreenState extends State<MatchingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _myUid = FirebaseAuth.instance.currentUser!.uid;

  final Color _holyGold = const Color(0xFFD4AF37);
  final Color _signatureColor = const Color(0xFF24FCFF);
  final Color _holyPurple = const Color(0xFF2E003E);

  @override
  void initState() {
    super.initState();
    // 🌟 탭이 3개로 늘어났습니다! (티마카세 / 나를 찜한 / 내가 찜한)
    _tabController = TabController(length: 3, vsync: this);
  }

  // 🌟 [기능 1] 나를 찜한 사람 블러 해제 (3 찻잎)
  Future<void> _unlockUser(String targetUid) async {
    final myRef = FirebaseFirestore.instance.collection('users').doc(_myUid);
    final doc = await myRef.get();
    int myTea = doc.data()?['tea_leaves'] ?? 0;

    if (myTea < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("찻잎이 부족합니다 (3개 필요) 🍵", style: TextStyle(color: Colors.red))));
      return;
    }

    await myRef.update({
      'tea_leaves': FieldValue.increment(-3),
      'unlocked_likes': FieldValue.arrayUnion([targetUid])
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("얼굴을 확인했습니다! 👀")));
  }

  // 🌟 [기능 2] 오늘의 티마카세 스페셜 카드 블러 해제 (10 찻잎)
  Future<void> _unlockDailyCard(String targetUid) async {
    final myRef = FirebaseFirestore.instance.collection('users').doc(_myUid);
    final doc = await myRef.get();
    int myTea = doc.data()?['tea_leaves'] ?? 0;

    if (myTea < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("찻잎이 부족합니다 (10개 필요) 🍵", style: TextStyle(color: Colors.red))));
      return;
    }

    await myRef.update({
      'tea_leaves': FieldValue.increment(-10),
      'unlocked_daily_cards': FieldValue.arrayUnion([targetUid])
    });
    
    // 블러 해제 팝업 연출
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("🎉 스페셜 인연 공개!"),
        content: const Text("운명의 상대를 확인해보세요.\n지금 바로 인사를 건네보는 건 어떨까요?"),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("확인"))],
      ),
    );
  }

  // 🌟 [핵심] 아바타 찌그러짐 방지용 완벽 크롭 헬퍼 (profile_screen과 동일)
  Widget _buildStaticSprite(String fileName) {
    bool is25D = !fileName.startsWith('snake') && !fileName.startsWith('avatar');
    if (!is25D) {
      return Image.asset('assets/avatars/$fileName', fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Icon(Icons.person, color: Colors.grey));
    }
    return FittedBox(
      fit: BoxFit.cover, alignment: Alignment.topCenter,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topLeft, widthFactor: 0.25, heightFactor: 0.5,
          child: Image.asset('assets/avatars/$fileName', errorBuilder: (_,__,___)=>const Icon(Icons.person, color: Colors.grey)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("인연 찾기", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black, indicatorColor: _signatureColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "오늘의 다과상 🫖"), 
            Tab(text: "나를 찜한 👀"), 
            Tab(text: "내가 찜한 ❤️")
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_myUid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          List<dynamic> iLiked = data['favorite_users'] ?? [];
          List<dynamic> likedMe = data['liked_me'] ?? [];
          List<dynamic> unlockedLikes = data['unlocked_likes'] ?? [];
          List<dynamic> unlockedDaily = data['unlocked_daily_cards'] ?? [];

          return TabBarView(
            controller: _tabController,
            children: [
              // 1번 탭: 오늘의 티마카세 (신규)
              _buildDailyTeaMakase(unlockedDaily),
              // 2번 탭: 나를 찜한 인연
              _buildUserGrid(likedMe, isLikedMeTab: true, unlockedList: unlockedLikes, iLikedList: iLiked),
              // 3번 탭: 내가 찜한 인연
              _buildUserGrid(iLiked, isLikedMeTab: false, unlockedList: [], iLikedList: []),
            ],
          );
        },
      ),
    );
  }

  // 🫖 [신규 UI] 오늘의 티마카세 화면
  Widget _buildDailyTeaMakase(List<dynamic> unlockedDaily) {
    return FutureBuilder<QuerySnapshot>(
      // 시연을 위해 나를 제외한 랜덤 유저 3명을 불러옵니다. (실제로는 Cloud Function으로 자정마다 세팅하는 것이 좋습니다)
      future: FirebaseFirestore.instance.collection('users').where('uid', isNotEqualTo: _myUid).limit(3).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;

        if (users.isEmpty) {
          return const Center(child: Text("아직 가입한 다른 유저가 없습니다 🥲", style: TextStyle(color: Colors.grey)));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("오늘의 티마카세 🫖", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _holyPurple)),
              const SizedBox(height: 5),
              const Text("차한잔 알고리즘이 분석한 오늘의 인연입니다.\n매일 밤 12시에 새로운 카드가 도착합니다.", style: TextStyle(color: Colors.grey, height: 1.4)),
              const SizedBox(height: 25),
              
              // 3명의 유저를 가로 스크롤로 보여줍니다.
              SizedBox(
                height: 420,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    String targetUid = userData['uid'];
                    
                    // 핵심 기획: 0번 카드는 무료(오픈), 1번과 2번 카드는 프리미엄(블러 처리)
                    bool isPremiumCard = index > 0; 
                    bool isUnlocked = unlockedDaily.contains(targetUid);
                    bool shouldBlur = isPremiumCard && !isUnlocked;

                    return _buildTeaMakaseCard(userData, shouldBlur, isPremiumCard);
                  },
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  // 🎴 개별 티마카세 카드 디자인
  Widget _buildTeaMakaseCard(Map<String, dynamic> userData, bool shouldBlur, bool isPremiumCard) {
    String name = userData['nickname'] ?? '비밀 유저';
    String profileType = userData['profile_type'] ?? 'avatar';
    String profileAvatar = userData['profile_avatar'] ?? 'rat.png';
    String? profileImageUrl = userData['profile_image_url'];
    String mbti = userData['mbti'] ?? '비밀';
    String targetUid = userData['uid'];

    // 매칭률 가짜 데이터 (인덱스에 따라 80%, 95%, 98% 등으로 표시)
    String matchRate = isPremiumCard ? "매칭률 95% 이상 🔥" : "매칭률 80% 🍵";

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(25),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, 5))],
        border: isPremiumCard ? Border.all(color: _holyGold, width: 2) : null,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 사진 또는 아바타 배경
          ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: profileType == 'photo' && profileImageUrl != null
                ? Image.network(profileImageUrl, fit: BoxFit.cover)
                : Container(color: _holyPurple.withOpacity(0.1), child: _buildStaticSprite(profileAvatar)),
          ),

          // 2. 🌟 프리미엄 카드 블러 처리
          if (shouldBlur)
            ClipRRect(
              borderRadius: BorderRadius.circular(23),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),

          // 3. 하단 그라데이션 및 정보 텍스트
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(23),
              gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black87], stops: [0.5, 1.0]),
            ),
          ),

          // 4. 텍스트 정보
          Positioned(
            bottom: 25, left: 20, right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: isPremiumCard ? _holyGold : _signatureColor, borderRadius: BorderRadius.circular(10)),
                  child: Text(matchRate, style: TextStyle(color: isPremiumCard ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 10),
                Text(shouldBlur ? "스페셜 블렌딩 티 🫖" : name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(shouldBlur ? "나와 성향이 완벽히 일치하는 인연" : "#$mbti #매너온도좋음", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 15),
                
                // 5. 액션 버튼
                SizedBox(
                  width: double.infinity, height: 45,
                  child: ElevatedButton(
                    onPressed: shouldBlur ? () => _unlockDailyCard(targetUid) : () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("프로필 상세 보기 기능은 개발 중입니다.")));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: shouldBlur ? _holyPurple : Colors.white,
                      foregroundColor: shouldBlur ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Text(shouldBlur ? "10🍵로 얼굴 확인하기" : "프로필 보기", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          
          if (isPremiumCard && shouldBlur)
             const Positioned(top: 20, right: 20, child: Icon(Icons.lock, color: Colors.white54, size: 30)),
        ],
      ),
    );
  }

  // 기존 찜한 목록 그리드 뷰 (유지)
  Widget _buildUserGrid(List<dynamic> uids, {required bool isLikedMeTab, required List<dynamic> unlockedList, required List<dynamic> iLikedList}) {
    if (uids.isEmpty) {
      return Center(child: Text(isLikedMeTab ? "아직 나를 찜한 사람이 없어요 🥲" : "아직 찜한 사람이 없어요.\n지도에서 하트를 눌러보세요!", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
      itemCount: uids.length,
      itemBuilder: (context, index) {
        String targetUid = uids[index];
        bool shouldBlur = isLikedMeTab && !unlockedList.contains(targetUid) && !iLikedList.contains(targetUid);

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(targetUid).get(),
          builder: (context, userSnap) {
            if (!userSnap.hasData) return const Card(child: Center(child: CircularProgressIndicator()));
            final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
            
            String name = userData['nickname'] ?? '비밀 유저';
            String profileType = userData['profile_type'] ?? 'avatar';
            String profileAvatar = userData['profile_avatar'] ?? 'rat.png';
            String? profileImageUrl = userData['profile_image_url'];

            return Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.white, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)]),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: profileType == 'photo' && profileImageUrl != null
                        ? Image.network(profileImageUrl, fit: BoxFit.cover)
                        : _buildStaticSprite(profileAvatar),
                  ),
                  if (shouldBlur)
                    ClipRRect(borderRadius: BorderRadius.circular(15), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), child: Container(color: Colors.black.withOpacity(0.3)))),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(padding: const EdgeInsets.all(10), decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)), color: Colors.black54), child: Text(shouldBlur ? "누군가 나를 찜했어요!" : name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  ),
                  if (shouldBlur)
                    Positioned.fill(child: Center(child: ElevatedButton.icon(onPressed: () => _unlockUser(targetUid), style: ElevatedButton.styleFrom(backgroundColor: _signatureColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), icon: const Icon(Icons.lock_open, size: 16), label: const Text("3🍵 확인", style: TextStyle(fontWeight: FontWeight.bold))))),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
