import 'package:uuid/uuid.dart';

class PredefinedFood {
  final String id;
  final String foodDataId;
  final double quantity;

  PredefinedFood._({
    required this.id,
    required this.foodDataId,
    required this.quantity,
  });

  factory PredefinedFood({
    required String foodDataId,
    required double quantity,
  }) {
    return PredefinedFood._(
      id: Uuid().v4(),
      foodDataId: foodDataId,
      quantity: quantity,
    );
  }

  // copyWith method (ID-sicher)
  PredefinedFood copyWith({
    String? foodDataId,
    double? quantity,
  }) {
    return PredefinedFood._(
      id: id,
      foodDataId: foodDataId ?? this.foodDataId,
      quantity: quantity ?? this.quantity,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodDataId': foodDataId,
      'quantity': quantity,
    };
  }

  // JSON deserialization
  factory PredefinedFood.fromJson(Map<String, dynamic> json) {
    return PredefinedFood._(
      id: json['id'] as String,
      foodDataId: json['foodDataId'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // toString override für Debugging
  @override
  String toString() {
    return 'PredefinedFood(id: $id, foodDataId: $foodDataId, quantity: $quantity)';
  }
}
