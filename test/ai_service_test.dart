import 'package:flutter_test/flutter_test.dart';
import 'package:agriflow_mobile/services/ai_service.dart';

void main() {
  test('AIService can be instantiated', () {
    final aiService = AIService();
    expect(aiService, isNotNull);
  });
}
