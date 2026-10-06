import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/app_bloc.dart';
import '../../bloc/app_states.dart';
import 'auth_pages.dart';
import 'dashboard_page.dart';
import 'profile_page.dart';
import 'marketplace_page.dart';
import 'lost_found_page.dart';
import 'study_help_page.dart';
import 'ai_quiz_page.dart';
import 'freshers_corner_page.dart';
import 'cgpa_calculator_page.dart';
import 'tuition_calculator_page.dart';
import 'notifications_page.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_navigator.dart';

class CampusMateApp extends StatelessWidget {
  const CampusMateApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        navigatorKey: campusMateNavigatorKey,
        scaffoldMessengerKey: campusMateScaffoldMessengerKey,
        title: 'CampusMate',
        debugShowCheckedModeBanner: false,
        themeMode: context.select((AppBloc bloc) => bloc.state.themeMode),
        theme: campusMateLightTheme,
        darkTheme: campusMateDarkTheme,
        home: BlocBuilder<AppBloc, AppState>(builder: (context, state) {
          if (state.isRestoring) return const _StartupScreen();
          if (state.user != null) return const DashboardPage();
          if (!state.hasUsedEmail) return const WelcomePage();
          return const SignInPage();
        }),
        routes: {
          '/signin': (_) => const SignInPage(),
          '/signup': (_) => const SignUpPage(),
          '/dashboard': (_) => const DashboardPage(),
          '/profile': (_) => const ProfilePage(),
          '/marketplace': (_) => const MarketplacePage(),
          '/marketplace/create': (_) => const CreateMarketplacePostPage(),
          '/lost-found': (_) => const LostFoundPage(),
          '/study-help': (_) => const StudyHelpPage(),
          '/study-help/create': (_) => const CreateStudyHelpPostPage(),
          '/ai-quiz': (_) => const AiQuizHomePage(),
          '/freshers-corner': (_) => const FreshersCornerPage(),
          '/cgpa-calculator': (_) => const CgpaCalculatorPage(),
          '/tuition-calculator': (_) => const TuitionCalculatorPage(),
          '/notifications': (_) => const NotificationsPage(),
        },
      );
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(body: SafeArea(child: Padding(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Spacer(),
      Container(width: 84, height: 84, decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(26)), child: const Icon(Icons.school_rounded, size: 44, color: Colors.white)),
      const SizedBox(height: 28),
      Text('CampusMate', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Text('Your UIU life, all in one place.', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: colors.onSurfaceVariant)),
      const SizedBox(height: 18),
      const Text('Stay on top of tuition deadlines, campus life and everything happening around you.'),
      const Spacer(),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pushReplacementNamed(context, '/signup'), child: const Text('Get started'))),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/signin'), child: const Text('I already have an account'))),
      const SizedBox(height: 18),
    ]))));
  }
}
