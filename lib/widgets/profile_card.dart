import 'package:flutter/material.dart';
import '../utils/translations.dart'; // 번역 파일 경로 확인

class ProfileCard extends StatelessWidget {
  final Map<String, dynamic> data; // 유저 데이터 전체

  const ProfileCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // 데이터 추출 (없으면 기본값)
    final String name = data['nickname'] ?? AppLocale.t('unknown_user');
    final String avatarFile = data['avatar_image'] ?? 'rat.png';
    final String mbti = data['mbti'] ?? '???';
    final String gender = data['gender'] ?? 'unknown';
    final String bio = data['bio'] ?? AppLocale.t('map_snippet');
    final List<dynamic> interests = data['interests'] ?? ['차 마시기 🍵', '대화하기 🗣️'];

    return Container(
      // 다이얼로그 안에서 크기 조절을 위해 높이 지정 (필요 시 조절)
      height: 450, 
      width: 320,
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
            Container(
              color: Colors.grey[100],
              child: Image.asset(
                'assets/avatars/$avatarFile',
                fit: BoxFit.cover,
              ),
            ),
            
            // 2. 그라데이션
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                  stops: [0.5, 1.0],
                ),
              ),
            ),

            // 3. 정보 텍스트
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
                      Text(
                        name,
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
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
                    child: Text(
                      mbti,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
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
