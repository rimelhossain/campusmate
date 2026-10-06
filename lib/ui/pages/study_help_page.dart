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

class StudyHelpPage extends StatefulWidget {
  const StudyHelpPage({super.key});

  @override
  State<StudyHelpPage> createState() => _StudyHelpPageState();
}

class _StudyHelpPageState extends State<StudyHelpPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();
  bool _onlyMine = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    context.read<AppBloc>().add(StudyHelpPostsLoadRequested());
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
        state.action == AppAction.loadStudyHelpPosts &&
        state.actionStatus != AppActionStatus.pending);
    bloc.add(StudyHelpPostsLoadRequested());
    await loaded;
  }

  Future<void> _createPost() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const CreateStudyHelpPostPage()),
    );
    if (created == true && mounted) {
      context.read<AppBloc>().add(StudyHelpPostsLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Study help'),
          bottom: TabBar(
            controller: _tabs,
            tabs: const [Tab(text: 'Unsolved'), Tab(text: 'Solved')],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _createPost,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Ask for help'),
        ),
        body: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 2),
              child: InputSurface(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search topic or description',
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
                ),
              ),
            ),
            SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: 22),
              title: const Text('Show only mine'),
              value: _onlyMine,
              onChanged: (value) => setState(() => _onlyMine = value),
            ),
            Expanded(
              child: BlocConsumer<AppBloc, AppState>(
                listenWhen: (previous, current) =>
                    current.action == AppAction.loadStudyHelpPosts &&
                    current.actionStatus == AppActionStatus.failure &&
                    previous.actionStatus != current.actionStatus,
                listener: (context, state) => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(
                        content: Text(state.errorMessage ??
                            'Could not load study help posts.'))),
                buildWhen: (previous, current) =>
                    previous.studyHelpPosts != current.studyHelpPosts ||
                    (current.action == AppAction.loadStudyHelpPosts &&
                        previous.actionStatus != current.actionStatus),
                builder: (context, state) {
                  if (state.action == AppAction.loadStudyHelpPosts &&
                      state.actionStatus == AppActionStatus.pending &&
                      state.studyHelpPosts.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return TabBarView(
                    controller: _tabs,
                    children: [
                      _postList(state.studyHelpPosts, solved: false),
                      _postList(state.studyHelpPosts, solved: true),
                    ],
                  );
                },
              ),
            ),
          ]),
        ),
      );

  Widget _postList(List<Map<String, dynamic>> posts,
      {required bool solved}) {
    final term = _search.text.trim().toLowerCase();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final filtered = posts.where((post) {
      if ((post['is_solved'] as bool? ?? false) != solved) return false;
      if (_onlyMine && post['author_id'] != userId) return false;
      if (term.isEmpty) return true;
      final searchable = '${post['topic_name'] ?? ''} ${post['description'] ?? ''}'
          .toLowerCase();
      return searchable.contains(term);
    }).toList(growable: false);
    return RefreshIndicator.adaptive(
      onRefresh: _refresh,
      child: filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 170),
                Icon(Icons.auto_stories_rounded,
                    size: 50,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    term.isNotEmpty || _onlyMine
                        ? 'No posts match these filters.'
                        : solved
                            ? 'No solved help posts yet.'
                            : 'No unsolved posts yet. Be the first to ask!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 13),
              itemBuilder: (context, index) => _StudyHelpPostCard(
                post: filtered[index],
                onView: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        StudyHelpDetailsPage(post: filtered[index]),
                  ),
                ),
              ),
            ),
    );
  }
}

class CreateStudyHelpPostPage extends StatefulWidget {
  const CreateStudyHelpPostPage({super.key});

  @override
  State<CreateStudyHelpPostPage> createState() =>
      _CreateStudyHelpPostPageState();
}

class _CreateStudyHelpPostPageState extends State<CreateStudyHelpPostPage> {
  final _form = GlobalKey<FormState>();
  final _course = TextEditingController();
  final _topic = TextEditingController();
  final _description = TextEditingController();
  final _picker = ImagePicker();
  final _images = <XFile>[];
  bool _submitting = false;

