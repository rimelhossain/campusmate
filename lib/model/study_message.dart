class StudyMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  StudyMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory StudyMessage.fromJson(Map<String, dynamic> json) {
    return StudyMessage(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      text: json['text'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
