import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bloc/app_bloc.dart';
import '../../bloc/app_events.dart';
import 'freshers_corner_page.dart';
import 'lost_found_page.dart';
import 'marketplace_page.dart';
import 'study_help_page.dart';
import 'tuition_calculator_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _client = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _notifications;
  bool _openingNotification = false;

  @override
  void initState() {
    super.initState();
    final userId = _client.auth.currentUser?.id;
    _notifications = userId == null
        ? Stream.value(const <Map<String, dynamic>>[])
        : _client
            .from('notifications')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .order('created_at', ascending: false);
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
    List<Map<String, dynamic>> notifications,
  ) {
    final groups = LinkedHashMap<String, List<Map<String, dynamic>>>();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    for (final notification in notifications) {
      final date = DateTime.tryParse(notification['created_at'] as String? ?? '')
          ?.toLocal();
      final dateOnly = date == null
          ? today
          : DateTime(date.year, date.month, date.day);
      final label = dateOnly == today
          ? 'Today'
          : dateOnly == yesterday
              ? 'Yesterday'
              : DateFormat('EEEE, d MMMM y').format(dateOnly);
      groups.putIfAbsent(label, () => []).add(notification);
    }
    return groups;
  }

  Future<void> _openNotification(Map<String, dynamic> notification) async {
    if (_openingNotification) return;
    setState(() => _openingNotification = true);
    try {
      final id = notification['id'] as String;
      if (notification['read_at'] == null) {
        await _client
            .from('notifications')
            .update({'read_at': DateTime.now().toUtc().toIso8601String()})
            .eq('id', id);
      }
      if (!mounted) return;
      final data = notification['data'];
      final payload = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      final type = payload['type'] as String?;
      switch (type) {
        case 'marketplace_response':
          final post = await _client
              .from('marketplace_posts')
              .select()
              .eq('id', payload['post_id'] as String)
              .single();
          if (!mounted) return;
          await Navigator.of(context).push<void>(MaterialPageRoute<void>(
            builder: (_) => MarketplacePostDetailsPage(
              post: Map<String, dynamic>.from(post),
              isMyPost: true,
              onSoldOutChanged: (isSoldOut) => context.read<AppBloc>().add(
                MarketplacePostSoldOutChanged(
                  postId: payload['post_id'] as String,
                  isSoldOut: isSoldOut,
                ),
              ),
            ),
          ));
          break;
        case 'lost_found_response':
          final post = await _client
              .from('lost_found_posts')
              .select()
              .eq('id', payload['post_id'] as String)
              .single();
          if (!mounted) return;
          await Navigator.of(context).push<void>(MaterialPageRoute<void>(
            builder: (_) => LostFoundDetailsPage(
              post: Map<String, dynamic>.from(post),
            ),
          ));
          break;
        case 'study_help_response':
          final post = await _client
              .from('study_help_posts')
              .select()
              .eq('id', payload['post_id'] as String)
              .single();
          if (!mounted) return;
          await Navigator.of(context).push<void>(MaterialPageRoute<void>(
            builder: (_) => StudyHelpDetailsPage(
              post: Map<String, dynamic>.from(post),
            ),
          ));
          break;
        case 'freshers_answer':
          final question = await _client
              .from('freshers_questions')
              .select()
              .eq('id', payload['question_id'] as String)
              .single();
          if (!mounted) return;
          await Navigator.of(context).push<void>(MaterialPageRoute<void>(
            builder: (_) => FreshersAnswersPage(
              question: Map<String, dynamic>.from(question),
            ),
          ));
          break;
        case 'tuition_reminder':
          await Navigator.of(context).push<void>(MaterialPageRoute<void>(
            builder: (_) => const TuitionCalculatorPage(),
          ));
          break;
        default:
          break;
      }
    } on PostgrestException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this notification.')),
        );
      }
    } finally {
      if (mounted) setState(() => _openingNotification = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _notifications,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Text(
                    'Could not load notifications. Please try again later.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final notifications = snapshot.data!;
            if (notifications.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 56,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 14),
                      Text('You’re all caught up',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text(
                        'New updates from your campus features will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            }
            final groups = _groupByDate(notifications);
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
              children: [
                for (final entry in groups.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(3, 8, 3, 10),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ),
                  for (final notification in entry.value) ...[
                    _NotificationTile(
                      notification: notification,
                      onTap: _openingNotification
                          ? null
                          : () => _openNotification(notification),
                    ),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 9),
                ],
              ],
            );
          },
        ),
      );
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, this.onTap});

  final Map<String, dynamic> notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final unread = notification['read_at'] == null;
    final title = notification['title'] as String? ?? 'CampusMate';
    final featureIcon = switch (title) {
      'Marketplace' => Icons.storefront_rounded,
      'Lost and Found' => Icons.travel_explore_rounded,
      'Study Help' => Icons.auto_stories_rounded,
      "Freshers' Corner" => Icons.waving_hand_rounded,
      'Tuition fee reminder' => Icons.account_balance_wallet_outlined,
      _ => Icons.notifications_none_rounded,
    };
    final createdAt = DateTime.tryParse(
      notification['created_at'] as String? ?? '',
    )?.toLocal();
    final time = createdAt == null ? '' : DateFormat('h:mm a').format(createdAt);
    return Material(
      color: unread
          ? colors.primaryContainer.withValues(alpha: 0.52)
          : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: unread
                  ? colors.primary.withValues(alpha: 0.32)
                  : colors.outlineVariant.withValues(alpha: 0.52),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                featureIcon,
                color: unread ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: colors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification['body'] as String? ?? '',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: unread ? FontWeight.w600 : FontWeight.normal,
                            color: unread ? colors.onSurface : colors.onSurfaceVariant,
                          ),
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        time,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