  @override
  void dispose() {
    _course.dispose();
    _topic.dispose();
    _description.dispose();
    super.dispose();
  }

  void _clear() {
    _course.clear();
    _topic.clear();
    _description.clear();
    setState(_images.clear);
  }

  Future<void> _pickImages() async {
    final selected = await _picker.pickMultiImage(imageQuality: 88);
    if (!mounted || selected.isEmpty) return;
    setState(() => _images.addAll(selected));
  }

  void _submit() {
    if (_submitting || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    context.read<AppBloc>().add(StudyHelpPostCreateRequested(
          courseName: _course.text,
          topicName: _topic.text,
          description: _description.text,
          images: List<XFile>.unmodifiable(_images),
        ));
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            current.action == AppAction.createStudyHelpPost &&
            previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == AppActionStatus.success) {
            Navigator.of(context).pop(true);
          } else if (state.actionStatus == AppActionStatus.failure) {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'Could not post your request.')));
          }
        },
        buildWhen: (previous, current) =>
            current.action == AppAction.createStudyHelpPost &&
            previous.actionStatus != current.actionStatus,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Ask for study help')),
          body: SafeArea(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.restart_alt_rounded),
                      label: const Text('Clear'),
                    ),
                  ),
                  _StudyHelpInput(
                    child: TextFormField(
                      controller: _course,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        hintText: 'For example, CSE 1111',
                        prefixIcon: Icon(Icons.menu_book_outlined),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Enter the course name or code.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _StudyHelpInput(
                    child: TextFormField(
                      controller: _topic,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 160,
                      decoration: const InputDecoration(
                        labelText: 'Topic name',
                        hintText: 'What topic do you need help with?',
                        prefixIcon: Icon(Icons.lightbulb_outline_rounded),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Enter the topic.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _StudyHelpInput(
                    child: TextFormField(
                      controller: _description,
                      textCapitalization: TextCapitalization.sentences,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 5000,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Explain what you have tried and where you are stuck.',
                        alignLabelWithHint: true,
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Add a description of the help you need.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: Text('Photos (optional)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              )),
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
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(File(_images[index].path),
                                  width: 112, height: 112, fit: BoxFit.cover),
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
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 54,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_submitting ? 'Posting…' : 'Post'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _StudyHelpInput extends StatelessWidget {
  const _StudyHelpInput({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => InputSurface(child: child);
}

class StudyHelpDetailsPage extends StatelessWidget {
  const StudyHelpDetailsPage({super.key, required this.post});
  final Map<String, dynamic> post;

  @override
  Widget build(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            current.action == AppAction.updateStudyHelpPost &&
            previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == AppActionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'That action failed.')));
          }
        },
        buildWhen: (previous, current) =>
            previous.studyHelpPosts != current.studyHelpPosts ||
            current.action == AppAction.updateStudyHelpPost &&
                previous.actionStatus != current.actionStatus,
        builder: (context, state) {
          final current = state.studyHelpPosts.firstWhere(
              (row) => row['id'] == post['id'],
              orElse: () => post);
          final paths = (current['image_paths'] as List<dynamic>? ?? const [])
              .whereType<String>()
              .toList(growable: false);
          final solved = current['is_solved'] as bool? ?? false;
          final isAuthor = current['author_id'] ==
              Supabase.instance.client.auth.currentUser?.id;
          final updating = state.action == AppAction.updateStudyHelpPost &&
              state.actionStatus == AppActionStatus.pending;
          final opening = state.action == AppAction.openStudyHelpChat &&
              state.actionStatus == AppActionStatus.pending;
          return Scaffold(
            appBar: AppBar(title: const Text('Study help details')),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                children: [
                  if (paths.isNotEmpty)
                    _StudyHelpPhotos(paths: paths, height: 285)
                  else
                    const _NoStudyHelpPhoto(height: 180),
                  const SizedBox(height: 20),
                  Row(children: [
                    _StudyHelpStatus(solved: solved),
                    const Spacer(),
                    Text(
                      current['course_name'] as String? ?? '',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ]),
                  const SizedBox(height: 15),
                  _StudyHelpAuthorRow(post: current),
                  const SizedBox(height: 22),
                  Text(current['topic_name'] as String? ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 18),
                  Text('Description',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(current['description'] as String? ?? '',
                      style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 24),
                  if (isAuthor && !solved)
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: updating
                            ? null
                            : () async {
                                final confirmed = await confirmAction(
                                  context,
                                  title: 'Mark request as solved?',
                                  message:
                                      'This will move the request to Solved. No further responses can be started.',
                                  confirmLabel: 'Mark solved',
                                );
                                if (confirmed && context.mounted) {
                                  context.read<AppBloc>().add(
                                      StudyHelpPostSolvedRequested(
                                          current['id'] as String));
                                }
                              },
                        icon: updating
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Mark as solved'),
                      ),
                    )
                  else if (!isAuthor && !solved)
                    SizedBox(
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: opening
                            ? null
                            : () => Navigator.of(context).push<void>(
                                  MaterialPageRoute<void>(
                                    builder: (_) => StudyHelpChatPage(
                                      post: current,
                                    ),
                                  ),
                                ),
                        icon: opening
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.forum_outlined),
                        label: const Text('Respond'),
                      ),
                    )
                  else if (solved)
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text('This request has been marked as solved.'),
                    ),
                ],
              ),
            ),
          );
        },
      );
}

