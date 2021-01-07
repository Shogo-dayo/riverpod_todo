import 'package:uuid/uuid.dart';

var _uuid = Uuid();

class Task {
  Task({
    this.title,
    this.isDone = false,
    String id,
    // idはnullならuuidが自動採番される
  }) : id = id ?? _uuid.v4();

  final String id;
  final String title;
  final bool isDone;
}