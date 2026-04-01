import 'package:flutter/material.dart';

import '../../../../../data/machine/models/mes_operation_model.dart';
import '../../operation_detail/operationDetailPage.dart';
import '../layout/narrow_layout.dart';
import '../layout/wide_layout.dart';
import '../models/status_style.dart';

class OperationCard extends StatelessWidget {
  final OperationStatusAndProgressModel operationData;
  final VoidCallback? onTogglePauseResume;

  const OperationCard({
    super.key,
    required this.operationData,
    this.onTogglePauseResume,
  });

  String get _prodOrderNo => operationData.prodOrderNo;
  String get _operationNo => operationData.operationNo;
  String get _operationStatus => operationData.operationStatus;
  String get _lastUpdatedAt => operationData.declaredAt;

  double get _progress {
    if (operationData.orderQuantity != 0) {
      return (operationData.progressPercent / 100).clamp(0.0, 1.0);
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final style = operationStatusStyleFromStatus(_operationStatus);
    final isRunning = _operationStatus == 'Running';

    return Opacity(
      opacity: isRunning ? 1.0 : 0.80,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OperationDetailPage(operationData: operationData),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x0A0F172A), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: 4,
                  child: ColoredBox(color: style.leftRail),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, right: 16, top: 16, bottom: 16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      if (isWide) {
                        return OperationWideLayout(
                          prodOrderNo: _prodOrderNo,
                          operationNo: _operationNo,
                          operationStatus: _operationStatus,
                          declaredAt: _lastUpdatedAt,
                          progress: _progress,
                          style: style,
                          onTogglePauseResume: onTogglePauseResume,
                        );
                      } else {
                        return OperationNarrowLayout(
                          prodOrderNo: _prodOrderNo,
                          operationNo: _operationNo,
                          operationStatus: _operationStatus,
                          declaredAt: _lastUpdatedAt,
                          progress: _progress,
                          style: style,
                          onTogglePauseResume: onTogglePauseResume,
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}