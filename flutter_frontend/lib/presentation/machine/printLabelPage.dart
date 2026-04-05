import 'package:barcode/barcode.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../../data/machine/models/mes_operation_model.dart';

class PrintLabelPage extends StatefulWidget {
  final OperationStatusAndProgressModel operationData;
  const PrintLabelPage({super.key, required this.operationData});

  @override
  State<PrintLabelPage> createState() => _PrintLabelPageState();
}

class _PrintLabelPageState extends State<PrintLabelPage> {
  bool _isLandscape = false;

  String get _barcodeData =>
      '${widget.operationData.prodOrderNo}'
      '|${widget.operationData.operationNo}'
      '|${widget.operationData.machineNo}'
      '|${widget.operationData.itemDescription}';

  Future<void> _print() async {
    final format = _isLandscape
        ? PdfPageFormat.a4.landscape
        : PdfPageFormat.a4.portrait;
    final svg = Barcode.dataMatrix().toSvg(
      _barcodeData,
      width: 120,
      height: 120,
    );
    await Printing.layoutPdf(
      format: format,
      onLayout: (_) async {
        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            pageFormat: format,
            build: (_) => pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SvgImage(svg: svg, width: 120, height: 120),
                pw.SizedBox(width: 20),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Production Label',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _pdfRow('Order', widget.operationData.prodOrderNo),
                    _pdfRow('Operation', widget.operationData.operationNo),
                    _pdfRow('Machine', widget.operationData.machineNo),
                    _pdfRow('Item', widget.operationData.itemDescription),
                    _pdfRow(
                      'Qty',
                      widget.operationData.orderQuantity.toStringAsFixed(0),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        return doc.save();
      },
    );
  }

  pw.Widget _pdfRow(String label, String value) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    ),
  );

  Widget _preview() => KeyedSubtree(
    key: ValueKey(_isLandscape),
    child: Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLandscape
          ? Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BarcodeWidget(
                  barcode: Barcode.dataMatrix(),
                  data: _barcodeData,
                  width: 100,
                  height: 100,
                ),
                const SizedBox(width: 16),
                _info(showTitle: true),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Production Label',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                BarcodeWidget(
                  barcode: Barcode.dataMatrix(),
                  data: _barcodeData,
                  width: 120,
                  height: 120,
                ),
                const SizedBox(height: 16),
                _info(showTitle: false),
              ],
            ),
    ),
  );

  Widget _info({required bool showTitle}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (showTitle) ...[
        const Text(
          'Production Label',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
      ],
      _infoRow('Order', widget.operationData.prodOrderNo),
      _infoRow('Operation', widget.operationData.operationNo),
      _infoRow('Machine', widget.operationData.machineNo),
      _infoRow('Item', widget.operationData.itemDescription),
      _infoRow('Qty', widget.operationData.orderQuantity.toStringAsFixed(0)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Print Label',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            children: [
              const Text('Landscape', style: TextStyle(fontSize: 13)),
              Switch(
                value: _isLandscape,
                onChanged: (val) => setState(() => _isLandscape = val),
              ),
            ],
          ),
          TextButton.icon(
            onPressed: _print,
            icon: const Icon(Icons.print),
            label: const Text('Print'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isPhone
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(child: _preview()),
            )
          : Row(
              children: [
                const VerticalDivider(width: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Center(child: _preview()),
                  ),
                ),
              ],
            ),
    );
  }
}
