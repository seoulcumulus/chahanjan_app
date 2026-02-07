import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart'; // rootBundle 사용

// 👇 다른 화면들 임포트
import 'profile_screen.dart';
import 'shop_screen.dart';
import 'chat_list_screen.dart'; // 채팅 목록 화면 (만드셨다면)
import 'chat_screen.dart'; // [추가] 채팅 화면
import '../utils/app_strings.dart';
import '../utils/translations.dart'; // [추가] 번역 파일
import '../services/user_service.dart'; // [추가]

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 서비스 인스턴스
  final UserService _userService = UserService(); // [추가]

  // 1. 지도 컨트롤러
  GoogleMapController? _mapController;
  
  // 2. 내 위치 및 마커 상태
  Position? _currentPosition;
  LatLng? _myPosition; // [추가] 가짜 위치 (마커용)

  
  // 1. 🟢 내 마커 (내 아바타 전용)
  Set<Marker> _myMarker = {}; 

  // 2. 🔵 남의 마커들 (검색된 유저 전용)
  Set<Marker> _otherMarkers = {};
  Set<Circle> _circles = {}; // 1. 원(Circle)을 관리할 변수 선언
  double _currentRadius = 5000.0; // 현재 반경 (기본값 5000m)
  String _currentAvatar = 'rat.png'; // 현재 아바타 (변화 감지용)
  BitmapDescriptor? _myMarkerIcon; // 변환된 마커 아이콘
  bool _isFirstLoad = true; // [추가] 처음 실행 여부 확인용

  final Color _signatureColor = const Color(0xFF24FCFF);

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 시작하자마자 위치 찾기
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
    if (_myPosition == null && _currentPosition == null) return;

    // 우선순위: 가짜 위치(_myPosition) > 진짜 위치(_currentPosition)
    // 아바타는 '가짜 위치'에 보여야 하니까요!
    final targetPos = _myPosition ?? LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    setState(() {
      _myMarker = {
        Marker(
          markerId: const MarkerId('me'),
          position: targetPos,
          // 아이콘이 준비되었으면 내 캐릭터, 아니면 기본 핀
          icon: _myMarkerIcon ?? BitmapDescriptor.defaultMarker, 
          infoWindow: const InfoWindow(title: "나"),
        ),
      };
    });
  }

  // 2. 위치가 업데이트될 때마다 원을 새로 그리는 함수
  void _updateMyRadiusCircle(LatLng myPosition, Color signatureColor) {
    setState(() {
      _circles = {
        Circle(
          circleId: const CircleId('my_radius'),
          center: myPosition,
          radius: _currentRadius, // [수정] 고정값 대신 변수 사용
          fillColor: Colors.transparent, // 투명 (지도 보임)
          strokeColor: signatureColor,   // 시그니처 컬러 테두리
          strokeWidth: 3,
        ),
      };
    });
  }

  // 📍 위치 정보 서버 전송 (가짜 위치 저장)
  void _updateUserLocation(double lat, double lng) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'location': GeoPoint(lat, lng), 
      'isOnline': true,
      'lastActive': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }



  // 📍 내 위치 가져오기 (보안 강화 버전)
  Future<void> _getCurrentLocation() async {
    // 1. 권한 확인 (기존과 동일)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    // 2. 진짜 내 위치 가져오기 (GPS)
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // 3. 🚨 [핵심] 강제로 위치 떼어놓기 (0.005도 = 약 500m ~ 700m 차이)
    // 랜덤 말고 고정값으로 더해서 확실하게 밀어버립니다.
    double offset = 0.005; 
    double publicLat = position.latitude + offset;  // 위로 500m 이동
    double publicLng = position.longitude + offset; // 오른쪽으로 500m 이동

    setState(() {
      // 👇 여기가 제일 중요합니다!
      // 지도의 중심은 '내 진짜 위치'로 잡고...
      _currentPosition = position; 

      // � 마커(아바타)는 '가짜 위치'에 찍어야 합니다!
      // 혹시 여기가 LatLng(position.latitude, position.longitude)로 되어 있지 않았나요?
      _myPosition = LatLng(publicLat, publicLng); 
      _updateMyMarker(); 
      _updateMyRadiusCircle(LatLng(position.latitude, position.longitude), _signatureColor);
    });

    // 4. 파이어베이스에 저장 (가짜 위치를 저장)
    _updateUserLocation(publicLat, publicLng);
    
    // 5. 카메라 이동 (내 진짜 위치와 가짜 위치 사이쯤을 비춤)
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );

    // 최초 1회 주변 검색 (기존 로직 유지)
    if (_isFirstLoad) {
      _searchNearbyUsers(); 
      _isFirstLoad = false;
    }
  }

  // 🔘 버튼 눌렀을 때 실행되는 함수
  Future<void> _onSearchPressed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. 찻잎 차감 시도
    bool success = await UserService().deductTeaLeaf(user.uid);

    if (success) {
      // ✅ 성공: 검색 시작
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.t('search_start'))),
        );
      }
      _searchNearbyUsers(isPaid: true); // (아까 만든 진짜 유저 검색 함수)
    } else {
      // ❌ 실패: 잔액 부족
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.t('tea_low'))),
        );
      }
    }
  }

  // 🚀 채팅방으로 이동
  void _navigateToChat(String peerId, String peerNickname, String peerAvatar) {
    // 채팅방 ID 만들기 (나_너 또는 너_나)
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    final chatId = myUid.hashCode <= peerId.hashCode 
        ? '$myUid-$peerId' 
        : '$peerId-$myUid';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: chatId,
          peerUid: peerId, // peerId 전달
          peerNickname: peerNickname,
          peerAvatar: peerAvatar, // 상대방 아바타 이미지 전달
        ),
      ),
    );
  }

  // 🍵 찻잎 1개 소모하고 채팅 시도
  Future<void> _onUserMarkerTapped(String peerId, String peerNickname, String peerAvatar) async {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;

    // 1. 찻잎 차감 시도
    bool success = await _userService.deductTeaLeaf(myUid);
    
    if (!success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("찻잎이 부족합니다! 🍵")),
        );
      }
      return;
    }

    // 2. 성공 시 채팅방 이동
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("찻잎 1개 소모! 채팅을 시작합니다. 🍵")),
      );
      _navigateToChat(peerId, peerNickname, peerAvatar);
    }
  }

  // 🔍 주변 실유저 찾기 (아바타 마커 적용 버전)
  Future<void> _searchNearbyUsers({bool isPaid = false}) async {
    if (_currentPosition == null) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    if (isPaid && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.t('search_start'))));
    }

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
      Set<Marker> realUserMarkers = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String uid = doc.id;

        if (uid == myUid) continue; // 나 제외
        if (data['location'] == null) continue; // 위치 없으면 제외

        final GeoPoint userGeo = data['location'];
        double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          userGeo.latitude,
          userGeo.longitude,
        );

        // 반경 체크
        if (distance <= _currentRadius) {
          final String nickname = data['nickname'] ?? '알 수 없음';
          final String avatar = data['avatar_image'] ?? 'rat.png'; // DB에 저장된 아바타 파일명
          final double temp = (data['manner_temp'] ?? 36.5).toDouble(); // 매너 온도 가져오기

          // 🌟 [핵심] 아바타 이미지를 마커 아이콘으로 변환! (온도 포함)
          final BitmapDescriptor customIcon = await _createAvatarMarker(avatar, temp);

          realUserMarkers.add(
            Marker(
              markerId: MarkerId(uid),
              position: LatLng(userGeo.latitude, userGeo.longitude),
              icon: customIcon, // 👈 여기가 핀 대신 얼굴 아이콘으로 바뀜!
              infoWindow: InfoWindow(
                title: nickname,
                snippet: "${distance.toInt()}m 👋",
                onTap: () => _onUserMarkerTapped(uid, nickname, avatar),
              ),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _otherMarkers = realUserMarkers;
        });
      }

    } catch (e) {
      print("❌ 유저 검색 오류: $e");
    }
  }

  // 🎨 [추가] 아바타 이미지를 지도 마커 아이콘으로 변환하는 함수
  // 🎨 [업그레이드] 매너 온도에 따라 왕관/링을 그려주는 마커 함수
  Future<BitmapDescriptor> _createAvatarMarker(String avatarName, double temp) async {
    try {
      // 1. 이미지 로드
      final ByteData data = await rootBundle.load('assets/avatars/$avatarName');
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: 150);
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;

      // 2. 캔버스 준비 (왕관 그릴 공간을 위해 높이를 좀 더 크게 잡음)
      final double size = 150.0;
      final double extraTop = 40.0; // 머리 위 여유 공간
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      
      // 캔버스 크기: 가로 150, 세로 190 (머리 위 장식 포함)
      final Canvas canvas = Canvas(pictureRecorder, Rect.fromPoints(Offset(0, 0), Offset(size, size + extraTop)));
      
      final double radius = size / 2;
      final Offset center = Offset(radius, radius + extraTop); // 아바타의 중심점 (y좌표를 내림)

      // 3. 아바타 그리기 (원형 클리핑)
      final Path clipPath = Path()
        ..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.clipPath(clipPath);
      
      paintImage(
        canvas: canvas,
        rect: Rect.fromCircle(center: center, radius: radius),
        image: image,
        fit: BoxFit.cover,
      );

      // 🌟 [핵심] 매너 온도에 따른 장식 그리기
      // 클리핑을 해제하기 위해 복구하지 않고, 원 위에 덧그립니다.
      // (단, canvas.clipPath가 적용된 상태라 덧그리기가 잘릴 수 있으므로 
      //  실제로는 clipPath 전에 그리거나, 별도의 레이어 처리가 필요하지만
      //  간단하게 테두리(Stroke) 기능을 이용해 효과를 줍니다.)

      // 4. 테두리 (기본 민트색)
      final Paint borderPaint = Paint()
        ..color = const Color(0xFF24FCFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0;
      
      canvas.drawCircle(center, radius - 4, borderPaint);

      // 👑 5. 왕관 그리기 (85도 이상)
      if (temp >= 85.0) {
        final Paint crownPaint = Paint()..color = const Color(0xFFFFD700); // 골드
        final Path crownPath = Path();
        
        // 왕관 좌표 (머리 위)
        double cw = 60; // 왕관 너비
        double ch = 40; // 왕관 높이
        double cx = center.dx;
        double cy = center.dy - radius + 10; // 머리 꼭대기

        crownPath.moveTo(cx - cw/2, cy); // 왼쪽 아래
        crownPath.lineTo(cx - cw/2, cy - ch); // 왼쪽 위
        crownPath.lineTo(cx - cw/4, cy - ch/2); // 왼쪽 골
        crownPath.lineTo(cx, cy - ch - 10); // 가운데 뾰족
        crownPath.lineTo(cx + cw/4, cy - ch/2); // 오른쪽 골
        crownPath.lineTo(cx + cw/2, cy - ch); // 오른쪽 위
        crownPath.lineTo(cx + cw/2, cy); // 오른쪽 아래
        crownPath.close();

        canvas.drawPath(crownPath, crownPaint);
      } 
      // 😇 6. 천사 링 그리기 (70도 이상)
      else if (temp >= 70.0) {
        final Paint haloPaint = Paint()
          ..color = const Color(0xFFFFD700) // 골드
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0;
        
        // 머리 위에 타원 그리기
        canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, center.dy - radius - 10), width: 80, height: 20),
          haloPaint
        );
      }

      // 7. 이미지 생성
      final ui.Image markerImage = await pictureRecorder.endRecording().toImage(size.toInt(), (size + extraTop).toInt());
      final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());

    } catch (e) {
      print("❌ 마커 생성 오류: $e");
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
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
            markers: _myMarker.union(_otherMarkers), // 👈 내 마커 + 남의 마커 합쳐서 표시
            circles: _circles, // 3. 위에서 만든 원 세트 연결
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
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(
                    myInventory: [], // 임시 빈 목록
                    onBuy: (item) {}, // 임시 빈 함수
                  ))),
                ),
                const SizedBox(height: 10),
                // 채팅 목록 버튼
                FloatingActionButton.small(
                  heroTag: 'chat',
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.chat_bubble_outline, color: Colors.black),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
                  },
                ),
              ],
            ),
          ),

          // 📍 5. 내 위치 찾기 버튼 (슬라이더 위로 이동)
          Positioned(
            bottom: 180, right: 20,
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
                    _updateMyRadiusCircle(LatLng(position.latitude, position.longitude), _signatureColor); // 원 그리기 추가
                  });

                } catch (e) {
                  print("❌ 위치 이동 실패: $e");
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("위치 오류: $e")));
                }
              },
            ),
          ),

          // 🔍 7. 유저 검색 버튼 (내 위치 버튼 위에 배치)
          Positioned(
            bottom: 250, right: 20, 
            child: FloatingActionButton(
              heroTag: 'search_users',
              backgroundColor: _signatureColor,
              child: const Icon(Icons.person_search, color: Colors.black),
              onPressed: _onSearchPressed,
            ),
          ),

          // 📏 6. 하단 슬라이더 컨트롤러 (지도 위에 겹침)
          Positioned(
            bottom: 30, // 하단에서 30만큼 띄움
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9), // 반투명 흰색 배경
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 현재 설정된 거리 텍스트 표시 (예: 2.5 km)
                  Text(
                    "${AppLocale.t('radius')}: ${(_currentRadius / 1000).toStringAsFixed(1)} km",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  
                  // 슬라이더 위젯
                  Slider(
                    value: _currentRadius,
                    min: 100.0,  // 최소 100미터
                    max: 5000.0, // 최대 5키로미터
                    activeColor: _signatureColor, // 시그니처 컬러 사용
                    inactiveColor: Colors.grey[300],
                    label: "${(_currentRadius).toInt()}m",
                    divisions: 49, // 100m 단위로 딱딱 끊어지게 하려면 설정 (선택사항)
                    onChanged: (double newValue) {
                      setState(() {
                        _currentRadius = newValue; // 1. 값 변경
                        
                        // 2. 지도 위의 원 크기 즉시 업데이트
                        if (_currentPosition != null) {
                           _updateMyRadiusCircle(
                             LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 
                             _signatureColor
                           );
                        }
                      });
                    },
                    onChangeEnd: (double newValue) {
                      // 3. 슬라이더를 놓았을 때 유저 검색 실행 (성능 최적화)
                      // _findUsersInRadius(); 
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
