import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String nickname;
  final String gender;
  final int age;
  final String region; // "서울 강남구" (자동 입력됨)
  final double latitude; // 위도
  final double longitude; // 경도
  final String intro; // 한줄 소개
  final List<String> interests; // 관심사 태그 ['커피', '독서']
  final String photoUrl; // 이미지 주소 (또는 캐릭터 ID)
  final String? avatar3dUrl; // 3D 모델 주소 (GLB)

  UserModel({
    required this.uid,
    required this.email,
    required this.nickname,
    required this.gender,
    required this.age,
    required this.region,
    required this.latitude,
    required this.longitude,
    required this.intro,
    required this.interests,
    required this.photoUrl,
    this.avatar3dUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nickname': nickname,
      'gender': gender,
      'age': age,
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
      'intro': intro,
      'interests': interests,
      'photoUrl': photoUrl,
      'avatar3dUrl': avatar3dUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      nickname: map['nickname'] ?? '',
      gender: map['gender'] ?? '',
      age: map['age']?.toInt() ?? 0,
      region: map['region'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      intro: map['intro'] ?? '',
      interests: List<String>.from(map['interests'] ?? []),
      photoUrl: map['photoUrl'] ?? '',
      avatar3dUrl: map['avatar3dUrl'],
    );
  }
}
