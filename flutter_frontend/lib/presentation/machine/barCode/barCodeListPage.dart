// lib/screens/barcode_list_screen.dart
import 'package:flutter/material.dart';
import 'package:pfe_mes/domain/machines/barCode/provider/mes_barCode_provider.dart';
import 'package:pfe_mes/presentation/machine/barCode/widgets/dataMatrix_card.dart';
import 'package:provider/provider.dart';


class BarcodeListPage extends StatefulWidget {
  const BarcodeListPage({Key? key}) : super(key: key);

  @override
  State<BarcodeListPage> createState() => _BarcodeListScreenState();
}

class _BarcodeListScreenState extends State<BarcodeListPage> {
  @override
  void initState() {
    super.initState();
    // Load barcodes when screen is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MesBarcodeProvider>().fetchAllBarcodes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Barcodes')),
      body: Consumer<MesBarcodeProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.fetchAllBarcodes(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.barcodes.isEmpty) {
            return const Center(child: Text('No barcodes found.'));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: provider.barcodes.length,
            itemBuilder: (ctx, index) {
              final barcode = provider.barcodes[index];
              return DataMatrixCard(
                itemNo: barcode.itemNo,
                description: barcode.description,
                encodedText: barcode.barcodeText,
              );
            },
          );
        },
      ),
    );
  }
}