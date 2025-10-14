import '../models/subscription.dart';

/// AiProviderService selects the underlying AI model/provider
/// based on the user's subscription plan and available keys.
///
/// free/plus -> Gemini Flash 2.5 (free model)
/// pro       -> OpenAI or Claude (prefer OpenAI if token is set)
class AiProviderService {
  const AiProviderService({
    String? openAiApiKey,
    String? anthropicApiKey,
  })  : _openAiApiKey = openAiApiKey,
        _anthropicApiKey = anthropicApiKey;

  final String? _openAiApiKey;
  final String? _anthropicApiKey;

  /// Returns a provider identifier string: 'gemini' | 'openai' | 'claude'
  String selectProvider(Subscription subscription) {
    if (subscription.isPro) {
      if (_openAiApiKey != null && _openAiApiKey.isNotEmpty) return 'openai';
      if (_anthropicApiKey != null && _anthropicApiKey.isNotEmpty) return 'claude';
      // Fallback to free provider if no keys configured
      return 'gemini';
    }
    // free/plus
    return 'gemini';
  }

  /// Returns a model name to use with the selected provider.
  /// You can wire this into your actual inference clients elsewhere.
  String selectModel(Subscription subscription) {
    final provider = selectProvider(subscription);
    switch (provider) {
      case 'openai':
        // Choose your preferred high-quality OpenAI model
        return 'gpt-4o-mini';
      case 'claude':
        // Claude Sonnet for higher quality
        return 'claude-3-5-sonnet-latest';
      case 'gemini':
      default:
        // Free tier model
        return 'gemini-2.5-flash';
    }
  }
}


