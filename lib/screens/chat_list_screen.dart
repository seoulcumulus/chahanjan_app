import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/user_service.dart'; // UserService 경로 확인 필요

import 'package:chahanjan_app/utils/translations.dart'; // [추가] 번역 파일
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  // 🕒 스마트 시간 변환 (폰 언어 설정 따라감)
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "";
    DateTime date = timestamp.toDate();
    DateTime now = DateTime.now();

    // 오늘이면 시간만, 아니면 날짜 표시 (시스템 언어 자동 적용)
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat.jm().format(date);
    } else {
      return DateFormat.MMMd().format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.t('chat_title')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // 🌟 컬렉션 이름: chat_rooms, 필드: participants, 정렬: updatedAt
        stream: FirebaseFirestore.instance
            .collection('chat_rooms')
            .where('participants', arrayContains: myUid)
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;

          if (allDocs.isEmpty) {
            return const Center(
              child: Text("참여 중인 대화방이 없습니다.\n지도에서 친구를 찾아보세요! 🗺️",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)),
            );
          }

          // 🛠️ [수정된 부분] 안전하게 분류하기 (데이터가 없으면 'pending'으로 간주)
          final activeChats = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // 'status'가 없으면 기본값 'pending'을 씀 (에러 방지 쉴드 🛡️)
            final status = data['status'] ?? 'pending'; 
            return status == 'accepted';
          }).toList();

          final pendingChats = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            return status == 'pending';
          }).toList();

          return ListView(
            children: [
              // 🟢 1. 대화 중인 방 (상단)
              if (activeChats.isNotEmpty) ...[
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(AppLocale.t('chat_active'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                ...activeChats.map((doc) => _buildChatTile(context, doc, myUid, isActive: true)),
              ],

              // 🟠 2. 대기 중인 요청 (하단)
              if (pendingChats.isNotEmpty) ...[
                if (activeChats.isNotEmpty) const Divider(thickness: 8, color: Colors.grey), // 구분선
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(AppLocale.t('chat_waiting'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                ...pendingChats.map((doc) => _buildChatTile(context, doc, myUid, isActive: false)),
              ],
            ],
          );
        },
      ),
    );
  }

  // 🧩 타일 만드는 함수 (중복 제거)
  Widget _buildChatTile(BuildContext context, DocumentSnapshot doc, String? myUid,
      {required bool isActive}) {
    final data = doc.data() as Map<String, dynamic>;
    final List<dynamic> participants = data['participants'];
    final String peerUid = participants.firstWhere((uid) => uid != myUid, orElse: () => "");

    // 내가 신청했는지 확인 (내가 보낸 거면 버튼 안 뜸)
    final String initiatorId = data['initiatorId'] ?? "";
    final bool isReceivedRequest = (initiatorId != myUid);

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(peerUid).get(),
      builder: (context, userSnapshot) {
        String peerNickname = AppLocale.t('unknown_user');
        String peerAvatar = 'rat.png';

        if (userSnapshot.hasData && userSnapshot.data!.exists) {
          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
          peerNickname = userData['nickname'] ?? AppLocale.t('unknown_user');
          peerAvatar = userData['avatar_image'] ?? 'rat.png';
        }

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.white,
            // 🌟 8방향 스프라이트 시트에서 '정면'만 잘라서 보여주기
            child: ClipOval(
              child: SizedBox(
                width: 60, height: 60,
                child: FittedBox(
                  fit: BoxFit.cover, // 자른 이미지를 동그라미에 꽉 차게 확대
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.topLeft, // 왼쪽 맨 위 기준
                      widthFactor: 0.25, // 가로를 4등분 한 것 중 1개
                      heightFactor: 0.5, // 세로를 2등분 한 것 중 1개
                      child: Image.asset(
                        'assets/avatars/$peerAvatar',
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 30, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: Text(peerNickname, style: const TextStyle(fontWeight: FontWeight.bold)),
          
          // 상태에 따른 메시지 표시
          subtitle: isActive
              ? Text(data['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis)
              : Text(
                  isReceivedRequest ? AppLocale.t('msg_received') : AppLocale.t('msg_wait'),
                  style: TextStyle(color: isReceivedRequest ? Colors.blue : Colors.grey),
                ),
          
          // 시간 또는 버튼 표시
          trailing: isActive
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_formatTimestamp(data['updatedAt']), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(width: 8),
                    // 대화 중인 방도 차단 가능
                    IconButton(
                      icon: const Icon(Icons.block, color: Colors.red, size: 20),
                      onPressed: () {
                        UserService().blockChatRoom(doc.id);
                      },
                      tooltip: '차단',
                    ),
                  ],
                )
              : (isReceivedRequest
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(60, 36),
                          ),
                          onPressed: () {
                            // ✅ 수락 버튼 클릭!
                            UserService().acceptChatRequest(doc.id);
                          },
                          child: Text(AppLocale.t('accept'), style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.block, color: Colors.red, size: 20),
                          onPressed: () {
                            UserService().blockChatRoom(doc.id);
                          },
                          tooltip: '차단',
                        ),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("대기 중", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.block, color: Colors.red, size: 20),
                          onPressed: () {
                            UserService().blockChatRoom(doc.id);
                          },
                          tooltip: '취소',
                        ),
                      ],
                    )),
          
          // 탭했을 때 이동 (수락된 상태일 때만)
          onTap: isActive
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatRoomId: doc.id,
                        peerUid: peerUid,
                        peerNickname: peerNickname,
                        peerAvatar: peerAvatar,
                      ),
                    ),
                  );
                }
              : null, // 대기 중일 땐 탭 안 됨 (수락해야 들어감)
        );
      },
    );
  }
}
