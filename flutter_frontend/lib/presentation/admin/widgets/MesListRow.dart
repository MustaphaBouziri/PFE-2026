import 'package:flutter/material.dart';

class MesListRow extends StatelessWidget {
  final String label;
  final int flex;
  final Color? color;
  final Color? bg;
  final TextStyle? textStyle;

  const MesListRow({
    required this.label,
    this.flex = 2,
    this.color,
    this.bg,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasBadgeStyle = color != null && bg != null;

    return Expanded(
      flex: flex,
      child: Align(
        alignment: Alignment.centerLeft,
        child: hasBadgeStyle
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              )
            : Text(label, overflow: TextOverflow.ellipsis, style: textStyle ?? const TextStyle(fontSize: 13)),
      ),
    );
  }
}