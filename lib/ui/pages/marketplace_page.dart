import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bloc/app_bloc.dart';
import '../../bloc/app_events.dart';
import '../../bloc/app_states.dart';
import '../../utils/confirmation_dialog.dart';
import '../common_ui_components/input_surface.dart';

const _marketplaceCategories = [
  'Food',
  'Robotics Components',
  'Study materials',
  'Others',
];

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key});

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  bool? _pendingSoldOutState;
  String _selectedCategory = 'All';
  static const _categoryFilters = [
    'All',
    'Foods',
    'Study Materials',
    'Robotics components',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<AppBloc>().add(MarketplacePostsLoadRequested());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final posted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const CreateMarketplacePostPage(),
      ),
    );
    if (posted == true && mounted) {
      context.read<AppBloc>().add(MarketplacePostsLoadRequested());
    }
  }

  Future<void> _refresh() async {
    final bloc = context.read<AppBloc>();
    final completedLoad = bloc.stream.firstWhere((state) =>
        state.action == AppAction.loadMarketplacePosts &&
        state.actionStatus != AppActionStatus.pending);
    bloc.add(MarketplacePostsLoadRequested());
    await completedLoad;
  }

  List<Map<String, dynamic>> _filterPosts(
    List<Map<String, dynamic>> posts,
  ) {
    final searchTerm = _searchController.text.trim().toLowerCase();
    final category = switch (_selectedCategory) {
      'Foods' => 'Food',
      'Study Materials' => 'Study materials',
      'Robotics components' => 'Robotics Components',
      'Others' => 'Others',
      _ => null,
    };

    return posts.where((post) {
      final postCategory = (post['category'] as String? ?? '').toLowerCase();
      final matchesCategory = category == null ||
          postCategory == category.toLowerCase();
      if (!matchesCategory) return false;
      if (searchTerm.isEmpty) return true;
      final searchableText = [
        post['title'],
        post['description'],
        post['category'],
        post['seller_name'],
      ].whereType<String>().join(' ').toLowerCase();
      return searchableText.contains(searchTerm);
    }).toList();
  }

  Widget _searchAndFilters(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InputSurface(child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search marketplace',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: colors.surfaceContainerHighest.withValues(
                alpha: Theme.of(context).brightness == Brightness.dark
                    ? 0.78
                    : 0.92,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.55),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: colors.primary, width: 1.4),
              ),
            ),
          )),
          const SizedBox(height: 13),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categoryFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categoryFilters[index];
                final selected = category == _selectedCategory;
                return ChoiceChip(
                  label: Text(category),
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _selectedCategory = category),
                  selectedColor: colors.primary,
                  backgroundColor: colors.surfaceContainerHighest.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.5
                        : 0.72,
                  ),
                  side: BorderSide(
                    color: selected
                        ? colors.primary
                        : colors.outlineVariant.withValues(alpha: 0.55),
                  ),
                  labelStyle: TextStyle(
                    color: selected ? colors.onPrimary : colors.onSurface,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Marketplace'),
          bottom: TabBar(
            controller: _tabController,
            onTap: (_) => setState(() {}),
            tabs: const [
              Tab(text: 'Available'),
              Tab(text: 'Sold out'),
            ],
          ),
        ),
        body: BlocConsumer<AppBloc, AppState>(
          listenWhen: (previous, current) =>
              current.action == AppAction.updateMarketplacePost &&
              previous.actionStatus != current.actionStatus,
          listener: (context, state) {
            if (state.actionStatus == AppActionStatus.success) {
              final newTab = _pendingSoldOutState == true ? 1 : 0;
              _pendingSoldOutState = null;
              _tabController.animateTo(newTab);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing status updated')),
              );
            } else if (state.actionStatus == AppActionStatus.failure) {
              _pendingSoldOutState = null;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ?? 'Could not update this listing.',
                  ),
                ),
              );
            }
          },
          buildWhen: (previous, current) =>
              previous.marketplacePosts != current.marketplacePosts ||
              (current.action == AppAction.loadMarketplacePosts &&
                  previous.actionStatus != current.actionStatus) ||
              (current.action == AppAction.updateMarketplacePost &&
                  previous.actionStatus != current.actionStatus),
          builder: (context, state) {
            final viewingSoldOut = _tabController.index == 1;
            final statusPosts = state.marketplacePosts.where((post) =>
                (post['is_sold_out'] as bool? ?? false) == viewingSoldOut);
            final posts = _filterPosts(statusPosts.toList());
            final searchIsActive = _searchController.text.trim().isNotEmpty;
            final categoryIsActive = _selectedCategory != 'All';
            final isLoading =
                state.action == AppAction.loadMarketplacePosts &&
                    state.actionStatus == AppActionStatus.pending;
            final loadFailed =
                state.action == AppAction.loadMarketplacePosts &&
                    state.actionStatus == AppActionStatus.failure;
            return RefreshIndicator(
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              displacement: 64,
              edgeOffset: 0,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              onRefresh: _refresh,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _searchAndFilters(context)),
                  if (isLoading && state.marketplacePosts.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (loadFailed && state.marketplacePosts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _MarketplaceMessage(
                        icon: Icons.wifi_off_rounded,
                        title: 'Could not load the marketplace',
                        message: state.errorMessage ??
                            'Please try again in a moment.',
                        action: FilledButton.icon(
                          onPressed: () => context
                              .read<AppBloc>()
                              .add(MarketplacePostsLoadRequested()),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try again'),
                        ),
                      ),
                    )
                  else if (posts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _MarketplaceMessage(
                        icon: state.marketplacePosts.isEmpty
                            ? Icons.storefront_outlined
                            : (searchIsActive || categoryIsActive)
                                ? Icons.search_off_rounded
                                : viewingSoldOut
                                    ? Icons.inventory_2_outlined
                                    : Icons.storefront_outlined,
                        title: state.marketplacePosts.isEmpty
                            ? 'Nothing for sale yet'
                            : (searchIsActive || categoryIsActive)
                                ? 'No matching items'
                                : viewingSoldOut
                                    ? 'No sold out items yet'
                                    : 'No available items',
                        message: state.marketplacePosts.isEmpty
                            ? 'Be the first to list something for the UIU community.'
                            : (searchIsActive || categoryIsActive)
                                ? 'Try another search or choose a different category.'
                                : viewingSoldOut
                                    ? 'Items you mark as sold out will appear here.'
                                    : 'All listings are currently marked as sold out.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index.isOdd) {
                              return const SizedBox(height: 14);
                            }
                            final post = posts[index ~/ 2];
                            final userId = Supabase
                                .instance.client.auth.currentUser?.id;
                            return _MarketplacePostCard(
                              key: ValueKey(post['id']),
                              post: post,
                              isMyPost: post['seller_id'] == userId,
                              onTap: () => Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => MarketplacePostDetailsPage(
                                    post: post,
                                    isMyPost: post['seller_id'] == userId,
                                    onSoldOutChanged: (isSoldOut) {
                                      _pendingSoldOutState = isSoldOut;
                                      context.read<AppBloc>().add(
                                        MarketplacePostSoldOutChanged(
                                          postId: post['id'] as String,
                                          isSoldOut: isSoldOut,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: posts.length * 2 - 1,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createPost,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Sell an item'),
        ),
      );
}

class _MarketplaceMessage extends StatelessWidget {
  const _MarketplaceMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, size: 38, color: colors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class _MarketplacePostCard extends StatelessWidget {
  const _MarketplacePostCard({
    super.key,
    required this.post,
    required this.isMyPost,
    required this.onTap,
  });

  final Map<String, dynamic> post;
  final bool isMyPost;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paths = (post['image_paths'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    final fixed = post['is_price_fixed'] as bool? ?? false;
    final isSoldOut = post['is_sold_out'] as bool? ?? false;
    final price = (post['price_bdt'] as num?)?.toDouble() ?? 0;
    final createdAt = DateTime.tryParse(post['created_at'] as String? ?? '');

    return Card(
      elevation: 3,
      color: isDark ? const Color(0xFF2E2B29) : Colors.white,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.5)
          : const Color(0xFF9A4A2A).withValues(alpha: 0.16),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : const Color(0xFFE8B39D).withValues(alpha: 0.62),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (paths.isNotEmpty)
              _PostImages(
                key: ValueKey(post['id']),
                paths: paths,
                height: 220,
                enableFullscreen: false,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 15, 17, 17),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      label: Text(post['category'] as String? ?? 'Others'),
                      visualDensity: VisualDensity.compact,
                      side: BorderSide.none,
                      backgroundColor: colors.primaryContainer,
                      labelStyle: TextStyle(color: colors.onPrimaryContainer),
                    ),
                    if (isSoldOut)
                      Chip(
                        label: const Text('Sold out'),
                        visualDensity: VisualDensity.compact,
                        side: BorderSide.none,
                        backgroundColor: colors.errorContainer,
                        labelStyle: TextStyle(color: colors.onErrorContainer),
                      ),
                    Text(
                      fixed ? 'Fixed price' : 'Negotiable',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  post['title'] as String? ?? '',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 7),
                Text(
                  '৳ ${NumberFormat('#,##0.##').format(price)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        ((post['seller_name'] as String?)?.trim().isNotEmpty ??
                                false)
                            ? (post['seller_name'] as String)
                                .trim()[0]
                                .toUpperCase()
                            : 'U',
                        style: TextStyle(color: colors.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        isMyPost
                            ? 'Your listing'
                            : post['seller_name'] as String? ?? 'UIU student',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (createdAt != null)
                      Text(
                        DateFormat('d MMM').format(createdAt.toLocal()),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                  ],
                ),
              ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketplacePostDetailsPage extends StatelessWidget {
  const MarketplacePostDetailsPage({
    super.key,
    required this.post,
    required this.isMyPost,
    required this.onSoldOutChanged,
  });

  final Map<String, dynamic> post;
  final bool isMyPost;
  final ValueChanged<bool> onSoldOutChanged;

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBloc, AppState>(
        buildWhen: (previous, current) =>
            previous.marketplacePosts != current.marketplacePosts ||
            (current.action == AppAction.updateMarketplacePost &&
                previous.actionStatus != current.actionStatus),
        builder: (context, state) {
          final currentPost = state.marketplacePosts.firstWhere(
            (row) => row['id'] == post['id'],
            orElse: () => post,
          );
          final colors = Theme.of(context).colorScheme;
          final paths =
              (currentPost['image_paths'] as List<dynamic>? ?? const [])
                  .whereType<String>()
                  .toList();
          final isSoldOut = currentPost['is_sold_out'] as bool? ?? false;
          final isUpdating =
              state.action == AppAction.updateMarketplacePost &&
                  state.actionStatus == AppActionStatus.pending;
          final price = (currentPost['price_bdt'] as num?)?.toDouble() ?? 0;
          final createdAt = DateTime.tryParse(
            currentPost['created_at'] as String? ?? '',
          );

          return Scaffold(
            appBar: AppBar(title: const Text('Post details')),
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: paths.isEmpty
                        ? Container(
                            height: 230,
                            color: colors.surfaceContainerHighest,
                            child: Icon(Icons.image_outlined,
                                size: 54, color: colors.onSurfaceVariant),
                          )
                        : _PostImages(
                            key: ValueKey(currentPost['id']),
                            paths: paths,
                            height: 310,
                            enableFullscreen: true,
                          ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
                    sliver: SliverList.list(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(
                              label: Text(
                                  currentPost['category'] as String? ??
                                      'Others'),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                              backgroundColor: colors.primaryContainer,
                              labelStyle:
                                  TextStyle(color: colors.onPrimaryContainer),
                            ),
                            Chip(
                              label: Text(isSoldOut ? 'Sold out' : 'Available'),
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                              backgroundColor: isSoldOut
                                  ? colors.errorContainer
                                  : colors.secondaryContainer,
                              labelStyle: TextStyle(
                                color: isSoldOut
                                    ? colors.onErrorContainer
                                    : colors.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          currentPost['title'] as String? ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '৳ ${NumberFormat('#,##0.##').format(price)}',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (currentPost['is_price_fixed'] as bool? ?? false)
                              ? 'Fixed price'
                              : 'Negotiable',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colors.primaryContainer,
                              child: Text(
                                ((currentPost['seller_name'] as String?)
                                            ?.trim()
                                            .isNotEmpty ??
                                        false)
                                    ? (currentPost['seller_name'] as String)
                                        .trim()[0]
                                        .toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                    color: colors.onPrimaryContainer),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                currentPost['seller_name'] as String? ??
                                    'UIU student',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (createdAt != null)
                              Text(
                                DateFormat('d MMM y')
                                    .format(createdAt.toLocal()),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Divider(),
                        const SizedBox(height: 14),
                        Text(
                          'Description',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          currentPost['description'] as String? ?? '',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        if (isMyPost)
                          SizedBox(
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: isUpdating
                                  ? null
                                  : () async {
                                      final confirmed = await confirmAction(
                                        context,
                                        title: isSoldOut
                                            ? 'Mark item as available?'
                                            : 'Mark item as sold out?',
                                        message: isSoldOut
                                            ? 'This item will return to the available listings.'
                                            : 'This item will move to the sold out listings.',
                                        confirmLabel: isSoldOut
                                            ? 'Mark available'
                                            : 'Mark sold out',
                                      );
                                      if (confirmed && context.mounted) {
                                        onSoldOutChanged(!isSoldOut);
                                      }
                                    },
                              icon: isUpdating
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Icon(isSoldOut
                                      ? Icons.restart_alt_rounded
                                      : Icons.check_circle_outline_rounded),
                              label: Text(isSoldOut
                                  ? 'Mark as available'
                                  : 'Mark as sold out'),
                            ),
                          ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 54,
                          child: FilledButton.icon(
                            onPressed: () => showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: colors.surface,
                              builder: (sheetContext) => AnimatedPadding(
                                duration: const Duration(milliseconds: 180),
                                curve: Curves.easeOut,
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.viewInsetsOf(sheetContext)
                                      .bottom,
                                ),
                                child: _MarketplaceResponsesSheet(
                                  postId: currentPost['id'] as String,
                                  postTitle:
                                      currentPost['title'] as String? ?? '',
                                  isSoldOut: isSoldOut,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.forum_outlined),
                            label: const Text('Show Responses'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _MarketplaceResponsesSheet extends StatefulWidget {
  const _MarketplaceResponsesSheet({
    required this.postId,
    required this.postTitle,
    required this.isSoldOut,
  });

  final String postId;
  final String postTitle;
  final bool isSoldOut;

  @override
  State<_MarketplaceResponsesSheet> createState() =>
      _MarketplaceResponsesSheetState();
}

class _MarketplaceResponsesSheetState
    extends State<_MarketplaceResponsesSheet> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context
        .read<AppBloc>()
        .add(MarketplaceCommentsLoadRequested(widget.postId));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() {
    if (widget.isSoldOut) return;
    final body = _commentController.text.trim();
    if (body.isEmpty) return;
    context.read<AppBloc>().add(MarketplaceCommentCreateRequested(
          postId: widget.postId,
          body: body,
        ));
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.22,
        maxChildSize: 1,
        snap: true,
        snapSizes: const [0.55, 1],
        shouldCloseOnMinExtent: true,
        builder: (context, scrollController) => BlocConsumer<AppBloc, AppState>(
          listenWhen: (previous, current) =>
              current.action == AppAction.createMarketplaceComment &&
              previous.actionStatus != current.actionStatus,
          listener: (context, state) {
            if (state.actionStatus == AppActionStatus.success) {
              _commentController.clear();
            } else if (state.actionStatus == AppActionStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.errorMessage ?? 'Could not send your response.',
                  ),
                ),
              );
            }
          },
          buildWhen: (previous, current) =>
              previous.marketplaceComments != current.marketplaceComments ||
              (current.action == AppAction.loadMarketplaceComments &&
                  previous.actionStatus != current.actionStatus) ||
              (current.action == AppAction.createMarketplaceComment &&
                  previous.actionStatus != current.actionStatus),
          builder: (context, state) {
            final isLoaded = state.commentsForPostId == widget.postId;
            final comments = isLoaded
                ? state.marketplaceComments
                : const <Map<String, dynamic>>[];
            final isLoading = !isLoaded &&
                state.action == AppAction.loadMarketplaceComments &&
                state.actionStatus == AppActionStatus.pending;
            final loadFailed = !isLoaded &&
                state.action == AppAction.loadMarketplaceComments &&
                state.actionStatus == AppActionStatus.failure;
            final isSending =
                state.action == AppAction.createMarketplaceComment &&
                    state.actionStatus == AppActionStatus.pending;
            final colors = Theme.of(context).colorScheme;

            return Material(
              color: colors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(26)),
              clipBehavior: Clip.antiAlias,
              child: SafeArea(
                child: Column(
                  children: [
                  const SizedBox(height: 11),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Responses',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                widget.postTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close responses',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                      itemCount: isLoading || loadFailed || comments.isEmpty
                          ? 1
                          : comments.length,
                      itemBuilder: (context, index) {
                        if (isLoading) {
                          return const Padding(
                            padding: EdgeInsets.all(28),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (loadFailed) {
                          return Padding(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              children: [
                                const Text('Could not load responses.'),
                                TextButton.icon(
                                  onPressed: () => context
                                      .read<AppBloc>()
                                      .add(MarketplaceCommentsLoadRequested(
                                          widget.postId)),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Try again'),
                                ),
                              ],
                            ),
                          );
                        }
                        if (comments.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(28),
                            child: Center(
                              child: Text(
                                'No responses yet. Start the conversation.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: colors.onSurfaceVariant),
                              ),
                            ),
                          );
                        }
                        final comment = comments[index];
                        final createdAt = DateTime.tryParse(
                          comment['created_at'] as String? ?? '',
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(
                                alpha: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? 0.48
                                    : 0.65,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: colors.outlineVariant
                                    .withValues(alpha: 0.45),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(13),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 17,
                                        backgroundColor:
                                            colors.primaryContainer,
                                        child: Text(
                                          ((comment['user_name'] as String?)
                                                      ?.trim()
                                                      .isNotEmpty ??
                                                  false)
                                              ? (comment['user_name'] as String)
                                                  .trim()[0]
                                                  .toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            color: colors.onPrimaryContainer,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              comment['user_name'] as String? ??
                                                  'UIU student',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            if ((comment['student_id']
                                                        as String?)
                                                    ?.isNotEmpty ??
                                                false)
                                              Text(
                                                comment['student_id'] as String,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.copyWith(
                                                      color: colors
                                                          .onSurfaceVariant
                                                          .withValues(
                                                              alpha: 0.68),
                                                    ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (createdAt != null)
                                        Text(
                                          DateFormat('d MMM, h:mm a')
                                              .format(createdAt.toLocal()),
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                  color:
                                                      colors.onSurfaceVariant),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Text(comment['body'] as String? ?? ''),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      14,
                      10,
                      14,
                      12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                    child: InputSurface(child: TextField(
                            controller: _commentController,
                            enabled:
                                isLoaded && !isSending && !widget.isSoldOut,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: 1000,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: widget.isSoldOut
                                  ? 'Responses are closed for this sold out post'
                                  : 'Write a response…',
                              counterText: '',
                              border: const OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(22)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            onSubmitted: widget.isSoldOut
                                ? null
                                : (_) => _sendComment(),
                          ),
                        ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Send response',
                          onPressed: !isLoaded || isSending || widget.isSoldOut
                              ? null
                              : _sendComment,
                          icon: isSending
                              ? const SizedBox.square(
                                  dimension: 19,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            );
          },
        ),
      );
}

class _PostImages extends StatefulWidget {
  const _PostImages({
    super.key,
    required this.paths,
    required this.height,
    this.enableFullscreen = false,
  });

  final List<String> paths;
  final double height;
  final bool enableFullscreen;

  @override
  State<_PostImages> createState() => _PostImagesState();
}

class _PostImagesState extends State<_PostImages> {
  int _currentPage = 0;
  late final Future<List<String>> _imageUrls = Future.wait(
    widget.paths.map((path) => Supabase.instance.client.storage
        .from('marketplace-images')
        .createSignedUrl(path, 3600)),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height,
        child: FutureBuilder<List<String>>(
          future: _imageUrls,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Icon(Icons.broken_image_outlined,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 36),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  itemCount: snapshot.data!.length,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final image = Image.network(
                      snapshot.data![index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        child: Icon(Icons.broken_image_outlined,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            size: 36),
                      ),
                    );
                    if (!widget.enableFullscreen) return image;
                    return GestureDetector(
                      onTap: () => _openFullscreenGallery(
                        context,
                        snapshot.data!,
                        initialIndex: index,
                      ),
                      child: image,
                    );
                  },
                ),
                if (snapshot.data!.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        child: Text(
                          '${_currentPage + 1} / ${snapshot.data!.length}',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );

  Future<void> _openFullscreenGallery(
    BuildContext context,
    List<String> imageUrls, {
    required int initialIndex,
  }) =>
      Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          opaque: false,
          barrierColor: Colors.black,
          pageBuilder: (_, __, ___) => _FullscreenMarketplaceGallery(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
          ),
          transitionsBuilder: (_, animation, __, child) => FadeTransition(
            opacity: animation,
            child: child,
          ),
        ),
      );
}

class _FullscreenMarketplaceGallery extends StatefulWidget {
  const _FullscreenMarketplaceGallery({
    required this.imageUrls,
    required this.initialIndex,
  });

  final List<String> imageUrls;
  final int initialIndex;

  @override
  State<_FullscreenMarketplaceGallery> createState() =>
      _FullscreenMarketplaceGalleryState();
}

class _FullscreenMarketplaceGalleryState
    extends State<_FullscreenMarketplaceGallery> {
  late final PageController _pageController =
      PageController(initialPage: widget.initialIndex);
  late int _currentPage = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Image.network(
                    widget.imageUrls[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 54,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filledTonal(
                    tooltip: 'Close photos',
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.56),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ),
            if (widget.imageUrls.length > 1)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.56),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 13, vertical: 7),
                        child: Text(
                          '${_currentPage + 1} / ${widget.imageUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      );
}

class CreateMarketplacePostPage extends StatefulWidget {
  const CreateMarketplacePostPage({super.key});

  @override
  State<CreateMarketplacePostPage> createState() =>
      _CreateMarketplacePostPageState();
}

class _CreateMarketplacePostPageState extends State<CreateMarketplacePostPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  String _category = _marketplaceCategories.first;
  bool _isPriceFixed = false;
  bool _isPosting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final selected = await _picker.pickMultiImage(
        imageQuality: 82,
        maxWidth: 1600,
      );
      if (selected.isNotEmpty && mounted) {
        setState(() => _images.addAll(selected));
      }
    } catch (error) {
      if (mounted) _showMessage('Could not open your gallery: $error');
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
    setState(() {
      _images.clear();
      _category = _marketplaceCategories.first;
      _isPriceFixed = false;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.tryParse(_priceController.text.trim());
    if (price == null) return;
    context.read<AppBloc>().add(MarketplacePostCreateRequested(
          title: _titleController.text,
          category: _category,
          description: _descriptionController.text,
          price: price,
          isPriceFixed: _isPriceFixed,
          images: List<XFile>.unmodifiable(_images),
        ));
  }

  void _showMessage(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));

  String? _requiredText(String? value, String label, {int minLength = 2}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter the $label.';
    if (text.length < minLength) return '$label is too short.';
    return null;
  }

  @override
  Widget build(BuildContext context) => BlocListener<AppBloc, AppState>(
          listenWhen: (previous, current) =>
            current.action == AppAction.createMarketplacePost &&
            previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          setState(() => _isPosting =
              state.actionStatus == AppActionStatus.pending);
          if (state.actionStatus == AppActionStatus.success) {
            Navigator.pop(context, true);
          } else if (state.actionStatus == AppActionStatus.failure) {
            _showMessage(state.errorMessage ?? 'Could not publish your item.');
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Sell an item')),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _isPosting ? null : _clearForm,
                    icon: const Icon(Icons.restart_alt_rounded),
                    label: const Text('Clear form'),
                  ),
                ),
                Text('What are you selling?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        )),
                const SizedBox(height: 6),
                Text(
                  'Share it with the UIU community.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 22),
                InputSurface(child: TextFormField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Item title',
                    hintText: 'e.g. Calculus textbook',
                    prefixIcon: Icon(Icons.sell_outlined),
                  ),
                  validator: (value) =>
                      _requiredText(value, 'title', minLength: 3),
                )),
                const SizedBox(height: 16),
                InputSurface(child: DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _marketplaceCategories
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: _isPosting
                      ? null
                      : (value) {
                          if (value != null) setState(() => _category = value);
                        },
                )),
                const SizedBox(height: 16),
                InputSurface(child: TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add details about the item and its condition',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => _requiredText(
                    value,
                    'description',
                    minLength: 10,
                  ),
                )),
                const SizedBox(height: 16),
                InputSurface(child: TextFormField(
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    hintText: '0.00',
                    prefixText: '৳ ',
                  ),
                  validator: (value) {
                    final raw = value?.trim() ?? '';
                    final price = double.tryParse(raw);
                    if (raw.isEmpty) return 'Enter a price in BDT.';
                    if (price == null || !price.isFinite || price < 0) {
                      return 'Enter a valid non-negative price.';
                    }
                    return null;
                  },
                )),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fixed price'),
                  subtitle: Text(_isPriceFixed
                      ? 'The listed price is firm.'
                      : 'Buyers can negotiate the price.'),
                  value: _isPriceFixed,
                  onChanged: _isPosting
                      ? null
                      : (value) => setState(() => _isPriceFixed = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Photos',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    TextButton.icon(
                      onPressed: _isPosting ? null : _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Choose images'),
                    ),
                  ],
                ),
                Text(
                  'Add one or more pictures from your gallery. You can remove any picture before posting.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                if (_images.isNotEmpty) ...[
                  const SizedBox(height: 13),
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) => SizedBox(
                        width: 112,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(_images[index].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Material(
                                color: Colors.black.withValues(alpha: 0.65),
                                shape: const CircleBorder(),
                                child: IconButton(
                                  onPressed: _isPosting
                                      ? null
                                      : () => setState(
                                          () => _images.removeAt(index)),
                                  tooltip: 'Remove image',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 19),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 54,
                  child: FilledButton.icon(
                    onPressed: _isPosting ? null : _submit,
                    icon: _isPosting
                        ? const SizedBox.square(
                            dimension: 19,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.publish_rounded),
                    label: Text(_isPosting ? 'Posting…' : 'Post'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
