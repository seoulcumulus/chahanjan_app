const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Firebase 관리자 모드 실행
admin.initializeApp();

exports.sendChatNotification = functions.firestore
    .document('chat_requests/{requestId}')
    .onCreate(async (snapshot, context) => {
        // 1. 생성된 요청 데이터 가져오기
        const data = snapshot.data();
        const toId = data.toId; // 받는 사람 UID
        const fromName = data.fromNickname || '알 수 없음';
        const type = data.type; // 'chat' 또는 'poke'

        // 2. 받는 사람(toId)의 정보(FCM 토큰) 가져오기
        const userDoc = await admin.firestore().collection('users').doc(toId).get();

        // 유저가 없거나 토큰이 없으면 중단
        if (!userDoc.exists) {
            console.log('No such user!');
            return null;
        }

        const token = userDoc.data().fcmToken;
        if (!token) {
            console.log('No FCM token for user, cannot send notification.');
            return null;
        }

        // 3. 알림 메시지 내용 만들기 (타입에 따라 다르게)
        let title = '차한잔 (ChaHanJan)';
        let body = '';

        if (type === 'poke') {
            body = `👋 ${fromName}님이 회원님을 콕 찔렀습니다!`;
        } else {
            body = `💌 ${fromName}님이 대화를 신청했습니다!`;
        }

        // 4. 알림 전송 (Payload 구성)
        const payload = {
            notification: {
                title: title,
                body: body,
                sound: 'default',
                clickAction: 'FLUTTER_NOTIFICATION_CLICK', // 알림 클릭 시 앱 열기
            },
            data: {
                requestId: context.params.requestId, // 필요 시 데이터 전달
                click_action: 'FLUTTER_NOTIFICATION_CLICK'
            }
        };

        // 5. 실제 전송
        try {
            const response = await admin.messaging().sendToDevice(token, payload);
            console.log('Successfully sent message:', response);
            return null;
        } catch (error) {
            console.log('Error sending message:', error);
            return null;
        }
    });
