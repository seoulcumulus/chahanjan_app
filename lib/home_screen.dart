import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 현재 선택된 탭 번호 (0: 홈, 1: 지도, 2: 채팅)
  int _selectedIndex = 0;

  // 탭을 눌렀을 때 실행될 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    // 각 탭에 보여줄 화면들
    final List<Widget> pages = [
      // [0번: 홈 탭] - 아까 보셨던 환영 화면
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 60)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              "${user?.displayName ?? '사용자'}님, 안녕하세요!",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(user?.email ?? "", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("로그아웃"),
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
      ),

      // [1번: 지도 탭] - 나중에 지도 코드를 여기에 넣을 거예요
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 100, color: Colors.blue),
            SizedBox(height: 20),
            Text("여기에 지도가 나옵니다", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),

      // [2번: 채팅 탭] - 나중에 채팅 목록을 여기에 넣을 거예요
      const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text("여기에 채팅방이 나옵니다", style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("차한잔"),
        centerTitle: true,
      ),
      // 현재 선택된 페이지 보여주기
      body: pages[_selectedIndex],
      
      // 하단 내비게이션 바 (메뉴)
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '내 정보',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '지도',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: '채팅',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}
