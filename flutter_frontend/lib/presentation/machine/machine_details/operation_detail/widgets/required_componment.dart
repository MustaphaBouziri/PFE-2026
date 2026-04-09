import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_componentConsumption_model.dart';
import 'package:pfe_mes/presentation/machine/machine_details/operation_detail/widgets/scanner_dialog.dart';
import 'package:pfe_mes/presentation/widgets/searchBar.dart';

class RequiredComponent extends StatefulWidget {
  final List<ComponentConsumptionModel> components;
  final double totalProduced;
  final String executionId;

  const RequiredComponent({
    super.key,
    required this.components,
    required this.totalProduced,
    required this.executionId,
  });

  @override
  State<RequiredComponent> createState() => _RequiredComponentState();
}

class _RequiredComponentState extends State<RequiredComponent> {
  final TextEditingController controller = TextEditingController();
  String selectedFilter = 'all';

  List<ComponentConsumptionModel> get filteredComponents {
    return widget.components.where((c) {
      final search = controller.text.toLowerCase();
      final matchesSearch = c.itemDescription.toLowerCase().contains(search);
      final scanned = c.quantityScanned * c.quantityPerUnit;

      if (selectedFilter == 'missing') return matchesSearch && scanned == 0;
      if (selectedFilter == 'low') return matchesSearch && scanned > 0;
      return matchesSearch;
    }).toList();
  }

  void _openScanner(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ScannerWidget(executionId: widget.executionId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 1024;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "requiredComponents".tr(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const Spacer(),

              // expand button — only on wide screens
              if (isWide)
                IconButton(
                  icon: const Icon(Icons.open_in_full),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        child: Container(
                          width: 900,
                          height: 650,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "requiredComponents".tr(),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Text(
                                      '${widget.components.length} ${'componentsFound'.tr()}',
                                    ),
                                    const Spacer(),
                                    // scan button inside dialog
                                    ElevatedButton(
                                      onPressed: () => _openScanner(context),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF0F172A,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                          horizontal: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        'scanItem'.tr(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                GlobalSearchBar(
                                  controller: controller,
                                  onSearchChanged: (_) => setState(() {}),
                                  dropdownItems: const [
                                    'all',
                                    'missing',
                                    'low',
                                  ],
                                  selectedValue: selectedFilter,
                                  onDropdownChanged: (val) => setState(
                                    () => selectedFilter = val ?? 'all',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: ComponentListView(
                                    components: filteredComponents,
                                    totalProduced: widget.totalProduced,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // scan button in normal view
              ElevatedButton(
                onPressed: () => _openScanner(context),
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
                  'scanItem'.tr(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // search and filter
          GlobalSearchBar(
            controller: controller,
            onSearchChanged: (_) => setState(() {}),
            dropdownItems: const ['all', 'missing', 'low'],
            selectedValue: selectedFilter,
            onDropdownChanged: (val) =>
                setState(() => selectedFilter = val ?? 'all'),
          ),

          const SizedBox(height: 16),
          Text('${widget.components.length} ${'componentsFound'.tr()}'),
          const SizedBox(height: 16),

          // display the list in normal way
          SizedBox(
            height: 400,
            child: ComponentListView(
              components: filteredComponents,
              totalProduced: widget.totalProduced,
            ),
          ),
        ],
      ),
    );
  }
}

// i seperated the list view into its own widget and gonna be reused in expanded dialog and in the main view
class ComponentListView extends StatelessWidget {
  final List<ComponentConsumptionModel> components;
  final double totalProduced;
  final bool shrinkWrap;
  final bool disableScroll;

  const ComponentListView({
    super.key,
    required this.components,
    required this.totalProduced,
    this.shrinkWrap = false,
    this.disableScroll = false,
  });

  static const statusMissing = 'missing';
  static const statusLowStock = 'lowStock';
  static const statusAvailable = 'available';

  String getStatus(double planned, double scanned) {
    if (scanned == 0) return statusMissing;
    if (scanned < planned) return statusLowStock;
    return statusAvailable;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: disableScroll
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: components.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final component = components[index];

        final planned = component.plannedQuantity;
        final isSpecific = component.belongsToThisOperation;

        // how much u consumed of this material
        final consumed = totalProduced * component.quantityPerUnit;
        // how qte u scanned of this item
        final scanned = component.quantityScanned * component.quantityPerUnit;
        // remaining = the qte u scanned - what was consumed
        final remaining = scanned - consumed;

        final status = isSpecific ? getStatus(planned, scanned) : '';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: !isSpecific
                ? const Color(0xFFF1F5F9)
                : status == statusAvailable
                ? const Color(0xFFF0FDF4)
                : status == statusLowStock
                ? const Color(0xFFFEFCE8)
                : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: !isSpecific
                  ? const Color(0xFFCBD5F5).withOpacity(0.2)
                  : status == statusAvailable
                  ? const Color(0xFF1AA44D).withOpacity(0.2)
                  : status == statusLowStock
                  ? const Color(0xFFD39D2B).withOpacity(0.2)
                  : const Color(0xFFE03B3B).withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                !isSpecific
                    ? Icons.remove_circle_outline
                    : status == 'Available'
                    ? Icons.check_circle_outline
                    : status == 'Low Stock'
                    ? Icons.warning_amber_outlined
                    : Icons.cancel_outlined,
                color: !isSpecific
                    ? const Color(0xFF64748B)
                    : status == 'Available'
                    ? const Color(0xFF1AA44D)
                    : status == 'Low Stock'
                    ? const Color(0xFFD39D2B)
                    : const Color(0xFFE03B3B),
                size: 22,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${component.itemDescription} ( ${component.quantityPerUnit} per unit)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${scanned.toString()} ${'quantity scanned'.tr()} | ${consumed.toString()} ${'used'.tr()} | ${remaining.toString()} ${' quantity left'.tr()}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              if (isSpecific)
                Text(
                  status.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status == statusAvailable
                        ? const Color(0xFF1AA44D)
                        : status == statusLowStock
                        ? const Color(0xFFD39D2B)
                        : const Color(0xFFE03B3B),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
