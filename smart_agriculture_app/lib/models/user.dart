class User {
  const User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  final int? id;
  final String name;
  final String email;
  final String phone;
  final String password;

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      password: (map['password'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
    };
  }
}
