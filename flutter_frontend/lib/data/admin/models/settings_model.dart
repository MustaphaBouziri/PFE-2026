// lib/data/admin/models/settings_model.dart

class SettingModel {
  final String pwChangePeriod;
  final bool twoFAEnabled;

  SettingModel({
    required this.pwChangePeriod,
    this.twoFAEnabled = false,
  });

  factory SettingModel.fromJson(Map<String, dynamic> json) {
    return SettingModel(
      pwChangePeriod: json['pwChangePeriod']?.toString() ?? '',
      twoFAEnabled: json['twoFAEnabled'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'pwChangePeriod': pwChangePeriod,
    'twoFAEnabled': twoFAEnabled,
  };

  SettingModel copyWith({String? pwChangePeriod, bool? twoFAEnabled}) {
    return SettingModel(
      pwChangePeriod: pwChangePeriod ?? this.pwChangePeriod,
      twoFAEnabled: twoFAEnabled ?? this.twoFAEnabled,
    );
  }
}