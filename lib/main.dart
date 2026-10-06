import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bloc/app_bloc.dart';
import 'bloc/app_events.dart';
import 'ui/pages/app_page.dart';
import 'utils/push_notification_service.dart';

const supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://umgzplbqrkpyocvcubtf.supabase.co',
);
const supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_wrJz5BG4yCL0vM0NPLiAbg_lH2AxcGm',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final configureAndroidPush =
      defaultTargetPlatform == TargetPlatform.android;
  if (configureAndroidPush) await Firebase.initializeApp();
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    runApp(const _ConfigurationRequiredApp());
    return;
  }
  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);
  final preferences = await SharedPreferences.getInstance();
  runApp(
    BlocProvider(
      create: (_) => AppBloc(Supabase.instance.client, preferences)
        ..add(RestoreSessionRequested()),
      child: const CampusMateApp(),
    ),
  );
  if (configureAndroidPush) {
    unawaited(PushNotificationService.initialize().catchError((Object error) {
      debugPrint('CampusMate push notifications could not initialize: $error');
    }));
  }
}

class _ConfigurationRequiredApp extends StatelessWidget {
  const _ConfigurationRequiredApp();

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'CampusMate is waiting for its CampusMate2 Supabase URL and publishable key. Configure SUPABASE_URL and SUPABASE_ANON_KEY to continue.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
}
