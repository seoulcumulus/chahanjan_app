import 'package:flutter/material.dart';

class AppColors {
  // ⚡ 새로운 시그니처 컬러 (#00D8FF - Vivid Sky Blue / Capri)
  static const Color primary = Color(0xFF00D8FF); 
  
  // 조금 더 진한 색 (버튼 눌렀을 때나 강조용 - 기존보다 살짝 어둡게 조정)
  static const Color primaryDark = Color(0xFF00B0FF); 
  
  // 연한 포인트 색 (배경이나 보조용)
  static const Color accent = Color(0xFF80EBFF); 
  
  // 온도 색상 (차가움/따뜻함)
  static const Color cold = Color(0xFFB3E5FC); // 36.5도 미만 (차가움)
  static const Color warm = Colors.orangeAccent; // 36.5도 이상 (따뜻함)
}
