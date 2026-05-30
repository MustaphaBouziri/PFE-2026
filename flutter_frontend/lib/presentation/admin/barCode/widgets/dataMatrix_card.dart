

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';
import 'package:easy_localization/easy_localization.dart';

class DataMatrixCard extends StatefulWidget {
  final String itemNo;
  final String description;
  final String encodedText;
  final VoidCallback onTap;

  const DataMatrixCard({
    super.key,
    required this.itemNo,
    required this.description,
    required this.encodedText,
    required this.onTap,
  });

  @override
  State<DataMatrixCard> createState() =>
      _DataMatrixCardState();
}
class _DataMatrixCardState extends State<DataMatrixCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() {
        _isHovered = false;
        _isPressed = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.identity()
            ..translate(0, _isHovered ? -4 : 0),
          child: Card(
            elevation: _isHovered ? 8 : 2,
            color: _isPressed
                ? Colors.grey.shade300
                : (_isHovered ? Colors.grey.shade100 : Colors.white),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BarcodeWidget(
                  barcode: Barcode.dataMatrix(),
                  data: widget.encodedText,
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.itemNo,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ExpandableText(
                  text: 
                  widget.description,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 20,),
                Text('clickToPrint'.tr(),style: const TextStyle(color: const Color.fromARGB(80, 0, 0, 0)),)
              ],
            ),
          ),
        ),
      ),
    );
  }
}