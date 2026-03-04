import 'package:flutter/material.dart';

import '../models/status_style.dart';

/// Displays the status pill and the "ORD-XXXX · OP-YY" identifier row.
/// Mirrors the role of [BadgeAndId] in the machineOrderPage layer.
///
/// For the "Running" state an animated pulse dot is shown inside the badge
/// to give a live-activity visual cue (design from the React prototype).
class OperationStatusBadge extends StatefulWidget {
  final String prodOrderNo;
  final String operationNo;
  final OperationStatusStyle style;

  const OperationStatusBadge({
    super.key,
    required this.prodOrderNo,
    required this.operationNo,
    required this.style,
  });

  @override
  State<OperationStatusBadge> createState() => _OperationStatusBadgeState();
}

class _OperationStatusBadgeState extends State<OperationStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool get _isRunning => widget.style.label == 'RUNNING';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Status pill ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: widget.style.badgeBg,
            border: Border.all(color: widget.style.badgeBorder),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated dot only while running
              if (_isRunning) ...[
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, _) => Opacity(
                    opacity: _pulseAnimation.value,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: widget.style.badgeText,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                widget.style.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.style.badgeText,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // ── Order + operation identifiers ────────────────────────────────
        Text(
          'ORD-${widget.prodOrderNo}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '· OP-${widget.operationNo}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}