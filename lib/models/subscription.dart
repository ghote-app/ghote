// Subscription model represents a user's subscription status and plan.
// This model is designed for clarity and includes helpers for (de)serialization.

class Subscription {
  final String userId;
  final String plan; // 'free' or 'pro'
  final DateTime? proStartDate;
  final DateTime? proEndDate;
  final bool isActive;
  final String? paymentProvider; // 'stripe', 'google_play', 'app_store'

  const Subscription({
    required this.userId,
    required this.plan,
    required this.proStartDate,
    required this.proEndDate,
    required this.isActive,
    this.paymentProvider,
  });

  bool get isPro => plan == 'pro' && isActive;
  bool get isFree => !isPro;

  Subscription copyWith({
    String? userId,
    String? plan,
    DateTime? proStartDate,
    DateTime? proEndDate,
    bool? isActive,
    String? paymentProvider,
  }) {
    return Subscription(
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      proStartDate: proStartDate ?? this.proStartDate,
      proEndDate: proEndDate ?? this.proEndDate,
      isActive: isActive ?? this.isActive,
      paymentProvider: paymentProvider ?? this.paymentProvider,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'plan': plan,
      'proStartDate': proStartDate?.toIso8601String(),
      'proEndDate': proEndDate?.toIso8601String(),
      'isActive': isActive,
      'paymentProvider': paymentProvider,
    };
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      userId: json['userId'] as String,
      plan: json['plan'] as String,
      proStartDate: json['proStartDate'] != null
          ? DateTime.parse(json['proStartDate'] as String)
          : null,
      proEndDate: json['proEndDate'] != null
          ? DateTime.parse(json['proEndDate'] as String)
          : null,
      isActive: (json['isActive'] as bool?) ?? false,
      paymentProvider: json['paymentProvider'] as String?,
    );
  }
}


