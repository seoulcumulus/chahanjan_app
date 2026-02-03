import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chahanjan_app/screens/map_screen.dart';
import 'package:chahanjan_app/screens/matching_screen.dart'; // [추가]
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
    // 각 탭에 보여줄 화면들
    final List<Widget> pages = [
      // [0번: 지도] - 메인 화면
      const MapScreen(),

      // [1번: 매칭] - 새로운 기능!
      const MatchingScreen(),

      // [2번: 내 정보]
      const ProfileScreen(),
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
            icon: Icon(Icons.map),
            label: '지도',
          ),
          
          // 3. 하단 탭 아이콘 추가
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite), // 하트 아이콘
            label: '매칭',
          ),
          
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내 정보',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}
