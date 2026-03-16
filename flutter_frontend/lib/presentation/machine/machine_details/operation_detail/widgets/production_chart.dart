import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_production_cycle.dart';

class ProductionChart extends StatefulWidget {
  final List<ProductionCycleModel> cycles;
  const ProductionChart({super.key, required this.cycles});

  @override
  State<ProductionChart> createState() => _ProductionChartState();
}

class _ProductionChartState extends State<ProductionChart> {
  @override
  Widget build(BuildContext context) {
    if (widget.cycles.isEmpty) {
      return const SizedBox();
    }
    final orderedCycles = widget.cycles.reversed.toList();
    final spots = orderedCycles.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.cycleQuantity);
    }).toList();

    final maxY = orderedCycles
            .map((c) => c.cycleQuantity)
            .reduce((a, b) => a > b ? a : b) +
        10;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Production Declarations",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 24),

          AspectRatio(
            aspectRatio: 1.70,
            child: Padding(
              padding: const EdgeInsets.only(
                right: 18,
                left: 12,
                top: 12,
                bottom: 12,
              ),
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final cycle = orderedCycles[spot.x.toInt()];
                          return LineTooltipItem(
                            '${cycle.fullName}\nDeclared ${spot.y.toInt()} units\nTotal: ${cycle.totalProducedQuantity.toInt()} units\n${cycle.fullLabel}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 10,
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (_) => const FlLine(
                      color: Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    ),
                  ),

                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    // x axis — time of each cycle
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= orderedCycles.length) {
                            return const SizedBox();
                          }
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              orderedCycles[index].timeLabel,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // y axis — declared quantity per cycle
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),

                  minX: 0,
                  maxX: (orderedCycles.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY,

                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: const Color(0xFF2563EB),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}