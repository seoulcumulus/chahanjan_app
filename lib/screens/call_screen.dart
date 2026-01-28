// lib/screens/call_screen.dart
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'dart:math';

class CallScreen extends StatelessWidget {
  final String callID; // 통화 방 ID (채팅방 ID와 동일하게 사용)
  final String userID; // 내 유저 ID
  final String userName; // 내 닉네임

  const CallScreen({
    Key? key, 
    required this.callID, 
    required this.userID, 
    required this.userName
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ZegoUIKitPrebuiltCall(
      // 👇 ZEGOCLOUD 콘솔에서 받은 키
      appID: 1345883646, // ZEGOCLOUD AppID
      appSign: "f1c2863802a4e5b3a2c828dac46b4b3c55aa676c3fc7f9ecde6ddd95090046d8", // ZEGOCLOUD AppSign
      
      callID: callID,
      userID: userID,
      userName: userName,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(), // 1:1 영상통화 모드
    );
  }
}
