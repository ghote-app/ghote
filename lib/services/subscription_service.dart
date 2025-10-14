import 'package:flutter/foundation.dart';

import '../models/subscription.dart';

/// SubscriptionService defines the contract for reading and updating
/// a user's subscription status. Implementation will be added later
/// (e.g., backed by Firestore and server-side verification).
class SubscriptionService {
  /// Fetch the latest subscription for the given user.
  Future<Subscription> getUserSubscription(String userId) async {
    // Placeholder: integrate with Firestore or a backend endpoint.
    // Returning a default free plan for now to unblock UI integration.
    debugPrint('getUserSubscription called for userId=$userId');
    return Subscription(
      userId: userId,
      plan: 'free',
      proStartDate: null,
      proEndDate: null,
      isActive: true,
      paymentProvider: null,
    );
  }

  /// Whether the user can upload to cloud storage based on their plan.
  bool canUploadToCloud(Subscription subscription) {
    return subscription.isPro;
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


