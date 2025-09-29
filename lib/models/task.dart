class Task {
  final String id;
  final String title;
  final bool done;
  final String? category;
  final String? color;
  final String? icon;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final List<String>? sharedWith;
  final String? attachmentUrl;
  final int? sortIndex;

  // NEW: Location fields
  final double? latitude;
  final double? longitude;
  final String? locationName;

  Task({
    required this.id,
    required this.title,
    this.done = false,
    this.category,
    this.color,
    this.icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.createdBy,
    this.sharedWith,
    this.attachmentUrl,
    this.sortIndex,
    // NEW: Location parameters
    this.latitude,
    this.longitude,
    this.locationName,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // NEW: Helper method to check if task has location
  bool get hasLocation => latitude != null && longitude != null;

  Task copyWith({
    String? id,
    String? title,
    bool? done,
    String? category,
    String? color,
    String? icon,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<String>? sharedWith,
    String? attachmentUrl,
    int? sortIndex,
    // NEW: Location copyWith parameters
    double? latitude,
    double? longitude,
    String? locationName,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      category: category ?? this.category,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      sharedWith: sharedWith ?? this.sharedWith,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      sortIndex: sortIndex ?? this.sortIndex,
      // NEW: Location copyWith assignments
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
    );
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString() ?? '',
      title: map['title'] as String,
      done: (map['done'] as bool?) ?? false,
      category: map['category'] as String?,
      color: map['color'] as String?,
      icon: map['icon'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      createdBy: map['created_by']?.toString(),
      sharedWith: map['shared_with'] != null
          ? List<String>.from(map['shared_with'] as List)
          : null,
      attachmentUrl: map['attachment_url'] as String?,
      sortIndex: map['sort_index'] as int?,
      // NEW: Location fromMap assignments
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      locationName: map['location_name'] as String?,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'title': title,
      'done': done,
      'category': category,
      'color': color,
      'icon': icon,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_by': createdBy,
      'shared_with': sharedWith,
      'attachment_url': attachmentUrl,
      'sort_index': sortIndex,
      // NEW: Location toInsertMap entries
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'done': done,
      'category': category,
      'color': color,
      'icon': icon,
      'updated_at': DateTime.now().toIso8601String(),
      'shared_with': sharedWith,
      'attachment_url': attachmentUrl,
      // NEW: Location toUpdateMap entries
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
    };
  }

  // Method to check if task is shared
  bool get isShared => sharedWith != null && sharedWith!.isNotEmpty;

  // Helper method to check if task has attachment
  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;

  // Method to check if current user can edit (is owner)
  bool canEdit(String? currentUserId) => createdBy == currentUserId;

  // Method to check if current user has access (owner or shared with)
  bool hasAccess(String? currentUserId) {
    if (currentUserId == null) return false;
    if (createdBy == currentUserId) return true;
    return sharedWith?.contains(currentUserId) ?? false;
  }
}
