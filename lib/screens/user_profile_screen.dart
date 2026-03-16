import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileScreen extends StatefulWidget {
  final String targetUid; // 누구의 프로필을 볼 것인가?

  const UserProfileScreen({super.key, required this.targetUid});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final String _myUid = FirebaseAuth.instance.currentUser!.uid;
  final Color _holyGold = const Color(0xFFD4AF37);
  final Color _holyPurple = const Color(0xFF2E003E);
  final Color _signatureColor = const Color(0xFF24FCFF);

  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  // 내가 찜했는지 확인
  Future<void> _checkIfLiked() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(_myUid).get();
    if (doc.exists) {
      List<dynamic> myFavorites = doc.data()?['favorite_users'] ?? [];
      if (myFavorites.contains(widget.targetUid)) {
        setState(() => _isLiked = true);
      }
    }
  }

  // ❤️ 관심 표현(찜하기) 로직
  Future<void> _toggleLike() async {
    final myRef = FirebaseFirestore.instance.collection('users').doc(_myUid);
    final peerRef = FirebaseFirestore.instance.collection('users').doc(widget.targetUid);

    setState(() => _isLiked = !_isLiked);

    if (_isLiked) {
      await myRef.update({'favorite_users': FieldValue.arrayUnion([widget.targetUid])});
      await peerRef.update({'liked_me': FieldValue.arrayUnion([_myUid])});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("관심 목록에 추가되었습니다. ❤️")));
    } else {
      await myRef.update({'favorite_users': FieldValue.arrayRemove([widget.targetUid])});
      await peerRef.update({'liked_me': FieldValue.arrayRemove([_myUid])});
    }
  }

  // 💬 대화 요청 로직 (1 찻잎 소모)
  Future<void> _requestChat() async {
    final roomRef = FirebaseFirestore.instance.collection('chat_rooms');
    final myRef = FirebaseFirestore.instance.collection('users').doc(_myUid);

    final String roomId = _myUid.hashCode <= widget.targetUid.hashCode 
        ? '${_myUid}_${widget.targetUid}' 
        : '${widget.targetUid}_$_myUid';

    try {
      final myDoc = await myRef.get();
      int myTea = myDoc.data()?['tea_leaves'] ?? 0;

      if (myTea < 1) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("찻잎이 부족합니다 🍵", style: TextStyle(color: Colors.red))));
        return;
      }

      // [수정된 부분] 찻잎 차감 및 방 생성/부활 (requested_by 추가!)
      await myRef.update({'tea_leaves': FieldValue.increment(-1)});
      
      final roomDoc = await roomRef.doc(roomId).get();
      if (!roomDoc.exists) {
        await roomRef.doc(roomId).set({
          'roomId': roomId, 'participants': [_myUid, widget.targetUid],
          'status': 'pending', 'left_by': [],
          'requested_by': _myUid, // 🌟 [핵심] 내가 요청했다고 꼬리표 달기!
          'lastMessage': '대화 요청이 도착했습니다.', 'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await roomRef.doc(roomId).update({
          'status': 'pending', 'left_by': FieldValue.arrayRemove([_myUid]),
          'requested_by': _myUid, // 🌟 [핵심] 다시 요청할 때도 꼬리표 달기!
          'lastMessage': '대화를 다시 요청했습니다.', 'lastMessageTime': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("대화 요청 완료! (1🍵 소모)")));
        Navigator.pop(context); // 요청 후 이전 화면으로 돌아가기
      }
    } catch (e) {
      print("대화 요청 에러: $e");
    }
  }

  // 🌟 아바타 찌그러짐 방지 헬퍼
  Widget _buildStaticSprite(String fileName) {
    bool is25D = !fileName.startsWith('snake') && !fileName.startsWith('avatar');
    if (!is25D) return Image.asset('assets/avatars/$fileName', fit: BoxFit.cover);
    return FittedBox(
      fit: BoxFit.cover, alignment: Alignment.topCenter,
      child: ClipRect(
        child: Align(alignment: Alignment.topLeft, widthFactor: 0.25, heightFactor: 0.5, child: Image.asset('assets/avatars/$fileName')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(widget.targetUid).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text("존재하지 않는 유저입니다."));

          final data = snapshot.data!.data() as Map<String, dynamic>;
          String name = data['nickname'] ?? '비밀 유저';
          String profileType = data['profile_type'] ?? 'avatar';
          String profileAvatar = data['profile_avatar'] ?? 'rat.png';
          String? profileImageUrl = data['profile_image_url'];
          String bio = data['bio'] ?? '안녕하세요!';
          String mbti = data['mbti'] ?? '비밀';
          double temp = (data['manner_temp'] ?? 36.5).toDouble();
          List<dynamic> interests = data['interests'] ?? [];

          return CustomScrollView(
            slivers: [
              // 1. 상단 대형 프로필 이미지 (스크롤 시 자연스럽게 줄어듦)
              SliverAppBar(
                expandedHeight: 400.0,
                pinned: true,
                backgroundColor: _holyPurple,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black54, blurRadius: 10)])),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      profileType == 'photo' && profileImageUrl != null
                          ? Image.network(profileImageUrl, fit: BoxFit.cover)
                          : Container(color: _holyPurple.withOpacity(0.1), child: _buildStaticSprite(profileAvatar)),
                      // 어두운 그라데이션 (글씨를 잘 보이게)
                      const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.center, colors: [Colors.black87, Colors.transparent]))),
                    ],
                  ),
                ),
              ),
              
              // 2. 하단 상세 정보 영역
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 매너 온도
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("매너 온도", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          Text("$temp℃", style: TextStyle(color: temp >= 70 ? _signatureColor : _holyGold, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(value: temp / 100.0, backgroundColor: Colors.grey[200], valueColor: AlwaysStoppedAnimation<Color>(temp >= 70 ? _signatureColor : _holyGold), minHeight: 10),
                      ),
                      const SizedBox(height: 30),

                      // 자기소개
                      const Text("한 줄 소개", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(bio, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                      const SizedBox(height: 30),

                      // 성향 및 관심사
                      const Text("성향 및 관심사", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Wrap(
                        spacing: 10, runSpacing: 10,
                        children: [
                          Chip(label: Text(mbti, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: _signatureColor.withOpacity(0.3), side: BorderSide.none),
                          ...interests.map((tag) => Chip(label: Text(tag.toString()), backgroundColor: Colors.grey[100], side: BorderSide.none)),
                        ],
                      ),
                      const SizedBox(height: 100), // 하단 버튼을 위한 여백
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      
      // 3. 하단 고정 액션 버튼
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              // 찜하기 버튼
              Container(
                decoration: BoxDecoration(color: Colors.pink[50], borderRadius: BorderRadius.circular(15)),
                child: IconButton(
                  icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.pinkAccent),
                  iconSize: 30,
                  onPressed: _toggleLike,
                ),
              ),
              const SizedBox(width: 15),
              // 대화 요청 버튼
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _requestChat,
                    style: ElevatedButton.styleFrom(backgroundColor: _holyGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text("대화 요청하기 (1🍵)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
