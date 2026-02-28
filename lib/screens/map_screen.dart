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
import '../widgets/profile_card.dart'; // 👈 프로필 카드 위젯
import 'chat_screen.dart'; // [추가] 채팅 화면
import '../utils/app_strings.dart';
import '../utils/translations.dart'; // [추가] 번역 파일
import '../services/user_service.dart'; // [추가]
import '../utils/marker_generator.dart'; // [추가] MarkerGenerator

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 서비스 인스턴스
  final UserService _userService = UserService(); // [추가]

  final Color _signatureColor = const Color(0xFF24FCFF);
  final Color _holyGold = const Color(0xFFD4AF37);
  final Color _holyPurple = const Color(0xFF2E003E);

  // 1. 지도 컨트롤러
  GoogleMapController? _mapController;
  
  // 2. 내 위치 및 마커 상태
  Position? _currentPosition;
  LatLng? _myPosition; // [추가] 가짜 위치 (마커용)

  // 1. 🟢 내 마커 (내 아바타 전용)
  Set<Marker> _myMarker = {}; 

  // 2. 🔵 남의 마커들 (검색된 유저 전용)
  Map<String, Marker> _otherMarkers = {};
  Set<Circle> _circles = {}; // 1. 원(Circle)을 관리할 변수 선언
  double _currentRadius = 5000.0; // 현재 반경 (기본값 5000m)
  String _currentAvatar = 'rat.png'; // 현재 아바타 (변화 감지용)
  BitmapDescriptor? _myMarkerIcon; // 변환된 마커 아이콘
  bool _isFirstLoad = true; // [추가] 처음 실행 여부 확인용

  // ⚡ 현재 애니메이션이 진행 중인지 체크하는 변수
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // 시작하자마자 위치 찾기
    _loadMyAvatarMarker(); // 👈 [추가] 내 아바타 불러오기 시작!
  }

  // 🎨 [추가] 파이어베이스에서 내 정보 가져와서 마커 만들기
  Future<void> _loadMyAvatarMarker() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();

      if (data != null) {
        final String avatar = data['avatar_image'] ?? 'rat.png'; // 지도 마커용 캐릭터
        final double mannerTemp = (data['manner_temp'] ?? 36.5).toDouble(); // 매너 온도 가져오기

        // 🌟 [수정] MarkerGenerator.createMyMarker 대신 local _createAvatarMarker 사용 (매너온도 효과 포함)
        final icon = await _createAvatarMarker(avatar, mannerTemp);

        if (mounted) {
          setState(() {
            _myMarkerIcon = icon; 
          });
          _updateMyMarker();
        }
      }
    } catch (e) {
      print("내 아바타 마커 로드 실패: $e");
    }
  }

  // 🎨 [업그레이드] 8방향 이미지를 1장으로 자르고 매너온도 효과를 주는 마커 함수
  Future<BitmapDescriptor> _createAvatarMarker(String avatarName, double temp) async {
    try {
      // 1. 이미지 로드
      final ByteData data = await rootBundle.load('assets/avatars/$avatarName');
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo fi = await codec.getNextFrame();
      final ui.Image image = fi.image;

      // 2. 캔버스 준비
      final double size = 150.0;
      final double extraTop = 40.0; // 머리 위 여유 공간
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder, Rect.fromPoints(const Offset(0, 0), Offset(size, size + extraTop)));
      
      final double radius = size / 2;
      final Offset center = Offset(radius, radius + extraTop);

      // 3. 원형 클리핑 적용
      final Path clipPath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
      canvas.clipPath(clipPath);

      // 🌟 [핵심] 8방향 스프라이트 시트에서 정면 1칸만 정확히 잘라내기!
      bool is25D = !avatarName.startsWith('snake') && !avatarName.startsWith('avatar');
      
      // 원본에서 가져올 영역의 가로/세로 길이 (2.5D면 4등분/2등분, 아니면 전체)
      double srcWidth = is25D ? image.width / 4 : image.width.toDouble();
      double srcHeight = is25D ? image.height / 2 : image.height.toDouble();

      // srcRect: 원본 이미지에서 어디를 자를 것인가 (0, 0 위치부터 1칸 크기만큼)
      Rect srcRect = Rect.fromLTWH(0, 0, srcWidth, srcHeight);
      
      // dstRect: 캔버스에서 어디에 그릴 것인가 (원형 마커 크기에 맞춤)
      Rect dstRect = Rect.fromCircle(center: center, radius: radius);

      // 캔버스에 잘라낸 이미지를 그립니다.
      canvas.drawImageRect(image, srcRect, dstRect, Paint());

      // 4. 테두리 (기본 민트색)
      final Paint borderPaint = Paint()
        ..color = const Color(0xFF24FCFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0;
      canvas.drawCircle(center, radius - 4, borderPaint);

      // 👑 5. 왕관 그리기 (85도 이상)
      if (temp >= 85.0) {
        final Paint crownPaint = Paint()..color = const Color(0xFFFFD700);
        final Path crownPath = Path();
        double cw = 60, ch = 40, cx = center.dx, cy = center.dy - radius + 10;

        crownPath.moveTo(cx - cw/2, cy); 
        crownPath.lineTo(cx - cw/2, cy - ch); 
        crownPath.lineTo(cx - cw/4, cy - ch/2); 
        crownPath.lineTo(cx, cy - ch - 10); 
        crownPath.lineTo(cx + cw/4, cy - ch/2); 
        crownPath.lineTo(cx + cw/2, cy - ch); 
        crownPath.lineTo(cx + cw/2, cy); 
        crownPath.close();
        canvas.drawPath(crownPath, crownPaint);
      } 
      // 😇 6. 천사 링 그리기 (70도 이상)
      else if (temp >= 70.0) {
        final Paint haloPaint = Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0;
        canvas.drawOval(Rect.fromCenter(center: Offset(center.dx, center.dy - radius - 10), width: 80, height: 20), haloPaint);
      }

      // 7. 이미지 생성 및 반환
      final ui.Image markerImage = await pictureRecorder.endRecording().toImage(size.toInt(), (size + extraTop).toInt());
      final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());

    } catch (e) {
      print("❌ 마커 생성 오류: $e");
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
  }

  // 📍 마커를 지도에 찍는 함수
  void _updateMyMarker() {
    if (_myPosition == null && _currentPosition == null) return;

    final targetPos = _myPosition ?? LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    if (mounted) {
      setState(() {
        _myMarker = {
          Marker(
            markerId: const MarkerId('me'),
            position: targetPos,
            icon: _myMarkerIcon ?? BitmapDescriptor.defaultMarker, 
            infoWindow: const InfoWindow(title: "나"),
          ),
        };
      });
    }
  }

  // 2. 위치가 업데이트될 때마다 원을 새로 그리는 함수
  void _updateMyRadiusCircle(LatLng myPosition, Color signatureColor) {
    if (mounted) {
      setState(() {
        _circles = {
          Circle(
            circleId: const CircleId('my_radius'),
            center: myPosition,
            radius: _currentRadius, 
            fillColor: Colors.transparent, 
            strokeColor: signatureColor,   
            strokeWidth: 3,
          ),
        };
      });
    }
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
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    double offset = 0.005; 
    double publicLat = position.latitude + offset;  
    double publicLng = position.longitude + offset; 

    if (mounted) {
      setState(() {
        _currentPosition = position; 
        _myPosition = LatLng(publicLat, publicLng); 
        _updateMyMarker(); 
        _updateMyRadiusCircle(LatLng(position.latitude, position.longitude), _signatureColor);
      });
    }

    _updateUserLocation(publicLat, publicLng);
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
    );

    if (_isFirstLoad) {
      _searchNearbyUsers(); 
      _isFirstLoad = false;
    }
  }

  // 🔘 버튼 눌렀을 때 실행되는 함수
  Future<void> _onSearchPressed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool success = await _userService.deductTeaLeaf(user.uid);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.t('search_start'))),
        );
      }
      _searchNearbyUsers(isPaid: true); 
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocale.t('tea_low'))),
        );
      }
    }
  }

  // 🌟 [추가] 스프라이트를 안전하게 1칸만 잘라 보여주는 헬퍼 함수
  Widget _buildStaticSprite(String fileName, double size) {
    bool is25D = !fileName.startsWith('snake') && !fileName.startsWith('avatar');
    
    if (!is25D) {
      return Image.asset(
        'assets/avatars/$fileName',
        width: size, height: size, fit: BoxFit.cover,
        errorBuilder: (_,__,___)=>const Icon(Icons.person, color: Colors.grey),
      );
    }
    
    return SizedBox(
      width: size, height: size,
      child: ClipRect(
        child: OverflowBox(
          minWidth: size * 4, maxWidth: size * 4,
          minHeight: size * 2, maxHeight: size * 2,
          alignment: Alignment.topLeft, 
          child: Image.asset(
            'assets/avatars/$fileName',
            fit: BoxFit.fill,
            errorBuilder: (_,__,___)=>const Icon(Icons.person, color: Colors.grey)
          ),
        ),
      ),
    );
  }

  // 🚀 채팅방으로 이동
  void _navigateToChat(String peerId, String peerNickname, String peerAvatar) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    // 🌟 [수정] ID 형식을 _로 통일 (기존 -에서 변경)
    final chatId = myUid.hashCode <= peerId.hashCode 
        ? '${myUid}_$peerId' 
        : '${peerId}_$myUid';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          chatRoomId: chatId,
          peerUid: peerId,
          peerNickname: peerNickname,
          peerAvatar: peerAvatar,
        ),
      ),
    );
  }

  // 🚀 대화 요청하기 버튼을 눌렀을 때 실행될 함수 (부활 기능 포함)
  Future<void> _requestChat(String peerId, String peerNickname, String peerAvatar) async {
    final String? myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null || myUid == peerId) return;

    // 1. 방 ID 생성 (항상 같은 ID가 되도록 정렬하여 조합)
    final String roomId = myUid.hashCode <= peerId.hashCode 
        ? '${myUid}_$peerId' 
        : '${peerId}_$myUid';

    final roomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(roomId);

    try {
      final roomDoc = await roomRef.get();
      bool roomExists = roomDoc.exists;
      bool isDeletedByMe = false;

      if (roomExists) {
        final roomData = roomDoc.data() as Map<String, dynamic>;
        List<dynamic> leftBy = roomData['left_by'] ?? [];
        isDeletedByMe = leftBy.contains(myUid);

        // 방이 살아있고 내가 지운 적도 없다면, 중복 요청 방지
        if (!isDeletedByMe && roomData['status'] == 'pending') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이미 수락을 대기 중인 상태입니다!")));
          }
          return;
        } else if (!isDeletedByMe && roomData['status'] == 'active') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("이미 대화 중인 상대입니다! 목록을 확인하세요.")));
          }
          return;
        }
      }

      // 3. 찻잎 차감 확인 (UserService 활용)
      bool success = await _userService.deductTeaLeaf(myUid);

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("찻잎이 부족합니다! 🍵")),
          );
        }
        return;
      }

      // 4. 채팅방 생성 또는 부활(업데이트) 로직
      if (!roomExists) {
        // 아예 처음 대화하는 경우 -> 새 방 생성
        await roomRef.set({
          'roomId': roomId,
          'participants': [myUid, peerId],
          'status': 'pending', // 수락 대기 상태
          'left_by': [],       // 나간 사람 없음
          'lastMessage': '대화 요청이 도착했습니다.',
          'updatedAt': FieldValue.serverTimestamp(), // [수정] 필드명 통일
          'createdAt': FieldValue.serverTimestamp(),
          'initiatorId': myUid,
        });
      } else if (isDeletedByMe) {
        // 내가 지웠던 방인 경우 -> left_by 배열에서 나를 빼고, 상태를 다시 pending으로!
        await roomRef.update({
          'left_by': FieldValue.arrayRemove([myUid]), // 나간 기록 삭제 (부활)
          'status': 'pending', // 다시 수락 대기 상태로
          'lastMessage': '대화를 다시 요청했습니다.',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("대화 요청 완료! 찻잎 1개가 소모되었습니다. 🍵")),
        );
      }

    } catch (e) {
      print("대화 요청 에러: $e");
    }
  }

  // 🔍 주변 실유저 찾기
  Future<void> _searchNearbyUsers({bool isPaid = false}) async {
    if (_currentPosition == null) return;
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    if (isPaid && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocale.t('search_start'))));
    }

    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
      Map<String, Marker> realUserMarkers = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String uid = doc.id;

        if (uid == myUid) continue; 
        if (data['location'] == null) continue; 

        final GeoPoint userGeo = data['location'];
        double distance = Geolocator.distanceBetween(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
          userGeo.latitude,
          userGeo.longitude,
        );

        if (distance <= _currentRadius) {
          final String nickname = data['nickname'] ?? '알 수 없음';
          final String avatar = data['avatar_image'] ?? 'rat.png'; 
          
          final String assetPath = 'assets/avatars/$avatar';

          BitmapDescriptor initialIcon = await MarkerGenerator.create25DMarkerBitmap(assetPath, nickname, 0);

          realUserMarkers[uid] = Marker(
            markerId: MarkerId(uid),
            position: LatLng(userGeo.latitude, userGeo.longitude),
            icon: initialIcon, 
            onTap: () async {
              await _animateMarkerRotation(uid, LatLng(userGeo.latitude, userGeo.longitude), avatar, nickname, data);
              if (mounted) {
                _showUserProfileDialog(uid, nickname, avatar, data);
              }
            },
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

  // 🔄 마커 회전 애니메이션
  Future<void> _animateMarkerRotation(String userId, LatLng position, String avatarName, String nickname, Map<String, dynamic> data) async {
    if (_isAnimating) return; 
    _isAnimating = true;

    String assetPath = 'assets/avatars/$avatarName';

    for (int currentFrame = 1; currentFrame <= 8; currentFrame++) {
      if (!mounted) break; 

      int frameIndex = currentFrame % 8; 
      BitmapDescriptor newIcon = await MarkerGenerator.create25DMarkerBitmap(assetPath, nickname, frameIndex);
      
      _updateMarkerOnMap(userId, position, newIcon, avatarName, nickname, data);
      await Future.delayed(const Duration(milliseconds: 100)); 
    }

    _isAnimating = false; 
  }

  // 🗺️ 지도 위의 마커 업데이트
  void _updateMarkerOnMap(String userId, LatLng position, BitmapDescriptor icon, String avatarName, String nickname, Map<String, dynamic> data) {
    if (!mounted) return;

    setState(() {
      _otherMarkers[userId] = Marker(
        markerId: MarkerId(userId),
        position: position,
        icon: icon,
        anchor: const Offset(0.5, 0.9), 
        onTap: () async { 
          await _animateMarkerRotation(userId, position, avatarName, nickname, data);
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
             _showUserProfileDialog(userId, nickname, avatarName, data);
          }
        },
      );
    });
  }

  void _showUserProfileDialog(String uid, String nickname, String avatar, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent, 
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileCard(uid: uid, data: data),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); 
                  _requestChat(uid, nickname, avatar); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF24FCFF), 
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.chat_bubble),
                label: const Text("대화 요청하기 (1🍵)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    Set<Marker> myMarkerSet = {};
    if (_currentPosition != null && _myMarkerIcon != null) {
      myMarkerSet.add(
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          icon: _myMarkerIcon!, 
          zIndex: 2, 
          infoWindow: const InfoWindow(title: "나 (Me)"),
          anchor: const Offset(0.5, 0.5), 
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          if (user != null)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final String avatar = data['avatar_image'] ?? 'rat.png';
                  
                  if (avatar != _currentAvatar) {
                    _currentAvatar = avatar;
                    _loadMyAvatarMarker(); 
                  }
                }
                return const SizedBox.shrink(); 
              },
            ),

          GoogleMap(
            onMapCreated: (controller) {
              _mapController = controller;
              if (_currentPosition != null) {
                 controller.animateCamera(CameraUpdate.newLatLngZoom(
                   LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 17
                 ));
              }
            },
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.5665, 126.9780), 
              zoom: 16,
            ),
            markers: _otherMarkers.values.toSet().union(myMarkerSet),
            circles: _circles, 
            myLocationEnabled: false, 
            myLocationButtonEnabled: false, 
            zoomControlsEnabled: false,
          ),

          if (user != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10, 
              left: 15,
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final String profileType = data['profile_type'] ?? 'avatar'; 
                  final String profileAvatar = data['profile_avatar'] ?? 'rat.png';
                  final String? profileImageUrl = data['profile_image_url'];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfileScreen()),
                      );
                    },
                    child: Container(
                      width: 55, height: 55,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: _holyGold, width: 2),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
                      ),
                      child: ClipOval(
                        child: profileType == 'photo' && profileImageUrl != null
                            ? Image.network(
                                profileImageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_,__,___)=>const Icon(Icons.person, color: Colors.grey),
                              )
                            : _buildStaticSprite(profileAvatar, 55), 
                      ),
                    ),
                  );
                },
              ),
            ),

          Positioned(
            top: 50, right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'shop',
                  backgroundColor: Colors.white,
                  child: const Text("🍵", style: TextStyle(fontSize: 20)),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShopScreen(
                    myInventory: [], 
                    onBuy: (item) {}, 
                  ))),
                ),
                const SizedBox(height: 10),
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

          Positioned(
            bottom: 180, right: 20,
            child: FloatingActionButton(
              heroTag: 'my_loc_fix',
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: _signatureColor),
              onPressed: () async {
                if (_mapController == null) return;
                try {
                  LocationPermission permission = await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.denied) return;
                  }
                  Position position = await Geolocator.getCurrentPosition(
                    desiredAccuracy: LocationAccuracy.high
                  );
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      LatLng(position.latitude, position.longitude),
                      18, 
                    ),
                  );
                  if (mounted) {
                    setState(() {
                      _currentPosition = position;
                      _updateMyMarker();
                      _updateMyRadiusCircle(LatLng(position.latitude, position.longitude), _signatureColor);
                    });
                  }
                } catch (e) {
                  print("❌ 위치 이동 실패: $e");
                }
              },
            ),
          ),

          Positioned(
            bottom: 250, right: 20, 
            child: FloatingActionButton(
              heroTag: 'search_users',
              backgroundColor: _signatureColor,
              child: const Icon(Icons.person_search, color: Colors.black),
              onPressed: _onSearchPressed,
            ),
          ),

          Positioned(
            bottom: 30, 
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9), 
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "${AppLocale.t('radius')}: ${(_currentRadius / 1000).toStringAsFixed(1)} km",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Slider(
                    value: _currentRadius,
                    min: 100.0,  
                    max: 5000.0, 
                    activeColor: _signatureColor, 
                    inactiveColor: Colors.grey[300],
                    label: "${(_currentRadius).toInt()}m",
                    divisions: 49, 
                    onChanged: (double newValue) {
                      if (mounted) {
                        setState(() {
                          _currentRadius = newValue; 
                          if (_currentPosition != null) {
                             _updateMyRadiusCircle(
                               LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 
                               _signatureColor
                             );
                          }
                        });
                      }
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
