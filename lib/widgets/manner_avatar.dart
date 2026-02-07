import 'package:flutter/material.dart';

class MannerAvatar extends StatelessWidget {
  final String imagePath;
  final double temp;
  final double size;

  const MannerAvatar({
    super.key,
    required this.imagePath,
    required this.temp,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + 30, // 왕관 공간 확보
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. 아바타 이미지
          Container(
            width: size,
            height: size,
            margin: const EdgeInsets.only(top: 20), // 머리 위 공간
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF24FCFF), width: 3),
              image: DecorationImage(
                image: AssetImage('assets/avatars/$imagePath'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(2, 4))
              ],
            ),
          ),

          // 👑 2. 황제 왕관 (85도 이상)
          if (temp >= 85.0)
            Positioned(
              top: 0,
              child: const Icon(Icons.emoji_events, color: Colors.amber, size: 40), // 간단히 아이콘 사용
              // 또는 이미지: Image.asset('assets/crown.png', width: 40)
            ),

          // 😇 3. 천사 링 (70도 이상)
          if (temp >= 70.0 && temp < 85.0)
            Positioned(
              top: 5,
              child: Container(
                width: size * 0.6,
                height: 15,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber, width: 4),
                  borderRadius: BorderRadius.circular(50), // 타원형
                ),
              ),
            ),
            
          // 🔥 4. 매너 온도 뱃지 (옵션)
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getTempColor(temp),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "$temp℃",
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTempColor(double t) {
    if (t >= 85) return Colors.purple;
    if (t >= 70) return Colors.green;
    if (t >= 36.5) return Colors.orange;
    return Colors.blueGrey;
  }
}
