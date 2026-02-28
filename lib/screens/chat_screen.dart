import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:translator/translator.dart'; // 🌍 번역 패키지 (Adapted import)
import 'call_screen.dart'; // 영상통화 화면
import '../services/user_service.dart'; // 👈 UserService 추가

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String peerUid; // peerUid 필드 추가
  final String peerNickname;
  final String peerAvatar;

  const ChatScreen({
    super.key, 
    required this.chatRoomId, 
    required this.peerUid, // peerUid 추가
    required this.peerNickname,
    required this.peerAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final Color _signatureColor = const Color(0xFF24FCFF);
  final translator = GoogleTranslator(); // 번역기 인스턴스

  void _sendMessage(String text, {String type = 'text'}) async {
    if (text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      if (widget.peerUid.isEmpty) {
        throw Exception("상대방 ID가 유효하지 않습니다.");
      }

      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(widget.chatRoomId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'type': type, // 'text' or 'image'
      });

      final roomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.chatRoomId);

      try {
        // 1. 기존 방이 있으면 업데이트만 (status 건드리지 않음)
        await roomRef.update({
          'lastMessage': type == 'image' ? '사진을 보냈습니다.' : text,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // 2. 방이 없으면 새로 생성 (이때만 status='pending' 설정)
        await roomRef.set({
          'participants': [user.uid, widget.peerUid],
          'initiatorId': user.uid, // 신청자 ID
          'status': 'pending',     // 대기 상태
          'lastMessage': type == 'image' ? '사진을 보냈습니다.' : text,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'left_by': [], // 👈 [추가] 초기화
          'roomId': widget.chatRoomId, // 👈 [추가] ID 명시
        });
      }

      _messageController.clear();
    } catch (e) {
      print("메시지 전송 실패: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("전송 실패: $e")),
        );
      }
    }
  }

  // 📸 이미지 전송
  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      // 웹에서는 path로 File을 만들 수 없으므로 bytes를 사용하거나 kIsWeb 체크 필요
      // 하지만 사용자 코드가 File(image.path)를 사용하므로 일단 그대로 둡니다.
      // 웹 실행 시 에러가 날 수 있음. -> 수정 필요하지만 사용자 요청 코드 우선 적용하되, 웹 호환성 고려하여 수정 제안 가능.
      // 일단 사용자 코드 그대로 적용하되 import만 수정.
      
      File file = File(image.path);
      String fileName = 'chat/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = FirebaseStorage.instance.ref().child(fileName);
      await ref.putFile(file);
      String downloadUrl = await ref.getDownloadURL();
      _sendMessage(downloadUrl, type: 'image');
    }
  }



  // 🌡️ [추가] 매너 점수 업데이트 함수 (UserService 위임)
  Future<void> _updateMannerScore(String targetUid, double delta) async {
    await UserService().updateMannerScore(targetUid, delta);
  }

  // 🍵 [추가] 리뷰 다이얼로그
  Future<void> _showReviewDialog() async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("티타임은 어떠셨나요? 🍵"),
          content: const Text("상대방의 매너를 평가해주세요.\n평가는 익명으로 반영됩니다."),
          actions: [
            // 👎 별로예요
            TextButton(
              onPressed: () {
                _updateMannerScore(widget.peerUid, -0.3); // 점수 깎기
                Navigator.pop(context); // 팝업 닫기
                Navigator.pop(context); // 채팅방 나가기
              },
              child: const Text("별로예요", style: TextStyle(color: Colors.grey)),
            ),
            // 👍 최고예요
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF24FCFF)),
              onPressed: () {
                _updateMannerScore(widget.peerUid, 0.5); // 점수 올리기
                Navigator.pop(context);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("따뜻한 평가를 남겼습니다! 🌡️")),
                );
              },
              child: const Text("최고였어요!", style: TextStyle(color: Colors.black)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return PopScope(
      canPop: false, // 👈 기본 뒤로가기 비활성화
      onPopInvoked: (didPop) async {
        if (!didPop) {
          await _showReviewDialog(); // 👈 리뷰 다이얼로그 표시
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: AssetImage('assets/avatars/${widget.peerAvatar}'),
              backgroundColor: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(widget.peerNickname, style: const TextStyle(fontSize: 16)),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          // 📹 영상통화 버튼
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CallScreen(
                    callID: widget.chatRoomId,
                    userID: myUid!,
                    userName: "나", 
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chat_rooms')
                  .doc(widget.chatRoomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == myUid;
                    
                    return _buildMessageItem(msg, isMe);
                  },
                );
              },
            ),
          ),
          // 입력창 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
                  onPressed: _sendImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "메시지 입력...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: _signatureColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(_messageController.text),
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

  // 💬 메시지 말풍선 빌더 (번역 기능 포함)
  Widget _buildMessageItem(DocumentSnapshot msg, bool isMe) {
    final String text = msg['text'];
    final String type = msg['type'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? _signatureColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: isMe ? const Radius.circular(15) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(15),
          ),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(1, 1))],
        ),
        constraints: const BoxConstraints(maxWidth: 250),
        child: type == 'image'
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(text, fit: BoxFit.cover),
              )
            : isMe
                ? Text(text, style: const TextStyle(color: Colors.black87)) // 내가 보낸 건 번역 안 함
                : FutureBuilder(
                    // 🌍 상대방 메시지만 한국어로 번역!
                    future: translator.translate(text, to: 'ko'), 
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(text, style: const TextStyle(color: Colors.black87, fontSize: 15)), // 원본
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Divider(height: 1, color: Colors.black26),
                            ),
                            Text(
                              "A.I 번역: ${snapshot.data!.text}", // 번역본
                              style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        );
                      }
                      return Text(text, style: const TextStyle(color: Colors.black87)); // 로딩 중엔 원본만
                    },
                  ),
      ),
    );
  }
}
