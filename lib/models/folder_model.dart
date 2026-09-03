class NoteFolder {
  final String id;
  final String name;
  final int colorValue;
  final String iconName;

  NoteFolder({
    required this.id,
    required this.name,
    this.colorValue = 0xFF4A90E2,
    this.iconName = 'folder',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'iconName': iconName,
    };
  }

  factory NoteFolder.fromMap(Map<String, dynamic> map) {
    return NoteFolder(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'Chung',
      colorValue: map['colorValue'] is int ? map['colorValue'] : 0xFF4A90E2,
      iconName: map['iconName']?.toString() ?? 'folder',
    );
  }
}
