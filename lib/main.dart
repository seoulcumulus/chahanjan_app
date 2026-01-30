import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // 👈 이거 추가!
import 'package:chahanjan_app/screens/login_screen.dart';
import 'package:chahanjan_app/screens/signup_screen.dart';
import 'package:chahanjan_app/screens/map_screen.dart';
import 'package:chahanjan_app/screens/profile_setup_screen.dart';
import 'package:chahanjan_app/screens/lounge_screen.dart'; // Added
import 'package:chahanjan_app/utils/app_strings.dart'; // Added

import 'package:provider/provider.dart';
import 'package:chahanjan_app/providers/user_provider.dart';

import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' hide User;

import 'package:firebase_core/firebase_core.dart';

import 'package:chahanjan_app/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chahanjan_app/utils/app_colors.dart'; // import 추가
import 'dart:ui'; // Added

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null); // 👈 이것도 추가!
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Kakao Native App Key & JS Key
  KakaoSdk.init(
    nativeAppKey: '42308a286df44fe81bcc8b9da2b601b4',
    javaScriptAppKey: '31959c07302221dae40f7cc45049ddae',
  );
  // 🌍 1. 스마트폰 언어 감지 및 설정
  final systemLocales = PlatformDispatcher.instance.locales;
  if (systemLocales.isNotEmpty && systemLocales.first.languageCode == 'ko') {
    AppStrings.language = 'ko';
  } else {
    AppStrings.language = 'en';
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChaHanJan',
      theme: ThemeData(
        // 🩵 메인 색상 테마 적용
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary, // 주요 부위 색상
          secondary: AppColors.accent,
        ),
        
        // 앱바 색상 통일
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white, // 글자색
          elevation: 0,
        ),
        
        // 버튼 색상 통일
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. 연결 상태 확인
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. 로그인 여부 확인
          if (snapshot.hasData) {
            // 로그인 됨 -> 프로필 있는지 확인
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(body: Center(child: CircularProgressIndicator()));
                }

                if (userSnapshot.hasData && userSnapshot.data!.exists) {
                  return const MapScreen(); // 프로필 있음 -> 지도
                } else {
                  return const ProfileSetupScreen(); // 프로필 없음 -> 설정
                }
              },
            );
          }

          // 3. 로그인 안됨 -> 로그인 화면
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/map': (context) => const MapScreen(),
        '/profile_setup': (context) => const ProfileSetupScreen(),
        '/lounge': (context) => const LoungeScreen(), // Added
      },
    );
  }
}
