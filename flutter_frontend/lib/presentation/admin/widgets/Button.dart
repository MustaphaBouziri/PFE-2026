import 'package:flutter/material.dart';

class Buttons extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final color = isprimary ? Colors.white : const Color(0xFF0F172A);

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 36,
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isprimary ? const Color(0xFF2563EB) : Colors.white,
          border: isprimary ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: color),
                  ),
                ),
              Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}