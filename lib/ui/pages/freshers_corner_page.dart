import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../bloc/app_bloc.dart';
import '../../bloc/app_events.dart';
import '../../bloc/app_states.dart';
import '../common_ui_components/input_surface.dart';

class FreshersCornerPage extends StatefulWidget {
  const FreshersCornerPage({super.key});

  @override
  State<FreshersCornerPage> createState() => _FreshersCornerPageState();
}

class _FreshersCornerPageState extends State<FreshersCornerPage> {
  @override
  void initState() {
    super.initState();
    context.read<AppBloc>().add(FreshersFaqsLoadRequested());
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            current.action == AppAction.loadFreshersFaqs &&
            current.actionStatus == AppActionStatus.failure &&
            previous.actionStatus != current.actionStatus,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  state.errorMessage ?? 'Could not load the FAQs right now.')),
        ),
        buildWhen: (previous, current) =>
            previous.freshersFaqs != current.freshersFaqs ||
            (current.action == AppAction.loadFreshersFaqs &&
                previous.actionStatus != current.actionStatus),
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text("Freshers' Corner")),
          body: SafeArea(
            child: RefreshIndicator.adaptive(
              onRefresh: () async {
                final bloc = context.read<AppBloc>();
                final loaded = bloc.stream.firstWhere((next) =>
                    next.action == AppAction.loadFreshersFaqs &&
                    next.actionStatus != AppActionStatus.pending);
                bloc.add(FreshersFaqsLoadRequested());
                await loaded;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.waving_hand_rounded,
                            size: 34,
                            color: Theme.of(context).colorScheme.onPrimary),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Welcome to UIU!',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text('Quick answers to help you get started.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary
                                              .withValues(alpha: .88))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text('Frequently asked questions',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 13),
                  if (state.action == AppAction.loadFreshersFaqs &&
                      state.actionStatus == AppActionStatus.pending &&
                      state.freshersFaqs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.freshersFaqs.isEmpty)
                    _FreshersEmptyCard(
                      icon: Icons.help_outline_rounded,
                      message: 'No FAQs are available right now.',
                      actionLabel: 'Try again',
                      onAction: () => context
                          .read<AppBloc>()
                          .add(FreshersFaqsLoadRequested()),
                    )
                  else
                    ...state.freshersFaqs.map((faq) => Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: Card(
                            elevation: 2,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                            ),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 17, vertical: 5),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                  17, 0, 17, 18),
                              leading: Icon(Icons.quiz_outlined,
                                  color: Theme.of(context).colorScheme.primary),
                              title: Text(faq['question'] as String,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    faq['answer'] as String,
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                  const SizedBox(height: 23),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                          builder: (_) => const FreshersQuestionsPage()),
                    ),
                    icon: const Icon(Icons.forum_outlined),
                    label: const Text('Other Questions'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class FreshersQuestionsPage extends StatefulWidget {
  const FreshersQuestionsPage({super.key});

  @override
  State<FreshersQuestionsPage> createState() => _FreshersQuestionsPageState();
}

class _FreshersQuestionsPageState extends State<FreshersQuestionsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    context.read<AppBloc>().add(FreshersQuestionsLoadRequested());
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
        state.action == AppAction.loadFreshersQuestions &&
        state.actionStatus != AppActionStatus.pending);
    bloc.add(FreshersQuestionsLoadRequested());
    await loaded;
  }

  Future<void> _ask() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AskFreshersQuestionPage()),
    );
    if (created == true && mounted) {
      context.read<AppBloc>().add(FreshersQuestionsLoadRequested());
    }
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            current.action == AppAction.loadFreshersQuestions &&
            current.actionStatus == AppActionStatus.failure &&
            previous.actionStatus != current.actionStatus,
        listener: (context, state) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(state.errorMessage ??
                  'Could not load questions right now.')),
        ),
        buildWhen: (previous, current) =>
            previous.freshersQuestions != current.freshersQuestions ||
            (current.action == AppAction.loadFreshersQuestions &&
                previous.actionStatus != current.actionStatus),
        builder: (context, state) => Scaffold(
          appBar: AppBar(
            title: const Text('Other questions'),
            bottom: TabBar(
              controller: _tabs,
              tabs: const [Tab(text: 'Unresolved'), Tab(text: 'Resolved')],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _ask,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Ask a question'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(17, 12, 17, 10),
                  child: InputSurface(
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search questions',
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
                Expanded(
                  child: state.action == AppAction.loadFreshersQuestions &&
                          state.actionStatus == AppActionStatus.pending &&
                          state.freshersQuestions.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabs,
                          children: [
                            _questionList(state.freshersQuestions,
                                resolved: false),
                            _questionList(state.freshersQuestions,
                                resolved: true),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _questionList(List<Map<String, dynamic>> questions,
      {required bool resolved}) {
    final term = _search.text.trim().toLowerCase();
    final filtered = questions.where((question) {
      if ((question['is_resolved'] as bool? ?? false) != resolved) {
        return false;
      }
      return term.isEmpty ||
          (question['question'] as String? ?? '').toLowerCase().contains(term);
    }).toList(growable: false);
    return RefreshIndicator.adaptive(
      onRefresh: _refresh,
      child: filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 180),
                Icon(Icons.forum_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    term.isNotEmpty
                        ? 'No questions match your search.'
                        : resolved
                            ? 'No answered questions yet.'
                            : 'No questions yet. Ask the first one!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(15, 6, 15, 100),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 11),
              itemBuilder: (context, index) => _FreshersQuestionCard(
                question: filtered[index],
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        FreshersAnswersPage(question: filtered[index]),
                  ),
                ),
              ),
            ),
    );
  }
}

class AskFreshersQuestionPage extends StatefulWidget {
  const AskFreshersQuestionPage({super.key});

  @override
  State<AskFreshersQuestionPage> createState() =>
      _AskFreshersQuestionPageState();
}

class _AskFreshersQuestionPageState extends State<AskFreshersQuestionPage> {
  final _form = GlobalKey<FormState>();
  final _question = TextEditingController();
  final _picker = ImagePicker();
  final _images = <XFile>[];
  bool _submitting = false;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
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
    context.read<AppBloc>().add(FreshersQuestionCreateRequested(
          question: _question.text,
          images: List<XFile>.unmodifiable(_images),
        ));
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            current.action == AppAction.createFreshersQuestion &&
            previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == AppActionStatus.success) {
            Navigator.of(context).pop(true);
          } else if (state.actionStatus == AppActionStatus.failure) {
            setState(() => _submitting = false);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ??
                    'Could not submit your question.')));
          }
        },
        buildWhen: (previous, current) =>
            current.action == AppAction.createFreshersQuestion &&
            previous.actionStatus != current.actionStatus,
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Ask a question')),
          body: SafeArea(
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(19, 10, 19, 30),
                children: [
                  Text('What would you like to know?',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 7),
                  Text(
                      'Ask a clear question so other UIU students can help.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  InputSurface(
                    child: TextFormField(
                      controller: _question,
                      minLines: 5,
                      maxLines: 9,
                      maxLength: 5000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Write Your Question here',
                        alignLabelWithHint: true,
                        border: InputBorder.none,
                      ),
                      validator: (value) => value == null || value.trim().isEmpty
                          ? 'Write your question first.'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _submitting ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add pictures (optional)'),
                  ),
                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 13),
                    SizedBox(
                      height: 112,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) => Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.file(File(_images[index].path),
                                  width: 112,
                                  height: 112,
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: IconButton.filledTonal(
                                tooltip: 'Remove picture',
                                onPressed: () =>
                                    setState(() => _images.removeAt(index)),
                                icon: const Icon(Icons.close_rounded),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 25),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox.square(
                            dimension: 19,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                    label: Text(_submitting ? 'Submitting…' : 'Submit'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(54)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class FreshersAnswersPage extends StatefulWidget {
  const FreshersAnswersPage({super.key, required this.question});

  final Map<String, dynamic> question;

  @override
  State<FreshersAnswersPage> createState() => _FreshersAnswersPageState();
}

class _FreshersAnswersPageState extends State<FreshersAnswersPage> {
  final _answer = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  String get _questionId => widget.question['id'] as String;

  @override
  void initState() {
    super.initState();
    context.read<AppBloc>().add(FreshersAnswersLoadRequested(_questionId));
  }

  @override
  void dispose() {
    _answer.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendAnswer() {
    if (_sending || _answer.text.trim().isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    context.read<AppBloc>().add(FreshersAnswerCreateRequested(
          questionId: _questionId,
          body: _answer.text,
        ));
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AppBloc, AppState>(
        listenWhen: (previous, current) =>
            (current.action == AppAction.createFreshersAnswer ||
                current.action == AppAction.setFreshersBestAnswer ||
                current.action == AppAction.loadFreshersAnswers) &&
            previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          if (state.action == AppAction.createFreshersAnswer &&
              state.actionStatus == AppActionStatus.success) {
            _answer.clear();
            setState(() => _sending = false);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              }
            });
          } else if (state.actionStatus == AppActionStatus.failure) {
            if (state.action == AppAction.createFreshersAnswer) {
              setState(() => _sending = false);
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.errorMessage ??
                    'Could not update the question.')));
          }
        },
        buildWhen: (previous, current) =>
            previous.freshersAnswers != current.freshersAnswers ||
            previous.freshersQuestion != current.freshersQuestion ||
            previous.freshersAnswersForQuestionId !=
                current.freshersAnswersForQuestionId ||
            ((current.action == AppAction.loadFreshersAnswers ||
                    current.action == AppAction.createFreshersAnswer ||
                    current.action == AppAction.setFreshersBestAnswer) &&
                previous.actionStatus != current.actionStatus),
        builder: (context, state) {
          final question = state.freshersQuestion?['id'] == _questionId
              ? state.freshersQuestion!
              : widget.question;
          final authorId = question['author_id'] as String?;
          final isAuthor =
              authorId == Supabase.instance.client.auth.currentUser?.id;
          final loaded = state.freshersAnswersForQuestionId == _questionId;
          final bestAnswerId = question['best_answer_id'] as String?;
          final answers = List<Map<String, dynamic>>.from(
              loaded ? state.freshersAnswers : const []);
          answers.sort((a, b) {
            final aBest = a['id'] == bestAnswerId;
            final bBest = b['id'] == bestAnswerId;
            if (aBest != bBest) return aBest ? -1 : 1;
            return (a['created_at'] as String)
                .compareTo(b['created_at'] as String);
          });
          return Scaffold(
            appBar: AppBar(title: const Text('Question and answers')),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(17, 12, 17, 18),
                      children: [
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(17),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FreshersAuthorHeader(
                                  name: question['author_name'] as String? ??
                                      'UIU student',
                                  studentId:
                                      question['author_student_id'] as String? ??
                                          '',
                                  avatarPath:
                                      question['author_avatar_path'] as String?,
                                ),
                                const SizedBox(height: 16),
                                _FreshersStatusBadge(
                                    resolved: question['is_resolved'] as bool? ??
                                        bestAnswerId != null),
                                const SizedBox(height: 12),
                                Text(
                                  question['question'] as String? ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                if ((question['image_paths'] as List<dynamic>? ??
                                        const [])
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 220,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount:
                                          (question['image_paths'] as List)
                                              .length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 10),
                                      itemBuilder: (context, index) =>
                                          _FreshersPhoto(
                                        path: (question['image_paths'] as List)[
                                            index] as String,
                                        width: 250,
                                        height: 220,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Text('Answers (${answers.length})',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800)),
                            ),
                            if (bestAnswerId != null)
                              const _FreshersStatusBadge(resolved: true),
                          ],
                        ),
                        const SizedBox(height: 11),
                        if (!loaded &&
                            state.action == AppAction.loadFreshersAnswers &&
                            state.actionStatus == AppActionStatus.pending)
                          const Padding(
                            padding: EdgeInsets.all(30),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (answers.isEmpty)
                          const _FreshersEmptyCard(
                            icon: Icons.chat_bubble_outline_rounded,
                            message:
                                'No answers yet. Share what you know to help!',
                          )
                        else
                          ...answers.map((answer) => Padding(
                                padding: const EdgeInsets.only(bottom: 11),
                                child: _FreshersAnswerCard(
                                  answer: answer,
                                  isBest: answer['id'] == bestAnswerId,
                                  canManage: isAuthor,
                                  onBestChanged: () {
                                    context.read<AppBloc>().add(
                                          FreshersBestAnswerChangedRequested(
                                            questionId: _questionId,
                                            answerId: answer['id'] == bestAnswerId
                                                ? null
                                                : answer['id'] as String,
                                          ),
                                        );
                                  },
                                ),
                              )),
                      ],
                    ),
                  ),
                  _answerComposer(context, state),
                ],
              ),
            ),
          );
        },
      );

  Widget _answerComposer(BuildContext context, AppState state) => Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: InputSurface(
                    child: TextField(
                      controller: _answer,
                      minLines: 1,
                      maxLines: 5,
                      maxLength: 5000,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Write an answer',
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                IconButton.filled(
                  onPressed: _sending ||
                          state.action == AppAction.createFreshersAnswer &&
                              state.actionStatus == AppActionStatus.pending
                      ? null
                      : _sendAnswer,
                  tooltip: 'Submit answer',
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      );
}

class _FreshersQuestionCard extends StatelessWidget {
  const _FreshersQuestionCard({required this.question, required this.onTap});

  final Map<String, dynamic> question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imagePaths = question['image_paths'] as List<dynamic>? ?? const [];
    final resolved = question['is_resolved'] as bool? ?? false;
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(19),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _FreshersAvatar(
                    name: question['author_name'] as String? ?? 'UIU student',
                    path: question['author_avatar_path'] as String?,
                    radius: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FreshersAuthorHeader(
                      name: question['author_name'] as String? ?? 'UIU student',
                      studentId:
                          question['author_student_id'] as String? ?? '',
                      avatarPath: null,
                      compact: true,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _FreshersStatusBadge(resolved: resolved),
                ],
              ),
              const SizedBox(height: 13),
              Text(question['question'] as String? ?? '',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              if (imagePaths.isNotEmpty) ...[
                const SizedBox(height: 12),
                _FreshersPhoto(
                  path: imagePaths.first as String,
                  height: 175,
                  width: double.infinity,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline_rounded,
                      size: 17, color: colors.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text('View answers',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colors.primary, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded,
                      size: 18, color: colors.primary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreshersAnswerCard extends StatelessWidget {
  const _FreshersAnswerCard({
    required this.answer,
    required this.isBest,
    required this.canManage,
    required this.onBestChanged,
  });

  final Map<String, dynamic> answer;
  final bool isBest;
  final bool canManage;
  final VoidCallback onBestChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: isBest ? 3 : 1,
      color: isBest ? colors.tertiaryContainer : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
            color: isBest ? colors.tertiary : colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _FreshersAvatar(
                  name: answer['author_name'] as String? ?? 'UIU student',
                  path: answer['author_avatar_path'] as String?,
                  radius: 19,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _FreshersAuthorHeader(
                    name: answer['author_name'] as String? ?? 'UIU student',
                    studentId: answer['author_student_id'] as String? ?? '',
                    avatarPath: null,
                    compact: true,
                  ),
                ),
                if (isBest)
                  Chip(
                    avatar: Icon(Icons.push_pin_rounded,
                        size: 16, color: colors.onTertiaryContainer),
                    label: const Text('Best answer'),
                    visualDensity: VisualDensity.compact,
                    side: BorderSide.none,
                    backgroundColor: colors.tertiary,
                    labelStyle: TextStyle(
                        color: colors.onTertiary, fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            const SizedBox(height: 11),
            Text(answer['body'] as String? ?? '',
                style: Theme.of(context).textTheme.bodyLarge),
            if (canManage) ...[
              const SizedBox(height: 7),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onBestChanged,
                  icon: Icon(isBest
                      ? Icons.remove_circle_outline_rounded
                      : Icons.push_pin_outlined),
                  label: Text(isBest ? 'Remove best answer' : 'Best answer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FreshersAuthorHeader extends StatelessWidget {
  const _FreshersAuthorHeader({
    required this.name,
    required this.studentId,
    required this.avatarPath,
    this.compact = false,
  });

  final String name;
  final String studentId;
  final String? avatarPath;
  final bool compact;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          if (!compact) ...[
            _FreshersAvatar(name: name, path: avatarPath, radius: 23),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700)),
                if (studentId.isNotEmpty)
                  Text(studentId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: .75))),
              ],
            ),
          ),
        ],
      );
}

class _FreshersAvatar extends StatelessWidget {
  const _FreshersAvatar(
      {required this.name, required this.path, required this.radius});

  final String name;
  final String? path;
  final double radius;

  @override
  Widget build(BuildContext context) => FutureBuilder<String>(
        future: path == null || path!.isEmpty
            ? null
            : Supabase.instance.client.storage
                .from('freshers-media')
                .createSignedUrl(path!, 3600),
        builder: (context, snapshot) => CircleAvatar(
          radius: radius,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          foregroundImage:
              snapshot.hasData ? NetworkImage(snapshot.data!) : null,
          child: snapshot.hasData
              ? null
              : Text(
                  name.trim().isEmpty
                      ? 'U'
                      : name.trim().substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      );
}

class _FreshersPhoto extends StatelessWidget {
  const _FreshersPhoto(
      {required this.path, required this.width, required this.height});

  final String path;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: width,
          height: height,
          child: FutureBuilder<String>(
            future: Supabase.instance.client.storage
                .from('freshers-media')
                .createSignedUrl(path, 3600),
            builder: (context, snapshot) => snapshot.hasData
                ? Image.network(snapshot.data!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _freshersImagePlaceholder(context))
                : snapshot.hasError
                    ? _freshersImagePlaceholder(context)
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
}

Widget _freshersImagePlaceholder(BuildContext context) => ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.image_not_supported_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );

class _FreshersStatusBadge extends StatelessWidget {
  const _FreshersStatusBadge({required this.resolved});

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
          resolved ? 'Answered' : 'Unresolved',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: resolved ? colors.onTertiaryContainer : colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _FreshersEmptyCard extends StatelessWidget {
  const _FreshersEmptyCard({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              Icon(icon,
                  size: 38,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(height: 10),
              Text(message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}
