
import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class DataMatrixCard extends StatelessWidget {
  final String itemNo;
  final String description;
  final String encodedText;

  const DataMatrixCard({
    super.key,
    required this.itemNo,
    required this.description,
    required this.encodedText,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BarcodeWidget(
              barcode: Barcode.dataMatrix(),
              data: encodedText,
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 8),
            Text(itemNo,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(description,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
