import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:typed_data';

class MarkerGenerator {
  // 🎨 이모지와 닉네임을 예쁜 마커 이미지로 변환하는 함수
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
}
