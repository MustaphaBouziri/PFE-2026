class MesUser {
  final String userId;
  final String employeeId;
  final String role;
  final String firstName;
  final String lastName;
  final String email;
  final List<String> workCenterNames;
  final String authId;
  final bool isActive;

  MesUser({
    required this.userId,
    required this.authId,
    required this.employeeId,
    required this.role,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    required this.workCenterNames,
    required this.isActive,
  });

  factory MesUser.fromJson(Map<String, dynamic> json) {
    return MesUser(
      userId:     json['userId']?.toString()     ?? '',
      employeeId: json['employeeId']?.toString()  ?? '',
      role:       json['role']?.toString()        ?? '',
      firstName:  json['firstName']?.toString()   ?? '',
      lastName:   json['lastName']?.toString()    ?? '',
      email:      json['email']?.toString()       ?? '',
      authId:     json['authId']?.toString()      ?? '',
      workCenterNames: (json['workCenters'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      isActive:   json['isActive'] == true // need to ask about this 
    );
  }

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'No Name' : name;
  }

  String get workCenterNameTextFormat {
    if (workCenterNames.isEmpty) return '-';
    return workCenterNames.join(', ');
  }

  @override
  String toString() {
    return 'MesUser(userId: $userId, employeeId: $employeeId, role: $role, fullName: $fullName, email: $email)';
  }
}