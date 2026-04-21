import 'package:flutter/material.dart';

class ActivityLogModel {
  final String type;
  final String operatorId;
  final String operatorName;
  final String declaredById;
  final String declaredByName;
  final String machineNo;
  final String prodOrderNo;
  final String operationNo;
  final String action;
  final String timestamp;

  ActivityLogModel({
    required this.type,
    required this.operatorId,
    required this.operatorName,
    required this.declaredById,
    required this.declaredByName,
    required this.machineNo,
    required this.prodOrderNo,
    required this.operationNo,
    required this.action,
    required this.timestamp,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      type: json['type'] ?? '',
      operatorId: json['operatorId'] ?? '',
      operatorName: json['operatorName'] ?? '',
      declaredById:   json['declaredById']   ?? '',
      declaredByName: json['declaredByName'] ?? '',
      machineNo: json['machineNo'] ?? '',
      prodOrderNo: json['prodOrderNo'] ?? '',
      operationNo: json['operationNo'] ?? '',
      action: json['action'] ?? '',
      timestamp: json['timestamp'] ?? '',
    );
  }

  IconData get icon {
    switch (type) {
      case 'status_change':
        return Icons.play_circle_outline;
      case 'production':
        return Icons.add_circle_outline;
      case 'scrap':
        return Icons.warning_amber_outlined;
      case 'scan':
        return Icons.qr_code_scanner;
      default:
        return Icons.circle_outlined;
    }
  }

  Color get color {
    switch (type) {
      case 'status_change':
        return const Color(0xFF2563EB);
      case 'production':
        return const Color(0xFF16A34A);
      case 'scrap':
        return const Color(0xFFDC2626);
      case 'scan':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF64748B);
    }
  }

  // for ui dropdown to make it look better
  String mapType(String uiType) {
    switch (uiType) {
      case 'Status':
        return 'status_change';
      case 'Productions':
        return 'production';
      case 'Scraps':
        return 'scrap';
      case 'Scans':
        return 'scan';
      default:
        return '';
    }
  }
}

class MachineDashboardModel {
  final String machineNo;
  final String machineName;
  final String workCenterNo;
  final int operationCount;
  final double uptimePercent;
  final double runningMinutes;
  final double totalProduced;
  final double totalScrap;

  MachineDashboardModel({
    required this.machineNo,
    required this.machineName,
    required this.workCenterNo,
    required this.operationCount,
    required this.uptimePercent,
    required this.runningMinutes,
    required this.totalProduced,
    required this.totalScrap,
  });

  factory MachineDashboardModel.fromJson(Map<String, dynamic> json) {
    return MachineDashboardModel(
      machineNo: json['machineNo'] ?? '',
      machineName: json['machineName'] ?? '',
      workCenterNo: json['workCenterNo'] ?? '',
      operationCount: (json['operationCount'] as num? ?? 0).toInt(),
      uptimePercent: (json['uptimePercent'] as num? ?? 0).toDouble(),
      runningMinutes: (json['runningMinutes'] as num? ?? 0).toDouble(),
      totalProduced: (json['totalProduced'] as num? ?? 0).toDouble(),
      totalScrap: (json['totalScrap'] as num? ?? 0).toDouble(),
    );
  }

  // Formats running minutes into 1h 30min, 45min etc
  String get formattedUptime {
    final mins = runningMinutes.toInt();
    if (mins <= 0) return '0min';
    if (mins < 60) return '${mins}min';
    final h = mins ~/ 60;
    final m = mins % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }
}
