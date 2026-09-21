import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/model/study_post.dart';
import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/utils/constants.dart';
import 'package:campusmate/ui/pages/add_study_post.dart';
import 'package:campusmate/ui/pages/chat_inbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StudyHelpFeed extends StatefulWidget {
  const StudyHelpFeed({super.key});

  @override
  State<StudyHelpFeed> createState() => _StudyHelpFeedState();
}

class _StudyHelpFeedState extends State<StudyHelpFeed> {
  bool _showOnlyMine = false;

  @override
  void initState() {
    super.initState();
    context.read<CmBloc>().add(LoadStudyPostsEvent());
  }

  Widget _buildPostList(List<StudyPost> posts, bool isResolvedTab) {
    final filteredPosts = posts.where((post) {
      if (_showOnlyMine && post.creatorId != student.id) return false;
      return post.isResolved == isResolvedTab;
    }).toList();

    if (filteredPosts.isEmpty) {
      return const Center(child: Qstext("No study help posts yet."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) {
        final post = filteredPosts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Qstext(
                      "${post.creatorName} (${post.creatorId})",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Qstext(
                  post.courseTopic,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Qstext(post.description),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!post.isResolved && post.creatorId == student.id)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Qstext("Resolve Post"),
                                  content: const Qstext(
                                    "Are you sure you want to resolve this post?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Qstext("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        context.read<CmBloc>().add(
                                          ResolveStudyPostEvent(post.id),
                                        );
                                        Navigator.pop(context);
                                      },
                                      child: const Qstext("Resolve"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Qstext("Resolve"),
                        ),
                      ),
                    if (post.creatorId != student.id)
                      ElevatedButton(
                        onPressed: post.isResolved
                            ? null
                            : () {
                                context.read<CmBloc>().add(
                                  RespondToStudyPostEvent(
                                    post.id,
                                    post.creatorId,
                                  ),
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: post.isResolved
                              ? Colors.grey
                              : primaryColor,
                        ),
                        child: const Qstext(
                          "Respond",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFE9ECEA),
        appBar: AppBar(
          title: const Qstext("Study Help Feed"),
          backgroundColor: Colors.transparent,
          actions: [
            Row(
              children: [
                const Qstext("Show only mine", style: TextStyle(fontSize: 14)),
                Switch(
                  value: _showOnlyMine,
                  activeThumbColor: primaryColor,
                  onChanged: (val) {
                    setState(() {
                      _showOnlyMine = val;
                    });
                  },
                ),
              ],
            ),
          ],
          bottom: const TabBar(
            indicatorColor: primaryColor,
            labelColor: primaryColor,
            tabs: [
              Tab(text: "Unresolved"),
              Tab(text: "Resolved"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddStudyPost()),
            );
            context.read<CmBloc>().add(LoadStudyPostsEvent());
          },
          backgroundColor: primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
        body: BlocConsumer<CmBloc, CmState>(
          listener: (context, state) {
            if (state is StudyChatInitializedState) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatInbox(chatId: state.chatId),
                ),
              );
            }
          },
          buildWhen: (previous, current) =>
              current is StudyPostsLoadingState ||
              current is StudyPostsLoadedState ||
              current is StudyHelpErrorState,
          builder: (context, state) {
            if (state is StudyPostsLoadingState) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is StudyHelpErrorState) {
              return Center(child: Text(state.msg));
            } else if (state is StudyPostsLoadedState) {
              final posts = state.posts as List<StudyPost>;
              return TabBarView(
                children: [
                  _buildPostList(posts, false),
                  _buildPostList(posts, true),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
