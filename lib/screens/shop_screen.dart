import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../utils/app_strings.dart'; // 다국어 파일

class ShopScreen extends StatefulWidget {
  // 👇 [추가] 부모(창고)로부터 받아올 데이터들
  final List<String> myInventory; // 내 창고 목록 (이미 산 건지 확인용)
  final Function(String) onBuy;   // 구매하면 창고에 알려줄 함수

  // 생성자에 required 추가
  const ShopScreen({
    super.key, 
    required this.myInventory, // 👈 추가
    required this.onBuy,       // 👈 추가
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  final Color _signatureColor = const Color(0xFF24FCFF);
  late TabController _tabController;

  // 찻잎 상품 목록 (개수, 키값)
  final List<Map<String, dynamic>> _teaBundles = [
    {'amount': 10, 'key': '10'},
    {'amount': 50, 'key': '50'},
    {'amount': 100, 'key': '100'},
    {'amount': 200, 'key': '200'},
    {'amount': 500, 'key': '500'},
    {'amount': 1000, 'key': '1000'},
  ];

  // 12지신 아바타 목록 (파일명, 가격)
  final List<Map<String, dynamic>> _avatarItems = [
    {'file': 'avatar_1.png', 'price': 50}, // 기본 아바타
    {'file': 'rat.png', 'price': 50},
    {'file': 'ox.png', 'price': 50},
    {'file': 'tiger.png', 'price': 50},
    {'file': 'rabbit.png', 'price': 50},
    {'file': 'dragon.png', 'price': 100}, // 용은 좀 더 비싸게?
    {'file': 'snake.png', 'price': 50},
    {'file': 'snake1.png', 'price': 50}, // 뱀 (다른 버전)
    {'file': 'horse.png', 'price': 50},
    {'file': 'sheep.png', 'price': 50},
    {'file': 'monkey.png', 'price': 50},
    {'file': 'rooster.png', 'price': 50},
    {'file': 'dog.png', 'price': 50},
    {'file': 'pig.png', 'price': 50},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs now
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
        title: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, snapshot) {
            String lang = 'English';
            if (snapshot.hasData && snapshot.data!.exists) {
              lang = snapshot.data!['language'] ?? 'English';
            }
            return Text(AppStrings.getByLang(lang, 'shop_title'), style: const TextStyle(fontWeight: FontWeight.bold));
          },
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          indicatorColor: _signatureColor,
          tabs: const [
            Tab(text: "Tea Shop 🍵"),
            Tab(text: "Avatar Shop 🎭"),
            Tab(text: "Fortune 🔮"),
          ],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final int myTea = data['tea_leaves'] ?? 0;
          final String myLang = data['language'] ?? 'English';
          final List<dynamic> unlockedAvatars = data['owned_avatars'] ?? ['avatar_1.png', 'rat.png']; 
          final String myZodiac = data['zodiac'] ?? '쥐'; // 기본값

          return Column(
            children: [
              // 1. 상점 메인 이미지 & 내 지갑 (공통 상단)
              Container(
                width: double.infinity,
                height: 150,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/shop_image.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(15),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppStrings.getByLang(myLang, 'tea_leaves'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              
              // 2. 탭 뷰 (찻잎 상점 / 아바타 상점 / 운세)
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // [탭 1] 찻잎 충전소
                    _buildTeaShop(myLang, user.uid),

                    // [탭 2] 아바타 상점
                    _buildAvatarShop(myLang, user.uid, myTea, unlockedAvatars),

                    // [탭 3] 운세
                    _buildFortuneTab(myLang, user.uid, myTea, myZodiac),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 🍵 찻잎 상점 뷰
  Widget _buildTeaShop(String lang, String uid) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _teaBundles.length,
      itemBuilder: (context, index) {
        final bundle = _teaBundles[index];
        final amount = bundle['amount'] as int;
        final key = bundle['key'] as String;
        final name = AppStrings.getByLang(lang, 'tea_$key');
        final price = AppStrings.getByLang(lang, 'price_$key');

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(15),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _signatureColor.withOpacity(0.2), shape: BoxShape.circle),
              child: const Text("🍵", style: TextStyle(fontSize: 24)),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            trailing: ElevatedButton(
              onPressed: () => _buyTeaLeaves(uid, amount, lang),
              style: ElevatedButton.styleFrom(
                backgroundColor: _signatureColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        );
      },
    );
  }

  // 🎭 아바타 상점 뷰
  Widget _buildAvatarShop(String lang, String uid, int myTea, List<dynamic> unlockedAvatars) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2열
        childAspectRatio: 0.8,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
      ),
      itemCount: _avatarItems.length,
      itemBuilder: (context, index) {
        final item = _avatarItems[index];
        final fileName = item['file'] as String;
        final price = item['price'] as int;
        final isUnlocked = unlockedAvatars.contains(fileName);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: isUnlocked ? Border.all(color: _signatureColor, width: 2) : null,
            boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 아바타 이미지
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset('assets/avatars/$fileName', fit: BoxFit.contain),
                ),
              ),
              
              // 가격 또는 보유중 표시
              Padding(
                padding: const EdgeInsets.all(10),
                child: isUnlocked
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                      child: const Text("Owned", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    )
                  : ElevatedButton(
                      onPressed: () => _buyAvatar(uid, fileName, price, myTea, lang),
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

  // 🔮 운세 탭 뷰
  Widget _buildFortuneTab(String lang, String uid, int myTea, String zodiac) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 80, color: Colors.purple),
            const SizedBox(height: 20),
            const Text(
              "오늘의 연애운세",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "찻잎 1개로 오늘의 운세를 확인하세요!",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Text("당신의 띠: $zodiac", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _checkHoroscope(zodiac, myTea, uid, lang),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _signatureColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.favorite, size: 24),
                    label: const Text("운세 보기 (1🍵)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 💰 찻잎 구매 로직
  void _buyTeaLeaves(String uid, int amount, String lang) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'tea_leaves': FieldValue.increment(amount),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("${AppStrings.getByLang(lang, 'buy_success')} (+ $amount 🍵)"),
        backgroundColor: _signatureColor,
        duration: const Duration(seconds: 1),
      ));
    }
  }

  // 🎭 아바타 구매 로직
  void _buyAvatar(String uid, String fileName, int price, int myTea, String lang) async {
    if (myTea < price) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.getByLang(lang, 'not_enough_tea')),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    // 1. 찻잎 차감
    // 2. 아바타 목록에 추가
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'tea_leaves': FieldValue.increment(-price),
      'owned_avatars': FieldValue.arrayUnion([fileName]),
    });

    // 👇 [추가] 창고에 아이템 추가하라고 신호 보내기!
    widget.onBuy(fileName);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("구매 완료! 창고에 배달되었습니다 📦"),
      ));
    }
  }

  // 🔮 운세 보기 함수 (찻잎 1개 소모)
  void _checkHoroscope(String userZodiac, int currentTea, String uid, String lang) async {
    // 1. 찻잎이 부족한 경우
    if (currentTea < 1) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.getByLang(lang, 'not_enough_tea')),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    // 2. 찻잎 차감
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'tea_leaves': FieldValue.increment(-1),
    });

    // 3. 운세 결과 보여주기 (랜덤 멘트)
    List<String> loveLuck = [
      "💖 오늘은 운명의 상대를 만날 수 있어요!",
      "💌 연락이 뜸했던 사람에게서 소식이 올지도?",
      "🔥 적극적으로 다가가면 사랑을 얻습니다.",
      "🤔 오늘은 조용히 나만의 시간을 갖는 게 좋아요.",
      "✨ 새로운 만남이 기다리고 있어요!",
      "💫 상대방의 마음이 조금씩 열리고 있습니다.",
      "🌟 진심을 표현하면 좋은 결과가 있을 거예요.",
      "💕 운명의 장난이 기다리고 있네요!",
    ];
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("$userZodiac 띠의 오늘 연애운 💘", style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Colors.pink, size: 50),
            const SizedBox(height: 15),
            Text(
              loveLuck[Random().nextInt(loveLuck.length)],
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("확인", style: TextStyle(fontSize: 16)),
          )
        ],
      ),
    );
  }
}
