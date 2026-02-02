import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chahanjan_app/screens/map_screen.dart';
import 'package:chahanjan_app/screens/chat_list_screen.dart';

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
      // [0번: 홈 탭] - 환영 화면
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

      // [1번: 지도 탭] - 실제 MapScreen 연결
      const MapScreen(),

      // [2번: 채팅 탭] - 실제 ChatListScreen 연결
      const ChatListScreen(),
    ];

    return Scaffold(
      // AppBar는 홈 탭일 때만 보여주기
      appBar: _selectedIndex == 0 
        ? AppBar(
            title: const Text("차한잔"),
            centerTitle: true,
          )
        : null,
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
