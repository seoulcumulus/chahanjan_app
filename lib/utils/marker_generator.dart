import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart'; // rootBundle 사용을 위해 추가
import 'dart:typed_data';

class MarkerGenerator {
  // ⚡ 성능 최적화: 한 번 불러온 이미지는 메모리에 저장해두고 재사용 (버벅임 방지)
  static final Map<String, ui.Image> _imageCache = {};

  static Future<ui.Image> _loadImage(String assetPath) async {
    if (_imageCache.containsKey(assetPath)) {
      return _imageCache[assetPath]!;
    }
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo fi = await codec.getNextFrame();
    _imageCache[assetPath] = fi.image;
    return fi.image;
  }

  // 🎨 1. 기존 기능: 이모지와 닉네임을 마커로 변환 (필요시 유지)
  static Future<BitmapDescriptor> createCustomMarkerBitmap(String emoji, String nickname) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // 마커 크기 설정
    const double size = 180.0; // 캔버스 전체 크기
    const double circleRadius = 50.0;
    
    // 1. 닉네임 태그 (알약 모양) 그리기
    final Paint tagPaint = Paint()..color = Colors.white;
    final Paint shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    const double tagWidth = 140.0;
    const double tagHeight = 40.0;
    final RRect tagRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(size / 2, size - 30), width: tagWidth, height: tagHeight),
      const Radius.circular(20),
    );

    // 그림자 -> 흰 배경 순서로 그림
    canvas.drawRRect(tagRRect.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawRRect(tagRRect, tagPaint);

    // 2. 닉네임 글자 쓰기
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: nickname.length > 5 ? "${nickname.substring(0, 5)}.." : nickname, // 너무 길면 자름
      style: const TextStyle(fontSize: 20.0, color: Colors.black, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size - textPainter.width) / 2, size - 48));

    // 3. 동그란 아바타 배경 (흰색 테두리 + 그림자)
    final Offset circleCenter = Offset(size / 2, size / 2 - 20);
    canvas.drawCircle(circleCenter + const Offset(0, 3), circleRadius, shadowPaint); // 그림자
    canvas.drawCircle(circleCenter, circleRadius, Paint()..color = Colors.white); // 흰 배경
    
    // 4. 이모지 그리기
    textPainter.text = TextSpan(text: emoji, style: const TextStyle(fontSize: 60.0));
    textPainter.layout();
    textPainter.paint(canvas, Offset(circleCenter.dx - (textPainter.width / 2), circleCenter.dy - (textPainter.height / 1.6)));

    // 이미지로 변환
    final ui.Image image = await pictureRecorder.endRecording().toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  // 🚀 2. 신규 기능: 2.5D 캐릭터(8방향) + 닉네임 마커 생성
  static Future<BitmapDescriptor> create25DMarkerBitmap(String assetPath, String nickname, int directionIndex) async {
    // 1. 전체 스프라이트 시트 이미지 불러오기 (캐시 활용)
    final ui.Image spriteSheet = await _loadImage(assetPath);

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // 2. 이미지 8등분 자르기 로직 (가로 4칸, 세로 2줄 기준)
    final double frameWidth = spriteSheet.width / 4;
    final double frameHeight = spriteSheet.height / 2;

    final int col = directionIndex % 4; // 열 (0, 1, 2, 3)
    final int row = directionIndex ~/ 4; // 행 (0, 1)

    // 원본 이미지에서 잘라낼 특정 프레임 영역
    final Rect srcRect = Rect.fromLTWH(col * frameWidth, row * frameHeight, frameWidth, frameHeight);

    // 3. 캔버스(최종 마커) 크기 설정
    const double markerWidth = 180.0;
    const double markerHeight = 220.0; // 아바타 비율을 위해 세로를 좀 더 길게
    const double avatarSize = 150.0;   // 그려질 캐릭터의 크기

    // 캔버스 중앙 상단에 캐릭터를 그릴 영역 지정
    final Rect dstRect = Rect.fromLTWH((markerWidth - avatarSize) / 2, 0, avatarSize, avatarSize);

    // 선택한 방향의 캐릭터 프레임을 캔버스에 그리기
    canvas.drawImageRect(spriteSheet, srcRect, dstRect, Paint());

    // 4. 닉네임 태그 그리기 (기존 로직 활용)
    final Paint tagPaint = Paint()..color = Colors.white;
    final Paint shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    const double tagWidth = 140.0;
    const double tagHeight = 40.0;
    final RRect tagRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: const Offset(markerWidth / 2, markerHeight - 25), width: tagWidth, height: tagHeight),
      const Radius.circular(20),
    );

    canvas.drawRRect(tagRRect.shift(const Offset(0, 3)), shadowPaint);
    canvas.drawRRect(tagRRect, tagPaint);

    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: nickname.length > 5 ? "${nickname.substring(0, 5)}.." : nickname,
      style: const TextStyle(fontSize: 20.0, color: Colors.black, fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((markerWidth - textPainter.width) / 2, markerHeight - 43));

    // 5. 최종 이미지로 변환하여 BitmapDescriptor 반환
    final ui.Image finalImage = await pictureRecorder.endRecording().toImage(markerWidth.toInt(), markerHeight.toInt());
    final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }

  // 🌟 [추가] 내 마커 생성 함수: 사진 연동 삭제, 캐릭터 정면 1장만 사용
  static Future<BitmapDescriptor> createMyMarker(String markerAvatar) async {
    const int targetWidth = 120; // 마커 크기 설정
    
    // 1. 뱀과 소녀를 제외한 12지신 캐릭터는 8방향 스프라이트 시트입니다.
    bool is25D = !markerAvatar.startsWith('snake') && !markerAvatar.startsWith('avatar');

    if (!is25D) {
      // 평면 이미지는 그냥 불러와서 반환 (BitmapDescriptor.fromAssetImage 사용)
      // 주의: 이 방식은 비동기 처리가 필요하므로 직접 렌더링하는 대신 이 방식을 권장하지만, 
      // 일관성을 위해 아래와 같이 렌더링 로직을 사용할 수도 있습니다.
      final ui.Image image = await _loadImage('assets/avatars/$markerAvatar');
      final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(pictureRecorder);
      canvas.drawImageRect(
        image, 
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetWidth.toDouble()),
        Paint()
      );
      final ui.Image finalImage = await pictureRecorder.endRecording().toImage(targetWidth, targetWidth);
      final ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
    }

    // 2. 🌟 핵심: 스프라이트 시트에서 정면 1칸만 수학적으로 잘라내기
    final ui.Image rawImage = await _loadImage('assets/avatars/$markerAvatar');

    // 원본 이미지에서 1칸의 크기 계산 (가로 4칸, 세로 2줄)
    final double frameWidth = rawImage.width / 4;
    final double frameHeight = rawImage.height / 2;

    // 그림을 그릴 캔버스 준비
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final ui.Canvas canvas = ui.Canvas(pictureRecorder);
    final ui.Paint paint = ui.Paint();

    // 보여줄 마커 크기(targetWidth)에 맞게 캔버스 크기 조정
    final double scale = targetWidth / frameWidth;
    final double dstWidth = targetWidth.toDouble();
    final double dstHeight = frameHeight * scale;

    // 원본에서 [가로 0, 세로 0] 위치의 프레임(정면) 1장만 따와서 캔버스에 그립니다.
    canvas.drawImageRect(
      rawImage,
      Rect.fromLTWH(0, 0, frameWidth, frameHeight), // 원본의 정면 영역
      Rect.fromLTWH(0, 0, dstWidth, dstHeight),      // 캔버스에 그려질 영역
      paint,
    );

    // 캔버스 내용을 파일로 변환
    final ui.Image markerImage = await pictureRecorder.endRecording().toImage(dstWidth.toInt(), dstHeight.toInt());
    final ByteData? byteData = await markerImage.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(byteData!.buffer.asUint8List());
  }
}
