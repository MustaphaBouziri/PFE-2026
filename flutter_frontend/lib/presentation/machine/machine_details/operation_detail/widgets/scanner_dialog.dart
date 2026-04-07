import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../../data/machine/barCode/models/mes_barCode_model.dart';
import '../../../../../domain/auth/providers/auth_provider.dart';
import '../../../../../domain/machines/barCode/provider/mes_barCode_provider.dart';
import '../../../../widgets/expandableText.dart';
import 'operator_selector.dart';

class ScannerWidget extends StatefulWidget {
  final String executionId;

  const ScannerWidget({super.key, required this.executionId});

  @override
  State<ScannerWidget> createState() => _ScannerWidgetState();
}

class _ScannerWidgetState extends State<ScannerWidget> {
  final MobileScannerController _controller = MobileScannerController();

  List<ItemBarcodeModel> _items = [];
  bool _isScanning = true;

  // Populated by OperatorSelector when the logged-in user is a Supervisor.
  String _onBehalfOfUserId = '';

  bool get _isSupervisor {
    final role =
        context
            .read<AuthProvider>()
            .userData?['role']
            ?.toString()
            .trim()
            .toLowerCase() ??
        '';
    return role == 'supervisor';
  }

  List<String> get _supervisorWorkCenters {
    final wcs = context.read<AuthProvider>().userData?['workCenters'];
    if (wcs is List) return wcs.map((e) => e.toString()).toList();
    return [];
  }

  // ── Barcode parsing ───────────────────────────────────────────────────────

  /// Converts the pipe-delimited barcode text into an [ItemBarcodeModel].
  /// Format: "Item Number: X|Item Description: Y|Base UOM: Z|..."
  ItemBarcodeModel _parseBarcode(String raw) {
    final map = <String, String>{};
    for (final segment in raw.split('|')) {
      final parts = segment.split(':');
      if (parts.length == 2) {
        map[parts[0].trim()] = parts[1].trim();
      }
    }

    return ItemBarcodeModel(
      itemNo: map['Item Number'] ?? '',
      description: map['Item Description'] ?? '',
      baseUOM: map['Base UOM'] ?? '',
      inventory: double.tryParse(map['Inventory'] ?? '0') ?? 0,
      shelfNo: map['Shelf No'] ?? '',
      lotSize: double.tryParse(map['Lot Size'] ?? '0') ?? 0,
      flushingMethod: map['Flushing Method'] ?? '',
      barcodeText: raw,
      quantity: 1,
    );
  }

  // ── Item list management ──────────────────────────────────────────────────

  /// Increments quantity if the item already exists, otherwise appends it.
  void _addOrIncrement(ItemBarcodeModel newItem) {
    final index = _items.indexWhere((e) => e.itemNo == newItem.itemNo);
    if (index != -1) {
      _setQuantity(index, _items[index].quantity + 1);
    } else {
      setState(() => _items.add(newItem));
    }
  }

  void _increment(int index) => _setQuantity(index, _items[index].quantity + 1);

  void _decrement(int index) {
    if (_items[index].quantity > 1) {
      _setQuantity(index, _items[index].quantity - 1);
    }
  }

  void _remove(int index) => setState(() => _items.removeAt(index));

  void _setQuantity(int index, double newQty) {
    setState(() {
      final original = _items[index];
      _items[index] = ItemBarcodeModel(
        itemNo: original.itemNo,
        description: original.description,
        baseUOM: original.baseUOM,
        inventory: original.inventory,
        shelfNo: original.shelfNo,
        lotSize: original.lotSize,
        flushingMethod: original.flushingMethod,
        barcodeText: original.barcodeText,
        quantity: newQty,
      );
    });
  }

  // ── Scan handling ─────────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null) return;

    setState(() {
      _addOrIncrement(_parseBarcode(rawValue));
      _isScanning = false;
    });
    _controller.stop();
  }

  void _scanAgain() {
    setState(() => _isScanning = true);
    _controller.start();
  }

  // ── Submission ────────────────────────────────────────────────────────────

  Future<void> _confirmScans() async {
    final provider = context.read<MesBarcodeProvider>();
    final token = context.read<AuthProvider>().token;

    final scans = _items.map((e) => e.toJson()).toList();

    final success = await provider.insertScans(
      widget.executionId,
      scans,
      _onBehalfOfUserId,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('insertedSuccessfully'.tr())));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'error'.tr())),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isPhone = MediaQuery.of(context).size.width <= 600;

    return Dialog(
      backgroundColor: const Color(0xFFF8FAFC),
      child: SizedBox(
        width: isPhone ? 400 : 500,
        height: _isSupervisor ? 680 : 600,
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ── Operator selector (supervisors only) ──────────────────────
            if (_isSupervisor)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OperatorSelector(
                  workCenterIds: _supervisorWorkCenters,
                  onOperatorSelected: (userId) =>
                      setState(() => _onBehalfOfUserId = userId ?? ''),
                ),
              ),

            if (_isSupervisor) const SizedBox(height: 12),

            // ── Camera viewfinder ─────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _scanAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'scanAgain'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
            ),

            // ── Scanned items list ────────────────────────────────────────
            Expanded(
              flex: 4,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ListTile(
                              title: ExpandableText(
                                text: '${item.itemNo} - ${item.description}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${'qty'.tr()}${item.quantity.toInt()}',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => _increment(index),
                            icon: const Icon(Icons.add, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () => _decrement(index),
                            icon: const Icon(Icons.remove, color: Colors.black),
                          ),
                          IconButton(
                            onPressed: () => _remove(index),
                            icon: const Icon(
                              Icons.delete_outline_sharp,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Confirm button ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _items.isEmpty ? null : _confirmScans,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'confirmScans'.tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
