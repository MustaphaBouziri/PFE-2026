import 'package:flutter/material.dart';

class Buttons extends StatelessWidget {
  final String text;
  final bool isprimary;
  final VoidCallback onTap;

  const Buttons({super.key, required this.text, required this.isprimary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isprimary ? const Color(0xFF2563EB) : Colors.white,
          border: isprimary ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isprimary ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
      ),
    );
  }
}

