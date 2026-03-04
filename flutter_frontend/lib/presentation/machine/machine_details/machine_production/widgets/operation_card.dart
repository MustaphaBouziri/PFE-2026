import 'package:flutter/material.dart';

import '../layout/narrow_layout.dart';
import '../layout/wide_layout.dart';
import '../models/status_style.dart';

/// Self-sizing card for a single machine operation.
///
/// The colored left rail is drawn using a Stack so we never need
/// [IntrinsicHeight] (which breaks inside ListView) or a non-uniform
/// Border (which breaks with borderRadius).
class OperationCard extends StatelessWidget {
  final Map<String, dynamic> operationData;
  final VoidCallback? onTap;

  const OperationCard({super.key, required this.operationData, this.onTap});

  String get _prodOrderNo => operationData['prodOrderNo']?.toString() ?? '—';

  String get _operationNo => operationData['operationNo']?.toString() ?? '—';

  String get _operationStatus =>
      operationData['operationStatus']?.toString() ?? '';

  String? get _lastUpdatedAt => operationData['lastUpdatedAt']?.toString();

  double get _progress {
    final rawProgress = operationData['progress'];
    if (rawProgress != null) {
      final p = (rawProgress as num).toDouble();
      return p > 1.0 ? p / 100.0 : p;
    }
    final produced = operationData['producedQty'];
    final required = operationData['requiredQty'];
    if (produced != null && required != null) {
      final req = (required as num).toDouble();
      if (req > 0) return ((produced as num).toDouble() / req).clamp(0.0, 1.0);
    }
    switch (_operationStatus) {
      case 'Running':
        return 0.5;
      case 'Paused':
        return 0.35;
      case 'Finished':
        return 1.0;
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = operationStatusStyleFromStatus(_operationStatus);
    final isRunning = _operationStatus == 'Running';

    return Opacity(
      opacity: isRunning ? 1.0 : 0.80,
      child: GestureDetector(
        onTap: onTap,
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
                      final isWide = constraints.maxWidth > 520;
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
