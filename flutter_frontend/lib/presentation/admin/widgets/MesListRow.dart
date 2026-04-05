import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';

class MesListRow extends StatelessWidget {
  final String label;
  final int flex;
  final Color? color;
  final Color? bg;
  final TextStyle? textStyle;
  final bool? isActive;

  const MesListRow({
    required this.label,
    this.flex = 2,
    this.color,
    this.bg,
    this.textStyle,
    this.isActive,
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
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          )
        : ExpandableText(
            text: label,
            maxLines: 1,
            style: textStyle ?? const TextStyle(fontSize: 13),
          ),
  ),
);
  }
}