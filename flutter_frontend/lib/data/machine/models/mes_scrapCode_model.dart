class MesScrapCode {
  final String code;
  final String description;

  MesScrapCode({required this.code, required this.description});

  factory MesScrapCode.fromJson(Map<String, dynamic> json) {
    return MesScrapCode(
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }

  String get displayLabel => '$code — $description';
}
