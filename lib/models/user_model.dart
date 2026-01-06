class User {
  final String userId;
  final String? email;
  final String firstName;
  final String lastName;
  final String number;
  final bool isSeller;

  User({
    required this.userId,
    this.email,
    required this.firstName,
    required this.lastName,
    required this.number,
    required this.isSeller,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      number: json['number'],
      isSeller: json['is_seller'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'email': email,
    'first_name': firstName,
    'last_name': lastName,
    'is_seller': isSeller,
  };
}
