import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/translations.dart'; 
import 'chat_screen.dart'; // 👈 실제 채팅방 화면 import

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String myUid = FirebaseAuth.instance.currentUser!.uid;

  // 🚪 [핵심] 채팅방 나가기(Soft Delete) 함수
  Future<void> _leaveChatRoom(String roomId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("대화방 나가기"),
        content: const Text("목록에서 삭제하시겠습니까?\n다시 대화하려면 찻잎을 소모해 새로 요청해야 합니다."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("취소")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("나가기"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      // 🚨 delete() 대신 left_by 배열에 내 UID를 추가합니다!
      await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).update({
        'left_by': FieldValue.arrayUnion([myUid]),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("채팅방에서 나갔습니다.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocale.t('chat_list_title') ?? "채팅 목록", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // 내가 포함된 모든 채팅방을 가져옵니다
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: myUid)
            .orderBy('updatedAt', descending: true) // 👈 기존 필드명 updatedAt 사용
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allRooms = snapshot.data!.docs;
          List<DocumentSnapshot> activeRooms = [];
          List<DocumentSnapshot> pendingRooms = [];

          for (var room in allRooms) {
            final data = room.data() as Map<String, dynamic>;
            List<dynamic> leftBy = data['left_by'] ?? [];

            // 🌟 [핵심 필터링] 내가 나간 방(left_by에 내가 포함됨)은 화면에 아예 보여주지 않습니다!
            if (leftBy.contains(myUid)) continue;

            if (data['status'] == 'active') {
              activeRooms.add(room);
            } else if (data['status'] == 'pending') {
              pendingRooms.add(room);
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // --- 대화 중인 방 ---
              const Text("대화 중인 방", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 10),
              if (activeRooms.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text("대화 중인 방이 없습니다.", style: TextStyle(color: Colors.grey))),
              ...activeRooms.map((room) => _buildChatTile(room)),
              
              const Divider(height: 40, thickness: 3, color: Colors.black12),

              // --- 대기 중인 요청 ---
              const Text("대기 중인 요청", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 10),
              if (pendingRooms.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Text("대기 중인 요청이 없습니다.", style: TextStyle(color: Colors.grey))),
              ...pendingRooms.map((room) => _buildChatTile(room, isPending: true)),
            ],
          );
        },
      ),
    );
  }

  // 채팅방 리스트 아이템 UI
  Widget _buildChatTile(DocumentSnapshot roomDoc, {bool isPending = false}) {
    final data = roomDoc.data() as Map<String, dynamic>;
    List<dynamic> participants = data['participants'];
    String peerUid = participants.firstWhere((id) => id != myUid, orElse: () => '');
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(peerUid).get(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();
        
        final peerData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
        final String nickname = peerData['nickname'] ?? '알 수 없음';
        final String avatar = peerData['avatar_image'] ?? 'rat.png';

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[200],
            // 🌟 8방향 스프라이트 시트에서 '정면'만 잘라서 보여주기 (기존 로직 유지)
            child: ClipOval(
              child: SizedBox(
                width: 60, height: 60,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topLeft,
                      widthFactor: 0.25,
                      heightFactor: 0.5,
                      child: Image.asset(
                        'assets/avatars/$avatar',
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(
            isPending ? "수락 대기 중..." : (data['lastMessage'] ?? "대화가 시작되었습니다."),
            style: TextStyle(color: isPending ? Colors.grey : Colors.black87),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.block, color: Colors.redAccent), // 🚫 버튼
            onPressed: () => _leaveChatRoom(roomDoc.id),
          ),
          onTap: () {
            if (isPending) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("상대방의 수락을 기다리고 있습니다.")));
            } else {
              // 실제 채팅방으로 이동
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    chatRoomId: roomDoc.id,
                    peerUid: peerUid,
                    peerNickname: nickname,
                    peerAvatar: avatar,
                  )
                )
              );
            }
          },
        );
      },
    );
  }
}
