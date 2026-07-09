class AuthSession {
  final String? userId;
  final String email;
  final DateTime signedInAt;

  const AuthSession({
    this.userId,
    required this.email,
    required this.signedInAt,
  });

  String get storageKey => userId ?? email;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'] as String?,
      email: json['email'] as String,
      signedInAt: DateTime.parse(json['signedInAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'signedInAt': signedInAt.toIso8601String(),
    };
  }
}