class UserModel {
  final String uid;
  final String email;
  final String role;
  final String name;
  final String branch;
  final String designation;
  final String photoUrl; // New field for profile picture

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    required this.branch,
    required this.designation,
    required this.photoUrl,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      role: map['role'] ?? 'faculty',
      name: map['name'] ?? 'No Name Provided',
      branch: map['branch'] ?? 'Not Specified',
      designation: map['designation'] ?? 'Not Specified',
      photoUrl: map['photoUrl'] ?? '', // Default to empty string
    );
  }
}
