import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/subscription.dart';
import 'package:ghote/services/ai_provider_service.dart';

void main() {
  group('AiProviderService', () {
    group('Constructor', () {
      test('should create AiProviderService without API keys', () {
        const service = AiProviderService();
        expect(service, isNotNull);
      });

      test('should create AiProviderService with OpenAI key', () {
        const service = AiProviderService(openAiApiKey: 'test_openai_key');
        expect(service, isNotNull);
      });

      test('should create AiProviderService with Anthropic key', () {
        const service = AiProviderService(anthropicApiKey: 'test_anthropic_key');
        expect(service, isNotNull);
      });

      test('should create AiProviderService with both keys', () {
        const service = AiProviderService(
          openAiApiKey: 'test_openai_key',
          anthropicApiKey: 'test_anthropic_key',
        );
        expect(service, isNotNull);
      });
    });

    group('selectProvider', () {
      Subscription createSubscription({
        String plan = 'free',
        bool isActive = true,
      }) {
        return Subscription(
          userId: 'user_1',
          plan: plan,
          proStartDate: null,
          proEndDate: null,
          isActive: isActive,
        );
      }

      test('should return gemini for free subscription', () {
        const service = AiProviderService();
        final subscription = createSubscription(plan: 'free');
        
        expect(service.selectProvider(subscription), 'gemini');
      });

      test('should return gemini for plus subscription', () {
        const service = AiProviderService();
        final subscription = createSubscription(plan: 'plus');
        
        expect(service.selectProvider(subscription), 'gemini');
      });

      test('should return gemini for pro subscription without API keys', () {
        const service = AiProviderService();
        final subscription = createSubscription(plan: 'pro');
        
        expect(service.selectProvider(subscription), 'gemini');
      });

      test('should return openai for pro subscription with OpenAI key', () {
        const service = AiProviderService(openAiApiKey: 'test_openai_key');
        final subscription = createSubscription(plan: 'pro');
        
        expect(service.selectProvider(subscription), 'openai');
      });

      test('should return claude for pro subscription with only Anthropic key', () {
        const service = AiProviderService(anthropicApiKey: 'test_anthropic_key');
        final subscription = createSubscription(plan: 'pro');
        
        expect(service.selectProvider(subscription), 'claude');
      });

      test('should prefer openai over claude when both keys provided', () {
        const service = AiProviderService(
          openAiApiKey: 'test_openai_key',
          anthropicApiKey: 'test_anthropic_key',
        );
        final subscription = createSubscription(plan: 'pro');
        
        expect(service.selectProvider(subscription), 'openai');
      });

      test('should return gemini for inactive pro subscription', () {
        const service = AiProviderService(openAiApiKey: 'test_openai_key');
        final subscription = createSubscription(plan: 'pro', isActive: false);
        
        // When not active, isPro returns false, so it falls back to gemini
        expect(service.selectProvider(subscription), 'gemini');
      });

      test('should return gemini when OpenAI key is empty string', () {
        const service = AiProviderService(openAiApiKey: '');
        final subscription = createSubscription(plan: 'pro');
        
        expect(service.selectProvider(subscription), 'gemini');
      });
    });

    group('selectModel', () {
      Subscription createSubscription({
        String plan = 'free',
        bool isActive = true,
      }) {
        return Subscription(
          userId: 'user_1',
          plan: plan,
          proStartDate: null,
          proEndDate: null,
          isActive: isActive,
        );
      }

      test('should return gemini-2.5-flash-lite for free subscription', () {
        const service = AiProviderService();
        final subscription = createSubscription(plan: 'free');
        
        expect(service.selectModel(subscription), 'gemini-2.5-flash-lite');
      });

      test('should return gpt-4o-mini for pro with OpenAI key', () {
        const service = AiProviderService(openAiApiKey: 'test_openai_key');
        final subscription = createSubscription(plan: 'pro');
        
        expect(service.selectModel(subscription), 'gpt-4o-mini');
      });

      test('should return claude-3-5-sonnet-latest for pro with Anthropic key', () {
        const service = AiProviderService(anthropicApiKey: 'test_anthropic_key');
        final subscription = createSubscription(plan: 'pro');
        
        expect(service.selectModel(subscription), 'claude-3-5-sonnet-latest');
      });

      test('should return gemini model for plus subscription', () {
        const service = AiProviderService();
        final subscription = createSubscription(plan: 'plus');
        
        expect(service.selectModel(subscription), 'gemini-2.5-flash-lite');
      });
    });
  });
}
