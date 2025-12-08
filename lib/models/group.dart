import 'dart:convert';

class MessageGroup {
  final String id;
  final String name;
  final List<String> members; // phone numbers
  final DateTime createdAt;

  MessageGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.createdAt,
  });

  factory MessageGroup.fromJson(Map<String, dynamic> json) {
    return MessageGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      members: List<String>.from(json['members'] as List),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'members': members,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  MessageGroup copyWith({
    String? id,
    String? name,
    List<String>? members,
    DateTime? createdAt,
  }) {
    return MessageGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get memberCount => members.length;

  @override
  String toString() => 'MessageGroup(id: $id, name: $name, members: ${members.length})';
}
