import 'package:easy_localization/easy_localization.dart';
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
          Expanded(flex: 3, child: Text('tableHeaderUser'.tr(), style: style)),
          Expanded(flex: 2, child: Text('tableHeaderRole'.tr(), style: style)),
          Expanded(flex: 2, child: Text('tableHeaderDepartment'.tr(), style: style)),
          Expanded(flex: 2, child: Text('tableHeaderStatus'.tr(), style: style)),
          Expanded(flex: 2, child: Text('tableHeaderLastActive'.tr(), style: style)),
          SizedBox(width: 60, child: Text('tableHeaderActions'.tr(), style: style)),
        ],
      ),
    );
  }
}