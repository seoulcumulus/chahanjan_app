import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chahanjan_app/screens/map_screen.dart';
import 'package:chahanjan_app/screens/chat_list_screen.dart';
import 'package:chahanjan_app/screens/profile_screen.dart';

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
      // [0번: 내 정보] -> ProfileScreen 위젯 사용
      const ProfileScreen(),

      // [1번: 지도] - 실제 MapScreen 연결
      const MapScreen(),

      // [2번: 채팅] - 실제 ChatListScreen 연결
      const ChatListScreen(),
    ];

    return Scaffold(
      // AppBar 제거 (각 화면이 자체 AppBar를 가짐)
      appBar: null,
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
