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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // 🌟 찻잎 3개를 소모하여 상대방 블러 해제 (나를 찜한 사람 확인!)
  Future<void> _unlockUser(String targetUid) async {
    final myRef = FirebaseFirestore.instance.collection('users').doc(_myUid);
    final doc = await myRef.get();
    int myTea = doc.data()?['tea_leaves'] ?? 0;

    if (myTea < 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("찻잎이 부족합니다 (3개 필요) 🍵", style: TextStyle(color: Colors.red))));
      return;
    }

    // 찻잎 3개 차감 & 해제한 유저 목록에 추가
    await myRef.update({
      'tea_leaves': FieldValue.increment(-3),
      'unlocked_likes': FieldValue.arrayUnion([targetUid])
    });

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("얼굴을 확인했습니다! 👀")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("인연 목록", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black, indicatorColor: const Color(0xFF24FCFF),
          tabs: const [Tab(text: "나를 찜한 인연 👀"), Tab(text: "내가 찜한 인연 ❤️")],
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

          return TabBarView(
            controller: _tabController,
            children: [
              _buildUserGrid(likedMe, isLikedMeTab: true, unlockedList: unlockedLikes, iLikedList: iLiked),
              _buildUserGrid(iLiked, isLikedMeTab: false, unlockedList: [], iLikedList: []),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserGrid(List<dynamic> uids, {required bool isLikedMeTab, required List<dynamic> unlockedList, required List<dynamic> iLikedList}) {
    if (uids.isEmpty) {
      return Center(child: Text(isLikedMeTab ? "아직 나를 찜한 사람이 없어요 🥲" : "아직 찜한 사람이 없어요. 지도에서 하트를 눌러보세요!", style: const TextStyle(color: Colors.grey)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 15, mainAxisSpacing: 15),
      itemCount: uids.length,
      itemBuilder: (context, index) {
        String targetUid = uids[index];
        // 블러 처리를 해야 하는가? (나를 찜한 탭이고, 내가 아직 언락 안 했고, 서로 찜한 사이도 아닐 때)
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
                        : Image.asset('assets/avatars/$profileAvatar', fit: BoxFit.cover),
                  ),
                  
                  // 🌟 블러 필터 적용 (BM 핵심)
                  if (shouldBlur)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                        child: Container(color: Colors.black.withOpacity(0.3)),
                      ),
                    ),

                  // 하단 이름 표시 영역
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)), color: Colors.black54),
                      child: Text(shouldBlur ? "누군가 나를 찜했어요!" : name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),

                  // 블러 해제 버튼
                  if (shouldBlur)
                    Positioned.fill(
                      child: Center(
                        child: ElevatedButton.icon(
                          onPressed: () => _unlockUser(targetUid),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF24FCFF), foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          icon: const Icon(Icons.lock_open, size: 16), label: const Text("3🍵 확인", style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
