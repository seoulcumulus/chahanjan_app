class AppStrings {
  // 12지신 동물 키값 (프로필에서 사용)
  static const List<String> animalsKeys = [
    'rat', 'ox', 'tiger', 'rabbit', 'dragon', 'snake',
    'horse', 'sheep', 'monkey', 'rooster', 'dog', 'pig'
  ];

  static const Map<String, Map<String, String>> data = {
    'Korean': {
      'map_title': '차한잔', 
      'shop_title': '상점', 
      'shop_desc': '나만의 12지신 캐릭터를 모아보세요!',
      'buy_btn': '구매', 'equip_btn': '착용 중', 'equipped_btn': '착용하기',
      'cost': '5 찻잎', 'not_enough_tea': '찻잎이 부족해요! 😢', 'buy_success': '구매 성공! 🎉',
      'profile_title': '프로필 설정', 'nickname': '닉네임', 'bio': '한줄 소개', 'age': '나이', 'gender': '성별', 
      'save': '저장 완료', 'interests': '관심사', 'language': '언어 설정', 'logout': '나가기',
      'greet': '인사하기', 'poke_sent': '👋 콕 찔렀습니다!', 'chat': '대화 신청', 'chat_req_sent': '💌 대화 요청을 보냈습니다!',
      'block': '차단', 'report': '신고', 'report_reason_hint': '신고 사유를 입력하세요', 'cancel': '취소', 'submit': '제출',
      'tea_leaves': '찻잎',
      'inventory': '나의 보관함 🎒', // 👈 Added

      // 🍵 찻잎 묶음 상품
      'tea_10': '찻잎 10개', 'price_10': '\$9.5',
      'tea_50': '찻잎 50개', 'price_50': '\$45',
      'tea_100': '찻잎 100개', 'price_100': '\$93',
      'tea_200': '찻잎 200개', 'price_200': '\$180',
      'tea_500': '찻잎 500개', 'price_500': '\$400',
      'tea_1000': '찻잎 1,000개', 'price_1000': '\$750',

      'rat': '쥐', 'ox': '소', 'tiger': '호랑이', 'rabbit': '토끼', 'dragon': '용', 'snake': '뱀',
      'horse': '말', 'sheep': '양', 'monkey': '원숭이', 'rooster': '닭', 'dog': '개', 'pig': '돼지',

      'adj_0': '행복한', 'adj_1': '용감한', 'adj_2': '졸린', 'adj_3': '빠른', 'adj_4': '똑똑한',
      'adj_5': '배고픈', 'adj_6': '멋진', 'adj_7': '귀여운', 'adj_8': '화난', 'adj_9': '슬픈',
      'adj_10': '강력한', 'adj_11': '조용한', 'adj_12': '시끄러운', 'adj_13': '친절한', 'adj_14': '차가운',
      'adj_15': '뜨거운', 'adj_16': '부유한', 'adj_17': '가난한', 'adj_18': '바쁜', 'adj_19': '게으른',

      // 🎲 랜덤 한줄 소개 30개 (Korean)
      'bio_0': '안녕하세요! 반가워요 👋', 'bio_1': '커피 한잔 하실래요? ☕', 'bio_2': '산책하는 걸 좋아해요 🌿',
      'bio_3': '맛집 탐방 같이 가요 🍕', 'bio_4': '주말엔 등산이 최고죠 ⛰️', 'bio_5': '영화 보는 게 취미예요 🎬',
      'bio_6': '운동 파트너 찾아요 💪', 'bio_7': '진지한 대화를 원해요 💬', 'bio_8': '심심해요 놀아줘요 🎈',
      'bio_9': '새로운 친구를 찾고 있어요 🤝', 'bio_10': '여행을 사랑합니다 ✈️', 'bio_11': '책 읽는 조용한 시간 📚',
      'bio_12': '음악 없이는 못 살아요 🎧', 'bio_13': '같이 게임 한판? 🎮', 'bio_14': '사진 찍는 걸 좋아해요 📸',
      'bio_15': '맥주 한잔의 여유 🍺', 'bio_16': '긍정적인 에너지가 넘쳐요 ✨', 'bio_17': '반려동물을 사랑해요 🐶',
      'bio_18': '코딩하는 개발자입니다 💻', 'bio_19': '직장인의 평범한 하루 💼', 'bio_20': '학생입니다 공부하기 싫어요 🏫',
      'bio_21': 'MBTI 이야기 좋아하세요? 🤔', 'bio_22': '맛있는 디저트 먹으러 가요 🍰', 'bio_23': '오늘 하루도 화이팅! 🔥',
      'bio_24': '드라이브 가고 싶다 🚗', 'bio_25': '자전거 타는 거 좋아해요 🚲', 'bio_26': '요리하는 게 취미예요 🍳',
      'bio_27': '영어 공부 중입니다 🇺🇸', 'bio_28': '편하게 연락주세요 📩', 'bio_29': '좋은 인연을 기다려요 ❤️',
    },
    'English': {
      'map_title': 'ChaHanJan', 
      'shop_title': 'Shop', 
      'shop_desc': 'Collect your Zodiac characters!',
      'buy_btn': 'Buy', 'equip_btn': 'Equipped', 'equipped_btn': 'Equip',
      'cost': '5 Tea', 'not_enough_tea': 'Not enough Tea Leaves! 😢', 'buy_success': 'Purchased! 🎉',
      'profile_title': 'Profile', 'nickname': 'Nickname', 'bio': 'Bio', 'age': 'Age', 'gender': 'Gender', 
      'save': 'Save', 'interests': 'Interests', 'language': 'Language', 'logout': 'Logout',
      'greet': 'Say Hello', 'poke_sent': '👋 Poked!', 'chat': "Let's Chat", 'chat_req_sent': '💌 Chat request sent!',
      'block': 'Block', 'report': 'Report', 'report_reason_hint': 'Enter report reason', 'cancel': 'Cancel', 'submit': 'Submit',
      'tea_leaves': 'Tea Leaves',
      'inventory': 'My Inventory 🎒', // 👈 Added

      // 🍵 Tea Bundles
      'tea_10': '10 Tea Leaves', 'price_10': '\$9.5',
      'tea_50': '50 Tea Leaves', 'price_50': '\$45',
      'tea_100': '100 Tea Leaves', 'price_100': '\$93',
      'tea_200': '200 Tea Leaves', 'price_200': '\$180',
      'tea_500': '500 Tea Leaves', 'price_500': '\$400',
      'tea_1000': '1,000 Tea Leaves', 'price_1000': '\$750',

      'rat': 'Rat', 'ox': 'Ox', 'tiger': 'Tiger', 'rabbit': 'Rabbit', 'dragon': 'Dragon', 'snake': 'Snake',
      'horse': 'Horse', 'sheep': 'Sheep', 'monkey': 'Monkey', 'rooster': 'Rooster', 'dog': 'Dog', 'pig': 'Pig',

      'adj_0': 'Happy', 'adj_1': 'Brave', 'adj_2': 'Sleepy', 'adj_3': 'Fast', 'adj_4': 'Smart',
      'adj_5': 'Hungry', 'adj_6': 'Cool', 'adj_7': 'Cute', 'adj_8': 'Angry', 'adj_9': 'Sad',
      'adj_10': 'Strong', 'adj_11': 'Quiet', 'adj_12': 'Loud', 'adj_13': 'Kind', 'adj_14': 'Cold',
      'adj_15': 'Hot', 'adj_16': 'Rich', 'adj_17': 'Poor', 'adj_18': 'Busy', 'adj_19': 'Lazy',

      // 🎲 Random Bio 30 (English)
      'bio_0': 'Hello! Nice to meet you 👋', 'bio_1': 'Coffee time? ☕', 'bio_2': 'I love walking 🌿',
      'bio_3': 'Let\'s go for pizza 🍕', 'bio_4': 'Hiking on weekends ⛰️', 'bio_5': 'Movie lover 🎬',
      'bio_6': 'Need a gym buddy 💪', 'bio_7': 'Deep conversations 💬', 'bio_8': 'Bored, let\'s play 🎈',
      'bio_9': 'Looking for new friends 🤝', 'bio_10': 'I love traveling ✈️', 'bio_11': 'Quiet reading time 📚',
      'bio_12': 'Can\'t live without music 🎧', 'bio_13': 'Gamer here 🎮', 'bio_14': 'I love photography 📸',
      'bio_15': 'Beer lover 🍺', 'bio_16': 'Positive vibes only ✨', 'bio_17': 'Animal lover 🐶',
      'bio_18': 'I am a Developer 💻', 'bio_19': 'Office worker life 💼', 'bio_20': 'Student life 🏫',
      'bio_21': 'Let\'s talk MBTI 🤔', 'bio_22': 'Love desserts 🍰', 'bio_23': 'Have a nice day! 🔥',
      'bio_24': 'Wanna go for a drive 🚗', 'bio_25': 'Cycling is fun 🚲', 'bio_26': 'Cooking is my hobby 🍳',
      'bio_27': 'Learning languages 🇺🇸', 'bio_28': 'Feel free to DM 📩', 'bio_29': 'Waiting for the one ❤️',
    },
    'Japanese': {
      'map_title': 'お茶一杯', 
      'shop_title': 'ショップ', 
      'shop_desc': '十二支のキャラクターを集めよう！',
      'buy_btn': '購入', 'equip_btn': '着用中', 'equipped_btn': '着用',
      'cost': '5 茶葉', 'not_enough_tea': '茶葉が足りません！ 😢', 'buy_success': '購入しました！ 🎉',
      'profile_title': 'プロフィール', 'nickname': 'ニックネーム', 'bio': '自己紹介', 'age': '年齢', 'gender': '性別', 
      'save': '保存', 'interests': '趣味', 'language': '言語', 'logout': 'ログアウト',
      'greet': '挨拶する', 'poke_sent': '👋 つつきました！', 'chat': 'チャット申請', 'chat_req_sent': '💌 チャットリクエストを送信しました！',
      'block': 'ブロック', 'report': '通報', 'report_reason_hint': '通報理由を入力してください', 'cancel': 'キャンセル', 'submit': '送信',
      'tea_leaves': '茶葉',
      'inventory': '私のインベントリ 🎒', // 👈 Added

      // 🍵 Tea Bundles
      'tea_10': '茶葉 10個', 'price_10': '\$9.5',
      'tea_50': '茶葉 50個', 'price_50': '\$45',
      'tea_100': '茶葉 100個', 'price_100': '\$93',
      'tea_200': '茶葉 200個', 'price_200': '\$180',
      'tea_500': '茶葉 500個', 'price_500': '\$400',
      'tea_1000': '茶葉 1,000個', 'price_1000': '\$750',

      'rat': 'ネズミ', 'ox': '牛', 'tiger': '虎', 'rabbit': 'ウサギ', 'dragon': '龍', 'snake': '蛇',
      'horse': '馬', 'sheep': '羊', 'monkey': '猿', 'rooster': '鶏', 'dog': '犬', 'pig': '豚',

      'adj_0': '幸せな', 'adj_1': '勇敢な', 'adj_2': '眠い', 'adj_3': '速い', 'adj_4': '賢い',
      'adj_5': '腹ペコ', 'adj_6': 'かっこいい', 'adj_7': '可愛い', 'adj_8': '怒った', 'adj_9': '悲しい',
      'adj_10': '強い', 'adj_11': '静かな', 'adj_12': 'うるさい', 'adj_13': '親切な', 'adj_14': '冷たい',
      'adj_15': '熱い', 'adj_16': '金持ち', 'adj_17': '貧しい', 'adj_18': '忙しい', 'adj_19': '怠け者',

      // 🎲 Random Bio 30 (Japanese)
      'bio_0': 'こんにちは！ 👋', 'bio_1': 'コーヒー飲みませんか？ ☕', 'bio_2': '散歩が好きです 🌿',
      'bio_3': '美味しいもの食べよう 🍕', 'bio_4': '週末は登山へ ⛰️', 'bio_5': '映画鑑賞が趣味 🎬',
      'bio_6': '運動仲間募集中 💪', 'bio_7': '真面目な話をしたい 💬', 'bio_8': '暇です、遊ぼう 🎈',
      'bio_9': '新しい友達募集中 🤝', 'bio_10': '旅行が大好き ✈️', 'bio_11': '読書の秋 📚',
      'bio_12': 'NO MUSIC NO LIFE 🎧', 'bio_13': 'ゲームしよう 🎮', 'bio_14': '写真撮るのが好き 📸',
      'bio_15': 'ビール大好き 🍺', 'bio_16': 'ポジティブ思考 ✨', 'bio_17': '動物大好き 🐶',
      'bio_18': 'プログラマーです 💻', 'bio_19': '社会人の日常 💼', 'bio_20': '学生です 🏫',
      'bio_21': 'MBTIの話しよう 🤔', 'bio_22': 'スイーツ好き 🍰', 'bio_23': '今日もファイト！ 🔥',
      'bio_24': 'ドライブ行きたい 🚗', 'bio_25': '自転車が好き 🚲', 'bio_26': '料理が趣味 🍳',
      'bio_27': '英語勉強中 🇺🇸', 'bio_28': '気軽にメッセージどうぞ 📩', 'bio_29': '素敵な出会いを ❤️',
    },
    'Chinese': {
      'map_title': '喝一杯茶', 
      'shop_title': '商店', 
      'shop_desc': '收集你的十二生肖角色！',
      'buy_btn': '购买', 'equip_btn': '使用中', 'equipped_btn': '使用',
      'cost': '5 茶叶', 'not_enough_tea': '茶叶不足！ 😢', 'buy_success': '购买成功！ 🎉',
      'profile_title': '个人资料', 'nickname': '昵称', 'bio': '自我介绍', 'age': '年龄', 'gender': '性别', 
      'save': '保存', 'interests': '兴趣', 'language': '语言', 'logout': '退出',
      'greet': '打招呼', 'poke_sent': '👋 戳了一下！', 'chat': '申请聊天', 'chat_req_sent': '💌 已发送聊天请求！',
      'block': '屏蔽', 'report': '举报', 'report_reason_hint': '输入举报理由', 'cancel': '取消', 'submit': '提交',
      'tea_leaves': '茶叶',
      'inventory': '我的库存 🎒', // 👈 Added

      // 🍵 Tea Bundles
      'tea_10': '茶叶 10个', 'price_10': '\$9.5',
      'tea_50': '茶叶 50个', 'price_50': '\$45',
      'tea_100': '茶叶 100个', 'price_100': '\$93',
      'tea_200': '茶叶 200个', 'price_200': '\$180',
      'tea_500': '茶叶 500个', 'price_500': '\$400',
      'tea_1000': '茶叶 1,000个', 'price_1000': '\$750',

      'rat': '鼠', 'ox': '牛', 'tiger': '虎', 'rabbit': '兔', 'dragon': '龙', 'snake': '蛇',
      'horse': '马', 'sheep': '羊', 'monkey': '猴', 'rooster': '鸡', 'dog': '狗', 'pig': '猪',

      'adj_0': '幸福的', 'adj_1': '勇敢的', 'adj_2': '困倦的', 'adj_3': '快速的', 'adj_4': '聪明的',
      'adj_5': '饥饿的', 'adj_6': '酷的', 'adj_7': '可爱的', 'adj_8': '生气的', 'adj_9': '悲伤的',
      'adj_10': '强大的', 'adj_11': '安静的', 'adj_12': '吵闹的', 'adj_13': '亲切的', 'adj_14': '冷漠的',
      'adj_15': '热情的', 'adj_16': '富有的', 'adj_17': '贫穷的', 'adj_18': '忙碌的', 'adj_19': '懒惰的',

      // 🎲 Random Bio 30 (Chinese)
      'bio_0': '你好！很高兴认识你 👋', 'bio_1': '喝杯咖啡吗？ ☕', 'bio_2': '我喜欢散步 🌿',
      'bio_3': '一起去吃美食吧 🍕', 'bio_4': '周末去爬山 ⛰️', 'bio_5': '我是电影迷 🎬',
      'bio_6': '寻找健身伙伴 💪', 'bio_7': '想聊聊心事 💬', 'bio_8': '好无聊，求聊天 🎈',
      'bio_9': '结交新朋友 🤝', 'bio_10': '我热爱旅行 ✈️', 'bio_11': '安静读书的时间 📚',
      'bio_12': '无音乐不生活 🎧', 'bio_13': '一起打游戏吗？ 🎮', 'bio_14': '我喜欢摄影 📸',
      'bio_15': '喜欢喝啤酒 🍺', 'bio_16': '充满正能量 ✨', 'bio_17': '我爱小动物 🐶',
      'bio_18': '我是程序员 💻', 'bio_19': '上班族的生活 💼', 'bio_20': '我是学生 🏫',
      'bio_21': '聊聊MBTI吗？ 🤔', 'bio_22': '喜欢甜点 🍰', 'bio_23': '今天也要加油！ 🔥',
      'bio_24': '想去兜风 🚗', 'bio_25': '喜欢骑行 🚲', 'bio_26': '爱好是做饭 🍳',
      'bio_27': '正在学英语 🇺🇸', 'bio_28': '欢迎私信 📩', 'bio_29': '等待有缘人 ❤️',
    },
    'Spanish': {
      'map_title': 'ChaHanJan', 
      'shop_title': 'Tienda', 
      'shop_desc': '¡Colecciona tus personajes del zodiaco!',
      'buy_btn': 'Comprar', 'equip_btn': 'Equipado', 'equipped_btn': 'Equipar',
      'cost': '5 Té', 'not_enough_tea': '¡No hay suficiente té! 😢', 'buy_success': '¡Comprado! 🎉',
      'profile_title': 'Perfil', 'nickname': 'Apodo', 'bio': 'Biografía', 'age': 'Edad', 'gender': 'Género', 
      'save': 'Guardar', 'interests': 'Intereses', 'language': 'Idioma', 'logout': 'Salir',
      'greet': 'Saludar', 'poke_sent': '👋 ¡Toque enviado!', 'chat': 'Chatear', 'chat_req_sent': '💌 ¡Solicitud de chat enviada!',
      'block': 'Bloquear', 'report': 'Reportar', 'report_reason_hint': 'Ingrese el motivo del reporte', 'cancel': 'Cancelar', 'submit': 'Enviar',
      'tea_leaves': 'Hojas de Té',
      'inventory': 'Mi Inventario 🎒', // 👈 Added

      // 🍵 Tea Bundles
      'tea_10': '10 Hojas de Té', 'price_10': '\$9.5',
      'tea_50': '50 Hojas de Té', 'price_50': '\$45',
      'tea_100': '100 Hojas de Té', 'price_100': '\$93',
      'tea_200': '200 Hojas de Té', 'price_200': '\$180',
      'tea_500': '500 Hojas de Té', 'price_500': '\$400',
      'tea_1000': '1,000 Hojas de Té', 'price_1000': '\$750',

      'rat': 'Rata', 'ox': 'Buey', 'tiger': 'Tigre', 'rabbit': 'Conejo', 'dragon': 'Dragón', 'snake': 'Serpiente',
      'horse': 'Caballo', 'sheep': 'Oveja', 'monkey': 'Mono', 'rooster': 'Gallo', 'dog': 'Perro', 'pig': 'Cerdo',

      'adj_0': 'Feliz', 'adj_1': 'Valiente', 'adj_2': 'Soñoliento', 'adj_3': 'Rápido', 'adj_4': 'Inteligente',
      'adj_5': 'Hambriento', 'adj_6': 'Genial', 'adj_7': 'Lindo', 'adj_8': 'Enojado', 'adj_9': 'Triste',
      'adj_10': 'Fuerte', 'adj_11': 'Tranquilo', 'adj_12': 'Ruidoso', 'adj_13': 'Amable', 'adj_14': 'Frío',
      'adj_15': 'Caliente', 'adj_16': 'Rico', 'adj_17': 'Pobre', 'adj_18': 'Ocupado', 'adj_19': 'Perezoso',

      // 🎲 Random Bio 30 (Spanish)
      'bio_0': '¡Hola! Encantado 👋', 'bio_1': '¿Un café? ☕', 'bio_2': 'Me gusta pasear 🌿',
      'bio_3': 'Vamos por pizza 🍕', 'bio_4': 'Senderismo el finde ⛰️', 'bio_5': 'Amante del cine 🎬',
      'bio_6': 'Busco compa de gym 💪', 'bio_7': 'Charlas profundas 💬', 'bio_8': 'Aburrido, juguemos 🎈',
      'bio_9': 'Buscando amigos 🤝', 'bio_10': 'Amo viajar ✈️', 'bio_11': 'Tiempo de lectura 📚',
      'bio_12': 'Amo la música 🎧', 'bio_13': 'Soy Gamer 🎮', 'bio_14': 'Me gusta la fotografía 📸',
      'bio_15': 'Cerveza por favor 🍺', 'bio_16': 'Solo buenas vibras ✨', 'bio_17': 'Amo los animales 🐶',
      'bio_18': 'Soy programador 💻', 'bio_19': 'Vida de oficina 💼', 'bio_20': 'Soy estudiante 🏫',
      'bio_21': 'Hablemos de MBTI 🤔', 'bio_22': 'Amo los postres 🍰', 'bio_23': '¡Vamos con todo! 🔥',
      'bio_24': 'Quiero conducir 🚗', 'bio_25': 'Me gusta el ciclismo 🚲', 'bio_26': 'Cocinar es mi hobby 🍳',
      'bio_27': 'Aprendiendo inglés 🇺🇸', 'bio_28': 'Escríbeme 📩', 'bio_29': 'Esperando el amor ❤️',
    },
    'Hindi': {
      'map_title': 'ChaHanJan', 
      'shop_title': 'दुकान', 
      'shop_desc': 'अपना राशि चक्र चरित्र लीजिए!',
      'buy_btn': 'खरीदें', 'equip_btn': 'पहना हुआ', 'equipped_btn': 'पहन लो',
      'cost': '5 चाय', 'not_enough_tea': 'पर्याप्त चाय नहीं है! 😢', 'buy_success': 'सफल खरीद! 🎉',
      'profile_title': 'प्रोफ़ाइल', 'nickname': 'उपनाम', 'bio': 'परिचय', 'age': 'आयु', 'gender': 'लिंग', 
      'save': 'सहेजें', 'interests': 'रुचियां', 'language': 'भाषा', 'logout': 'लॉग आउट',
      'greet': 'नमस्ते कहें', 'poke_sent': '👋 पोक किया!', 'chat': 'बातचीत करें', 'chat_req_sent': '💌 चैट अनुरोध भेजा गया!',
      'block': 'ब्लॉक करें', 'report': 'रिपोर्ट करें', 'report_reason_hint': 'रिपोर्ट का कारण दर्ज करें', 'cancel': 'रद्द करें', 'submit': 'जमा करें',
      'tea_leaves': 'चाय की पत्तियां',
      'inventory': 'मेरी सूची 🎒', // 👈 Added

      // 🍵 Tea Bundles
      'tea_10': '10 चाय की पत्तियां', 'price_10': '\$9.5',
      'tea_50': '50 चाय की पत्तियां', 'price_50': '\$45',
      'tea_100': '100 चाय की पत्तियां', 'price_100': '\$93',
      'tea_200': '200 चाय की पत्तियां', 'price_200': '\$180',
      'tea_500': '500 चाय की पत्तियां', 'price_500': '\$400',
      'tea_1000': '1,000 चाय की पत्तियां', 'price_1000': '\$750',

      'rat': 'चूहा', 'ox': 'बेल', 'tiger': 'बाघ', 'rabbit': 'खरगोश', 'dragon': 'ड्रैगन', 'snake': 'सांप',
      'horse': 'घोड़ा', 'sheep': 'भेड़', 'monkey': 'बंदर', 'rooster': 'मुर्गा', 'dog': 'कुत्ता', 'pig': 'सूअर',

      'adj_0': 'खुश', 'adj_1': 'बहादुर', 'adj_2': 'नींद में', 'adj_3': 'तेज़', 'adj_4': 'होशियार',
      'adj_5': 'भूखा', 'adj_6': 'ठंडा', 'adj_7': 'प्यारा', 'adj_8': 'गुस्सा', 'adj_9': 'दुखी',
      'adj_10': 'मजबूत', 'adj_11': 'शांत', 'adj_12': 'जोर से', 'adj_13': 'दयालु', 'adj_14': 'ठंडा',
      'adj_15': 'गर्म', 'adj_16': 'अमीर', 'adj_17': 'गरीब', 'adj_18': 'व्यस्त', 'adj_19': 'आलसी',

      // 🎲 Random Bio 30 (Hindi)
      'bio_0': 'नमस्ते! 👋', 'bio_1': 'कॉफी पियेंगे? ☕', 'bio_2': 'चलना पसंद है 🌿',
      'bio_3': 'पिज्जा खाने चलते हैं 🍕', 'bio_4': 'पहाड़ों पर ट्रेकिंग ⛰️', 'bio_5': 'फिल्म प्रेमी 🎬',
      'bio_6': 'जिम पार्टनर चाहिए 💪', 'bio_7': 'गहरी बातें 💬', 'bio_8': 'बोर हो रहा हूँ 🎈',
      'bio_9': 'नए दोस्त चाहिए 🤝', 'bio_10': 'यात्रा पसंद है ✈️', 'bio_11': 'किताबें पढ़ना 📚',
      'bio_12': 'संगीत मेरी जान है 🎧', 'bio_13': 'गेमर हूँ 🎮', 'bio_14': 'फोटोग्राफी पसंद है 📸',
      'bio_15': 'बियर पसंद है 🍺', 'bio_16': 'सकारात्मक सोच ✨', 'bio_17': 'जानवर प्रेमी 🐶',
      'bio_18': 'मैं कोडर हूँ 💻', 'bio_19': 'ऑफिस लाइफ 💼', 'bio_20': 'मैं छात्र हूँ 🏫',
      'bio_21': 'MBTI की बातें? 🤔', 'bio_22': 'मिठाई पसंद है 🍰', 'bio_23': 'आपका दिन शुभ हो! 🔥',
      'bio_24': 'ड्राइव पर चलें 🚗', 'bio_25': 'साइकिल चलाना पसंद है 🚲', 'bio_26': 'खाना बनाना पसंद है 🍳',
      'bio_27': 'अंग्रेजी सीख रहा हूँ 🇺🇸', 'bio_28': 'मैसेज करें 📩', 'bio_29': 'सच्चे प्यार का इंतजार ❤️',
    },
  };

  static String language = 'Korean';

  // 1-arg version using static language (for backward compatibility)
  static String get(String key) {
    return data[language]?[key] ?? data['Korean']?[key] ?? key;
  }
  
  // 2-arg version for explicit language selection
  static String getByLang(String lang, String key) {
    return data[lang]?[key] ?? data['Korean']?[key] ?? key;
  }
  
  // Helper for dummy data if needed by map_screen.dart
  static List<String> getList(String key) {
     // Dummy implementation to prevent errors if map_screen.dart calls it.
     // In a real app, this should return localized lists.
     if (key == 'dummy_names') return ['User1', 'User2', 'User3', 'User4'];
     if (key == 'dummy_bios') return ['Bio1', 'Bio2', 'Bio3', 'Bio4'];
     return [];
  }
}
