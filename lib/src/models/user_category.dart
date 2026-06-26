/// A user-created category (collection/shelf). Pure data model with JSON
/// serialization for local persistence.
class UserCategory {
  const UserCategory({
    required this.id,
    required this.name,
    this.bookIds = const [],
  });

  final String id;
  final String name;
  final List<String> bookIds;

  UserCategory copyWith({
    String? name,
    List<String>? bookIds,
  }) {
    return UserCategory(
      id: id,
      name: name ?? this.name,
      bookIds: bookIds ?? this.bookIds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bookIds': bookIds,
      };

  factory UserCategory.fromJson(Map<String, dynamic> json) {
    return UserCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      bookIds: (json['bookIds'] as List?)?.cast<String>() ?? const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserCategory && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
