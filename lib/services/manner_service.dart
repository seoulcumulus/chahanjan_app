import 'package:cloud_firestore/cloud_firestore.dart';

class MannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 👻 유령 여부 판독기
  bool isGhost(double temp) {
    return temp < 30.0;
  }

  // 🌿 1. 유령 구출 보상 (일반 유저가 유령에게 말 걸었을 때)
  Future<void> rewardForRescue(String heroUid) async {
    // 일반 유저에게 찻잎 10장 지급!
    await _firestore.collection('users').doc(heroUid).update({
      'teaLeaves': FieldValue.increment(10), 
    });
  }

  // 💊 2. 매너 회복 물약 구매 (찻잎 소모)
  Future<String> buyRecoveryPotion(String myUid, int currentTeaLeaves) async {
    const int potionCost = 50; // 물약 가격: 찻잎 50장
    const double recoveryAmount = 5.0; // 회복 온도: +5도

    // 1) 찻잎 부족?
    if (currentTeaLeaves < potionCost) {
      return "찻잎이 부족해요! (필요: $potionCost🌿)";
    }

    final userRef = _firestore.collection('users').doc(myUid);
    final snapshot = await userRef.get();
    
    // 2) 쿨타임 체크 (일주일)
    Timestamp? lastUsed = snapshot.data()?['lastPotionUsedAt'];
    if (lastUsed != null) {
      final date = lastUsed.toDate();
      final diff = DateTime.now().difference(date).inDays;
      if (diff < 7) {
        return "물약은 일주일에 한 번만 마실 수 있어요. (${7-diff}일 남음)";
      }
    }

    // 3) 구매 처리 (트랜잭션)
    await userRef.update({
      'teaLeaves': FieldValue.increment(-potionCost), // 찻잎 차감
      'mannerTemp': FieldValue.increment(recoveryAmount), // 온도 상승
      'lastPotionUsedAt': FieldValue.serverTimestamp(), // 시간 기록
    });

    return "success"; // 성공
  }

  // ⭐ 별점에 따른 온도 변화량
  // 5점: +0.5도, 4점: +0.2도, 3점: 변화없음, 2점: -0.2도, 1점: -0.5도
  double _getTempChange(int stars) {
    if (stars == 5) return 0.5;
    if (stars == 4) return 0.2;
    if (stars == 2) return -0.2;
    if (stars == 1) return -0.5;
    return 0.0;
  }

  // 📝 평가 제출하기
  Future<void> submitRating({required String targetUid, required int stars}) async {
    final userRef = _firestore.collection('users').doc(targetUid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      // 현재 온도 가져오기 (없으면 기본 36.5)
      double currentTemp = (snapshot.data()?['mannerTemp'] ?? 36.5).toDouble();
      
      // 새 온도 계산 (최대 99도, 최소 0도)
      double newTemp = currentTemp + _getTempChange(stars);
      if (newTemp > 99.0) newTemp = 99.0;
      if (newTemp < 0.0) newTemp = 0.0;

      // 업데이트
      transaction.update(userRef, {'mannerTemp': newTemp});
    });
  }


  // 🚑 매너 회복 (출석, 광고 시청 등)
  // amount: 회복할 점수 (예: 0.1)
  Future<void> recoverMannerTemp({required String targetUid, required double amount}) async {
    final userRef = _firestore.collection('users').doc(targetUid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      double currentTemp = (snapshot.data()?['mannerTemp'] ?? 36.5).toDouble();

      // ⚠️ 이미 36.5도 이상인 사람은 회복 기능을 쓸 수 없음 (악용 방지)
      if (currentTemp >= 36.5) {
        return; // 그냥 종료
      }

      // 온도 상승
      double newTemp = currentTemp + amount;
      
      // 36.5도를 넘지 못하게 막음 (회복으로는 딱 기본까지만!)
      if (newTemp > 36.5) newTemp = 36.5;

      transaction.update(userRef, {'mannerTemp': newTemp});
    });
  }
}
