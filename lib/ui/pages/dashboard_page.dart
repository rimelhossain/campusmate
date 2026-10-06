import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bloc/app_bloc.dart';
import '../../bloc/app_states.dart';
import 'study_help_page.dart';
import 'notifications_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _tab = 0;
  final _client = Supabase.instance.client;
  Future<List<Map<String, dynamic>>>? _deadlines;

  @override
  void initState() {
    super.initState();
    _deadlines = _loadDeadlines();
  }

  Future<List<Map<String, dynamic>>> _loadDeadlines() async => _client
      .from('tuition_installments')
      .select('id,label,due_on')
      .not('due_on', 'is', null)
      .order('id');

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: _tab == 0 ? _home() : const StudyHelpChatsPage()),
        bottomNavigationBar: NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (v) => setState(() => _tab = v),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home'),
              NavigationDestination(
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                  selectedIcon: Icon(Icons.chat_bubble_rounded),
                  label: 'Chats')
            ]),
      );

  Widget _home() {
    final user = _client.auth.currentUser;
    final name = (user?.userMetadata?['full_name'] as String?)?.trim();
    final greetingName = name == null || name.isEmpty
        ? 'there'
        : name;
    final avatar = user?.userMetadata?['avatar_path'] as String?;
    return CustomScrollView(slivers: [
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
          sliver: SliverList.list(children: [
            Row(children: [
              const Spacer(),
              _NotificationButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationsPage(),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                  onTap: () async {
                    await Navigator.pushNamed(context, '/profile');
                    if (mounted) setState(() {});
                  },
                  child: _Avatar(url: avatar, name: name ?? 'U', radius: 21)),
            ]),
            const SizedBox(height: 15),
            Text('Hello, $greetingName ',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text('A little more organized, every day.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),
            _TuitionCard(deadlines: _deadlines ??= _loadDeadlines()),
            const SizedBox(height: 27),
            const _SectionHeader(
                title: 'Campus life',
                subtitle: 'Make the most of your time on campus'),
            const SizedBox(height: 13),
            _FeatureGrid(onItemTap: (item) {
              if (item.title == 'Marketplace') {
                Navigator.pushNamed(context, '/marketplace');
              } else if (item.title == 'Lost & found') {
                Navigator.pushNamed(context, '/lost-found');
              } else if (item.title == "Freshers' corner") {
                Navigator.pushNamed(context, '/freshers-corner');
              } else if (item.title == 'Study help') {
                Navigator.pushNamed(context, '/study-help');
              }
            }, items: const [
              _Feature('Marketplace', Icons.storefront_rounded),
              _Feature('Lost & found', Icons.travel_explore_rounded),
              _Feature("Freshers' corner", Icons.waving_hand_rounded),
            ]),
            const SizedBox(height: 25),
            const _SectionHeader(
                title: 'Academics',
                subtitle: 'Tools for your next big breakthrough'),
            const SizedBox(height: 13),
            _FeatureGrid(onItemTap: (item) {
              if (item.title == 'Study help') {
                Navigator.pushNamed(context, '/study-help');
              } else if (item.title == 'AI quiz') {
                Navigator.pushNamed(context, '/ai-quiz');
              } else if (item.title == 'CGPA calculator') {
                Navigator.pushNamed(context, '/cgpa-calculator');
              }
            }, items: const [
              _Feature('Study help', Icons.auto_stories_rounded),
              _Feature('AI quiz', Icons.quiz_rounded),
              _Feature('CGPA calculator', Icons.calculate_rounded),
            ]),
            const SizedBox(height: 10),
          ])),
    ]);
  }
}

