import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../ui/pages/lost_found_page.dart';
import '../ui/pages/study_help_page.dart';
import '../ui/pages/tuition_calculator_page.dart';
import 'app_navigator.dart';

class PushNotificationService {
  PushNotificationService._();

  static StreamSubscription<AuthState>? _authSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;
  static StreamSubscription<String>? _tokenSubscription;
  static String? _registeredUserId;
  static String? _registeredToken;
  static Future<void>? _registrationInProgress;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || defaultTargetPlatform != TargetPlatform.android) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title;
      final body = message.notification?.body;
      if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
        return;
      }
      campusMateScaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title ?? 'CampusMate'),
              if (body != null && body.isNotEmpty) Text(body),
            ],
          ),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => unawaited(_openDestination(message.data)),
          ),
        ),
      );
    });
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => unawaited(_openDestination(message.data)),
    );
    _tokenSubscription = messaging.onTokenRefresh.listen((_) {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) unawaited(_registerToken(userId));
    });
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (event) {
        final userId = event.session?.user.id;
        if (userId != null) unawaited(_registerToken(userId));
      },
    );

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      unawaited(_openDestination(initialMessage.data));
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) await _registerToken(userId);
  }

  static Future<void> unregisterCurrentDevice() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final token = _registeredToken;
    if (userId == null || token == null) return;
    await Supabase.instance.client
        .from('push_devices')
        .delete()
        .eq('user_id', userId)
        .eq('fcm_token', token);
    _registeredUserId = null;
  }

  static Future<void> _registerToken(String userId) async {
    if (_registeredUserId == userId && _registeredToken != null) return;
    if (_registrationInProgress != null) {
      try {
        await _registrationInProgress;
      } catch (_) {
        // A concurrent refresh can retry token registration below.
      }
      if (_registeredUserId == userId && _registeredToken != null) return;
    }
    final pending = _saveToken(userId);
    _registrationInProgress = pending;
    try {
      await pending;
    } catch (error) {
      debugPrint('CampusMate could not register this device for push: $error');
    } finally {
      if (identical(_registrationInProgress, pending)) {
        _registrationInProgress = null;
      }
    }
  }

  static Future<void> _saveToken(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await Supabase.instance.client.from('push_devices').upsert(
      {
        'user_id': userId,
        'fcm_token': token,
        'platform': 'android',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      },
      onConflict: 'fcm_token',
    );
    _registeredUserId = userId;
    _registeredToken = token;
  }

  static Future<void> _openDestination(Map<String, dynamic> data) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final navigator = await _waitForNavigator();
    if (navigator == null) return;

    try {
      switch (data['type']) {
        case 'tuition_reminder':
          await navigator.push<void>(MaterialPageRoute<void>(
            builder: (_) => const TuitionCalculatorPage(),
          ));
          break;
        case 'lost_found_response':
          final post = await Supabase.instance.client
              .from('lost_found_posts')
              .select()
              .eq('id', data['post_id'] as String)
              .single();
          await navigator.push<void>(MaterialPageRoute<void>(
            builder: (_) => LostFoundDetailsPage(
              post: Map<String, dynamic>.from(post),
            ),
          ));
          break;
        case 'chat_message':
          final chat = await Supabase.instance.client
              .from('study_help_chats')
              .select()
              .eq('id', data['chat_id'] as String)
              .single();
          final post = await Supabase.instance.client
              .from('study_help_posts')
              .select()
              .eq('id', chat['post_id'] as String)
              .single();
          await navigator.push<void>(MaterialPageRoute<void>(
            builder: (_) => StudyHelpChatPage(
              chat: {
                ...Map<String, dynamic>.from(chat),
                'post_details': Map<String, dynamic>.from(post),
              },
            ),
          ));
          break;
      }
    } catch (_) {
      // A deleted post/chat or an expired session should not crash app launch.
    }
  }

  static Future<NavigatorState?> _waitForNavigator() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final navigator = campusMateNavigatorKey.currentState;
      if (navigator != null) return navigator;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  static Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    await _tokenSubscription?.cancel();
    _initialized = false;
  }
}
