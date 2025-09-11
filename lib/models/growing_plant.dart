class GrowingPlant {
  final String plantId;
  final String plantName;
  final DateTime plantedAt;
  final int serraIndex;

  GrowingPlant({
    required this.plantId,
    required this.plantName,
    required this.plantedAt,
    required this.serraIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'plantId': plantId,
      'plantName': plantName,
      'plantedAt': plantedAt.toIso8601String(),
      'serraIndex': serraIndex,
    };
  }

  factory GrowingPlant.fromMap(Map<String, dynamic> map) {
    return GrowingPlant(
      plantId: map['plantId'],
      plantName: map['plantName'],
      plantedAt: DateTime.parse(map['plantedAt']),
      serraIndex: map['serraIndex'],
    );
  }
}