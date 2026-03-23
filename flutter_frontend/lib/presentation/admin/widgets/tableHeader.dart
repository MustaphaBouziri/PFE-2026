import 'package:flutter/material.dart';

class TableHeader extends StatelessWidget {
  const TableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('USER', style: style)),
          Expanded(flex: 2, child: Text('ROLE', style: style)),
          Expanded(flex: 2, child: Text('DEPARTMENT', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          Expanded(flex: 2, child: Text('LAST ACTIVE', style: style)),
          SizedBox(width: 60, child: Text('ACTIONS', style: style)),
        ],
      ),
    );
  }
}