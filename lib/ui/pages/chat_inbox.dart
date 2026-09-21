import 'package:campusmate/bloc/cm_bloc.dart';
import 'package:campusmate/ui/components/Qstext.dart';
import 'package:campusmate/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatInbox extends StatefulWidget {
  final String chatId;
  const ChatInbox({super.key, required this.chatId});

  @override
  State<ChatInbox> createState() => _ChatInboxState();
}

class _ChatInboxState extends State<ChatInbox> {
  final TextEditingController _msgController = TextEditingController();
  late final Future<({String postTitle, String responderName, String responderId})>
      _chatInfoFuture = _fetchChatInfo();

  Future<({String postTitle, String responderName, String responderId})>
      _fetchChatInfo() async {
    try {
      final result = await Supabase.instance.client
          .from('study_chats')
          .select('responder_id, responder_name, study_posts(course_topic)')
          .eq('id', widget.chatId)
          .single();
      final postData = result['study_posts'];
      final postTitle = (postData != null && postData['course_topic'] != null)
          ? postData['course_topic'] as String
          : 'Chat Inbox';
      final responderName = (result['responder_name'] as String?) ?? 'Unknown';
      final responderId = (result['responder_id'] as String?) ?? '';
      return (postTitle: postTitle, responderName: responderName, responderId: responderId);
    } catch (_) {}
    return (postTitle: 'Chat Inbox', responderName: '', responderId: '');
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    
    _msgController.clear();
    await Supabase.instance.client.from('study_messages').insert({
      'chat_id': widget.chatId,
      'sender_id': student.id,
      'text': text,
    });
  }

  void _closeChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Qstext("Close Chat?"),
        content: const Qstext("Are you sure you want to close this chat? You won't be able to send messages if both users close it."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Qstext("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              context.read<CmBloc>().add(CloseStudyChatEvent(widget.chatId));
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close inbox
            },
            child: const Qstext("Close Chat", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: _chatInfoFuture,
          builder: (context, snapshot) {
            final info = snapshot.data;
            if (info == null || info.responderName.isEmpty) {
              return Qstext(
                info?.postTitle ?? 'Chat Inbox',
                style: const TextStyle(fontWeight: FontWeight.bold),
              );
            }
            return RichText(
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: info.postTitle,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: ' - [${info.responderName} (${info.responderId})]',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: _closeChat,
            icon: const Icon(Icons.close),
            tooltip: "Close Chat",
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('study_messages')
                  .stream(primaryKey: ['id'])
                  .eq('chat_id', widget.chatId)
                  .order('created_at'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(child: Qstext("No messages yet."));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == student.id;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? primaryColor : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          msg['text'],
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('study_chats')
                .stream(primaryKey: ['id'])
                .eq('id', widget.chatId),
            builder: (context, chatSnapshot) {
              bool isClosed = false;
              if (chatSnapshot.hasData && chatSnapshot.data!.isNotEmpty) {
                isClosed = chatSnapshot.data!.first['status'] == 'closed';
              }

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgController,
                        enabled: !isClosed,
                        decoration: InputDecoration(
                          hintText: isClosed ? "Chat is closed" : "Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: isClosed ? null : _sendMessage,
                      icon: const Icon(Icons.send),
                      color: isClosed ? Colors.grey : primaryColor,
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
