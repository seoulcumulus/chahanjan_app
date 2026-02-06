import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chahanjan_app/screens/map_screen.dart';
import 'package:chahanjan_app/screens/matching_screen.dart'; // [추가]
import 'package:chahanjan_app/screens/profile_screen.dart';
import 'package:chahanjan_app/utils/translations.dart'; // [추가] 번역 파일

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
        items: <BottomNavigationBarItem>[ // [수정] const 제거
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: AppLocale.t('nav_map'),
          ),
          
          // 3. 하단 탭 아이콘 추가
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite), // 하트 아이콘
            label: AppLocale.t('nav_matching'),
          ),
          
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocale.t('nav_profile'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.deepPurple,
        onTap: _onItemTapped,
      ),
    );
  }
}
