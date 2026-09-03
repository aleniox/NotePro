import 'dart:convert';

class ChecklistItem {
  final String id;
  String text;
  bool isDone;

  ChecklistItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'isDone': isDone ? 1 : 0,
    };
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      isDone: map['isDone'] == true || map['isDone'] == 1,
    );
  }

  String toJson() => json.encode(toMap());
  factory ChecklistItem.fromJson(String source) => ChecklistItem.fromMap(json.decode(source));
}
