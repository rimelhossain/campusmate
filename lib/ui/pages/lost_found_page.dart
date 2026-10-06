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

class LostFoundPage extends StatefulWidget {
  const LostFoundPage({super.key});

  @override
  State<LostFoundPage> createState() => _LostFoundPageState();
}

class _LostFoundPageState extends State<LostFoundPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    context.read<AppBloc>().add(LostFoundPostsLoadRequested());
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final bloc = context.read<AppBloc>();
    final loaded = bloc.stream.firstWhere((state) =>
        state.action == AppAction.loadLostFoundPosts &&
        state.actionStatus != AppActionStatus.pending);
    bloc.add(LostFoundPostsLoadRequested());
    await loaded;
  }

  Future<void> _createPost() async {
    final posted = await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
      builder: (_) => const CreateLostFoundPostPage(),
    ));
    if (posted == true && mounted) {
      context.read<AppBloc>().add(LostFoundPostsLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Lost & Found'),
          bottom: TabBar(
            controller: _tabs,
            tabs: const [Tab(text: 'Unresolved'), Tab(text: 'Resolved')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createPost,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create post'),
        ),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
              child: InputSurface(child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search lost and found',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            _search.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              )),
            ),
            Expanded(
              child: BlocBuilder<AppBloc, AppState>(
                buildWhen: (previous, current) =>
                    previous.lostFoundPosts != current.lostFoundPosts ||
                    (current.action == AppAction.loadLostFoundPosts &&
                        previous.actionStatus != current.actionStatus),
                builder: (context, state) {
                  if (state.action == AppAction.loadLostFoundPosts &&
                      state.actionStatus == AppActionStatus.pending &&
                      state.lostFoundPosts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return TabBarView(
                    controller: _tabs,
                    children: [
                      _postList(state.lostFoundPosts, resolved: false),
                      _postList(state.lostFoundPosts, resolved: true),
                    ],
                  );
                },
              ),
            ),
          ]),
        ),
      );

  Widget _postList(List<Map<String, dynamic>> posts,
      {required bool resolved}) {
    final term = _search.text.trim().toLowerCase();
    final filtered = posts.where((post) {
      if ((post['is_resolved'] as bool? ?? false) != resolved) return false;
      if (term.isEmpty) return true;
      return [
        post['title'],
        post['description'],
        post['location'],
        post['author_name'],
        post['author_student_id'],
      ].whereType<String>().join(' ').toLowerCase().contains(term);
    }).toList(growable: false);
    return RefreshIndicator.adaptive(
      onRefresh: _refresh,
      child: filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 190),
                Icon(Icons.travel_explore_rounded,
                    size: 50,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    term.isEmpty
                        ? (resolved
                            ? 'No resolved posts yet.'
                            : 'No unresolved posts yet. Create the first one!')
                        : 'No posts match your search.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _LostFoundPostCard(
                post: filtered[index],
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => LostFoundDetailsPage(post: filtered[index]),
                  ),
                ),
              ),
            ),
    );
  }
}

class CreateLostFoundPostPage extends StatefulWidget {
  const CreateLostFoundPostPage({super.key});

  @override
  State<CreateLostFoundPostPage> createState() =>
      _CreateLostFoundPostPageState();
}

