import 'package:flutter/material.dart';
import '../utils/translations.dart';

class ProfileCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const ProfileCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // 🌟 [수정] 데이터 추출 시 쥐 아바타 대신 실제 프로필 사진 URL을 가져옵니다!
    final String name = data['nickname'] ?? AppLocale.t('unknown_user');
    final String? profileImageUrl = data['profile_image_url']; // 👈 추가된 부분
    final String mbti = data['mbti'] ?? '???';
    final String gender = data['gender'] ?? 'unknown';
    final String bio = data['bio'] ?? AppLocale.t('map_snippet');
    final List<dynamic> interests = data['interests'] ?? ['차 마시기 🍵'];
    
    // 🌡️ 매너 온도 가져오기
    final double temp = (data['manner_temp'] ?? 36.5).toDouble();
    final bool isHighManner = temp >= 70.0;
    final Color barColor = isHighManner ? const Color(0xFF24FCFF) : const Color(0xFFFFD700); 
    final double barHeight = isHighManner ? 12.0 : 8.0; 

    return Container(
      width: 320,
      height: 480, 
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
            // 📸 1. [핵심 변경] 아바타 대신 실제 프로필 사진 배경
            SizedBox.expand(
              child: profileImageUrl != null && profileImageUrl.isNotEmpty
                  ? Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover, // 사진을 카드 전체에 꽉 차게
                      alignment: Alignment.topCenter, // 얼굴이 잘리지 않게 위쪽 기준 정렬
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))); // 로딩 표시
                      },
                      errorBuilder: (context, error, stackTrace) => _buildDefaultBackground(), // 에러 시 기본 배경
                    )
                  : _buildDefaultBackground(), // 사진을 안 올린 유저를 위한 기본 배경
            ),
            
            // 2. 그라데이션 (텍스트 가독성용)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent, Colors.black87],
                  stops: [0.0, 0.4, 0.8], // 얼굴이 잘 보이도록 중간 투명 영역을 넓혔습니다.
                ),
              ),
            ),

            // 🌡️ 3. 상단 온도 막대 & 숫자
            Positioned(
              top: 20, left: 20, right: 20,
              child: Row(
                children: [
                  Icon(Icons.thermostat, color: barColor, size: 20),
                  const SizedBox(width: 5),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: temp / 100.0, 
                        backgroundColor: Colors.white30,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        minHeight: barHeight, 
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "$temp℃",
                    style: TextStyle(
                      color: barColor, fontSize: 18, fontWeight: FontWeight.bold,
                      shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                    ),
                  ),
                ],
              ),
            ),

            // 4. 하단 정보 텍스트 (이름, MBTI, 관심사, 한줄소개)
            Positioned(
              bottom: 20, left: 20, right: 20,
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
                    decoration: BoxDecoration(color: const Color(0xFF24FCFF), borderRadius: BorderRadius.circular(10)),
                    child: Text(mbti, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: interests.map((tag) => _buildChip(tag.toString())).toList(),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    bio,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
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

  // 🖼️ 사진이 없을 때 보여줄 예쁜 기본 배경 헬퍼 위젯
  Widget _buildDefaultBackground() {
    return Container(
      color: const Color(0xFF2E003E), // 앱 시그니처 보라색
      child: const Center(
        child: Icon(Icons.person, size: 100, color: Colors.white24),
      ),
    );
  }

  Widget _getGenderIcon(String gender) {
    if (gender == 'male' || gender == '남성') return const Icon(Icons.male, color: Colors.blue, size: 24);
    if (gender == 'female' || gender == '여성') return const Icon(Icons.female, color: Colors.pink, size: 24);
    return const SizedBox.shrink();
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white30),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }
}
