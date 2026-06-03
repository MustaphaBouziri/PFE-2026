import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pfe_mes/domain/machines/barCode/provider/mes_barCode_provider.dart';
import 'package:pfe_mes/presentation/admin/barCode/widgets/dataMatrix_card.dart';
import 'package:pfe_mes/presentation/widgets/expandableText.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:barcode_widget/barcode_widget.dart';

class BarcodeListPage extends StatefulWidget {
  const BarcodeListPage({super.key});

  @override
  State<BarcodeListPage> createState() => _BarcodeListScreenState();
}

class _BarcodeListScreenState extends State<BarcodeListPage> {
  final TextEditingController searchcontroller = TextEditingController();

  int _currentPage = 0;

  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MesBarcodeProvider>().fetchAllBarcodes();
    });
  }

  //pdf export

  Future<Uint8List> _renderBarcodeToBytes(String data) async {
    final barcode = bw.Barcode.dataMatrix();

    const double size = 400;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final backgroundPaint = Paint()..color = Colors.white;
    final foregroundPaint = Paint()..color = Colors.black;

    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), backgroundPaint);

    final elements = barcode.make(
      data,
      width: size,
      height: size,
      drawText: false,
    );

    for (final element in elements) {
      if (element is bw.BarcodeBar && element.black) {
        canvas.drawRect(
          Rect.fromLTWH(
            element.left,
            element.top,
            element.width,
            element.height,
          ),
          foregroundPaint,
        );
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return bytes!.buffer.asUint8List();
  }

  Future<void> _printSingleBarcode(
    String itemNo,
    String description,
    String encodedText,
  ) async {
    try {
      final barcodeImage = await _renderBarcodeToBytes(encodedText);
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Center(
            child: pw.Image(
              pw.MemoryImage(barcodeImage),
              width: 300,
              height: 300,
            ),
          ),
        ),
      );

      final bytes = await pdf.save();

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'barcode_$itemNo.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('exportFailed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    searchcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MesBarcodeProvider>();
    final barcodes = provider.barcodes;

    final filteredBarcodes = barcodes.where((barcode) {
      return barcode.description.toLowerCase().contains(
        searchcontroller.text.toLowerCase(),
      );
    }).toList();

    final totalPages = (filteredBarcodes.length / _pageSize).ceil();

    final pageBarcode = filteredBarcodes
        .skip(_currentPage * _pageSize)
        .take(_pageSize)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'barcodes'.tr(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MesBarcodeProvider>().fetchAllBarcodes();
            },
          ),
        ],
      ),
      body: Consumer<MesBarcodeProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.barcodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('noBarcodesFound'.tr()),
                  const SizedBox(height: 16),
                  
                ],
              ),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('FailedToFetchData'.tr()),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchAllBarcodes(),
                    child: Text('retry'.tr()),
                  ),
                ],
              ),
            );
          }

          if (provider.barcodes.isEmpty) {
            return Center(child: Text('noBarcodesFound'.tr()));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: GlobalSearchBar(
                  controller: searchcontroller,
                  onSearchChanged: (val) {
                    setState(() {
                      _currentPage = 0;
                    });
                  },
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: pageBarcode.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.9,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (ctx, index) {
                    final barcode = pageBarcode[index];

                    return DataMatrixCard(
                      itemNo: barcode.itemNo,
                      description: barcode.description,
                      encodedText: barcode.barcodeText,
                      onTap: () {
                        _printSingleBarcode(
                          barcode.itemNo,
                          barcode.description,
                          barcode.barcodeText,
                        );
                      },
                    );
                  },
                ),
              ),
              if (totalPages > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _currentPage > 0
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                            : null,
                      ),
                      Text(
                        '${_currentPage + 1} / $totalPages',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _currentPage < totalPages - 1
                            ? () {
                                setState(() {
                                  _currentPage++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
