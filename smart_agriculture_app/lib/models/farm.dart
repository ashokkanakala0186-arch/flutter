class Farm {
  const Farm({
    this.id,
    required this.userId,
    required this.farmName,
    required this.location,
    required this.farmSize,
    required this.soilType,
    required this.mainCrop,
    required this.description,
  });

  final int? id;
  final int userId;
  final String farmName;
  final String location;
  final String farmSize;
  final String soilType;
  final String mainCrop;
  final String description;

  factory Farm.fromMap(Map<String, dynamic> map) {
    return Farm(
      id: map['id'] as int?,
      userId: (map['userId'] as int?) ?? 0,
      farmName: (map['farmName'] as String?) ?? '',
      location: (map['location'] as String?) ?? '',
      farmSize: (map['farmSize'] as String?) ?? '',
      soilType: (map['soilType'] as String?) ?? '',
      mainCrop: (map['mainCrop'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'farmName': farmName,
      'location': location,
      'farmSize': farmSize,
      'soilType': soilType,
      'mainCrop': mainCrop,
      'description': description,
    };
  }
}
