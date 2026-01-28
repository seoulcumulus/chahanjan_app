import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:ui' as ui;
import 'dart:typed_data';

// 👇 다른 화면들 임포트
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'chat_list_screen.dart'; // 채팅 목록 화면 (만드셨다면)
import '../utils/app_strings.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 1. 지도 컨트롤러
  GoogleMapController? _mapController;
  
  // 2. 내 위치 및 마커 상태
  Position? _currentPosition;
  Set<Marker> _markers = {};
  String _currentAvatar = 'rat.png'; // 현재 아바타 (변화 감지용)
  BitmapDescriptor? _myMarkerIcon; // 변환된 마커 아이콘

  final Color _signatureColor = const Color(0xFF24FCFF);

  @override
  void initState() {
    super.initState();
    _determinePosition(); // 시작하자마자 위치 찾기
  }

  // 📍 (핵심) 이미지를 지도 마커로 변환하는 함수 (천사링/날개 이펙트 추가!)
  Future<void> _updateMarkerIcon(String avatarName, double mannerTemp) async {
    // mannerTemp: 매너 온도 (기본 36.5)
    
    try {
      // 1. 기본 이미지 로드
      final ByteData data = await rootBundle.load('assets/avatars/$avatarName');
      final ui.Codec codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 150 // 이미지 크기
      );
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;

      // 2. 캔버스 준비 (이펙트 그리기 위해 공간 확보)
      final int size = 220; // 전체 마커 크기 (이펙트 포함)
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      final double center = size / 2.0;
      
      // 3. 이펙트 그리기 로직
      final Paint glowPaint = Paint()
        ..color = _signatureColor.withOpacity(0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15); // 빛나는 효과

      final Paint ringPaint = Paint()
        ..color = _signatureColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;

      // 🔥 85도 이상: 천사 날개 (뒤쪽에 그리기)
      if (mannerTemp >= 85) {
         final Path wingPath = Path();
         // 왼쪽 날개
         wingPath.moveTo(center - 40, center);
         wingPath.quadraticBezierTo(center - 100, center - 80, center - 60, center + 20);
         // 오른쪽 날개
         wingPath.moveTo(center + 40, center);
         wingPath.quadraticBezierTo(center + 100, center - 80, center + 60, center + 20);
         
         canvas.drawPath(wingPath, glowPaint..style = PaintingStyle.fill);
      }

      // ✨ 70도 이상: 천사 링 (후광)
      if (mannerTemp >= 70) {
        canvas.drawCircle(Offset(center, center), 65, glowPaint); // 빛
        canvas.drawCircle(Offset(center, center), 60, ringPaint); // 링 테두리
      }

      // 4. 캐릭터 얼굴 그리기 (중앙)
      // 이미지를 원형으로 클리핑해서 그림
      final Path clipPath = Path()..addOval(Rect.fromCircle(center: Offset(center, center), radius: 50));
      canvas.clipPath(clipPath);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(center - 50, center - 50, 100, 100), // 중앙 위치
        Paint(),
      );

      // 5. 마커 아이콘 생성 완료
      final ui.Image finalImage = await pictureRecorder.endRecording().toImage(size, size);
      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List markerIcon = byteData!.buffer.asUint8List();

      final BitmapDescriptor newIcon = BitmapDescriptor.fromBytes(markerIcon);

      setState(() {
        _currentAvatar = avatarName;
        _myMarkerIcon = newIcon;
      });
      _updateMyMarker();

    } catch (e) {
      print("❌ 마커 생성 오류: $e");
    }
  }

  // 📍 마커를 지도에 찍는 함수
  void _updateMyMarker() {
    if (_currentPosition == null) return;

    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          // 아이콘이 준비되었으면 내 캐릭터, 아니면 기본 핀
          icon: _myMarkerIcon ?? BitmapDescriptor.defaultMarker, 
          infoWindow: const InfoWindow(title: "나"),
        ),
      };
    });
  }

  // 📍 내 위치 가져오기 (권한 체크 포함)
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. GPS 켜져 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("❌ GPS가 꺼져 있습니다.");
      return;
    }

    // 2. 권한 확인 및 요청
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // 3. 위치 가져오기
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    
    setState(() {
      _currentPosition = position;
      _updateMyMarker(); // 위치 찾으면 마커 찍기
    });

    // 4. 지도 카메라 이동 (처음 한 번만)
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        children: [
          // 📡 1. 실시간 사용자 정보 감지 (아바타 변경 시 즉시 반영)
          if (user != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                // 데이터가 들어오면 마커 아이콘 업데이트 시도
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final String avatar = data['avatar_image'] ?? 'rat.png';
                  final double mannerTemp = (data['manner_temp'] ?? 36.5).toDouble(); // 매너 온도 가져오기
                  
                  // 아바타가 바뀌었으면 마커 아이콘 새로 만들기
                  if (avatar != _currentAvatar || _myMarkerIcon == null) {
                    _updateMarkerIcon(avatar, mannerTemp);
                  }
                }
                return const SizedBox.shrink(); // 화면에는 아무것도 안 그림 (감시만 함)
              },
            ),

          // 🗺️ 2. 구글 지도
          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              // 지도가 다 만들어지면 내 스타일 적용 + 위치 이동
              if (_currentPosition != null) {
                 controller.animateCamera(CameraUpdate.newLatLngZoom(
                   LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 17
                 ));
              }
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.5665, 126.9780), // 서울 기본값
              zoom: 16,
            ),
            markers: _markers, // 👈 내 12지신 마커가 여기 들어감
            myLocationEnabled: true, // 파란 점 표시 (보조용)
            myLocationButtonEnabled: false, // 기본 버튼 끄기 (우리가 만든 거 쓸 거임)
            zoomControlsEnabled: false,
          ),

          // 🟢 3. 좌측 상단 프로필 버튼 (내 얼굴)
          StreamBuilder<DocumentSnapshot>(
            stream: user != null 
              ? FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots()
              : null,
            builder: (context, snapshot) {
              String myAvatar = 'rat.png';
              if (snapshot.hasData && snapshot.data!.exists) {
                myAvatar = snapshot.data!['avatar_image'] ?? 'rat.png';
              }
              return Positioned(
                top: 50, left: 20,
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
                  child: Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _signatureColor, width: 3),
                      color: Colors.white,
                      image: DecorationImage(
                        image: AssetImage('assets/avatars/$myAvatar'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6, offset: const Offset(2, 2))],
                    ),
                  ),
                ),
              );
            },
          ),

          // 🔵 4. 우측 상단 버튼들 (상점, 채팅 등)
          Positioned(
            top: 50, right: 20,
            child: Column(
              children: [
                // 상점 버튼
                FloatingActionButton.small(
                  heroTag: 'shop',
                  backgroundColor: Colors.white,
                  child: const Text("🍵", style: TextStyle(fontSize: 20)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
                ),
                const SizedBox(height: 10),
                // 채팅 목록 버튼 (구현하셨다면 연결)
                FloatingActionButton.small(
                  heroTag: 'chat',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                  onPressed: () {
                    // Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
                  },
                ),
              ],
            ),
          ),

          // 📍 5. 내 위치 찾기 버튼 (수리 완료!)
          Positioned(
            bottom: 30, right: 20,
            child: FloatingActionButton(
              heroTag: 'my_loc_fix',
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: _signatureColor),
              onPressed: () async {
                print("🎯 내 위치 버튼 클릭됨!");
                
                // 1. 지도 컨트롤러 체크
                if (_mapController == null) {
                  print("⚠️ 지도 컨트롤러가 아직 로딩 중입니다.");
                  return;
                }

                try {
                  // 2. 권한 및 위치 다시 확인 (확실하게!)
                  LocationPermission permission = await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.denied) return;
                  }

                  // 3. 현재 위치 겟!
                  Position position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high
                  );

                  print("✅ 위치 이동: ${position.latitude}, ${position.longitude}");
                  
                  // 4. 카메라 부드럽게 이동
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(position.latitude, position.longitude),
                      18, // 줌 레벨 (가깝게)
                    ),
                  );

                  // 5. 마커도 같이 업데이트
                  setState(() {
                    _currentPosition = position;
                    _updateMyMarker();
                  });

                } catch (e) {
                  print("❌ 위치 이동 실패: $e");
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("위치 오류: $e")));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
