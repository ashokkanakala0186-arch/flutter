class ChatMessage {
  const ChatMessage({
    this.id,
    required this.userId,
    required this.question,
    required this.answer,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final String question;
  final String answer;
  final String createdAt;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as int?,
      userId: (map['userId'] as int?) ?? 0,
      question: (map['question'] as String?) ?? '',
      answer: (map['answer'] as String?) ?? '',
      createdAt: (map['createdAt'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'question': question,
      'answer': answer,
      'createdAt': createdAt,
    };
  }
}
