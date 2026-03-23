import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_production_cycle.dart';

class ProductionCycle extends StatefulWidget {
  final List<ProductionCycleModel> cycles;
  final int perPage;
  final bool horizontalScrollable;

  const ProductionCycle({
    super.key,
    required this.cycles,
    required this.perPage,
    this.horizontalScrollable = false,
  });

  @override
  State<ProductionCycle> createState() => _ProductionCycleState();
}

class _ProductionCycleState extends State<ProductionCycle> {
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final cycles = widget.cycles.where((c) => c.cycleQuantity > 0).toList();

    if (cycles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text("No production cycles found"),
        ),
      );
    }

    final totalPages = (cycles.length / widget.perPage).ceil();
    final safeCurrentPage = currentPage >= totalPages ? totalPages - 1 : currentPage;

    final start = safeCurrentPage * widget.perPage;
    final end = (start + widget.perPage > cycles.length)
        ? cycles.length
        : start + widget.perPage;

    final pageItems = cycles.sublist(start, end);

    Widget buildHeaderScrollable() {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: const Row(
          children: [
            TableCellWidget(text: "Operator", width: 180, isHeader: true),
            TableCellWidget(text: "Cycle Qty", width: 100, isHeader: true),
            TableCellWidget(text: "Produced", width: 100, isHeader: true),
            TableCellWidget(text: "Scrap", width: 100, isHeader: true),
            TableCellWidget(text: "Time", width: 100, isHeader: true),
          ],
        ),
      );
    }

    Widget buildRowScrollable(ProductionCycleModel cycle) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            TableCellWidget(text: cycle.fullName, width: 180),
            TableCellWidget(text: cycle.cycleQuantity.toString(), width: 100),
            TableCellWidget(
              text: cycle.totalProducedQuantity.toString(),
              width: 100,
            ),
            TableCellWidget(text: cycle.scrapQuantity.toString(), width: 100),
            TableCellWidget(text: cycle.timeLabel, width: 100),
          ],
        ),
      );
    }

    Widget buildHeaderNormal() {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: const Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                "Operator",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                "Cycle Qty",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                "Produced",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                "Scrap",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                "Time",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildRowNormal(ProductionCycleModel cycle) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                cycle.fullName,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                cycle.cycleQuantity.toString(),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                cycle.totalProducedQuantity.toString(),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                cycle.scrapQuantity.toString(),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                cycle.timeLabel,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          widget.horizontalScrollable
              ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeaderScrollable(),
                ...pageItems.map(buildRowScrollable),
              ],
            ),
          )
              : Column(
            children: [
              buildHeaderNormal(),
              ...pageItems.map(buildRowNormal),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: safeCurrentPage > 0
                    ? () {
                  setState(() {
                    currentPage = safeCurrentPage - 1;
                  });
                }
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                "Page ${safeCurrentPage + 1} / $totalPages",
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              IconButton(
                onPressed: safeCurrentPage < totalPages - 1
                    ? () {
                  setState(() {
                    currentPage = safeCurrentPage + 1;
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

class TableCellWidget extends StatelessWidget {
  final String text;
  final double width;
  final bool isHeader;

  const TableCellWidget({
    super.key,
    required this.text,
    required this.width,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}