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
      final scanned = c.totalQuantityScanned;

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
    final isWide = MediaQuery.of(context).size.width > 1210;

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
               SizedBox(
                  
                  child: ElevatedButton.icon(
                     onPressed: () => _openScanner(context),
                    
                          
                       
                    label: Text(
                      'scanItem'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
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
            height: 750,
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

  String getStatus(double remaining, double scanned) {
    if (scanned == 0 || remaining <= 0) return statusMissing;// if there are less than 20% of the scanned quantity remaining and remaining is less than or equal to zero we consider it low stock
    if (remaining < scanned * 0.2) return statusLowStock;
    return statusAvailable;
  }

  Color getBgColor(String status, bool isSpecific) {
    if (status == statusAvailable) {
      return isSpecific ? const Color(0xFFDCFCE7) : const Color(0xFFECFDF5);
    } else if (status == statusLowStock) {
      return isSpecific
          ? const Color.fromARGB(255, 255, 251, 219)
          : const Color.fromARGB(255, 255, 253, 222);
    } else {
      return isSpecific
          ? const Color.fromARGB(255, 255, 236, 236)
          : const Color.fromARGB(255, 255, 244, 244);
    }
  }

  Color getBorderColor(String status, bool isSpecific) {
    if (status == statusAvailable) {
      return const Color(0xFF16A34A).withOpacity(isSpecific ? 1 : 0.2);
    } else if (status == statusLowStock) {
      return const Color(0xFFCA8A04).withOpacity(isSpecific ? 1 : 0.2);
    } else {
      return const Color(0xFFDC2626).withOpacity(isSpecific ? 1 : 0.2);
    }
  }

  IconData getIcon(String status) {
    if (status == statusAvailable) return Icons.check_circle_outline;
    if (status == statusLowStock) return Icons.warning_amber_outlined;
    return Icons.cancel_outlined;
  }

  Color getIconColor(String status, bool isSpecific) {
    if (status == statusAvailable) {
      return isSpecific
          ? const Color(0xFF16A34A)
          : const Color(0xFF16A34A).withOpacity(0.8);
    } else if (status == statusLowStock) {
      return isSpecific
          ? const Color(0xFFCA8A04)
          : const Color(0xFFCA8A04).withOpacity(0.8);
    } else {
      return isSpecific
          ? const Color(0xFFDC2626)
          : const Color(0xFFDC2626).withOpacity(0.8);
    }
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
        // if the component belongs to this operation, we highlight it more and show full opacity else we show it with less opacity and lighter colors
        final isSpecific = component.belongsToThisOperation;
        // consumed is how many items have been used based on the total produced and the quantity per unit
        final consumed = totalProduced * component.quantityPerUnit;
        // scanned is how many qte of this item u scanned  * qte per unit of measure 
        final scanned = component.totalQuantityScanned;
        // remaining is how many items are left to be scanned or used

        final scrap = component.scrapQuantity;
        final remaining = scanned - consumed - scrap;

        final status = getStatus(remaining, scanned);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: getBgColor(status, isSpecific),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: getBorderColor(status, isSpecific)),
          ),
          child: Row(
            children: [
              Icon(
                getIcon(status),
                color: getIconColor(status, isSpecific),
                size: 22,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${component.itemDescription} (${component.quantityPerUnit} per unit)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSpecific
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF0F172A).withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${scanned.toString()} ${'quantity scanned'.tr()} | '
                      '${consumed.toString()} ${'used'.tr()} | '
                      '${remaining.toString()} ${'quantity left'.tr()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isSpecific
                            ? const Color(0xFF64748B)
                            : const Color(0xFF64748B).withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                status.tr(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: getIconColor(status, isSpecific),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
