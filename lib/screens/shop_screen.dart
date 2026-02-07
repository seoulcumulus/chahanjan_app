import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chahanjan_app/utils/translations.dart'; // ✅ 번역기
import 'package:chahanjan_app/utils/bible_service.dart'; // ✅ 말씀 서비스 (import 확인!)

class ShopScreen extends StatefulWidget {
  final List<String> myInventory;
  final Function(String) onBuy;

  const ShopScreen({
    super.key,
    required this.myInventory,
    required this.onBuy,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  final Color _signatureColor = const Color(0xFF24FCFF);
  late TabController _tabController;

  // 찻잎 상품 목록
  final List<Map<String, dynamic>> _teaBundles = [
    {'amount': 10, 'key': '10', 'price_label': '1,000₩'}, // 가격표 임시 표기
    {'amount': 50, 'key': '50', 'price_label': '4,500₩'},
    {'amount': 100, 'key': '100', 'price_label': '9,000₩'},
    // ...
  ];

  // 12지신 + 기본 아바타 목록 (파일 이름과 정확히 일치!)
  final List<Map<String, dynamic>> _avatarItems = [
    {'file': 'avatar_1.png', 'price': 50}, // 기본 소녀
    {'file': 'rat.png', 'price': 50},      // 쥐
    {'file': 'ox.png', 'price': 50},       // 소 (보유중인 것!)
    {'file': 'tiger.png', 'price': 50},    // 호랑이
    {'file': 'rabbit.png', 'price': 50},   // 토끼
    {'file': 'dragon.png', 'price': 100},  // 용 (비쌈)
    {'file': 'snake.png', 'price': 50},    // 뱀 (골프)
    {'file': 'snake1.png', 'price': 50},   // 뱀 (책)
    {'file': 'horse.png', 'price': 50},    // 말
    {'file': 'sheep.png', 'price': 50},    // 양
    {'file': 'monkey.png', 'price': 50},   // 원숭이
    {'file': 'rooster.png', 'price': 50},  // 닭
    {'file': 'dog.png', 'price': 50},      // 개
    {'file': 'pig.png', 'price': 50},      // 돼지
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        // ✅ [수정] AppStrings 삭제 -> AppLocale.t 사용
        title: Text(AppLocale.t('shop_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: _signatureColor,
          // 🚨 [수정] const 제거! (번역기 때문에 변해야 함)
          tabs: [
            Tab(text: AppLocale.t('tab_tea')),     // 찻잎 상점
            Tab(text: AppLocale.t('tab_avatar')),  // 아바타 상점
            Tab(text: AppLocale.t('tab_fortune')), // 성스러운 신탁
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final int myTea = data['tea_leaves'] ?? 0;
          // owned_avatars는 이제 부모(widget.myInventory)나 DB에서 가져옴
          final List<dynamic> unlockedAvatars = data['owned_avatars'] ?? [];
          final String myZodiac = data['zodiac'] ?? '쥐';

          return Column(
            children: [
              // 1. 상단 이미지 & 지갑
              Container(
                width: double.infinity,
                height: 150,
                decoration: const BoxDecoration(
                  image: DecorationImage(image: AssetImage('assets/shop_image.png'), fit: BoxFit.cover),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(15),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocale.t('tea_leaves'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(color: _signatureColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          const Text("🍵", style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text("$myTea", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 탭 뷰
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTeaShop(user.uid),
                    _buildAvatarShop(user.uid, myTea, unlockedAvatars),
                    _buildFortuneTab(user.uid, myTea, myZodiac),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🍵 찻잎 상점
  Widget _buildTeaShop(String uid) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _teaBundles.length,
      itemBuilder: (context, index) {
        final bundle = _teaBundles[index];
        final amount = bundle['amount'] as int;
        final priceLabel = bundle['price_label'] as String; // 실제 결제 연동 전 표시용

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _signatureColor.withOpacity(0.2), shape: BoxShape.circle),
              child: const Text("🍵", style: TextStyle(fontSize: 24)),
            ),
            title: Text("$amount Tea Leaves", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            trailing: ElevatedButton(
              onPressed: () => _buyTeaLeaves(uid, amount),
              style: ElevatedButton.styleFrom(
                backgroundColor: _signatureColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(priceLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  // 🎭 아바타 상점
  Widget _buildAvatarShop(String uid, int myTea, List<dynamic> unlockedAvatars) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 15, mainAxisSpacing: 15,
      ),
      itemCount: _avatarItems.length,
      itemBuilder: (context, index) {
        final item = _avatarItems[index];
        final fileName = item['file'] as String;
        final price = item['price'] as int;
        
        // 내 창고 목록(widget.myInventory) 또는 DB 데이터(unlockedAvatars) 확인
        final isUnlocked = unlockedAvatars.contains(fileName) || widget.myInventory.contains(fileName);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: isUnlocked ? Border.all(color: _signatureColor, width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset('assets/avatars/$fileName', fit: BoxFit.contain),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: isUnlocked
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                      child: Text(AppLocale.t('owned'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    )
                  : ElevatedButton(
                      onPressed: () => _buyAvatar(uid, fileName, price, myTea),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _signatureColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text("$price 🍵", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔮 운세 (성경 말씀) 탭
  Widget _buildFortuneTab(String uid, int myTea, String zodiac) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Colors.purple),
            const SizedBox(height: 20),
            Text(AppLocale.t('fortune_title'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(AppLocale.t('fortune_desc'), style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _showHolyRevelation(uid, myTea), // ✅ 여기! 성경 말씀 함수로 연결
              style: ElevatedButton.styleFrom(
                backgroundColor: _signatureColor,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              icon: const Icon(Icons.menu_book, size: 24),
              label: Text("${AppLocale.t('view_fortune')} (1🍵)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 기능 함수들 ---

  void _buyTeaLeaves(String uid, int amount) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'tea_leaves': FieldValue.increment(amount),
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.t('buy_success'))));
  }

  void _buyAvatar(String uid, String fileName, int price, int myTea) async {
    if (myTea < price) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.t('not_enough_tea')), backgroundColor: Colors.red));
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'tea_leaves': FieldValue.increment(-price),
      'owned_avatars': FieldValue.arrayUnion([fileName]),
    });
    widget.onBuy(fileName); // 창고 업데이트 알림
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.t('buy_success'))));
  }

  // 📖 성스러운 말씀 뽑기 (BibleService 연동)
  void _showHolyRevelation(String uid, int myTea) async {
    if (myTea < 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.t('not_enough_tea')), backgroundColor: Colors.red));
      return;
    }

    // 1. 찻잎 차감
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'tea_leaves': FieldValue.increment(-1),
    });

    // 2. 말씀 가져오기 (비동기)
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    
    // ✅ BibleService 사용!
    final verseData = await BibleService.getRandomVerse(); 
    
    if (!mounted) return;
    Navigator.pop(context); // 로딩 끄기

    // 3. 팝업 보여주기
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Column(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.amber, size: 40),
            const SizedBox(height: 10),
            Text(AppLocale.t('fortune_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"${verseData['text']}"', // 말씀 본문
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, height: 1.5),
            ),
            const SizedBox(height: 20),
            Text(
              "- ${verseData['source']} -", // 출처
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocale.t('confirm'), style: const TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }
}
