class SoilReading {
  const SoilReading({
    this.id,
    required this.userId,
    required this.farmId,
    required this.moisturePercent,
    required this.waterLevelPercent,
    required this.waterUsedLitres,
    required this.waterRequiredLitres,
    required this.minMoisturePercent,
    required this.minWaterLevelPercent,
    required this.note,
    required this.createdAt,
  });

  final int? id;
  final int userId;
  final int farmId;
  final double moisturePercent;
  final double waterLevelPercent;
  final double waterUsedLitres;
  final double waterRequiredLitres;
  final double minMoisturePercent;
  final double minWaterLevelPercent;
  final String note;
  final String createdAt;

  bool get isMoistureLow => moisturePercent < minMoisturePercent;

  bool get isWaterLevelLow => waterLevelPercent < minWaterLevelPercent;

  bool get needsWater => isMoistureLow || isWaterLevelLow;

  double get waterBalanceLitres => waterRequiredLitres - waterUsedLitres;

  bool get isWaterSaved => waterBalanceLitres > 0;

  SoilReading copyWith({double? moisturePercent, double? waterLevelPercent}) {
    return SoilReading(
      id: id,
      userId: userId,
      farmId: farmId,
      moisturePercent: moisturePercent ?? this.moisturePercent,
      waterLevelPercent: waterLevelPercent ?? this.waterLevelPercent,
      waterUsedLitres: waterUsedLitres,
      waterRequiredLitres: waterRequiredLitres,
      minMoisturePercent: minMoisturePercent,
      minWaterLevelPercent: minWaterLevelPercent,
      note: note,
      createdAt: createdAt,
    );
  }

  factory SoilReading.fromMap(Map<String, dynamic> map) {
    return SoilReading(
      id: map['id'] as int?,
      userId: (map['userId'] as int?) ?? 0,
      farmId: (map['farmId'] as int?) ?? 0,
      moisturePercent: (map['moisturePercent'] as num?)?.toDouble() ?? 0,
      waterLevelPercent: (map['waterLevelPercent'] as num?)?.toDouble() ?? 0,
      waterUsedLitres: (map['waterUsedLitres'] as num?)?.toDouble() ?? 0,
      waterRequiredLitres:
          (map['waterRequiredLitres'] as num?)?.toDouble() ?? 0,
      minMoisturePercent: (map['minMoisturePercent'] as num?)?.toDouble() ?? 0,
      minWaterLevelPercent:
          (map['minWaterLevelPercent'] as num?)?.toDouble() ?? 0,
      note: (map['note'] as String?) ?? '',
      createdAt: (map['createdAt'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'farmId': farmId,
      'moisturePercent': moisturePercent,
      'waterLevelPercent': waterLevelPercent,
      'waterUsedLitres': waterUsedLitres,
      'waterRequiredLitres': waterRequiredLitres,
      'minMoisturePercent': minMoisturePercent,
      'minWaterLevelPercent': minWaterLevelPercent,
      'note': note,
      'createdAt': createdAt,
    };
  }
}
