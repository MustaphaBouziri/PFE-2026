import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';

class InfoCell extends StatelessWidget {
  final String label;
  final String value;

  const InfoCell({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpandableText(
            text:label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 2),
         ExpandableText(
            text:value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
           
          ),
        ],
      ),
    );
  }
}
