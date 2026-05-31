class AuthResponse {
  final String idToken;
  final String email;
  final String localId;

  AuthResponse({
    required this.idToken,
    required this.email,
    required this.localId,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      idToken: json['idToken'],
      email: json['email'],
      localId: json['localId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'idToken': idToken, 'email': email, 'localId': localId};
  }
}