class _CreateLostFoundPostPageState extends State<CreateLostFoundPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  DateTime _occurredAt = DateTime.now();
  String _postType = 'lost';
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  void _clear() {
    _title.clear();
    _description.clear();
    _location.clear();
    setState(() {
      _images.clear();
      _postType = 'lost';
      _occurredAt = DateTime.now();
    });
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 88);
    if (!mounted || picked.isEmpty) return;
    setState(() => _images.addAll(picked));
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Approximate date',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
      helpText: 'Approximate time',
    );
    if (time == null || !mounted) return;
    setState(() => _occurredAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  void _submit() {
    if (_submitting || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    context.read<AppBloc>().add(LostFoundPostCreateRequested(
          title: _title.text,
          postType: _postType,
          description: _description.text,
          location: _location.text,
          occurredAt: _occurredAt,
          images: List<XFile>.unmodifiable(_images),
        ));
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            current.action == AppAction.createLostFoundPost &&
            previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == AppActionStatus.success) {
            Navigator.of(context).pop(true);
          } else if (state.actionStatus == AppActionStatus.failure) {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'Could not create post.')));
          }
        },
        buildWhen: (previous, current) =>
            current.action == AppAction.createLostFoundPost &&
            previous.actionStatus != current.actionStatus,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Create a post')),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Clear'),
                    ),
                  ),
                  InputSurface(child: TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 120,
                    decoration: const InputDecoration(
                        labelText: 'Item title',
                        hintText: 'What was lost or found?'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a title.'
                        : null,
                  )),
                  const SizedBox(height: 18),
                  Text('Post type',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'lost',
                          label: Text('Lost'),
                          icon: Icon(Icons.search_rounded)),
                      ButtonSegment(
                          value: 'found',
                          label: Text('Found'),
                          icon: Icon(Icons.inventory_2_outlined)),
                    ],
                    selected: {_postType},
                    onSelectionChanged: (values) =>
                        setState(() => _postType = values.first),
                  ),
                  const SizedBox(height: 18),
                  InputSurface(child: TextFormField(
                    controller: _description,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 4,
                    maxLines: 7,
                    maxLength: 5000,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Share useful details about the item'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a description.'
                        : null,
                  )),
                  const SizedBox(height: 16),
                  Text('Approximate time',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          )),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(DateFormat('EEE, d MMM y · h:mm a')
                        .format(_occurredAt)),
                    style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 15)),
                  ),
                  const SizedBox(height: 18),
                  InputSurface(child: TextFormField(
                    controller: _location,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 300,
                    decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'For example, Building A, 3rd floor'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter where it was lost or found.'
                        : null,
                  )),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: Text('Photos (optional)',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    TextButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Add photos'),
                    ),
                  ]),
                  if (_images.isNotEmpty)
                    SizedBox(
                      height: 112,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(File(_images[index].path),
                                  width: 112,
                                  height: 112,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              right: -6,
                              top: -6,
                              child: IconButton.filledTonal(
                                visualDensity: VisualDensity.compact,
                                onPressed: () =>
                                    setState(() => _images.removeAt(index)),
                                icon: const Icon(Icons.close_rounded, size: 17),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox.square(
                              dimension: 19,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_submitting ? 'Submitting…' : 'Submit post'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class LostFoundDetailsPage extends StatelessWidget {
  const LostFoundDetailsPage({super.key, required this.post});

  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBloc, AppState>(
        buildWhen: (previous, current) =>
            previous.lostFoundPosts != current.lostFoundPosts ||
            (current.action == AppAction.updateLostFoundPost &&
                previous.actionStatus != current.actionStatus),
        builder: (context, state) {
          final current = state.lostFoundPosts.firstWhere(
              (item) => item['id'] == post['id'],
              orElse: () => post);
          final paths = (current['image_paths'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(growable: false);
          final resolved = current['is_resolved'] as bool? ?? false;
          final isMine = current['author_id'] ==
              Supabase.instance.client.auth.currentUser?.id;
          final occupied = state.action == AppAction.updateLostFoundPost &&
              state.actionStatus == AppActionStatus.pending;
          final occurred = DateTime.tryParse(
              current['occurred_at'] as String? ?? '');
          final colors = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(title: const Text('Post details')),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
                children: [
                  if (paths.isNotEmpty)
                    _LostFoundPhotos(paths: paths, height: 290)
                  else
                    Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(Icons.image_outlined,
                          size: 48, color: colors.onSurfaceVariant),
                    ),
                  const SizedBox(height: 18),
                  Row(children: [
                    _PostTypeBadge(
                        type: current['post_type'] as String? ?? 'lost',
                        resolved: resolved),
                    const Spacer(),
                    if (isMine && !resolved)
                      TextButton.icon(
                        onPressed: occupied
                            ? null
                            : () async {
                                final confirmed = await confirmAction(
                                  context,
                                  title: 'Mark post as resolved?',
                                  message:
                                      'This will move the post to Resolved and close its responses.',
                                  confirmLabel: 'Mark resolved',
                                );
                                if (confirmed && context.mounted) {
                                  context.read<AppBloc>().add(
                                        LostFoundPostResolvedChanged(
                                          postId: current['id'] as String,
                                          isResolved: true,
                                        ),
                                      );
                                }
                              },
                        icon: occupied
                            ? const SizedBox.square(
                                dimension: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2))
                            : Icon(resolved
                                ? Icons.restart_alt_rounded
                                : Icons.check_circle_outline_rounded),
                        label: const Text('Mark resolved'),
                      ),
                  ]),
                  const SizedBox(height: 10),
                  _LostFoundAuthorRow(post: current, showDate: false),
                  const SizedBox(height: 18),
                  Text(current['title'] as String? ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 18),
                  _DetailLine(
                      icon: Icons.location_on_outlined,
                      title: 'Location',
                      value: current['location'] as String? ?? ''),
                  if (occurred != null) ...[
                    const SizedBox(height: 12),
                    _DetailLine(
                        icon: Icons.schedule_rounded,
                        title: (current['post_type'] == 'found'
                            ? 'Approximate found time'
                            : 'Approximate lost time'),
                        value: DateFormat('EEEE, d MMMM y · h:mm a')
                            .format(occurred.toLocal())),
                  ],
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 13),
                  Text('Description',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(current['description'] as String? ?? '',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        backgroundColor: colors.surface,
                        builder: (sheetContext) => AnimatedPadding(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
                          ),
                          child: _LostFoundResponsesSheet(
                            postId: current['id'] as String,
                            postTitle: current['title'] as String? ?? '',
                            isResolved: resolved,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('Responses'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _LostFoundResponsesSheet extends StatefulWidget {
  const _LostFoundResponsesSheet({
    required this.postId,
    required this.postTitle,
    required this.isResolved,
  });

  final String postId;
  final String postTitle;
  final bool isResolved;

  @override
  State<_LostFoundResponsesSheet> createState() =>
      _LostFoundResponsesSheetState();
}

class _LostFoundResponsesSheetState extends State<_LostFoundResponsesSheet> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AppBloc>().add(LostFoundResponsesLoadRequested(widget.postId));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              current.action == AppAction.createLostFoundResponse &&
              previous.actionStatus != current.actionStatus,
          listener: (context, state) {
            if (state.actionStatus == AppActionStatus.success) {
              _controller.clear();
            } else if (state.actionStatus == AppActionStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(state.errorMessage ?? 'Could not send response.')));
            }
          },
          builder: (context, state) {
            final loaded = state.lostFoundResponsesForPostId == widget.postId;
            final responses = loaded
                ? state.lostFoundResponses
                : const <Map<String, dynamic>>[];
            final loading = !loaded &&
                state.action == AppAction.loadLostFoundResponses &&
                state.actionStatus == AppActionStatus.pending;
            final sending = state.action == AppAction.createLostFoundResponse &&
                state.actionStatus == AppActionStatus.pending;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 7),
                child: Column(children: [
                  Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(height: 13),
                  Row(children: [
                    Expanded(
                      child: Text('Responses',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800)),
                    ),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded)),
                  ]),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(widget.postTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                  ),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : responses.isEmpty
                        ? Center(
                            child: Text('No responses yet.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.all(18),
                            itemCount: responses.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = responses[index];
                              final name =
                                  item['user_name'] as String? ?? 'UIU student';
                              final created = DateTime.tryParse(
                                  item['created_at'] as String? ?? '');
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    child: Text(_initial(name),
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer)),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                                child: Text(name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                            fontWeight:
                                                                FontWeight
                                                                    .w700))),
                                            if (created != null)
                                              Text(
                                                  DateFormat('d MMM · h:mm a')
                                                      .format(created.toLocal()),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                          color: Theme.of(
                                                                  context)
                                                              .colorScheme
                                                              .onSurfaceVariant)),
                                          ]),
                                          const SizedBox(height: 4),
                                          Text(item['body'] as String? ?? ''),
                                        ]),
                                  ),
                                ],
                              );
                            },
                          ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(children: [
                    Expanded(
                      child: InputSurface(child: TextField(
                        controller: _controller,
                        enabled: !widget.isResolved && !sending,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(context),
                        decoration: InputDecoration(
                          hintText: widget.isResolved
                              ? 'Post resolved · responses are closed'
                              : 'Write a response…',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 13),
                        ),
                      )),
                    ),
                    const SizedBox(width: 9),
                    IconButton.filled(
                      tooltip: 'Send response',
                      onPressed: widget.isResolved || sending
                          ? null
                          : () => _send(context),
                      icon: sending
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                    ),
                  ]),
                ),
              ),
            ]);
          },
        ),
      );

  void _send(BuildContext context) {
    final body = _controller.text.trim();
    if (widget.isResolved || body.isEmpty) return;
    context.read<AppBloc>().add(LostFoundResponseCreateRequested(
        postId: widget.postId, body: body));
  }
}

