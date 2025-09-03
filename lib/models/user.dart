class UserModel {
  final String uid;
  final String email;
  final int money;
  final int loan;
  final int serre;

  UserModel({
    required this.uid,
    required this.email,
    required this.money,
    required this.loan,
    required this.serre,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'money': money,
      'loan': loan,
      'serre': serre,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      money: map['money'] ?? 0,
      loan: map['loan'] ?? 0,
      serre: map['serre'] ?? 0,
    );
  }
}