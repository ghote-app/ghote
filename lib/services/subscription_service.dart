import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/subscription.dart';

/// SubscriptionService defines the contract for reading and updating
/// a user's subscription status. Implementation will be added later
/// (e.g., backed by Firestore and server-side verification).
class SubscriptionService {
  SubscriptionService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// 讀取使用者訂閱：users/{uid}/subscription/current
  Future<Subscription> getUserSubscription(String userId) async {
    try {
      if (userId.isEmpty) {
        return const Subscription(
          userId: '',
          plan: 'free',
          proStartDate: null,
          proEndDate: null,
          isActive: true,
        );
      }
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .get();
      if (!doc.exists) {
        return Subscription(
          userId: userId,
          plan: 'free',
          proStartDate: null,
          proEndDate: null,
          isActive: true,
          paymentProvider: null,
        );
      }
      final data = doc.data()!;
      return Subscription.fromJson({
        'userId': userId,
        ...data,
      });
    } catch (e) {
      debugPrint('getUserSubscription error: $e');
      return Subscription(
        userId: userId,
        plan: 'free',
        proStartDate: null,
        proEndDate: null,
        isActive: true,
        paymentProvider: null,
      );
    }
  }

  /// 設定測試方案（free/plus/pro）到 users/{uid}/subscription/current
  Future<void> setTestPlan({required String userId, required String plan}) async {
    assert(plan == 'free' || plan == 'plus' || plan == 'pro');
    // 僅允許特定開發者 UID 觸發此方法，且只能改自己的訂閱文件
    const String allowedDevUid = 'zytg5Pr9JnhgaYSnyIw3JyhdS3m1';
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid != allowedDevUid || userId != allowedDevUid) {
      throw StateError('Permission denied: developer switch is restricted.');
    }
    final now = DateTime.now();
    final data = {
      'plan': plan,
      'isActive': true,
      'proStartDate': plan == 'pro' ? now.toIso8601String() : null,
      'proEndDate': null,
      'paymentProvider': 'test',
    };
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('subscription')
        .doc('current')
        .set(data, SetOptions(merge: true));
  }

  /// Whether the user can upload to cloud storage based on their plan.
  bool canUploadToCloud(Subscription subscription) {
    // free/plus: limited cloud (handled by StorageService); pro: unlimited
    return subscription.isPlus || subscription.isPro;
  }

  /// Whether the user can create another project.
  bool canCreateProject({required int currentProjectCount, required Subscription subscription}) {
    return subscription.isPro || currentProjectCount < 3;
  }

  /// Whether the user can add another file into a project.
  bool canAddFile({required int currentFileCountInProject, required Subscription subscription}) {
    return subscription.isPro || currentFileCountInProject < 10;
  }

  /// Initiate upgrade flow to Pro. Actual implementation will vary by platform/provider.
  Future<void> upgradeToPro({required String userId, required String paymentToken}) async {
    // TODO: Integrate with Stripe / Google Play / App Store via backend.
    debugPrint('upgradeToPro called for userId=$userId with paymentToken=$paymentToken');
  }
}


