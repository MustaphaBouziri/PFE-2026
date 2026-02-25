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
    String? imageBase64;

    final rawImage = json['image'];
    if (rawImage != null) {
      if (rawImage is Map) {
        // BC structured media object: { "value": "...", "mediaType": "..." }
        imageBase64 = rawImage['value']?.toString();
      } else if (rawImage is String && rawImage.isNotEmpty) {
        imageBase64 = rawImage;
      }
    }
    return ErpEmployee(
      employeeId: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      middleName: json['middleName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      imageBase64: imageBase64,
    );
  }

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;

  String get fullName {
    final name = '$firstName $middleName $lastName '.trim();
    return name.isEmpty ? 'No Name' : name;
  }
}
