import 'package:flutter_test/flutter_test.dart';
import 'package:ghote/models/subscription.dart';
import 'package:ghote/services/subscription_service.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  group('SubscriptionService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late SubscriptionService subscriptionService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      subscriptionService = SubscriptionService(firestore: fakeFirestore);
    });

    group('Constructor', () {
      test('should create SubscriptionService with custom Firestore', () {
        final service = SubscriptionService(firestore: fakeFirestore);
        expect(service, isNotNull);
      });
    });

    group('getUserSubscription', () {
      test('should return free subscription for empty userId', () async {
        final subscription = await subscriptionService.getUserSubscription('');
        
        expect(subscription.userId, '');
        expect(subscription.plan, 'free');
        expect(subscription.isActive, true);
      });

      test('should return free subscription when no document exists', () async {
        final subscription = await subscriptionService.getUserSubscription('user_1');
        
        expect(subscription.userId, 'user_1');
        expect(subscription.plan, 'free');
        expect(subscription.isActive, true);
      });

      test('should return subscription from Firestore when exists', () async {
        await fakeFirestore
            .collection('users')
            .doc('user_1')
            .collection('subscription')
            .doc('current')
            .set({
          'plan': 'pro',
          'isActive': true,
          'proStartDate': '2025-01-01T00:00:00.000',
          'proEndDate': '2025-12-31T00:00:00.000',
          'paymentProvider': 'stripe',
        });

        final subscription = await subscriptionService.getUserSubscription('user_1');
        
        expect(subscription.userId, 'user_1');
        expect(subscription.plan, 'pro');
        expect(subscription.isActive, true);
        expect(subscription.paymentProvider, 'stripe');
      });

      test('should return plus subscription when stored', () async {
        await fakeFirestore
            .collection('users')
            .doc('user_2')
            .collection('subscription')
            .doc('current')
            .set({
          'plan': 'plus',
          'isActive': true,
        });

        final subscription = await subscriptionService.getUserSubscription('user_2');
        
        expect(subscription.plan, 'plus');
        expect(subscription.isActive, true);
      });
    });

    group('canUploadToCloud', () {
      test('should return false for free subscription', () {
        const freeSubscription = Subscription(
          userId: 'user_1',
          plan: 'free',
          proStartDate: null,
          proEndDate: null,
          isActive: true,
        );

        expect(subscriptionService.canUploadToCloud(freeSubscription), false);
      });

      test('should return true for plus subscription', () {
        const plusSubscription = Subscription(
          userId: 'user_1',
          plan: 'plus',
          proStartDate: null,
          proEndDate: null,
          isActive: true,
        );

        expect(subscriptionService.canUploadToCloud(plusSubscription), true);
      });

      test('should return true for pro subscription', () {
        final proSubscription = Subscription(
          userId: 'user_1',
          plan: 'pro',
          proStartDate: DateTime.now(),
          proEndDate: DateTime.now().add(const Duration(days: 30)),
          isActive: true,
        );

        expect(subscriptionService.canUploadToCloud(proSubscription), true);
      });
    });

    group('canCreateProject', () {
      test('should return true for pro subscription regardless of count', () {
        final proSubscription = Subscription(
          userId: 'user_1',
          plan: 'pro',
          proStartDate: DateTime.now(),
          proEndDate: DateTime.now().add(const Duration(days: 30)),
          isActive: true,
        );

        expect(subscriptionService.canCreateProject(
          currentProjectCount: 10,
          subscription: proSubscription,
        ), true);
      });

      test('should return true for free subscription with less than 3 projects', () {
        const freeSubscription = Subscription(
          userId: 'user_1',
          plan: 'free',
          proStartDate: null,
          proEndDate: null,
          isActive: true,
        );

        expect(subscriptionService.canCreateProject(
          currentProjectCount: 2,
          subscription: freeSubscription,
        ), true);
      });

      test('should return false for free subscription with 3 or more projects', () {
        const freeSubscription = Subscription(
          userId: 'user_1',
          plan: 'free',
          proStartDate: null,
          proEndDate: null,
          isActive: true,
        );

        expect(subscriptionService.canCreateProject(
          currentProjectCount: 3,
          subscription: freeSubscription,
        ), false);
      });
    });

    group('canAddFile', () {
      test('should return true for pro subscription regardless of count', () {
        final proSubscription = Subscription(
          userId: 'user_1',
          plan: 'pro',
          proStartDate: DateTime.now(),
          proEndDate: DateTime.now().add(const Duration(days: 30)),
          isActive: true,
        );

        expect(subscriptionService.canAddFile(
          currentFileCountInProject: 100,
          subscription: proSubscription,
        ), true);
      });

      test('should return true for free subscription with less than 10 files', () {
        const freeSubscription = Subscription(
          userId: 'user_1',
          plan: 'free',
          proStartDate: null,
          proEndDate: null,
          isActive: true,
        );

        expect(subscriptionService.canAddFile(
          currentFileCountInProject: 5,
          subscription: freeSubscription,
        ), true);
      });

      test('should return false for free subscription with 10 or more files', () {
        const freeSubscription = Subscription(
          userId: 'user_1',
          plan: 'free',
          proStartDate: null,
          proEndDate: null,
          isActive: true,
        );

        expect(subscriptionService.canAddFile(
          currentFileCountInProject: 10,
          subscription: freeSubscription,
        ), false);
      });
    });
  });
}
