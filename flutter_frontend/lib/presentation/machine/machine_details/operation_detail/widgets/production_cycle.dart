import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_production_cycle.dart';

class ProductionCycle extends StatefulWidget {
  final List<ProductionCycleModel> cycles;

  const ProductionCycle({super.key, required this.cycles});

  @override
  State<ProductionCycle> createState() => _ProductionCycleState();
}

class _ProductionCycleState extends State<ProductionCycle> {
  static const int rowsPerPage = 10;
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final cycles = widget.cycles;

    final start = currentPage * rowsPerPage;
    final end = (start + rowsPerPage > cycles.length)
        ? cycles.length
        : start + rowsPerPage;

    final pageItems = cycles.sublist(start, end);

    final totalPages = (cycles.length / rowsPerPage).ceil();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                headerCell("Operator"),
                headerCell("Cycle Qty"),
                headerCell("Produced"),
                headerCell("Scrap"),
                headerCell("Time"),
              ],
            ),
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pageItems.length,
            itemBuilder: (context, index) {
              final cycle = pageItems[index];

              return Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                ),
                child: Row(
                  children: [
                    rowCell(cycle.fullName),
                    rowCell(cycle.cycleQuantity.toString()),
                    rowCell(cycle.totalProducedQuantity.toString()),
                    rowCell(cycle.scrapQuantity.toString()),
                    rowCell(cycle.timeLabel),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: currentPage > 0
                    ? () {
                        setState(() {
                          currentPage--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),

              Text(
                "Page ${currentPage + 1} / $totalPages",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),

              IconButton(
                onPressed: currentPage < totalPages - 1
                    ? () {
                        setState(() {
                          currentPage++;
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget headerCell(String text) {
  return Expanded(
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    ),
  );
}

Widget rowCell(String text) {
  return Expanded(child: Text(text, style: const TextStyle(fontSize: 14)));
}