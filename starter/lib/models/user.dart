import 'dart:convert';

/// The signed in user's profile.
///
/// Mirrors one row of the `profiles` table in Supabase (see the README for
/// the table definition). In a demo session it is filled with fake data and
/// never touches the network.
class User {
  final String id;
  final String? name;
  final String? username;
  final String? email;

  const User({
    required this.id,
    this.name,
    this.username,
    this.email,
  });

  /// First name for greetings. The first word of [name], or null.
  String? get firstName {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return null;
    return n.split(RegExp(r'\s+')).first;
  }

  /// Up to two initials for the avatar circle.
  String get initials {
    final n = name?.trim() ?? '';
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final last =
        parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as String,
        name: map['name'] as String?,
        username: map['username'] as String?,
        email: map['email'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'username': username,
        'email': email,
      };

  factory User.fromJson(String json) =>
      User.fromMap(jsonDecode(json) as Map<String, dynamic>);

  String toJson() => jsonEncode(toMap());
}