class StudyHelpChatsPage extends StatefulWidget {
  const StudyHelpChatsPage({super.key});

  @override
  State<StudyHelpChatsPage> createState() => _StudyHelpChatsPageState();
}

class _StudyHelpChatsPageState extends State<StudyHelpChatsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AppBloc>().add(StudyHelpChatsLoadRequested());
  }

  Future<void> _refresh() async {
    final bloc = context.read<AppBloc>();
    final loaded = bloc.stream.firstWhere((state) =>
        state.action == AppAction.loadStudyHelpChats &&
        state.actionStatus != AppActionStatus.pending);
    bloc.add(StudyHelpChatsLoadRequested());
    await loaded;
  }

  Future<void> _openChat(Map<String, dynamic> chat) async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => StudyHelpChatPage(chat: chat),
    ));
    if (mounted) context.read<AppBloc>().add(StudyHelpChatsLoadRequested());
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            current.action == AppAction.loadStudyHelpChats &&
            current.actionStatus == AppActionStatus.failure &&
            previous.actionStatus != current.actionStatus,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage ?? 'Could not load chats.'))),
        buildWhen: (previous, current) =>
            previous.studyHelpChats != current.studyHelpChats ||
            (current.action == AppAction.loadStudyHelpChats &&
                previous.actionStatus != current.actionStatus),
        builder: (context, state) {
          if (state.action == AppAction.loadStudyHelpChats &&
              state.actionStatus == AppActionStatus.pending &&
              state.studyHelpChats.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator.adaptive(
            onRefresh: _refresh,
            child: state.studyHelpChats.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 130),
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 54,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Your study help conversations will appear here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(15, 12, 15, 28),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: state.studyHelpChats.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final chat = state.studyHelpChats[index];
                      final name = chat['other_user_name'] as String? ?? 'UIU student';
                      final studentId = chat['other_student_id'] as String? ?? '';
                      return Card(
                        elevation: 2,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .5),
                          ),
                        ),
                        child: ListTile(
                          onTap: () => _openChat(chat),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          leading: _StudyHelpAvatar(
                            name: name,
                            path: chat['other_avatar_path'] as String?,
                            radius: 24,
                          ),
                          title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (studentId.isNotEmpty)
                                Text(studentId,
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: .75),
                                    )),
                              const SizedBox(height: 4),
                              Text(chat['last_message_preview'] as String? ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  )),
                            ],
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                        ),
                      );
                    },
                  ),
          );
        },
      );
}

