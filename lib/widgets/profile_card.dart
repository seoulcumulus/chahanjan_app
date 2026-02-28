import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/translations.dart';

class ProfileCard extends StatefulWidget {
  final String uid; // 🌟 상대방의 UID (DB 저장을 위해 필수!)
  final Map<String, dynamic> data;

  const ProfileCard({super.key, required this.uid, required this.data});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  bool _isLiked = false;
  final String _myUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _checkIfLiked();
  }

  // 내가 이미 찜한 상대인지 파이어베이스에서 확인
  Future<void> _checkIfLiked() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(_myUid).get();
    if (doc.exists) {
      List<dynamic> myFavorites = doc.data()?['favorite_users'] ?? [];
      if (myFavorites.contains(widget.uid)) {
        setState(() => _isLiked = true);
      }
    }
  }

  // 💖 하트 버튼 눌렀을 때의 로직
  Future<void> _toggleLike() async {
    final myRef = FirebaseFirestore.instance.collection('users').doc(_myUid);
    final peerRef = FirebaseFirestore.instance.collection('users').doc(widget.uid);

    setState(() => _isLiked = !_isLiked); // UI 즉시 변경

    if (_isLiked) {
      // 1. 내 목록에 추가, 상대방의 '나를 찜한 목록'에 추가
      await myRef.update({'favorite_users': FieldValue.arrayUnion([widget.uid])});
      await peerRef.update({'liked_me': FieldValue.arrayUnion([_myUid])});

      // 2. 🌟 쌍방 찜(매칭) 확인 로직
      final peerDoc = await peerRef.get();
      List<dynamic> peerFavorites = peerDoc.data()?['favorite_users'] ?? [];
      
      if (peerFavorites.contains(_myUid)) {
        // 서로 찜했다면 운명적인 매칭! (무료 채팅방 자동 생성)
        final String roomId = _myUid.hashCode <= widget.uid.hashCode ? '${_myUid}_${widget.uid}' : '${widget.uid}_$_myUid';
        await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set({
          'roomId': roomId,
          'participants': [_myUid, widget.uid],
          'status': 'active', // 바로 대화 가능
          'left_by': [],
          'lastMessage': '❤️ 운명적인 매칭이 성사되었습니다!',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎉 통했습니다! 무료 대화방이 열렸습니다!"), backgroundColor: Colors.pinkAccent));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("관심 목록에 추가되었습니다. ❤️")));
      }
    } else {
      // 찜 취소
      await myRef.update({'favorite_users': FieldValue.arrayRemove([widget.uid])});
      await peerRef.update({'liked_me': FieldValue.arrayRemove([_myUid])});
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.data['nickname'] ?? AppLocale.t('unknown_user');
    final String profileType = widget.data['profile_type'] ?? 'avatar'; 
    final String profileAvatar = widget.data['profile_avatar'] ?? widget.data['avatar_image'] ?? 'rat.png'; 
    final String? profileImageUrl = widget.data['profile_image_url']; 
    final String mbti = widget.data['mbti'] ?? '???';
    final String gender = widget.data['gender'] ?? 'unknown';
    final String bio = widget.data['bio'] ?? AppLocale.t('map_snippet');
    final List<dynamic> interests = widget.data['interests'] ?? ['차 마시기 🍵'];
    
    final double temp = (widget.data['manner_temp'] ?? 36.5).toDouble();
    final bool isHighManner = temp >= 70.0;
    final Color barColor = isHighManner ? const Color(0xFF24FCFF) : const Color(0xFFFFD700); 

    return Container(
      width: 320, height: 480, 
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: Colors.white, boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SizedBox.expand(
              child: profileType == 'photo' && profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? Image.network(profileImageUrl, fit: BoxFit.cover, alignment: Alignment.topCenter)
                  : _buildAvatarBackground(profileAvatar),
            ),
            Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black54, Colors.transparent, Colors.black87], stops: [0.0, 0.4, 0.8]))),

            // 🌟 하트(찜하기) 버튼 우측 상단 배치
            Positioned(
              top: 20, right: 20,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _toggleLike,
                child: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: Colors.pinkAccent, size: 28),
              ),
            ),

            // 온도 막대 (왼쪽 위)
            Positioned(
              top: 25, left: 20,
              child: Row(
                children: [
                  Icon(Icons.thermostat, color: barColor, size: 20),
                  const SizedBox(width: 5),
                  Text("$temp℃", style: TextStyle(color: barColor, fontSize: 18, fontWeight: FontWeight.bold, shadows: const [Shadow(color: Colors.black, blurRadius: 2)])),
                ],
              ),
            ),

            Positioned(
              bottom: 20, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)), const SizedBox(width: 8), _getGenderIcon(gender)]),
                  const SizedBox(height: 5),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF24FCFF), borderRadius: BorderRadius.circular(10)), child: Text(mbti, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 8),
                  Wrap(spacing: 6, runSpacing: 6, children: interests.map((tag) => _buildChip(tag.toString())).toList()),
                  const SizedBox(height: 10),
                  Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarBackground(String fileName) {
    bool is25D = !fileName.startsWith('snake') && !fileName.startsWith('avatar');
    if (!is25D) {
      return Image.asset('assets/avatars/$fileName', fit: BoxFit.cover, errorBuilder: (_,__,___)=>const Center(child: Icon(Icons.person, size: 100, color: Colors.white24)));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return ClipRect(
          child: OverflowBox(
            minWidth: w * 4, maxWidth: w * 4,
            minHeight: h * 2, maxHeight: h * 2,
            alignment: Alignment.topLeft, 
            child: Image.asset('assets/avatars/$fileName', fit: BoxFit.fill),
          ),
        );
      }
    );
  }

  Widget _getGenderIcon(String gender) {
    if (gender == 'male' || gender == '남성') return const Icon(Icons.male, color: Colors.blue, size: 24);
    if (gender == 'female' || gender == '여성') return const Icon(Icons.female, color: Colors.pink, size: 24);
    return const SizedBox.shrink();
  }

  Widget _buildChip(String label) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white30)), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)));
  }
}
