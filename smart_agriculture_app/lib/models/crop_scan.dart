class CropScan {
  const CropScan({
    this.id,
    required this.userId,
    required this.cropName,
    required this.imagePath,
    required this.condition,
    required this.problem,
    required this.care,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final String cropName;
  final String imagePath;
  final String condition;
  final String problem;
  final String care;
  final String createdAt;

  factory CropScan.fromMap(Map<String, dynamic> map) {
    return CropScan(
      id: map['id'] as int?,
      userId: (map['userId'] as int?) ?? 0,
      cropName: (map['cropName'] as String?) ?? '',
      imagePath: (map['imagePath'] as String?) ?? '',
      condition: (map['condition'] as String?) ?? '',
      problem: (map['problem'] as String?) ?? '',
      care: (map['care'] as String?) ?? '',
      createdAt: (map['createdAt'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'cropName': cropName,
      'imagePath': imagePath,
      'condition': condition,
      'problem': problem,
      'care': care,
      'createdAt': createdAt,
    };
  }
}