class StudyHelpChatPage extends StatefulWidget {
  const StudyHelpChatPage({super.key, this.chat, this.post});

  final Map<String, dynamic>? chat;
  final Map<String, dynamic>? post;

  @override
  State<StudyHelpChatPage> createState() => _StudyHelpChatPageState();
}

class _StudyHelpChatPageState extends State<StudyHelpChatPage> {
  late final AppBloc _appBloc;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _imagePicker = ImagePicker();
  XFile? _imageToSend;
  bool _closedByMe = false;

  @override
  void initState() {
    super.initState();
    _appBloc = context.read<AppBloc>();
    final chat = widget.chat;
    if (chat != null) {
      _appBloc.add(StudyHelpChatMessagesWatchRequested(chat['id'] as String));
    } else if (widget.post != null) {
      _appBloc.add(StudyHelpChatOpenRequested(widget.post!['id'] as String));
    }
  }

  @override
  void dispose() {
    _appBloc.add(StudyHelpChatMessagesStopRequested());
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickMessageImage() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image != null && mounted) setState(() => _imageToSend = image);
  }

  void _send(String chatId, bool sending) {
    if (sending || _closedByMe) return;
    final body = _messageController.text.trim();
    if (body.isEmpty && _imageToSend == null) return;
    context.read<AppBloc>().add(StudyHelpMessageSendRequested(
          chatId: chatId,
          body: body,
          image: _imageToSend,
        ));
  }

  void _viewPost(Map<String, dynamic> chat) {
    final post = chat['post_details'] as Map<String, dynamic>? ?? widget.post;
    if (post == null) return;
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => StudyHelpDetailsPage(post: post),
    ));
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            ((current.action == AppAction.openStudyHelpChat ||
                    current.action == AppAction.sendStudyHelpMessage ||
                    current.action == AppAction.closeStudyHelpChat) &&
                previous.actionStatus != current.actionStatus) ||
            previous.studyHelpMessages != current.studyHelpMessages,
        listener: (context, state) {
          if (state.action == AppAction.openStudyHelpChat &&
              state.actionStatus == AppActionStatus.success) {
            final chatId = state.studyHelpOpenedChat?['id'] as String?;
            if (chatId != null) {
              context
                  .read<AppBloc>()
                  .add(StudyHelpChatMessagesWatchRequested(chatId));
              context.read<AppBloc>().add(StudyHelpChatsLoadRequested());
            }
          } else if (state.action == AppAction.sendStudyHelpMessage) {
            if (state.actionStatus == AppActionStatus.success) {
              _messageController.clear();
              setState(() => _imageToSend = null);
              _scrollToLatest();
            } else if (state.actionStatus == AppActionStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.errorMessage ?? 'Message could not be sent.')));
            }
          } else if (state.action == AppAction.closeStudyHelpChat) {
            if (state.actionStatus == AppActionStatus.success) {
              setState(() => _closedByMe = true);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text(
                    'Chat has been marked for deletion waiting for other user'),
                duration: Duration(seconds: 4),
              ));
            } else if (state.actionStatus == AppActionStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(state.errorMessage ?? 'Could not close chat.')));
            }
          } else if (state.action == AppAction.openStudyHelpChat &&
              state.actionStatus == AppActionStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ?? 'Could not open chat.')));
          }
          if (state.studyHelpMessages.isNotEmpty) _scrollToLatest();
        },
        buildWhen: (previous, current) =>
            previous.studyHelpOpenedChat != current.studyHelpOpenedChat ||
            previous.studyHelpMessages != current.studyHelpMessages ||
            (current.action == AppAction.openStudyHelpChat &&
                previous.actionStatus != current.actionStatus) ||
            (current.action == AppAction.loadStudyHelpMessages &&
                previous.actionStatus != current.actionStatus) ||
            (current.action == AppAction.sendStudyHelpMessage &&
                previous.actionStatus != current.actionStatus) ||
            (current.action == AppAction.closeStudyHelpChat &&
                previous.actionStatus != current.actionStatus),
        builder: (context, state) {
          final chat = widget.chat ?? state.studyHelpOpenedChat;
          final post = chat?['post_details'] as Map<String, dynamic>? ?? widget.post;
          final isOpening = widget.chat == null &&
              state.action == AppAction.openStudyHelpChat &&
              state.actionStatus == AppActionStatus.pending;
          final sending = state.action == AppAction.sendStudyHelpMessage &&
              state.actionStatus == AppActionStatus.pending;
          final messagesLoaded = chat != null &&
              state.studyHelpMessagesForChatId == chat['id'];
          final messages = messagesLoaded
              ? state.studyHelpMessages
              : const <Map<String, dynamic>>[];
          final userId = Supabase.instance.client.auth.currentUser?.id;
          final isAuthor = chat != null && chat['author_id'] == userId;
          final recipientName = chat == null
              ? (post?['author_name'] as String? ?? 'UIU student')
              : (isAuthor
                  ? chat['responder_name'] as String? ?? 'UIU student'
                  : chat['author_name'] as String? ?? 'UIU student');
          final recipientStudentId = chat == null
              ? (post?['author_student_id'] as String? ?? '')
              : (isAuthor
                  ? chat['responder_student_id'] as String? ?? ''
                  : chat['author_student_id'] as String? ?? '');
          final String? recipientAvatar;
          if (chat == null) {
            recipientAvatar = post?['author_avatar_path'] as String?;
          } else if (isAuthor) {
            recipientAvatar = chat['responder_avatar_path'] as String?;
          } else {
            recipientAvatar = chat['author_avatar_path'] as String?;
          }
          final chatId = chat?['id'] as String?;
          return Scaffold(
            resizeToAvoidBottomInset: true,
            appBar: AppBar(
              titleSpacing: 0,
              title: Row(children: [
                _StudyHelpAvatar(
                    name: recipientName, path: recipientAvatar, radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(recipientName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                      if (recipientStudentId.isNotEmpty)
                        Text(recipientStudentId,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                )),
                    ],
                  ),
                ),
              ]),
              actions: [
                if (chat != null)
                  PopupMenuButton<String>(
                    tooltip: 'Chat options',
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'details') {
                        _viewPost(chat);
                      } else if (value == 'close') {
                        context.read<AppBloc>().add(
                            StudyHelpChatCloseRequested(chat['id'] as String));
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'details',
                        child: Text('View details of the post'),
                      ),
                      PopupMenuItem(value: 'close', child: Text('Close Chat')),
                    ],
                  ),
              ],
            ),
            body: SafeArea(
              child: Column(children: [
                Expanded(
                  child: chat == null
                      ? Center(
                          child: isOpening
                              ? const CircularProgressIndicator()
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Could not open this conversation.'),
                                    const SizedBox(height: 10),
                                    FilledButton.tonal(
                                      onPressed: post == null
                                          ? null
                                          : () => context.read<AppBloc>().add(
                                              StudyHelpChatOpenRequested(
                                                  post['id'] as String)),
                                      child: const Text('Try again'),
                                    ),
                                  ],
                                ),
                        )
                      : messagesLoaded
                          ? ListView.builder(
                              controller: _scrollController,
                              reverse: true,
                              padding: const EdgeInsets.fromLTRB(14, 15, 14, 20),
                              itemCount: messages.length,
                              itemBuilder: (context, index) => _StudyHelpMessageTile(
                                message: messages[index],
                                isMine: messages[index]['sender_id'] == userId,
                                onOpenPost: () => _viewPost(chat),
                              ),
                            )
                          : const Center(child: CircularProgressIndicator()),
                ),
                if (_imageToSend != null && !_closedByMe)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_imageToSend!.path),
                                width: 68, height: 68, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: -7,
                            top: -7,
                            child: IconButton.filledTonal(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => setState(() => _imageToSend = null),
                              icon: const Icon(Icons.close_rounded, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
                    child: Row(children: [
                      IconButton(
                        tooltip: 'Attach image',
                        onPressed: chat == null || sending || _closedByMe
                            ? null
                            : _pickMessageImage,
                        icon: const Icon(Icons.attach_file_rounded),
                      ),
                      Expanded(
                        child: InputSurface(
                          child: TextField(
                            controller: _messageController,
                            enabled: chat != null && !sending && !_closedByMe,
                            minLines: 1,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.send,
                            onSubmitted: chatId == null
                                ? null
                                : (_) => _send(chatId, sending),
                            decoration: InputDecoration(
                              hintText: _closedByMe
                                  ? 'You marked this chat for deletion'
                                  : 'Write a message…',
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Send message',
                        onPressed: chatId == null || sending || _closedByMe
                            ? null
                            : () => _send(chatId, sending),
                        icon: sending
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
          );
        },
      );
}

class _StudyHelpMessageTile extends StatelessWidget {
  const _StudyHelpMessageTile({
    required this.message,
    required this.isMine,
    required this.onOpenPost,
  });

  final Map<String, dynamic> message;
  final bool isMine;
  final VoidCallback onOpenPost;

  @override
  Widget build(BuildContext context) {
    final kind = message['message_kind'] as String? ?? 'text';
    if (kind == 'post_preview') {
      return Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SizedBox(
            width: 290,
            child: Card(
              elevation: 2,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onOpenPost,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message['preview_image_path'] is String &&
                        (message['preview_image_path'] as String).isNotEmpty)
                      _StudyHelpInlineImage(
                          path: message['preview_image_path'] as String,
                          width: 290,
                          height: 145)
                    else
                      const _NoStudyHelpPhoto(height: 115),
                    Padding(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('STUDY HELP REQUEST',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: .7,
                                  )),
                          const SizedBox(height: 5),
                          Text(message['preview_topic'] as String? ?? '',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  )),
                          const SizedBox(height: 3),
                          Text(message['preview_course'] as String? ?? '',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final created = DateTime.tryParse(message['created_at'] as String? ?? '');
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 7),
        decoration: BoxDecoration(
          color: isMine ? colors.primaryContainer : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(isMine ? 17 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 17),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (kind == 'image' && message['attachment_path'] is String)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: _StudyHelpInlineImage(
                  path: message['attachment_path'] as String,
                  width: 245,
                  height: 205,
                ),
              ),
            if ((message['body'] as String? ?? '').isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: Text(message['body'] as String,
                    style: TextStyle(color: isMine ? colors.onPrimaryContainer : colors.onSurface)),
              ),
            if (created != null) ...[
              const SizedBox(height: 3),
              Text(DateFormat('h:mm a').format(created.toLocal()),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: (isMine ? colors.onPrimaryContainer : colors.onSurfaceVariant).withValues(alpha: .72),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudyHelpPostCard extends StatelessWidget {
  const _StudyHelpPostCard({required this.post, required this.onView});
  final Map<String, dynamic> post;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final paths = (post['image_paths'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .48)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _StudyHelpAuthorRow(post: post, compact: true),
          const SizedBox(height: 13),
          Row(children: [
            Expanded(
              child: Text(post['topic_name'] as String? ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      )),
            ),
            const SizedBox(width: 8),
            _StudyHelpStatus(solved: post['is_solved'] as bool? ?? false),
          ]),
          const SizedBox(height: 4),
          Text(post['course_name'] as String? ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  )),
          if (paths.isNotEmpty) ...[
            const SizedBox(height: 12),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onView,
                child: _StudyHelpInlineImage(
                    path: paths.first, width: double.infinity, height: 165),
              ),
            ),
          ],
          const SizedBox(height: 9),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onView,
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: const Text('View details'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _StudyHelpAuthorRow extends StatelessWidget {
  const _StudyHelpAuthorRow({required this.post, this.compact = false});
  final Map<String, dynamic> post;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final name = post['author_name'] as String? ?? 'UIU student';
    final studentId = post['author_student_id'] as String? ?? '';
    final colors = Theme.of(context).colorScheme;
    return Row(children: [
      _StudyHelpAvatar(
        name: name,
        path: post['author_avatar_path'] as String?,
        radius: compact ? 19 : 24,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (studentId.isNotEmpty)
            Text(studentId,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: .75),
                    )),
        ]),
      ),
      if (!compact)
        Text(
          DateTime.tryParse(post['created_at'] as String? ?? '') == null
              ? ''
              : DateFormat('d MMM y').format(
                  DateTime.parse(post['created_at'] as String).toLocal()),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
    ]);
  }
}

class _StudyHelpStatus extends StatelessWidget {
  const _StudyHelpStatus({required this.solved});
  final bool solved;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: solved ? colors.tertiaryContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(solved ? 'Solved' : 'Unsolved',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: solved ? colors.onTertiaryContainer : colors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                )),
      ),
    );
  }
}

