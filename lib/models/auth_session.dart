class AuthSession {
  final String email;
  final DateTime signedInAt;

  const AuthSession({
    required this.email,
    required this.signedInAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      email: json['email'] as String,
      signedInAt: DateTime.parse(json['signedInAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'signedInAt': signedInAt.toIso8601String(),
    };
  }
}