class _LostFoundPostCard extends StatelessWidget {
  const _LostFoundPostCard({required this.post, required this.onTap});

  final Map<String, dynamic> post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final paths = (post['image_paths'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .48)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (paths.isNotEmpty)
              _SignedLostFoundImage(path: paths.first, width: 96, height: 96)
            else
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(15)),
                child: Icon(Icons.image_outlined,
                    color: colors.onSurfaceVariant, size: 31),
              ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['title'] as String? ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 7),
                    _PostTypeBadge(
                      type: post['post_type'] as String? ?? 'lost',
                      resolved: post['is_resolved'] as bool? ?? false,
                    ),
                    const SizedBox(height: 7),
                    Row(children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: colors.onSurfaceVariant),
                      const SizedBox(width: 3),
                      Expanded(
                          child: Text(post['location'] as String? ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant))),
                    ]),
                    const SizedBox(height: 9),
                    _LostFoundAuthorRow(post: post, compact: true),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LostFoundAuthorRow extends StatelessWidget {
  const _LostFoundAuthorRow(
      {required this.post, this.compact = false, this.showDate = false});

  final Map<String, dynamic> post;
  final bool compact;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final name = post['author_name'] as String? ?? 'UIU student';
    final studentId = post['author_student_id'] as String? ?? '';
    final avatarPath = post['author_avatar_path'] as String?;
    final colors = Theme.of(context).colorScheme;
    final date = DateTime.tryParse(post['created_at'] as String? ?? '');
    return Row(children: [
      _AuthorAvatar(path: avatarPath, name: name, radius: compact ? 15 : 21),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (studentId.isNotEmpty)
            Text(studentId,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant.withValues(alpha: .75))),
        ]),
      ),
      if (showDate && date != null)
        Text(DateFormat('d MMM y').format(date.toLocal()),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.onSurfaceVariant)),
    ]);
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.path, required this.name, required this.radius});

  final String? path;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final future = path == null || path!.isEmpty
        ? null
        : Supabase.instance.client.storage
            .from('profile-avatars')
            .createSignedUrl(path!, 3600);
    return FutureBuilder<String>(
      future: future,
      builder: (context, snapshot) => CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        backgroundImage:
            snapshot.hasData ? NetworkImage(snapshot.data!) : null,
        child: snapshot.hasData
            ? null
            : Text(_initial(name),
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: radius * .85)),
      ),
    );
  }
}

