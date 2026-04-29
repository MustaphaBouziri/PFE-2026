
class ErpEmployee {
  final String employeeId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String? imageBase64;

  ErpEmployee({
    required this.employeeId,
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.email = '',
    this.imageBase64,
  });

  factory ErpEmployee.fromJson(Map<String, dynamic> json) {
   

    return ErpEmployee(
      employeeId: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      middleName: json['middleName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      imageBase64: json['image']?.toString(),
      
    );
  }


  String get fullName {
    final parts = [firstName, middleName, lastName]
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'No Name';
    return parts.join(' ').trim();
  }

  @override
  String toString() => 'ErpEmployee($employeeId, $fullName)';
}