import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart'; 

class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key});

  // ✅ 요청 수락 함수
  Future<void> _acceptRequest(BuildContext context, String requestId, String senderId, String senderNickname) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;

    try {
      // 1. 이미 방이 있는지 확인 (중복 방지)
      final existingChat = await FirebaseFirestore.instance
          .collection('chats')
          .where('users', arrayContains: myUid)
          .get();

      String? existingRoomId;
      for (var doc in existingChat.docs) {
        List<dynamic> users = doc['users'];
        if (users.contains(senderId)) {
          existingRoomId = doc.id;
          break;
        }
      }

      DocumentReference chatRoomRef;
      if (existingRoomId != null) {
        chatRoomRef = FirebaseFirestore.instance.collection('chats').doc(existingRoomId);
      } else {
        // 새 방 만들기
        chatRoomRef = await FirebaseFirestore.instance.collection('chats').add({
          'users': [myUid, senderId],
          'created_at': FieldValue.serverTimestamp(),
          'last_message': '대화가 시작되었습니다.',
          'last_time': FieldValue.serverTimestamp(),
        });
      }

      // 2. 요청 상태 'accepted'로 변경
      await FirebaseFirestore.instance.collection('chat_requests').doc(requestId).update({
        'status': 'accepted',
        'chatRoomId': chatRoomRef.id,
      });

      // 3. 채팅방 이동
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(chatRoomId: chatRoomRef.id, peerNickname: senderNickname, peerAvatar: "rat.png"),
          ),
        );
      }
    } catch (e) {
      print("수락 실패: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('에러: $e')));
    }
  }

  // ❌ 요청 거절 함수
  Future<void> _rejectRequest(String requestId) async {
    await FirebaseFirestore.instance.collection('chat_requests').doc(requestId).update({
      'status': 'rejected',
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('받은 요청함 📬')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chat_requests')
            .where('toId', isEqualTo: myUid)
            .where('status', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          // 🚨 에러 발생 시 화면에 표시 (이걸 봐야 원인을 알 수 있음)
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("데이터를 불러오지 못했습니다.\n\n[개발자 팁]\n콘솔창에 뜨는 '링크'를 클릭해서\n색인(Index)을 생성해주세요!\n\n에러: ${snapshot.error}"),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("도착한 대화 요청이 없습니다. 🍃"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.amber, child: Text("?")),
                  title: Text("${data['fromNickname']} 님의 대화 신청"),
                  subtitle: const Text("대화를 시작하시겠습니까?"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _rejectRequest(doc.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptRequest(context, doc.id, data['fromId'], data['fromNickname']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
