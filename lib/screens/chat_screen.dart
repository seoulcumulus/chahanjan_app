import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:translator/translator.dart'; // 🌍 번역 패키지 (Adapted import)
import 'call_screen.dart'; // 영상통화 화면
import '../services/user_service.dart'; // 👈 UserService 추가
import '../widgets/promise_dialog.dart'; 
import 'package:google_generative_ai/google_generative_ai.dart'; // 🌟 Gemini 추가!

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

  // 🌟 (여기에 발급받은 API 키를 넣어주세요!)
  static const String _geminiApiKey = 'AIzaSyBA48Azmje4yCJp7_Y_aLNI4Q0GSTecmPg';

  // 🌟 AI 티 소믈리에 호출 함수 (2 찻잎 소모)
  Future<void> _callAiSommelier(String peerUid) async {
    final String myUid = FirebaseAuth.instance.currentUser!.uid;
    final myRef = FirebaseFirestore.instance.collection('users').doc(myUid);
    final peerRef = FirebaseFirestore.instance.collection('users').doc(peerUid);

    // 1. 찻잎 검사
    final myDoc = await myRef.get();
    int myTea = myDoc.data()?['tea_leaves'] ?? 0;

    if (myTea < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("찻잎이 2개 필요합니다 🍵", style: TextStyle(color: Colors.red))));
      return;
    }

    // 2. 찻잎 차감
    await myRef.update({'tea_leaves': FieldValue.increment(-2)});

    // 3. 팝업창 띄우기 (로딩 중)
    if (!mounted) return;
    _showAiBottomSheet(context, peerRef);
  }

  // 🌟 AI 결과 화면 (바텀 시트)
  void _showAiBottomSheet(BuildContext context, DocumentReference peerRef) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: 450,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: FutureBuilder<DocumentSnapshot>(
            future: peerRef.get(),
            builder: (context, snapshot) {
              // 로딩 중 UI (소믈리에가 차를 우리고 있습니다)
              if (!snapshot.hasData) {
                return const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("🫖", style: TextStyle(fontSize: 50)),
                    SizedBox(height: 20),
                    Text("수석 티 소믈리에가\n상대방의 성향을 분석 중입니다...", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 20),
                    CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  ],
                );
              }

              // 상대방 데이터 추출
              final peerData = snapshot.data!.data() as Map<String, dynamic>;
              
              // 실제 AI가 추천해주는 것처럼 FutureBuilder로 감싸서 멘트 생성 (API 연동)
              return FutureBuilder<List<String>>(
                future: _generateAiMessages(peerData),
                builder: (context, aiSnapshot) {
                  if (!aiSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF24FCFF)));
                  }

                  final suggestions = aiSnapshot.data!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 8),
                          const Text("티 소믈리에ของ 추천 멘트", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E003E))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text("마음에 드는 문장을 눌러 바로 전송창에 붙여넣으세요!", style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 20),
                      
                      // 추천 문장 3개 리스트 출력
                      Expanded(
                        child: ListView.builder(
                          itemCount: suggestions.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                // 🌟 텍스트 입력창(_messageController)에 텍스트를 쏙! 넣어줍니다.
                                String pureText = suggestions[index].split(']').last.trim(); 
                                _messageController.text = pureText; 
                                Navigator.pop(ctx); // 창 닫기
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF24FCFF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: const Color(0xFF24FCFF).withOpacity(0.5)),
                                ),
                                child: Text(suggestions[index], style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87)),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // 🧠 [진짜 AI 연동] Gemini API를 통해 상대방 정보 기반 멘트 생성
  Future<List<String>> _generateAiMessages(Map<String, dynamic> peerData) async {
    // 1. API 키 확인 (사용자가 입력하지 않았을 경우를 위한 방어 코드)
    if (_geminiApiKey == 'AIzaSyBA48Azmje4yCJp7_Y_aLNI4Q0GSTecmPg') {
      return [
        "[🍵 정중한 녹차맛]\n안녕하세요! 프로필을 보니 관심사가 비슷하시네요. 혹시 즐겨하시는 편이신가요?",
        "[🥤 유쾌한 탄산맛]\n앗, 발견! ✨ MBTI가 궁금해지는데 혹시 알려주실 수 있나요?!",
        "[🧋 설레는 밀크티맛]\n소개글이 너무 인상 깊어서 용기 내어 인사 건넵니다. 오늘 하루 어떠셨어요? 🌙",
      ];
    }

    // 2. 상대방 데이터 가공
    String mbti = peerData['mbti'] ?? '비밀';
    List<dynamic> interestsRaw = peerData['interests'] ?? [];
    String interest = interestsRaw.isNotEmpty ? interestsRaw.first.toString() : '차 마시기';
    String bio = peerData['bio'] ?? '반갑습니다!';

    try {
      // 3. Gemini 모델 설정 (gemini-1.5-flash 가 빠르고 저렴합니다)
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: _geminiApiKey);

      // 4. 프롬프트 작성 (페르소나 부여)
      final prompt = """
너는 데이팅 앱의 '수석 티 소믈리에'야. 
상대방의 정보를 바탕으로 대화를 시작하기 좋은 첫인사 문구 3가지를 만들어줘.
각 문구는 아래의 태그로 시작하고, 한국어로 작성해줘.

1. [🍵 정중한 녹차맛]: 정중하고 차분하게 관심사를 묻는 스타일
2. [🥤 유쾌한 탄산맛]: 에너지가 넘치고 MBTI나 공통점을 언급하는 밝은 스타일
3. [🧋 설레는 밀크티맛]: 따뜻하고 감성적이며 소개글의 디테일을 칭찬하는 스타일

상대방 정보:
- MBTI: $mbti
- 관심사: $interest
- 소개글: $bio

출력 시 문구 앞에 번호를 붙이지 말고, 각 스타일별로 한 줄씩만 딱 3줄로 출력해줘.
""";

      // 5. AI 호출
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      
      if (response.text == null) throw Exception("Gemini 응답 없음");

      // 6. 결과 파싱 (한 줄씩 나누기)
      List<String> results = response.text!.trim().split('\n').where((s) => s.contains('[')).toList();
      
      // 혹시라도 3개가 안 나왔을 경우를 대비해 placeholder와 합침
      if (results.length < 3) throw Exception("파싱 실패");
      
      return results;
    } catch (e) {
      print("Gemini 에러: $e");
      // 에러 발생 시 fallback
      return [
        "[🍵 정중한 녹차맛]\n인사가 늦었네요! 관심사 $interest 관련해서 궁금한 게 많은데 대화 가능할까요?",
        "[🥤 유쾌한 탄산맛]\n우와 $mbti 이시네요! 저랑 대화 티키타카가 아주 잘 맞을 것 같은 예감이 들어요! 😆",
        "[🧋 설레는 밀크티맛]\n소개글이 너무 예뻐서 저도 모르게 용기 냈어요. 오늘 하루는 어떻게 보내셨나요? 🌙",
      ];
    }
  }

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
          // 🤝 매너 약속 버튼
          IconButton(
            icon: const Icon(Icons.handshake, color: Colors.blue),
            onPressed: () {
              // 상대방의 uid와 현재 방의 roomId를 넘겨줍니다.
              PromiseDialog.show(context, widget.chatRoomId, widget.peerUid); 
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
          _buildChatInput(widget.peerUid),
        ],
      ),
    ),
    );
  }

  // 🌟 채팅 하단 입력 UI (AI 소믈리에 포함)
  Widget _buildChatInput(String peerUid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            // 1. 사진 전송 버튼
            IconButton(
              icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
              onPressed: _sendImage,
            ),
            // 2. 🌟 AI 티 소믈리에 마법봉 버튼
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Color(0xFFD4AF37)),
              onPressed: () => _callAiSommelier(peerUid),
              tooltip: "AI 티 소믈리에 호출 (2🍵)",
            ),
            // 3. 텍스트 입력창
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: "메시지를 입력하세요...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 4. 전송 버튼
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
