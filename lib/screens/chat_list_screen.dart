import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_screen.dart'; // 채팅 화면 import 필수

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  // 🕒 시간 포맷 (예: 오후 2:30 or 어제)
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();
    
    // 오늘이면 시간만, 아니면 날짜 표시
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('a h:mm', 'ko_KR').format(date);
    } else {
      return DateFormat('MM월 dd일', 'ko_KR').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅 목록 💬'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🔥 중요: 'users' 배열에 내 UID가 포함된 채팅방만 찾기
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: myUid)
            .orderBy('last_time', descending: true) // 최신 대화순 정렬
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chatRooms = snapshot.data!.docs;

          if (chatRooms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 20),
                  Text("참여 중인 대화방이 없습니다.\n지도에서 친구를 찾아보세요! 🗺️", 
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final doc = chatRooms[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // 🔍 상대방 ID 찾기 (참여자 목록 중 '나'가 아닌 사람)
              final List<dynamic> users = data['users'];
              final String peerUid = users.firstWhere((uid) => uid != myUid, orElse: () => "");
              
              // 🔍 상대방 닉네임 가져오기 (FutureBuilder 사용)
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(peerUid).get(),
                builder: (context, userSnapshot) {
                  // 로딩 중이거나 데이터가 없으면 기본값 표시
                  String peerNickname = '알 수 없음';
                  String peerAvatar = 'rat.png';
                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    peerNickname = userData['nickname'] ?? '알 수 없음';
                    peerAvatar = userData['avatar_image'] ?? 'rat.png';
                  }

                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.amberAccent,
                      child: Text('🐼', style: TextStyle(fontSize: 24)), // 나중에 상대 아바타 이미지로 교체
                    ),
                    title: Text(
                      peerNickname,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      data['last_message'] ?? '대화 내용 없음', // 마지막 메시지 미리보기
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      _formatTimestamp(data['last_time']), // 마지막 시간
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    onTap: () {
                      // 채팅방 입장!
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatRoomId: doc.id, 
                            peerNickname: peerNickname,
                            peerAvatar: peerAvatar,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
