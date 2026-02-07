import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // 👈 이거 추가!
import 'package:chahanjan_app/services/notification_service.dart'; // 👈 import 추가
import 'package:chahanjan_app/screens/login_screen.dart';
import 'package:chahanjan_app/screens/signup_screen.dart';
import 'package:chahanjan_app/screens/map_screen.dart';
import 'package:chahanjan_app/screens/profile_setup_screen.dart';
import 'package:chahanjan_app/screens/lounge_screen.dart'; // Added
import 'package:chahanjan_app/utils/app_strings.dart'; // Added
import 'package:chahanjan_app/home_screen.dart'; // 👈 새로 추가!

import 'package:provider/provider.dart';
import 'package:chahanjan_app/providers/user_provider.dart';

import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart' hide User;

import 'package:firebase_core/firebase_core.dart';

import 'package:chahanjan_app/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chahanjan_app/utils/app_colors.dart'; // import 추가
import 'dart:ui'; // Added
import 'package:chahanjan_app/utils/translations.dart'; // [추가] 번역 파일


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null); // 👈 이것도 추가!
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 👇 [추가 1] 알림 설정 초기화
  await NotificationService().init();

  // Kakao Native App Key & JS Key
  KakaoSdk.init(
    nativeAppKey: '42308a286df44fe81bcc8b9da2b601b4',
    javaScriptAppKey: '31959c07302221dae40f7cc45049ddae',
  );
  
  // 👇 [추가] 이 코드가 콘솔에 키 해시를 찍어줍니다.
  print('==========================================');
  print('내 앱의 해시 키: ${await KakaoSdk.origin}'); 
  print('==========================================');
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
    // 👇 여기가 핵심입니다! AppLocale의 확성기를 감시합니다.
    return ValueListenableBuilder<String>(
      valueListenable: AppLocale.currentNotifier, // 무엇을 감시하나요? 언어 변경!
      builder: (context, currentLang, child) {
        return MaterialApp(
          // 언어가 바뀌면 이 key가 바뀌면서 앱을 강제로 다시 그립니다.
          key: ValueKey(currentLang), 
          
          // 제목도 번역된 걸로 나오게 수정!
          title: AppLocale.t('app_title'),
          
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
          // 🚪 문지기 역할 - 로그인 여부 확인
          home: const AuthGate(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/map': (context) => const MapScreen(),
            '/profile_setup': (context) => const ProfileSetupScreen(),
            '/lounge': (context) => const LoungeScreen(), // Added
          },
        );
      },
    );
  }
}

// 🚪 문지기 역할 (로그인 여부 확인)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 로딩 중일 때
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        // 로그인 되어 있으면 -> 홈 화면(HomeScreen)으로!
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        
        // 안 되어 있으면 -> 로그인 화면(LoginScreen)으로!
        return const LoginScreen();
      },
    );
  }
}

