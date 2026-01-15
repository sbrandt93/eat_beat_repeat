import 'package:eat_beat_repeat/logic/utils/wrapper.dart';

abstract class ISoftDeletable<T> {
  String get id;
  DateTime? get deletedAt;

  // Diese Methode muss jedes Modell implementieren, um sich selbst zu kopieren
  T copyWith({Wrapper<DateTime?>? deletedAt});
}
