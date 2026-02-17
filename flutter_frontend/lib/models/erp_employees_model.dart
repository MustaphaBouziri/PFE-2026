class ErpEmployee {

  final String employeeId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String image;

  ErpEmployee({
   
    required this.employeeId,
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.email = '',
    this.image= '',
  });

  factory ErpEmployee.fromJson(Map<String, dynamic> json) {
    return ErpEmployee(
     
      employeeId: json['employeeId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      middleName: json['middleName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      image: json['image']?.toString() ?? 'https://picsum.photos/200/200',

    );
  }

  String get fullName {
    final name = '$firstName $middleName $lastName '.trim();
    return name.isEmpty ? 'No Name' : name;
  }

  
}