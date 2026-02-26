import 'package:flutter/material.dart';

class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 1,
  });

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => isExpanded = !isExpanded),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: isExpanded ? null : widget.maxLines,
        overflow:
            isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
      ),
    );
  }
}