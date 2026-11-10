class Crop {
  const Crop({
    this.id,
    required this.farmId,
    required this.cropName,
    required this.plantingDate,
    required this.growthStage,
    required this.status,
    required this.notes,
  });

  final int? id;
  final int farmId;
  final String cropName;
  final String plantingDate;
  final String growthStage;
  final String status;
  final String notes;

  factory Crop.fromMap(Map<String, dynamic> map) {
    return Crop(
      id: map['id'] as int?,
      farmId: (map['farmId'] as int?) ?? 0,
      cropName: (map['cropName'] as String?) ?? '',
      plantingDate: (map['plantingDate'] as String?) ?? '',
      growthStage: (map['growthStage'] as String?) ?? '',
      status: (map['status'] as String?) ?? '',
      notes: (map['notes'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'farmId': farmId,
      'cropName': cropName,
      'plantingDate': plantingDate,
      'growthStage': growthStage,
      'status': status,
      'notes': notes,
    };
  }
}
