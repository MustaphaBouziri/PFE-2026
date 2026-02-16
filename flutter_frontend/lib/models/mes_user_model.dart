class MesUser {
  final String userId;
  final String employeeId;
  final String role;
  final String firstName;
  final String lastName;
  final String email;

  MesUser({
    required this.userId,
    required this.employeeId,
    required this.role,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
  });

  factory MesUser.fromJson(Map<String, dynamic> json) {
    final employee = json['EmployeeRec'] ?? {};

    return MesUser(
      userId: json['userId'] ?? '',
      employeeId: json['employeeId'] ?? '',
      role: json['role']?.toString() ?? '',
      firstName: employee['firstName'] ?? '',
      lastName: employee['lastName'] ?? '',
      email: employee['email'] ?? '',
    );
  }

  String get fullName => "$firstName $lastName";

  @override
  String toString() =>
      'MesUser(userId: $userId, employeeId: $employeeId, role: $role, fullName: $fullName, email: $email)';
}
