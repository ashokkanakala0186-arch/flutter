class Alert {
  const Alert({
    this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;

  Alert copyWith({bool? isRead}) {
    return Alert(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      id: map['id'] as int?,
      userId: (map['userId'] as int?) ?? 0,
      title: (map['title'] as String?) ?? '',
      message: (map['message'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'Weather Alert',
      isRead: ((map['isRead'] as int?) ?? 0) == 1,
      createdAt: (map['createdAt'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead ? 1 : 0,
      'createdAt': createdAt,
    };
  }
}
