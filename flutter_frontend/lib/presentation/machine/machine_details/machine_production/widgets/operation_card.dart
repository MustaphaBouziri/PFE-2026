import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_operation_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/operationDetailPage.dart';

import '../layout/narrow_layout.dart';
import '../layout/wide_layout.dart';
import '../models/status_style.dart';

/// Self-sizing card for a single machine operation.
///
/// The colored left rail is drawn using a Stack so we never need
/// [IntrinsicHeight] (which breaks inside ListView) or a non-uniform
/// Border (which breaks with borderRadius).
class OperationCard extends StatelessWidget {
  final OperationStatusAndProgressModel operationData;
  

  const OperationCard({super.key, required this.operationData});
  //fixed by making it use the model  + fixed the proggress now dynamic

  String get _prodOrderNo => operationData.prodOrderNo;

  String get _operationNo => operationData.operationNo;

  String get _operationStatus => operationData.operationStatus;

  String get _lastUpdatedAt => operationData.lastUpdatedAt;

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
        onTap:() {
          Navigator.push(context, MaterialPageRoute(builder:(context) => OperationDetailPage(operationData: operationData,),));
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Stack(
              children: [
                // ── Colored left rail via Positioned fill ────────────────
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: 4,
                  child: ColoredBox(color: style.leftRail),
                ),

                // ── Card content with left padding for the rail ──────────
                Padding(
                  padding: const EdgeInsets.only(
                    left: 20, // 4 rail + 16 content padding
                    right: 16,
                    top: 16,
                    bottom: 16,
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 600;
                      if (isWide) {
                        return OperationWideLayout(
                          prodOrderNo: _prodOrderNo,
                          operationNo: _operationNo,
                          operationStatus: _operationStatus,
                          lastUpdatedAt: _lastUpdatedAt,
                          progress: _progress,
                          style: style,
                          onTogglePauseResume: null,
                        );
                      } else {
                        return OperationNarrowLayout(
                          prodOrderNo: _prodOrderNo,
                          operationNo: _operationNo,
                          operationStatus: _operationStatus,
                          lastUpdatedAt: _lastUpdatedAt,
                          progress: _progress,
                          style: style,
                          onTogglePauseResume: null,
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
