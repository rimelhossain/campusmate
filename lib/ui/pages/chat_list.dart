import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/ui/pages/chat_inbox.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:campusmate/bloc/cm_bloc.dart';

class ChatList extends StatelessWidget {
  const ChatList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE9ECEA),
      appBar: AppBar(
        title: const Qstext(
          "Chats",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('study_chats')
            .stream(primaryKey: ['id'])
            .order('created_at'),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];
          final activeChats = data.where((chat) {
            final isCreator = chat['creator_id'] == student.id;
            final isResponder = chat['responder_id'] == student.id;
            return (isCreator || isResponder) && (chat['status'] != 'closed');
          }).toList();

          if (activeChats.isEmpty) {
            return const Center(child: Qstext("No active chats."));
          }

          return ListView.builder(
            itemCount: activeChats.length,
            itemBuilder: (context, index) {
              return _ChatListTile(chat: activeChats[index]);
            },
          );
        },
      ),
    );
  }
}

/// Record holding the fetched post title for a chat row.
typedef _ChatInfo = ({
  String postTitle,
  String responderName,
  String responderId,
});

class _ChatListTile extends StatefulWidget {
  final Map<String, dynamic> chat;
  const _ChatListTile({required this.chat});

  @override
  State<_ChatListTile> createState() => _ChatListTileState();
}

class _ChatListTileState extends State<_ChatListTile> {
  late final Future<_ChatInfo> _chatInfoFuture = _fetchChatInfo();

  Future<_ChatInfo> _fetchChatInfo() async {
    String postTitle = 'Study Chat';
    try {
      final result = await Supabase.instance.client
          .from('study_chats')
          .select('responder_id, responder_name, study_posts(course_topic)')
          .eq('id', widget.chat['id'])
          .single();

      final postData = result['study_posts'];
      if (postData != null && postData['course_topic'] != null) {
        postTitle = postData['course_topic'] as String;
      }

      final responderName = (result['responder_name'] as String?) ?? 'Unknown';
      final responderId = (result['responder_id'] as String?) ?? '';

      return (
        postTitle: postTitle,
        responderName: responderName,
        responderId: responderId,
      );
    } catch (_) {}

    return (
      postTitle: postTitle,
      responderName: (widget.chat['responder_name'] as String?) ?? 'Unknown',
      responderId: (widget.chat['responder_id'] as String?) ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ChatInfo>(
      future: _chatInfoFuture,
      builder: (context, snapshot) {
        final info = snapshot.data;
        final isLoading = info == null;

        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.forum)),
          title: isLoading
              ? const Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                )
              : RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: info.postTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text:
                            ' - [${info.responderName} (${info.responderId})]',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.normal,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
          subtitle: const Text("Status: open"),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatInbox(chatId: widget.chat['id']),
              ),
            );
          },
        );
      },
    );
  }
}
