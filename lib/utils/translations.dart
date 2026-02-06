// lib/utils/translations.dart

import 'package:flutter/foundation.dart';

class AppLocale {
  // 📢 확성기(Notifier): 언어 변경 감지용
  static final ValueNotifier<String> currentNotifier = ValueNotifier('ko');

  static String get current => currentNotifier.value;

  // 지원 언어: 한국어, 영어, 일본어, 중국어, 스페인어, 힌디(인도)
  static final List<String> supportedLocales = ['ko', 'en', 'ja', 'zh', 'es', 'hi'];

  // 📝 6개 국어 전체 데이터
  // 📝 6개 국어 전체 데이터
  static final Map<String, Map<String, String>> _db = {
    // 1. 🇰🇷 한국어 (Korean)
    'ko': {
      'app_title': '성스러운 매칭',
      'nav_map': '지도', 'nav_matching': '매칭', 'nav_profile': '내 정보',
      'shop_title': '상점',
      'tea_leaves': '보유 찻잎',
      // [채팅]
      'chat_title': '채팅 목록',
      'chat_active': '대화 중인 방',
      'chat_waiting': '대기 중인 요청',
      'unknown_user': '알 수 없음',
      'accept': '수락',
      // [지도]
      'radius': '반경',
      'map_snippet': '터치해서 대화하기',
      'search_start': '찻잎 1장을 쓰고 주변을 둘러봅니다.',
      'tea_low': '찻잎이 부족해요!',
      // [메시지]
      'msg_received': '대화 요청이 왔어요!',
      'msg_sent': '대화를 요청했어요!',
      'msg_accepted': '대화가 수락되었습니다!',
      'msg_wait': '수락 대기 중...',
      // [기타]
      'my_avatar': '나의 아바타',
      'inventory': '보유 아바타 창고',
      'nickname': '닉네임',
      'mbti': 'MBTI',
      'mbti_select_title': 'MBTI 선택',
      'mbti_unknown_link': '내 MBTI를 모르겠나요? (테스트)',
      'gender_age': '성별 & 나이',
      'age': '나이',
      'bio': '한줄 소개',
      'interests': '관심사',
      'save_profile': '프로필 저장',
      'male': '남성', 'female': '여성',
      'no_more_friends': '더 이상 추천할 친구가 없어요 😢',
      'matching_title': '성스러운 매칭 💞',

      // Shop Tabs/Items
      'tab_tea': '찻잎 충전 🍵', 'tab_avatar': '아바타 상점 🎭', 'tab_fortune': '성스러운 신탁 📜',
      'owned': '보유중', 'buy_success': '구매 성공!', 'not_enough_tea': '찻잎이 부족합니다 😢',
      'confirm': '아멘 (확인)', 'tea_10': '찻잎 10개', 'price_10': '1,000원',
      
      // Fortune
      'fortune_title': '성스러운 신탁 📜', 'fortune_desc': '신이 예비하신 오늘의 계시를 확인하세요.',
      'your_zodiac': '당신의 수호 동물', 'view_fortune': '계시 받기',
      'INTJ_desc': '용의주도한 전략가',

      // Interests
      'hiking': '등산 ⛰️', 'golf': '골프 ⛳', 'gym': '헬스 💪',
      'tennis': '테니스 🎾', 'baseball': '야구 ⚾', 'soccer': '축구 ⚽',
      'wine': '와인 🍷', 'coffee': '커피 ☕', 'whiskey': '위스키 🥃',
      'foodie': '맛집 🍕', 'reading': '독서 📚', 'finance': '재테크 💰',
      'meditation': '명상 🧘', 'gaming': '게임 🎮', 'business': '비즈니스 💼',
    },

    // 2. 🇺🇸 영어 (English)
    'en': {
      'app_title': 'Holy Match',
      'nav_map': 'Map', 'nav_matching': 'Match', 'nav_profile': 'My Profile',
      'shop_title': 'Shop',
      'tea_leaves': 'Tea Leaves',
      'chat_title': 'Chats',
      'chat_active': 'Active Chats',
      'chat_waiting': 'Pending Requests',
      'unknown_user': 'Unknown',
      'accept': 'Accept',
      'radius': 'Radius',
      'map_snippet': 'Touch to Chat',
      'search_start': 'Looking around with 1 Tea Leaf.',
      'tea_low': 'Not enough Tea Leaves!',
      'msg_received': 'Request Received!',
      'msg_sent': 'Request Sent!',
      'msg_accepted': 'Chat Accepted!',
      'msg_wait': 'Waiting...',
      'my_avatar': 'My Avatar',
      'inventory': 'Avatar Inventory',
      'nickname': 'Nickname',
      'mbti': 'MBTI',
      'mbti_select_title': 'Select MBTI',
      'mbti_unknown_link': 'Don\'t know your MBTI? (Test)',
      'gender_age': 'Gender & Age',
      'age': 'Age',
      'bio': 'Bio',
      'interests': 'Interests',
      'save_profile': 'Save Profile',
      'male': 'Male', 'female': 'Female',
      'no_more_friends': 'No more friends to recommend 😢',
      'matching_title': 'Holy Match 💞',

      // Shop Tabs/Items
      'tab_tea': 'Tea Shop 🍵', 'tab_avatar': 'Avatar Shop 🎭', 'tab_fortune': 'Holy Oracle 📜',
      'owned': 'Owned', 'buy_success': 'Purchase Successful!', 'not_enough_tea': 'Not enough tea leaves 😢',
      'confirm': 'Amen (OK)', 'tea_10': '10 Tea Leaves', 'price_10': '\$0.99',
      
      // Fortune
      'fortune_title': 'The Holy Oracle 📜', 'fortune_desc': 'Reveal the destiny prepared by the Divine.',
      'your_zodiac': 'Guardian Animal', 'view_fortune': 'Receive Revelation',
      'INTJ_desc': 'Architect',

      // Interests
      'hiking': 'Hiking ⛰️', 'golf': 'Golf ⛳', 'gym': 'Gym 💪',
      'tennis': 'Tennis 🎾', 'baseball': 'Baseball ⚾', 'soccer': 'Soccer ⚽',
      'wine': 'Wine 🍷', 'coffee': 'Coffee ☕', 'whiskey': 'Whiskey 🥃',
      'foodie': 'Foodie 🍕', 'reading': 'Reading 📚', 'finance': 'Finance 💰',
      'meditation': 'Meditation 🧘', 'gaming': 'Gaming 🎮', 'business': 'Business 💼',
    },

    // 3. 🇯🇵 일본어 (Japanese)
    'ja': {
      'app_title': '聖なるマッチング',
      'nav_map': '地図', 'nav_matching': 'マッチング', 'nav_profile': 'マイページ',
      'shop_title': 'ショップ',
      'tea_leaves': '保有茶葉',
      'chat_title': 'チャット一覧',
      'chat_active': '対話中のルーム',
      'chat_waiting': '待機中のリクエスト',
      'unknown_user': '不明なユーザー',
      'accept': '承諾',
      'radius': '半径',
      'map_snippet': 'タップしてチャット',
      'search_start': '茶葉1枚を使って周りを見渡します。',
      'tea_low': '茶葉が足りません！',
      'msg_received': '対話リクエストが来ました！',
      'msg_sent': '対話をリクエストしました！',
      'msg_accepted': '対話が承諾されました！',
      'msg_wait': '承諾待ち...',
      'my_avatar': '私のアバター',
      'inventory': 'アバター倉庫',
      'nickname': 'ニックネーム',
      'mbti': 'MBTI',
      'mbti_select_title': 'MBTIを選択',
      'mbti_unknown_link': 'MBTIがわかりませんか？ (テスト)',
      'gender_age': '性別 & 年齢',
      'age': '年齢',
      'bio': '自己紹介',
      'interests': '興味',
      'save_profile': '保存する',
      'male': '男性', 'female': '女性',
      'no_more_friends': 'もう推薦できる友達がいません 😢',
      'matching_title': '聖なるマッチング 💞',

      // Shop Tabs/Items
      'tab_tea': '茶葉チャージ 🍵', 'tab_avatar': 'アバターショップ 🎭', 'tab_fortune': '聖なる神託 📜',
      'owned': '保有中', 'buy_success': '購入成功！', 'not_enough_tea': '茶葉が足りません 😢',
      'confirm': 'アーメン (確認)', 'tea_10': '茶葉 10個', 'price_10': '100円',

      // Fortune
      'fortune_title': '聖なる神託 📜', 'fortune_desc': '神が予備された今日の啓示を確認してください。',
      'your_zodiac': '守護動物', 'view_fortune': '啓示を受ける',
      'INTJ_desc': '用意周到な戦略家',

      // Interests
      'hiking': '登山 ⛰️', 'golf': 'ゴルフ ⛳', 'gym': 'ジム 💪',
      'tennis': 'テニス 🎾', 'baseball': '野球 ⚾', 'soccer': 'サッカー ⚽',
      'wine': 'ワイン 🍷', 'coffee': 'コーヒー ☕', 'whiskey': 'ウイスキー 🥃',
      'foodie': 'グルメ 🍕', 'reading': '読書 📚', 'finance': '財テク 💰',
      'meditation': '瞑想 🧘', 'gaming': 'ゲーム 🎮', 'business': 'ビジネス 💼',
    },

    // 4. 🇨🇳 중국어 (Chinese)
    'zh': {
      'app_title': '神圣的匹配',
      'nav_map': '地图', 'nav_matching': '匹配', 'nav_profile': '我的信息',
      'shop_title': '商店',
      'tea_leaves': '持有茶叶',
      'chat_title': '聊天列表',
      'chat_active': '活跃聊天',
      'chat_waiting': '待处理请求',
      'unknown_user': '未知用户',
      'accept': '接受',
      'radius': '半径',
      'map_snippet': '点击聊天',
      'search_start': '使用1片茶叶环顾四周。',
      'tea_low': '茶叶不足！',
      'msg_received': '收到对话请求！',
      'msg_sent': '已发送对话请求！',
      'msg_accepted': '请求已接受！',
      'msg_wait': '等待中...',
      'my_avatar': '我的头像',
      'inventory': '头像仓库',
      'nickname': '昵称',
      'mbti': 'MBTI',
      'mbti_select_title': '选择 MBTI',
      'mbti_unknown_link': '不知道您的 MBTI？ (测试)',
      'gender_age': '性别 & 年龄',
      'age': '年龄',
      'bio': '个人简介',
      'interests': '兴趣',
      'save_profile': '保存',
      'male': '男性', 'female': '女性',
      'no_more_friends': '没有更多推荐的朋友了 😢',
      'matching_title': '神圣的匹配 💞',

      // Shop Tabs/Items
      'tab_tea': '茶叶充值 🍵', 'tab_avatar': '头像商店 🎭', 'tab_fortune': '神圣神谕 📜',
      'owned': '已拥有', 'buy_success': '购买成功！', 'not_enough_tea': '茶叶不足 😢',
      'confirm': '阿门 (确认)', 'tea_10': '茶叶 10个', 'price_10': '¥6.00',

      // Fortune
      'fortune_title': '神圣的神谕 📜', 'fortune_desc': '查看神为您预备的今日启示。',
      'your_zodiac': '守护动物', 'view_fortune': '接受启示',
      // 'INTJ_desc' needed? Let's add default or omitted since not strictly required by prompt but good for completeness 
      // The snippet didn't explicitly ask for INTJ_desc in user prompt, but it was in previous file. I'll include empty string or skip if unsure, but better to keep previous logic?
      // Actually user prompt provided a "perfect" snippet for ko/en/es/hi. I should stick to that pattern. 
      // I will infer standard translations for consistency.

      // Interests
      'hiking': '登山 ⛰️', 'golf': '高尔夫 ⛳', 'gym': '健身 💪',
      'tennis': '网球 🎾', 'baseball': '棒球 ⚾', 'soccer': '足球 ⚽',
      'wine': '红酒 🍷', 'coffee': '咖啡 ☕', 'whiskey': '威士忌 🥃',
      'foodie': '美食 🍕', 'reading': '阅读 📚', 'finance': '理财 💰',
      'meditation': '冥想 🧘', 'gaming': '游戏 🎮', 'business': '商务 💼',
    },

    // 5. 🇪🇸 스페인어 (Spanish)
    'es': {
      'app_title': 'Partido Santo',
      'nav_map': 'Mapa', 'nav_matching': 'Pareja', 'nav_profile': 'Mi Perfil',
      'shop_title': 'Tienda',
      'tea_leaves': 'Hojas de Té',
      'chat_title': 'Chats',
      'chat_active': 'Chats Activos',
      'chat_waiting': 'Solicitudes',
      'unknown_user': 'Desconocido',
      'accept': 'Aceptar',
      'radius': 'Radio',
      'map_snippet': 'Toca para chatear',
      'search_start': 'Mirando alrededor con 1 hoja.',
      'tea_low': '¡No hay suficiente té!',
      'msg_received': '¡Solicitud recibida!',
      'msg_sent': '¡Solicitud enviada!',
      'msg_accepted': '¡Chat aceptado!',
      'msg_wait': 'Esperando...',
      'my_avatar': 'Mi Avatar',
      'inventory': 'Inventario',
      'nickname': 'Apodo',
      'mbti': 'MBTI',
      'mbti_select_title': 'Seleccionar MBTI',
      'mbti_unknown_link': '¿No conoces tu MBTI? (Prueba)',
      'gender_age': 'Género y Edad',
      'age': 'Edad',
      'bio': 'Biografía',
      'interests': 'Intereses',
      'save_profile': 'Guardar Perfil',
      'male': 'Hombre', 'female': 'Mujer',
      'no_more_friends': 'No hay más amigos 😢',
      'matching_title': 'Partido Santo 💞',

      // Shop Tabs/Items
      'tab_tea': 'Tienda de Té 🍵', 'tab_avatar': 'Tienda de Avatares 🎭', 'tab_fortune': 'El Oráculo Sagrado 📜',
      'owned': 'Propiedad', 'buy_success': '¡Compra Exitosa!', 'not_enough_tea': 'No hay suficientes hojas de té 😢',
      'confirm': 'Amén (OK)', 'tea_10': '10 Hojas de Té', 'price_10': '0.99 €',

      // Fortune
      'fortune_title': 'El Oráculo Sagrado 📜', 'fortune_desc': 'Revela el destino preparado por lo Divino.',
      'your_zodiac': 'Animal Guardián', 'view_fortune': 'Recibir Revelación',

      // Interests
      'hiking': 'Senderismo ⛰️', 'golf': 'Golf ⛳', 'gym': 'Gimnasio 💪',
      'tennis': 'Tenis 🎾', 'baseball': 'Béisbol ⚾', 'soccer': 'Fútbol ⚽',
      'wine': 'Vino 🍷', 'coffee': 'Café ☕', 'whiskey': 'Whisky 🥃',
      'foodie': 'Comida 🍕', 'reading': 'Lectura 📚', 'finance': 'Finanzas 💰',
      'meditation': 'Meditación 🧘', 'gaming': 'Juegos 🎮', 'business': 'Negocios 💼',
    },

    // 6. 🇮🇳 힌디 (Hindi)
    'hi': {
      'app_title': 'पवित्र मिलन',
      'nav_map': 'नक्शा', 'nav_matching': 'जोड़ी', 'nav_profile': 'मेरी प्रोफ़ाइल',
      'shop_title': 'दुकान',
      'tea_leaves': 'चाय की पत्तियां',
      'chat_title': 'चैट',
      'chat_active': 'सक्रिय चैट',
      'chat_waiting': 'लंबित अनुरोध',
      'unknown_user': 'अज्ञात',
      'accept': 'स्वीकार करें',
      'radius': 'दायरा',
      'map_snippet': 'चैट करने के लिए छुएं',
      'search_start': '1 चाय पत्ती का उपयोग कर रहा हूँ।',
      'tea_low': 'चाय कम है!',
      'msg_received': 'अनुरोध प्राप्त हुआ!',
      'msg_sent': 'अनुरोध भेजा गया!',
      'msg_accepted': 'चैट स्वीकार की गई!',
      'msg_wait': 'प्रतीक्षा में...',
      'my_avatar': 'मेरा अवतार',
      'inventory': 'अवतार भंडार',
      'nickname': 'उपनाम',
      'mbti': 'MBTI',
      'mbti_select_title': 'MBTI चुनें',
      'mbti_unknown_link': 'अपना MBTI नहीं जानते? (टेस्ट)',
      'gender_age': 'लिंग और आयु',
      'age': 'आयु',
      'bio': 'परिचय',
      'interests': 'रुचियाँ',
      'save_profile': 'सहेजें',
      'male': 'पुरुष', 'female': 'महिला',
      'no_more_friends': 'अब और दोस्त नहीं हैं 😢',
      'matching_title': 'पवित्र मिलन 💞',

      // Shop Tabs/Items
      'tab_tea': 'चाय की पत्तियां 🍵', 'tab_avatar': 'अवतार की दुकान 🎭', 'tab_fortune': 'पवित्र देववाणी 📜',
      'owned': 'स्वामित्व', 'buy_success': 'खरीदारी सफल!', 'not_enough_tea': 'चाय की पत्तियां कम हैं 😢',
      'confirm': 'आमीन (ठीक है)', 'tea_10': '10 चाय की पत्तियां', 'price_10': '₹80',

      // Fortune
      'fortune_title': 'पवित्र देववाणी 📜', 'fortune_desc': 'ईश्वर द्वारा रचित अपना आज का भाग्य देखें।',
      'your_zodiac': 'रक्षक जानवर', 'view_fortune': 'दिव्य संदेश देखें',

      // Interests
      'hiking': 'ट्रैकिंग ⛰️', 'golf': 'गोल्फ ⛳', 'gym': 'जिम 💪',
      'tennis': 'टेनिस 🎾', 'baseball': 'बेसबॉल ⚾', 'soccer': 'फुटबॉल ⚽',
      'wine': 'वाइन 🍷', 'coffee': 'कॉफी ☕', 'whiskey': 'व्हिस्की 🥃',
      'foodie': 'खाने के शौकीन 🍕', 'reading': 'पढ़ना 📚', 'finance': 'वित्त 💰',
      'meditation': 'ध्यान 🧘', 'gaming': 'गेमिंग 🎮', 'business': 'व्यापार 💼',
    },
  };

  // 번역 함수
  static String t(String key) {
    return _db[currentNotifier.value]?[key] ?? key;
  }

  // 언어 변경 함수
  static void changeLanguage(String languageCode) {
    currentNotifier.value = languageCode;
  }
}
