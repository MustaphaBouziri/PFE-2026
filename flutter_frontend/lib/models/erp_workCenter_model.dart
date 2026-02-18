class ErpWorkCenter {
  final String id;
  final String workCenterName;

  ErpWorkCenter({
    required this.id,
    this.workCenterName = '',
  });

  factory ErpWorkCenter.fromJson(Map<String, dynamic> json) {
    return ErpWorkCenter(
     
      id: json['id']?.toString() ?? '',
      workCenterName: json['workCenterName']?.toString() ?? '',
     
    );
  }

  
}