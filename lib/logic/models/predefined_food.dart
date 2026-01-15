import 'package:eat_beat_repeat/logic/interfaces/i_soft_deletable.dart';
import 'package:eat_beat_repeat/logic/utils/wrapper.dart';
import 'package:uuid/uuid.dart';

class PredefinedFood implements ISoftDeletable<PredefinedFood> {
  @override
  final String id;
  final String foodDataId;
  final double quantity;
  @override
  final DateTime? deletedAt;

  PredefinedFood._({
    required this.id,
    required this.foodDataId,
    required this.quantity,
    this.deletedAt,
  });

  factory PredefinedFood({
    required String foodDataId,
    required double quantity,
  }) {
    return PredefinedFood._(
      id: Uuid().v4(),
      foodDataId: foodDataId,
      quantity: quantity,
      deletedAt: null,
    );
  }

  @override
  PredefinedFood copyWith({
    String? foodDataId,
    double? quantity,
    Wrapper<DateTime?>? deletedAt,
  }) {
    return PredefinedFood._(
      id: id,
      foodDataId: foodDataId ?? this.foodDataId,
      quantity: quantity ?? this.quantity,
      deletedAt: deletedAt != null ? deletedAt.value : this.deletedAt,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'foodDataId': foodDataId,
      'quantity': quantity,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  // JSON deserialization
  factory PredefinedFood.fromJson(Map<String, dynamic> json) {
    return PredefinedFood._(
      id: json['id'] as String,
      foodDataId: json['foodDataId'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
    );
  }

  // toString override für Debugging
  @override
  String toString() {
    return 'PredefinedFood(id: $id, foodDataId: $foodDataId, quantity: $quantity, deletedAt: $deletedAt)';
  }
}
