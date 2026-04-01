import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class GlobalSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearchChanged;

  final List<String>? dropdownItems;
  final String? selectedValue;
  final Function(String?)? onDropdownChanged;

  final bool? sortAscending;
  final VoidCallback? onSortPressed;

  const GlobalSearchBar({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    this.dropdownItems,
    this.selectedValue,
    this.onDropdownChanged,
    this.sortAscending,
    this.onSortPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Row(
          children: [
            /// search field
            Expanded(
              flex: 1,
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'search'.tr(),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // sort button (yes its optional u can not pass it )
            if (sortAscending !=
                null) // since it can be optional if user do not type it in the call it gonna be = null so this wont show
              IconButton(
                icon: Icon(
                  sortAscending! ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                onPressed: onSortPressed,
              ),

            // drop down for mobile
            if (isMobile && dropdownItems != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.tune),
                onSelected: onDropdownChanged,
                itemBuilder: (context) {
                  return dropdownItems!
                      .map(
                        (e) => PopupMenuItem<String>(value: e, child: Text(e)),
                      )
                      .toList();
                },
              ),

            // drop down for pc and tablet
            if (!isMobile && dropdownItems != null) ...[
              const SizedBox(width: 12),
              Container(
                height: 47,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedValue,
                    dropdownColor: Colors.white,
                    items: dropdownItems!
                        .map(
                          (e) => DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          ),
                        )
                        .toList(),
                    onChanged: onDropdownChanged,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
