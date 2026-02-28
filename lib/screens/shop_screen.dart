import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chahanjan_app/utils/translations.dart'; 
import 'package:chahanjan_app/utils/bible_service.dart';

class ShopScreen extends StatefulWidget {
  final List<String> myInventory;
  final Function(String) onBuy;

  const ShopScreen({super.key, required this.myInventory, required this.onBuy});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with SingleTickerProviderStateMixin {
  final Color _signatureColor = const Color(0xFF24FCFF);
  late TabController _tabController;

  final List<Map<String, dynamic>> _teaBundles = [
    {'amount': 10, 'key': '10', 'price_label': '1,000₩'},
    {'amount': 50, 'key': '50', 'price_label': '4,500₩'},
    {'amount': 100, 'key': '100', 'price_label': '9,000₩'},
  ];

  // 🌟 폴더 상황에 맞춰 8방향 3D 캐릭터 지정 (뱀 제외 모두 회전)
  final List<Map<String, dynamic>> _avatarItems = [
    {'file': 'avatar_1.png', 'price': 50, 'is_25d': false}, 
    {'file': 'rat.png', 'price': 50, 'is_25d': true},       
    {'file': 'ox.png', 'price': 50, 'is_25d': true},        
    {'file': 'tiger.png', 'price': 50, 'is_25d': true},     
    {'file': 'rabbit.png', 'price': 50, 'is_25d': true},    
    {'file': 'dragon.png', 'price': 100, 'is_25d': true},   
    {'file': 'snake.png', 'price': 50, 'is_25d': false},    // 뱀은 평면
    {'file': 'snake1.png', 'price': 50, 'is_25d': false},   
    {'file': 'horse.png', 'price': 50, 'is_25d': true},     
    {'file': 'sheep.png', 'price': 50, 'is_25d': true},     
    {'file': 'monkey.png', 'price': 50, 'is_25d': true},    
    {'file': 'rooster.png', 'price': 50, 'is_25d': true},   
    {'file': 'dog.png', 'price': 50, 'is_25d': true},       
    {'file': 'pig.png', 'price': 50, 'is_25d': true},       
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
        title: Text(AppLocale.t('shop_title'), style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0,
        bottom: TabBar(
          controller: _tabController, labelColor: Colors.black, indicatorColor: _signatureColor,
          tabs: [Tab(text: AppLocale.t('tab_tea')), Tab(text: AppLocale.t('tab_avatar')), Tab(text: AppLocale.t('tab_fortune'))],
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final int myTea = data['tea_leaves'] ?? 0;
          final List<dynamic> unlockedAvatars = data['owned_avatars'] ?? [];

          return Column(
            children: [
              Container(width: double.infinity, height: 150, decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/shop_image.png'), fit: BoxFit.cover))),
              Container(
                padding: const EdgeInsets.all(15), color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(AppLocale.t('tea_leaves'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      decoration: BoxDecoration(color: _signatureColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [const Text("🍵", style: TextStyle(fontSize: 20)), const SizedBox(width: 8), Text("$myTea", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black))]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTeaShop(user.uid),
                    _buildAvatarShop(user.uid, myTea, unlockedAvatars),
                    _buildFortuneTab(user.uid, myTea),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTeaShop(String uid) {
    return ListView.builder(
      padding: const EdgeInsets.all(15), itemCount: _teaBundles.length,
      itemBuilder: (context, index) {
        final amount = _teaBundles[index]['amount'] as int;
        return Card(
          margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _signatureColor.withOpacity(0.2), shape: BoxShape.circle), child: const Text("🍵", style: TextStyle(fontSize: 24))),
            title: Text("$amount Tea Leaves", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            trailing: ElevatedButton(
              onPressed: () => _buyTeaLeaves(uid, amount),
              style: ElevatedButton.styleFrom(backgroundColor: _signatureColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              child: Text(_teaBundles[index]['price_label'], style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarShop(String uid, int myTea, List<dynamic> unlockedAvatars) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.8, crossAxisSpacing: 15, mainAxisSpacing: 15),
      itemCount: _avatarItems.length,
      itemBuilder: (context, index) {
        final fileName = _avatarItems[index]['file'] as String;
        final price = _avatarItems[index]['price'] as int;
        final isUnlocked = unlockedAvatars.contains(fileName) || widget.myInventory.contains(fileName);

        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: isUnlocked ? Border.all(color: _signatureColor, width: 2) : null),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  // 🌟 평면 이미지는 그대로, 8방향 이미지는 회전 위젯으로!
                  child: _avatarItems[index]['is_25d'] == true 
                      ? _AnimatedAvatarWidget(assetPath: 'assets/avatars/$fileName')
                      : Image.asset('assets/avatars/$fileName', fit: BoxFit.contain, errorBuilder: (_,__,___)=>const Icon(Icons.error)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: isUnlocked
                  ? Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)), child: Text(AppLocale.t('owned'), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))
                  : ElevatedButton(
                      onPressed: () => _buyAvatar(uid, fileName, price, myTea),
                      style: ElevatedButton.styleFrom(backgroundColor: _signatureColor, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                      child: Text("$price 🍵", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFortuneTab(String uid, int myTea) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, size: 80, color: Colors.purple), const SizedBox(height: 20),
          Text(AppLocale.t('fortune_title'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)), const SizedBox(height: 10),
          Text(AppLocale.t('fortune_desc'), style: TextStyle(fontSize: 16, color: Colors.grey[600])), const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: () => _showHolyRevelation(uid, myTea), 
            style: ElevatedButton.styleFrom(backgroundColor: _signatureColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
            icon: const Icon(Icons.menu_book, size: 24), label: Text("${AppLocale.t('view_fortune')} (1🍵)", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _buyTeaLeaves(String uid, int amount) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'tea_leaves': FieldValue.increment(amount)});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.t('buy_success'))));
  }

  void _buyAvatar(String uid, String fileName, int price, int myTea) async {
    if (myTea < price) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.t('not_enough_tea')), backgroundColor: Colors.red)); return; }
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'tea_leaves': FieldValue.increment(-price), 'owned_avatars': FieldValue.arrayUnion([fileName])});
    widget.onBuy(fileName); 
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.t('buy_success'))));
  }

  void _showHolyRevelation(String uid, int myTea) async {
    if (myTea < 1) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.t('not_enough_tea')), backgroundColor: Colors.red)); return; }
    await FirebaseFirestore.instance.collection('users').doc(uid).update({'tea_leaves': FieldValue.increment(-1)});
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    final verseData = await BibleService.getRandomVerse(); 
    if (!mounted) return;
    Navigator.pop(context); 
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Column(children: [const Icon(Icons.auto_awesome, color: Colors.amber, size: 40), const SizedBox(height: 10), Text(AppLocale.t('fortune_title'), style: const TextStyle(fontWeight: FontWeight.bold))]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [Text('"${verseData['text']}"', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, height: 1.5)), const SizedBox(height: 20), Text("- ${verseData['source']} -", style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold))]),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocale.t('confirm'), style: const TextStyle(color: Colors.deepPurple)))],
    ));
  }
}

