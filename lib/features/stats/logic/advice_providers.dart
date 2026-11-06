import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/gemini_advice_client.dart';

final Provider<GeminiAdviceClient> geminiAdviceClientProvider =
    Provider<GeminiAdviceClient>((ref) {
  return GeminiAdviceClient();
});
