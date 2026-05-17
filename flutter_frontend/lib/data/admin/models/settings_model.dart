// lib/data/admin/models/settings_model.dart

class SettingModel {
  final String pwChangePeriod;

  SettingModel({required this.pwChangePeriod});

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    return SettingModel(pwChangePeriod: json['pwChangePeriod'] ?? '');
  }

  Map<String, dynamic> toJson() => {'pwChangePeriod': pwChangePeriod};

  SettingModel copyWith({String? pwChangePeriod}) {
    return SettingModel(pwChangePeriod: pwChangePeriod ?? this.pwChangePeriod);
  }
}