// -----------------------------------------------------------------------------
// 🌟 찌그러짐을 완벽히 해결한 새로운 스톱모션 위젯!
// -----------------------------------------------------------------------------
class _AnimatedAvatarWidget extends StatefulWidget {
  final String assetPath;
  const _AnimatedAvatarWidget({required this.assetPath});

  @override
  State<_AnimatedAvatarWidget> createState() => _AnimatedAvatarWidgetState();
}

class _AnimatedAvatarWidgetState extends State<_AnimatedAvatarWidget> {
  int _currentFrame = 0;
  Timer? _rotationTimer;

  @override
  void initState() {
    super.initState();
    _rotationTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) return;
      for (int i = 1; i <= 8; i++) {
        if (!mounted) break;
        setState(() => _currentFrame = i % 8);
        await Future.delayed(const Duration(milliseconds: 100));
      }
    });
  }

  @override
  void dispose() {
    _rotationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int col = _currentFrame % 4;
    final int row = _currentFrame ~/ 4;
    
    // 비율이 망가지지 않게 자르기 위해 OverflowBox 좌표를 수학적으로 계산
    final double x = -1.0 + (col * (2.0 / 3.0));
    final double y = -1.0 + (row * (2.0 / 1.0));

    return ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          return OverflowBox(
            minWidth: w * 4, maxWidth: w * 4,
            minHeight: h * 2, maxHeight: h * 2,
            alignment: Alignment(x, y), // 정확히 1프레임 위치로 이동
            child: Image.asset(widget.assetPath, fit: BoxFit.fill),
          );
        }
      ),
    );
  }
}
