import 'package:flutter/material.dart';

class Buttons extends StatefulWidget {
  final String text;
  final bool isprimary;
  final VoidCallback onTap;
  final bool isLoading;

  const Buttons({
    super.key,
    required this.text,
    required this.isprimary,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<Buttons> createState() => _ButtonsState();
}

class _ButtonsState extends State<Buttons> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isprimary ? Colors.white : const Color(0xFF0F172A);

    final bgColor = widget.isprimary
        ? const Color(0xFF2563EB)
        : Colors.white;

    final hoverBg = widget.isprimary
        ? const Color(0xFF1D4ED8)
        : Colors.grey.shade50;

    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: GestureDetector(
        onTap: widget.isLoading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 36,
          width: 140,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: hovered ? hoverBg : bgColor,
            border: widget.isprimary ? null : Border.all(color: Colors.grey.shade300),
            boxShadow: hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    ),
                  ),
                Text(
                  widget.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
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