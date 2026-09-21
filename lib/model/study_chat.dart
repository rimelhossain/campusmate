class StudyChat {
  final String id;
  final String postId;
  final String creatorId;
  final String responderId;
  final String responderName;
  final bool creatorClosed;
  final bool responderClosed;
  final String status;
  final DateTime createdAt;

  StudyChat({
    required this.id,
    required this.postId,
    required this.creatorId,
    required this.responderId,
    required this.responderName,
    required this.creatorClosed,
    required this.responderClosed,
    required this.status,
    required this.createdAt,
  });

  factory StudyChat.fromJson(Map<String, dynamic> json) {
    return StudyChat(
      id: json['id'],
      postId: json['post_id'],
      creatorId: json['creator_id'],
      responderId: json['responder_id'],
      responderName: json['responder_name'] ?? 'Unknown',
      creatorClosed: json['creator_closed'] ?? false,
      responderClosed: json['responder_closed'] ?? false,
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
