import 'package:translator/translator.dart';

class HolyTranslator {
  static final GoogleTranslator _translator = GoogleTranslator();

  // 📖 성스러운 번역 (Google Translate API)
  static Future<String> translate({
    required String text,
    required String source,
    required String target,
  }) async {
    try {
      // 언어가 같으면 번역 불필요
      if (source == target) return text;

      final translation = await _translator.translate(
        text,
        from: source,
        to: target,
      );
      return translation.text;
    } catch (e) {
      print("❌ HolyTranslator Error: $e");
      return text; // 실패 시 원문 반환
    }
  }
}
