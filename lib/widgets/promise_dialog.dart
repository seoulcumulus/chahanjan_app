import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart'; // GPS 기능

class PromiseDialog extends StatefulWidget {
  final String roomId;
  final String peerUid;

  const PromiseDialog({super.key, required this.roomId, required this.peerUid});

  // 채팅방 등에서 이 팝업을 띄우는 헬퍼 함수
  static void show(BuildContext context, String roomId, String peerUid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PromiseDialog(roomId: roomId, peerUid: peerUid),
    );
  }

  @override
  State<PromiseDialog> createState() => _PromiseDialogState();
}

class _PromiseDialogState extends State<PromiseDialog> {
  final String _myUid = FirebaseAuth.instance.currentUser!.uid;
  bool _isLoading = false;

  // 1. 매너 서약 (약속 제안하기) - 50 찻잎 소모
  Future<void> _proposePromise() async {
    setState(() => _isLoading = true);
    final myRef = FirebaseFirestore.instance.collection('users').doc(_myUid);
    final roomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.roomId);

    try {
      final myDoc = await myRef.get();
      int myTea = myDoc.data()?['tea_leaves'] ?? 0;

      if (myTea < 50) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("찻잎이 50개 이상 필요합니다!")));
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 내 찻잎 50개 차감
        transaction.update(myRef, {'tea_leaves': FieldValue.increment(-50)});
        // 채팅방에 약속 정보 세팅
        transaction.set(roomRef.collection('promise').doc('current'), {
          'status': 'proposed', // 제안됨
          'proposer': _myUid,
          'amount': 50,
          'timestamp': FieldValue.serverTimestamp(),
          'user1_loc': null, // 나중에 GPS 인증 시 사용할 좌표
          'user2_loc': null,
        });
      });

      if (mounted) Navigator.pop(context); // 팝업 닫기
    } catch (e) {
      print("서약 에러: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. 서약 수락하기 (상대방도 50 찻잎 소모)
  Future<void> _acceptPromise() async {
    setState(() => _isLoading = true);
    final myRef = FirebaseFirestore.instance.collection('users').doc(_myUid);
    final promiseRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.roomId).collection('promise').doc('current');

    try {
      final myDoc = await myRef.get();
      int myTea = myDoc.data()?['tea_leaves'] ?? 0;

      if (myTea < 50) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("찻잎이 부족합니다.")));
        setState(() => _isLoading = false);
        return;
      }

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(myRef, {'tea_leaves': FieldValue.increment(-50)});
        transaction.update(promiseRef, {
          'status': 'accepted', // 수락됨 (약속 확정)
          'acceptor': _myUid,
        });
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("수락 에러: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. 🌟 약속 장소에서 GPS 만남 인증하기!
  Future<void> _verifyMeeting(Map<String, dynamic> promiseData) async {
    setState(() => _isLoading = true);
    try {
      // 위치 권한 확인 및 현재 위치 가져오기
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception("위치 권한이 필요합니다.");
      }
      
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      GeoPoint myLocation = GeoPoint(position.latitude, position.longitude);

      final promiseRef = FirebaseFirestore.instance.collection('chat_rooms').doc(widget.roomId).collection('promise').doc('current');
      
      // 내 위치 저장
      String myLocField = promiseData['proposer'] == _myUid ? 'user1_loc' : 'user2_loc';
      String peerLocField = promiseData['proposer'] == _myUid ? 'user2_loc' : 'user1_loc';

      await promiseRef.update({
        myLocField: myLocation,
      });

      // 최신 데이터 다시 불러와서 둘 다 인증했는지 확인
      final updatedDoc = await promiseRef.get();
      final updatedData = updatedDoc.data()!;

      if (updatedData[peerLocField] != null) {
        // 상대방도 위치를 등록했다면 거리 계산!
        GeoPoint peerLocation = updatedData[peerLocField];
        double distanceInMeters = Geolocator.distanceBetween(
          myLocation.latitude, myLocation.longitude,
          peerLocation.latitude, peerLocation.longitude,
        );

        if (distanceInMeters <= 500) { // 500미터 이내면 만남 인정!
          await promiseRef.update({'status': 'completed'});
          
          // 양쪽 모두에게 보증금(50) 환불 + 보너스(10) + 매너온도(+5) 지급 (실제 앱에서는 Cloud Function으로 처리하는 것이 더 안전합니다)
          final myUserRef = FirebaseFirestore.instance.collection('users').doc(_myUid);
          final peerUserRef = FirebaseFirestore.instance.collection('users').doc(widget.peerUid);

          await FirebaseFirestore.instance.runTransaction((tx) async {
            tx.update(myUserRef, {'tea_leaves': FieldValue.increment(60), 'manner_temp': FieldValue.increment(5.0)});
            tx.update(peerUserRef, {'tea_leaves': FieldValue.increment(60), 'manner_temp': FieldValue.increment(5.0)});
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🎉 만남 인증 성공! 보증금 환불 및 매너온도가 상승했습니다.")));
            Navigator.pop(context);
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("상대방과의 거리가 너무 멉니다! (${distanceInMeters.toInt()}m)")));
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("내 위치가 인증되었습니다. 상대방의 인증을 기다립니다.")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("인증 실패: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('chat_rooms').doc(widget.roomId).collection('promise').snapshots().first.then((v) => FirebaseFirestore.instance.collection('chat_rooms').doc(widget.roomId).collection('promise').doc('current').snapshots()),
        builder: (context, snapshot) {
          if (_isLoading) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          
          // NOTE: StreamBuilder complexity handled by directly listening to the document snapshots
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('chat_rooms').doc(widget.roomId).collection('promise').doc('current').snapshots(),
            builder: (context, promiseSnap) {
              if (promiseSnap.connectionState == ConnectionState.waiting && !promiseSnap.hasData) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              final doc = promiseSnap.data;
              final data = doc?.data() as Map<String, dynamic>?;

              // 1. 약속이 없을 때 (제안하기)
              if (data == null || data['status'] == 'completed' || data['status'] == 'broken') {
                return _buildProposeUI();
              }

              // 2. 약속이 제안되었을 때
              if (data['status'] == 'proposed') {
                if (data['proposer'] == _myUid) {
                  return const SizedBox(height: 200, child: Center(child: Text("상대방의 수락을 기다리고 있습니다 ⏳", style: TextStyle(fontSize: 18))));
                } else {
                  return _buildAcceptUI();
                }
              }

              // 3. 약속이 성사되었을 때 (만남 인증하기)
              if (data['status'] == 'accepted') {
                String myLocField = data['proposer'] == _myUid ? 'user1_loc' : 'user2_loc';
                bool hasVerified = data[myLocField] != null;
                return _buildVerifyUI(data, hasVerified);
              }

              return const SizedBox.shrink();
            }
          );
        },
      ),
    );
  }

  Widget _buildProposeUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.handshake, size: 60, color: Color(0xFFD4AF37)),
        const SizedBox(height: 10),
        const Text("매너 만남 서약하기", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text("50 찻잎을 걸고 확실한 만남을 약속하세요.\n만나서 인증하면 100% 환불되고 매너온도가 오릅니다!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _proposePromise,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E003E), foregroundColor: Colors.white),
            child: const Text("50🍵 걸고 약속 제안하기"),
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptUI() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.mark_email_unread, size: 60, color: Colors.pinkAccent),
        const SizedBox(height: 10),
        const Text("약속 제안이 도착했습니다!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text("상대방이 50 찻잎을 걸고 만남을 제안했습니다.\n수락하시겠습니까?", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _acceptPromise,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF24FCFF), foregroundColor: Colors.black),
            child: const Text("50🍵 걸고 수락하기"),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyUI(Map<String, dynamic> data, bool hasVerified) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on, size: 60, color: Colors.green),
        const SizedBox(height: 10),
        const Text("약속 장소에 도착하셨나요?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text("서로 500m 이내에 있을 때 버튼을 누르면\n만남이 인증되고 보증금이 환불됩니다!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: hasVerified ? null : () => _verifyMeeting(data),
            style: ElevatedButton.styleFrom(backgroundColor: hasVerified ? Colors.grey : Colors.green, foregroundColor: Colors.white),
            child: Text(hasVerified ? "상대방 인증 대기중..." : "📍 여기서 만남 인증하기"),
          ),
        ),
      ],
    );
  }
}
