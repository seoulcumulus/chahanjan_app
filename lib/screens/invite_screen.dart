import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // 클립보드 복사용
import 'package:share_plus/share_plus.dart'; // 🌟 공유 패키지 추가

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final Color _holyGold = const Color(0xFFD4AF37);
  final Color _holyPurple = const Color(0xFF2E003E);
  final Color _signatureColor = const Color(0xFF24FCFF);

  final String _myUid = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _codeController = TextEditingController();

  String _myInviteCode = '';
  bool _hasUsedCode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateInviteCode();
  }

  // 1. 내 초대 코드 불러오기 (없으면 즉시 생성!)
  Future<void> _loadOrGenerateInviteCode() async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(_myUid);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      final data = docSnap.data() as Map<String, dynamic>;
      String? code = data['invite_code'];
      bool hasUsed = data['has_used_invite_code'] ?? false;

      // 코드가 아직 없는 기존 유저라면 랜덤 6자리 코드 생성 후 DB에 저장
      if (code == null || code.isEmpty) {
        code = _generateRandomCode(6);
        await docRef.set({'invite_code': code}, SetOptions(merge: true));
      }

      setState(() {
        _myInviteCode = code!;
        _hasUsedCode = hasUsed;
        _isLoading = false;
      });
    }
  }

  // 랜덤 6자리 영문대문자+숫자 조합 생성기
  String _generateRandomCode(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random();
    return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
  }

  // 2. 🌟 핵심: 친구 코드 입력 및 쌍방 보상 (트랜잭션)
  Future<void> _submitInviteCode() async {
    final inputCode = _codeController.text.trim().toUpperCase();

    if (inputCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("코드를 입력해주세요.")));
      return;
    }
    if (inputCode == _myInviteCode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("자신의 코드는 입력할 수 없습니다! 😅", style: TextStyle(color: Colors.red))));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 해당 코드를 가진 유저(초대자) 찾기
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('invite_code', isEqualTo: inputCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("존재하지 않는 코드입니다.", style: TextStyle(color: Colors.red))));
        setState(() => _isLoading = false);
        return;
      }

      final inviterDocRef = querySnapshot.docs.first.reference;
      final myDocRef = FirebaseFirestore.instance.collection('users').doc(_myUid);

      // 🌟 트랜잭션: 동시에 성공하거나 동시에 실패하도록 안전하게 처리 (어뷰징 방지)
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final mySnapshot = await transaction.get(myDocRef);
        
        // 다시 한번 혹시나 그새 코드를 썼는지 이중 체크
        if (mySnapshot.data()?['has_used_invite_code'] == true) {
          throw Exception("already_used");
        }

        // 1. 나에게 50 찻잎 지급 & 코드 사용 완료 처리
        transaction.update(myDocRef, {
          'tea_leaves': FieldValue.increment(50),
          'has_used_invite_code': true,
        });

        // 2. 초대한 친구에게도 50 찻잎 지급
        transaction.update(inviterDocRef, {
          'tea_leaves': FieldValue.increment(50),
        });
      });

      setState(() {
        _hasUsedCode = true;
        _isLoading = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("🎉 축하합니다!"),
            content: const Text("친구 초대 보상으로\n찻잎 50개가 지급되었습니다! 🍵"),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("확인"))],
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (e.toString().contains("already_used")) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이미 코드를 입력하여 보상을 받으셨습니다.", style: TextStyle(color: Colors.red))));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("에러가 발생했습니다: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("친구 초대", style: TextStyle(fontWeight: FontWeight.bold, color: _holyGold)),
        backgroundColor: _holyPurple,
        centerTitle: true,
        iconTheme: IconThemeData(color: _holyGold),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _holyGold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Icon(Icons.redeem, size: 80, color: Colors.pinkAccent),
                  const SizedBox(height: 20),
                  const Text("친구도 나도 50 찻잎! 🍵", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text("내 코드를 친구가 가입 시 입력하면,\n두 사람 모두에게 찻잎 50개를 드립니다.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 40),

                  // 1. 내 코드 복사 영역
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("나의 초대 코드", style: TextStyle(fontWeight: FontWeight.bold, color: _holyPurple, fontSize: 16)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                                child: Text(_myInviteCode, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 5)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _myInviteCode));
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("코드가 복사되었습니다!")));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[300], foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                              child: const Icon(Icons.copy),
                            ),
                          ],
                        ),
                        
                        // 🌟 새로 추가된 공유하기 버튼 🌟
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // 친구에게 전송될 초대장 메시지 내용
                              final String shareText = 
                                  "☕ 매너 있는 사람들의 다과회, '차한잔'에 초대합니다!\n\n"
                                  "가입 시 아래 초대 코드를 입력하면\n"
                                  "우리 둘 다 '50 찻잎 🍵'을 받을 수 있어요!\n\n"
                                  "🎁 나의 초대 코드: $_myInviteCode\n\n"
                                  "👇 지금 바로 다운로드 하세요!\n"
                                  "https://play.google.com/store/apps/details?id=com.chahanjan.app"; // 실제 앱스토어 링크로 나중에 변경
                                  
                              Share.share(shareText);
                            },
                            icon: const Icon(Icons.send, size: 20),
                            label: const Text("카카오톡으로 친구 초대하기", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEE500), // 카카오톡 노란색
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // 2. 친구 코드 입력 영역
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("초대받으셨나요?", style: TextStyle(fontWeight: FontWeight.bold, color: _holyPurple, fontSize: 16)),
                        const SizedBox(height: 10),
                        if (_hasUsedCode)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green)),
                            child: const Text("✅ 이미 초대 코드를 입력하여 보상을 받으셨습니다!", textAlign: TextAlign.center, style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          )
                        else
                          Column(
                            children: [
                              TextField(
                                controller: _codeController,
                                textCapitalization: TextCapitalization.characters,
                                decoration: InputDecoration(
                                  hintText: "친구의 초대 코드를 입력하세요",
                                  filled: true, fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity, height: 50,
                                child: ElevatedButton(
                                  onPressed: _submitInviteCode,
                                  style: ElevatedButton.styleFrom(backgroundColor: _holyGold, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                  child: const Text("보상 받기 🍵", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
