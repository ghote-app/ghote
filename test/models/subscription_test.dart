import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/subscription.dart';

void main() {
  group('Subscription', () {
    final testStartDate = DateTime(2025, 1, 1);
    final testEndDate = DateTime(2025, 12, 31);

    Subscription createTestSubscription({
      String userId = 'user_1',
      String plan = 'free',
      DateTime? proStartDate,
      DateTime? proEndDate,
      bool isActive = true,
      String? paymentProvider,
    }) {
      return Subscription(
        userId: userId,
        plan: plan,
        proStartDate: proStartDate,
        proEndDate: proEndDate,
        isActive: isActive,
        paymentProvider: paymentProvider,
      );
    }

    group('Constructor', () {
      test('should create Subscription with required parameters', () {
        final sub = createTestSubscription();

        expect(sub.userId, 'user_1');
        expect(sub.plan, 'free');
        expect(sub.isActive, true);
      });

      test('should create Subscription with optional parameters', () {
        final sub = createTestSubscription(
          plan: 'pro',
          proStartDate: testStartDate,
          proEndDate: testEndDate,
          paymentProvider: 'stripe',
        );

        expect(sub.proStartDate, testStartDate);
        expect(sub.proEndDate, testEndDate);
        expect(sub.paymentProvider, 'stripe');
      });
    });

    group('Plan getters', () {
      test('isPro should return true for active pro plan', () {
        final sub = createTestSubscription(plan: 'pro', isActive: true);
        expect(sub.isPro, true);
        expect(sub.isPlus, false);
        expect(sub.isFree, false);
      });

      test('isPro should return false for inactive pro plan', () {
        final sub = createTestSubscription(plan: 'pro', isActive: false);
        expect(sub.isPro, false);
        expect(sub.isFree, true);
      });

      test('isPlus should return true for active plus plan', () {
        final sub = createTestSubscription(plan: 'plus', isActive: true);
        expect(sub.isPlus, true);
        expect(sub.isPro, false);
        expect(sub.isFree, false);
      });

      test('isFree should return true for free plan', () {
        final sub = createTestSubscription(plan: 'free', isActive: true);
        expect(sub.isFree, true);
        expect(sub.isPro, false);
        expect(sub.isPlus, false);
      });

      test('isFree should return true when not active', () {
        final sub = createTestSubscription(plan: 'pro', isActive: false);
        expect(sub.isFree, true);
      });
    });

    group('Capability getters', () {
      test('hasUnlimitedCloudStorage should be true for pro', () {
        final proSub = createTestSubscription(plan: 'pro', isActive: true);
        final freeSub = createTestSubscription(plan: 'free', isActive: true);

        expect(proSub.hasUnlimitedCloudStorage, true);
        expect(freeSub.hasUnlimitedCloudStorage, false);
      });

      test('usesOpenAIOrClaude should be true for pro', () {
        final proSub = createTestSubscription(plan: 'pro', isActive: true);
        final freeSub = createTestSubscription(plan: 'free', isActive: true);

        expect(proSub.usesOpenAIOrClaude, true);
        expect(freeSub.usesOpenAIOrClaude, false);
      });

      test('usesGeminiFree should be true for free and plus', () {
        final freeSub = createTestSubscription(plan: 'free', isActive: true);
        final plusSub = createTestSubscription(plan: 'plus', isActive: true);
        final proSub = createTestSubscription(plan: 'pro', isActive: true);

        expect(freeSub.usesGeminiFree, true);
        expect(plusSub.usesGeminiFree, true);
        expect(proSub.usesGeminiFree, false);
      });

      test('monthlyAiQuota should return correct values', () {
        final proSub = createTestSubscription(plan: 'pro', isActive: true);
        final freeSub = createTestSubscription(plan: 'free', isActive: true);

        expect(proSub.monthlyAiQuota, 500);
        expect(freeSub.monthlyAiQuota, 50);
      });
    });

    group('copyWith', () {
      test('should copy with new values', () {
        final original = createTestSubscription();
        final copied = original.copyWith(
          plan: 'pro',
          isActive: true,
          paymentProvider: 'google_play',
        );

        expect(copied.plan, 'pro');
        expect(copied.paymentProvider, 'google_play');
        expect(copied.userId, original.userId);
      });

      test('should preserve original values when not specified', () {
        final original = createTestSubscription(
          plan: 'pro',
          proStartDate: testStartDate,
          proEndDate: testEndDate,
          paymentProvider: 'stripe',
        );
        final copied = original.copyWith();

        expect(copied.userId, original.userId);
        expect(copied.plan, original.plan);
        expect(copied.proStartDate, original.proStartDate);
        expect(copied.paymentProvider, original.paymentProvider);
      });
    });

    group('toJson', () {
      test('should convert Subscription to Map', () {
        final sub = createTestSubscription(
          plan: 'pro',
          proStartDate: testStartDate,
          proEndDate: testEndDate,
          paymentProvider: 'stripe',
        );
        final json = sub.toJson();

        expect(json['userId'], 'user_1');
        expect(json['plan'], 'pro');
        expect(json['proStartDate'], testStartDate.toIso8601String());
        expect(json['proEndDate'], testEndDate.toIso8601String());
        expect(json['isActive'], true);
        expect(json['paymentProvider'], 'stripe');
      });

      test('should handle null dates', () {
        final sub = createTestSubscription();
        final json = sub.toJson();

        expect(json['proStartDate'], null);
        expect(json['proEndDate'], null);
      });
    });

    group('fromJson', () {
      test('should create Subscription from Map', () {
        final json = {
          'userId': 'user_1',
          'plan': 'pro',
          'proStartDate': '2025-01-01T00:00:00.000',
          'proEndDate': '2025-12-31T00:00:00.000',
          'isActive': true,
          'paymentProvider': 'stripe',
        };

        final sub = Subscription.fromJson(json);

        expect(sub.userId, 'user_1');
        expect(sub.plan, 'pro');
        expect(sub.proStartDate, testStartDate);
        expect(sub.proEndDate, testEndDate);
        expect(sub.isActive, true);
        expect(sub.paymentProvider, 'stripe');
      });

      test('should handle null dates in JSON', () {
        final json = {
          'userId': 'user_1',
          'plan': 'free',
          'proStartDate': null,
          'proEndDate': null,
          'isActive': true,
        };

        final sub = Subscription.fromJson(json);

        expect(sub.proStartDate, null);
        expect(sub.proEndDate, null);
      });

      test('should default isActive to false if not provided', () {
        final json = {
          'userId': 'user_1',
          'plan': 'free',
          'proStartDate': null,
          'proEndDate': null,
        };

        final sub = Subscription.fromJson(json);
        expect(sub.isActive, false);
      });
    });

    group('JSON round trip', () {
      test('should preserve all data through JSON serialization', () {
        final original = createTestSubscription(
          plan: 'pro',
          proStartDate: testStartDate,
          proEndDate: testEndDate,
          paymentProvider: 'app_store',
        );

        final json = original.toJson();
        final restored = Subscription.fromJson(json);

        expect(restored.userId, original.userId);
        expect(restored.plan, original.plan);
        expect(restored.proStartDate, original.proStartDate);
        expect(restored.proEndDate, original.proEndDate);
        expect(restored.isActive, original.isActive);
        expect(restored.paymentProvider, original.paymentProvider);
      });
    });
  });
}
