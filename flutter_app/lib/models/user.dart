class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final UserType userType;
  final DateTime createdAt;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.userType,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == json['userType'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'userType': userType.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get fullName => '$firstName $lastName';
}

enum UserType { CUSTOMER, GARAGE_OWNER }