class _PostTypeBadge extends StatelessWidget {
  const _PostTypeBadge({required this.type, required this.resolved});

  final String type;
  final bool resolved;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: resolved ? colors.tertiaryContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          '${type == 'found' ? 'Found' : 'Lost'}${resolved ? ' (Resolved)' : ''}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: resolved ? colors.onTertiaryContainer : colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(
      {required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ]),
          ),
        ],
      );
}

class _LostFoundPhotos extends StatefulWidget {
  const _LostFoundPhotos({required this.paths, required this.height});

  final List<String> paths;
  final double height;

  @override
  State<_LostFoundPhotos> createState() => _LostFoundPhotosState();
}

class _LostFoundPhotosState extends State<_LostFoundPhotos> {
  int _index = 0;
  late final Future<List<String>> _urls = Future.wait(widget.paths.map((path) =>
      Supabase.instance.client.storage
          .from('lost-found-images')
          .createSignedUrl(path, 3600)));

  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height,
        child: FutureBuilder<List<String>>(
          future: _urls,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(alignment: Alignment.bottomCenter, children: [
                PageView.builder(
                  itemCount: snapshot.data!.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, index) => Image.network(
                    snapshot.data![index],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined, size: 40),
                    ),
                  ),
                ),
                if (snapshot.data!.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: .65),
                          borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 5),
                        child: Text('${_index + 1} / ${snapshot.data!.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ]),
            );
          },
        ),
      );
}

class _SignedLostFoundImage extends StatelessWidget {
  const _SignedLostFoundImage(
      {required this.path, required this.width, required this.height});

  final String path;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: width,
          height: height,
          child: FutureBuilder<String>(
            future: Supabase.instance.client.storage
                .from('lost-found-images')
                .createSignedUrl(path, 3600),
            builder: (context, snapshot) => snapshot.hasData
                ? Image.network(snapshot.data!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(context))
                : snapshot.hasError
                    ? _imageFallback(context)
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );

  Widget _imageFallback(BuildContext context) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
}

String _initial(String name) {
  final trimmed = name.trim();
  return trimmed.isEmpty ? 'U' : trimmed.characters.first.toUpperCase();
}
