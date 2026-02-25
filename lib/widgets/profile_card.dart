import 'package:flutter/material.dart';
import '../utils/translations.dart';

class ProfileCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfileCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // 데이터 추출
    final String name = data['nickname'] ?? AppLocale.t('unknown_user');
    final String avatarFile = data['avatar_image'] ?? 'rat.png';
    final String mbti = data['mbti'] ?? '???';
    final String gender = data['gender'] ?? 'unknown';
    final String bio = data['bio'] ?? AppLocale.t('map_snippet');
    final List<dynamic> interests = data['interests'] ?? ['차 마시기 🍵'];
    
    // 🌡️ 매너 온도 가져오기 (없으면 기본 36.5)
    final double temp = (data['manner_temp'] ?? 36.5).toDouble();
    
    // 🎨 온도에 따른 디자인 변수 설정
    final bool isHighManner = temp >= 70.0;
    final Color barColor = isHighManner ? const Color(0xFF24FCFF) : const Color(0xFFFFD700); // 시그니처 민트 vs 황금색
    final double barHeight = isHighManner ? 12.0 : 8.0; // 1.5배 두꺼워짐

    return Container(
      width: 320,
      height: 480, // 온도가 들어가서 높이를 살짝 늘림
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. 아바타 배경
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover, // 🌟 자른 이미지를 카드 전체에 꽉 차게 확대
                alignment: Alignment.topCenter, // 얼굴이 잘리지 않도록 위쪽 정렬
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.topLeft, // 원본의 왼쪽 맨 위(정면) 기준
                    widthFactor: 0.25, // 가로를 1/4 크기(4칸 중 1칸)로 자름
                    heightFactor: 0.5, // 세로를 1/2 크기(2줄 중 1줄)로 자름
                    child: Image.asset(
                      'assets/avatars/$avatarFile',
                      // 🚨 주의: 이곳에 있던 fit: BoxFit.cover는 지워야 원본 비율대로 똑바로 잘립니다!
                    ),
                  ),
                ),
              ),
            ),
            
            // 2. 그라데이션 (텍스트 가독성용)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  stops: [0.0, 0.3, 0.8],
                ),
              ),
            ),

            // 🌡️ 3. [핵심] 상단 온도 막대 & 숫자
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  // 온도 아이콘
                  Icon(Icons.thermostat, color: barColor, size: 20),
                  const SizedBox(width: 5),
                  
                  // 막대 (Bar)
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: temp / 100.0, // 100도 만점 기준
                        backgroundColor: Colors.white30,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        minHeight: barHeight, // 두께 변화 적용!
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 10),
                  
                  // 숫자 텍스트
                  Text(
                    "$temp℃",
                    style: TextStyle(
                      color: barColor, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                  ),
                ],
              ),
            ),

            // 4. 하단 정보 텍스트
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _getGenderIcon(gender),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF24FCFF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(mbti, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: interests.map((tag) => _buildChip(tag.toString())).toList(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bio,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getGenderIcon(String gender) {
    if (gender == 'male') return const Icon(Icons.male, color: Colors.blue, size: 24);
    if (gender == 'female') return const Icon(Icons.female, color: Colors.pink, size: 24);
    return const SizedBox.shrink();
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white30),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}
