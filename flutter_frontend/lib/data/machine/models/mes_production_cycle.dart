class ProductionCycleModel {
  final double orderQuantity;
  final double cycleQuantity;
  final double totalProducedQuantity;
  final double scrapQuantity;
  final String operatorId;
  final String firstName;
  final String lastName;
  final String declaredAt;

  ProductionCycleModel({
    required this.orderQuantity,
    required this.cycleQuantity,
    required this.totalProducedQuantity,
    required this.scrapQuantity,
    required this.operatorId,
    required this.firstName,
    required this.lastName,
    required this.declaredAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get timeLabel {
    try {
      final dt = DateTime.parse(declaredAt);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return declaredAt;
    }
  }

  String get fullLabel {
    try {
      final dt = DateTime.parse(declaredAt);
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      return '$d/$mo ${h}:${m}';
    } catch (_) {
      return declaredAt;
    }
  }

  factory ProductionCycleModel.fromJson(Map<String, dynamic> json) {
    return ProductionCycleModel(
      orderQuantity:         (json['orderQuantity']         as num? ?? 0).toDouble(),
      cycleQuantity:         (json['cycleQuantity']         as num? ?? 0).toDouble(),
      totalProducedQuantity: (json['totalProducedQuantity'] as num? ?? 0).toDouble(),
      scrapQuantity:         (json['scrapQuantity']         as num? ?? 0).toDouble(),
      operatorId:             json['operatorId']            ?? '',
      firstName:              json['firstName']             ?? '',
      lastName:               json['lastName']              ?? '',
      declaredAt:             json['declaredAt']            ?? '',
    );
  }
}