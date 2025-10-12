import 'package:go_router/go_router.dart';
import 'home_page.dart';
import 'terms_of_service_page.dart';
import 'privacy_policy_page.dart';

final GoRouter websiteRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsOfServicePage(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyPolicyPage(),
    ),
  ],
);