class _StudyHelpPhotos extends StatefulWidget {
  const _StudyHelpPhotos({required this.paths, required this.height});
  final List<String> paths;
  final double height;

  @override
  State<_StudyHelpPhotos> createState() => _StudyHelpPhotosState();
}

class _StudyHelpPhotosState extends State<_StudyHelpPhotos> {
  int _page = 0;
  late final Future<List<String>> _urls = Future.wait(widget.paths.map(
      (path) => Supabase.instance.client.storage
          .from('study-help-media')
          .createSignedUrl(path, 3600)));

  @override
  Widget build(BuildContext context) => SizedBox(
        height: widget.height,
        child: FutureBuilder<List<String>>(
          future: _urls,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _NoStudyHelpPhoto(height: widget.height);
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(alignment: Alignment.bottomCenter, children: [
                PageView.builder(
                  itemCount: snapshot.data!.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) => Image.network(
                    snapshot.data![index],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _NoStudyHelpPhoto(height: widget.height),
                  ),
                ),
                if (snapshot.data!.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        child: Text('${_page + 1} / ${snapshot.data!.length}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
              ]),
            );
          },
        ),
      );
}

class _StudyHelpInlineImage extends StatelessWidget {
  const _StudyHelpInlineImage({
    required this.path,
    required this.width,
    required this.height,
  });

