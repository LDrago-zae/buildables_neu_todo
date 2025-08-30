class Task {
  final String id;
  final String title;
  final bool done;
  final String? category;
  final DateTime? createdAt;

  Task({
    required this.id,
    required this.title,
    this.done = false,
    this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    bool? done,
    String? category,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString() ?? '',
      title: map['title'] as String,
      done: (map['done'] as bool?) ?? false,
      category: map['category'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'title': title,
      'done': done,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'done': done,
      'category': category,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}