class _NotificationButton extends StatefulWidget {
  const _NotificationButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<_NotificationButton> {
  late final Stream<List<Map<String, dynamic>>> _notifications;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    _notifications = userId == null
        ? Stream.value(const <Map<String, dynamic>>[])
        : client
            .from('notifications')
            .stream(primaryKey: ['id'])
            .eq('user_id', userId)
            .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notifications,
        builder: (context, snapshot) {
          final unreadCount = (snapshot.data ?? const [])
              .where((notification) => notification['read_at'] == null)
              .length;
          return IconButton(
            onPressed: widget.onPressed,
            tooltip: unreadCount == 0
                ? 'Notifications'
                : 'Notifications, $unreadCount unread',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded),
                if (unreadCount > 0)
                  Positioned(
                    top: -7,
                    right: -9,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

class _TuitionCard extends StatelessWidget {
  const _TuitionCard({required this.deadlines});
  final Future<List<Map<String, dynamic>>> deadlines;
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: deadlines,
        builder: (context, snapshot) {
          final rows = snapshot.data ?? [];
          final now = DateTime.now();
          final next = rows
              .where((r) => DateTime.parse(r['due_on'] as String).isAfter(
                  DateTime(now.year, now.month, now.day)
                      .subtract(const Duration(days: 1))))
              .firstOrNull;
          final date =
              next == null ? null : DateTime.parse(next['due_on'] as String);
          final days =
              date?.difference(DateTime(now.year, now.month, now.day)).inDays;
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFE64A19), Color(0xFFBF360C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(26)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.white),
                const SizedBox(width: 9),
                Text('TUITION CHECK-IN',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1))
              ]),
              const SizedBox(height: 20),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(
                    color: Colors.white, backgroundColor: Colors.white24)
              else if (snapshot.hasError)
                const Text('Could not load the tuition schedule right now.',
                    style: TextStyle(color: Colors.white))
              else ...[
                Text(
                  date == null
                      ? 'All installment deadlines have passed'
                      : days == 0
                          ? 'Due today'
                          : days! < 0
                              ? 'Deadline passed'
                              : '$days days to go',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 5),
                  Text(
                    'Upcoming deadline ${DateFormat('d MMMM y').format(date)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (rows.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var index = 0; index < rows.length; index++) ...[
                        if (index > 0) const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  rows[index]['label'] as String? ??
                                      'Installment ${index + 1}',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  DateFormat('d MMM y').format(DateTime.parse(
                                      rows[index]['due_on'] as String)),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
              const SizedBox(height: 19),
              SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                      onPressed: () => Navigator.pushNamed(
                          context, '/tuition-calculator'),
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFBF360C)),
                      child: const Text('Calculate tuition'))),
            ]),
          );
        },
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant))
      ]);
}

class _Feature {
  const _Feature(this.title, this.icon);
  final String title;
  final IconData icon;
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.items, this.onItemTap});
  final List<_Feature> items;
  final ValueChanged<_Feature>? onItemTap;
  @override
  Widget build(BuildContext context) => BlocBuilder<AppBloc, AppState>(
        buildWhen: (previous, current) =>
            previous.themeMode != current.themeMode,
        builder: (context, state) {
          final isDark = state.themeMode == ThemeMode.dark;
          return GridView.builder(
            key: ValueKey(state.themeMode),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: .95),
            itemBuilder: (context, index) {
              final item = items[index];
              final colors = Theme.of(context).colorScheme;
              final cardColor =
                  isDark ? const Color(0xFF2E2B29) : Colors.white;
              final cardOutline =
                  isDark ? const Color(0xFF34302E) : const Color(0xFFFFE1D4);
              final iconTileColor =
                  isDark ? const Color(0xFF4B281E) : const Color(0xFFFFE5D9);
              final iconColor =
                  isDark ? const Color(0xFFFFB69E) : const Color(0xFFBF360C);
              final titleColor =
                  isDark ? const Color(0xFFF3EEEB) : const Color(0xFF34251F);
              return Card(
                  elevation: 5,
                  color: cardColor,
                  shadowColor: colors.shadow,
                  surfaceTintColor:
                      isDark ? Colors.transparent : colors.surfaceTint,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(19),
                      side: BorderSide(color: cardOutline, width: 0.7)),
                  child: InkWell(
                      borderRadius: BorderRadius.circular(19),
                      onTap: () => onItemTap?.call(item),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 13),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                        color: iconTileColor,
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    child: Icon(item.icon, color: iconColor)),
                                const SizedBox(height: 11),
                                Text(item.title,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                            color: titleColor,
                                            fontWeight: FontWeight.w700))
                              ]))));
            },
          );
        },
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name, required this.radius});
  final String? url;
  final String name;
  final double radius;
  @override
  Widget build(BuildContext context) => FutureBuilder<String?>(
        future: url == null || url!.isEmpty
            ? Future.value(null)
            : Supabase.instance.client.storage
                .from('profile-avatars')
                .createSignedUrl(url!, 3600),
        builder: (context, snapshot) => CircleAvatar(
            radius: radius,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundImage:
                snapshot.data == null ? null : NetworkImage(snapshot.data!),
            child: snapshot.data != null
                ? null
                : Text(name.trim().isEmpty ? 'U' : name.trim()[0].toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer))),
      );
}