  final String path;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: height,
        child: FutureBuilder<String>(
          future: Supabase.instance.client.storage
              .from('study-help-media')
              .createSignedUrl(path, 3600),
          builder: (context, snapshot) => snapshot.hasData
              ? Image.network(snapshot.data!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _NoStudyHelpPhoto(height: height))
              : snapshot.hasError
                  ? _NoStudyHelpPhoto(height: height)
                  : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
}

class _NoStudyHelpPhoto extends StatelessWidget {
  const _NoStudyHelpPhoto({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) => Container(
        height: height,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(Icons.auto_stories_outlined,
              size: 38,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
}

class _StudyHelpAvatar extends StatelessWidget {
  const _StudyHelpAvatar({
    required this.name,
    required this.path,
    required this.radius,
  });

  final String name;
  final String? path;
  final double radius;

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: path == null || path!.isEmpty
            ? null
            : Supabase.instance.client.storage
                .from('study-help-media')
                .createSignedUrl(path!, 3600),
        builder: (context, snapshot) => CircleAvatar(
          radius: radius,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundImage:
              snapshot.hasData ? NetworkImage(snapshot.data!) : null,
          child: snapshot.hasData
              ? null
              : Text(_nameInitial(name),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  )),
        ),
      );
}

String _nameInitial(String value) {
  final name = value.trim();
  return name.isEmpty ? 'U' : name.substring(0, 1).toUpperCase();
}

