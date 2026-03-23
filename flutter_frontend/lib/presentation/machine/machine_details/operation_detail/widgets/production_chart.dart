import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pfe_mes/data/machine/models/mes_production_cycle.dart';

class ProductionChart extends StatefulWidget {
  final List<ProductionCycleModel> cycles;
  final bool horizontalScrollable;
  final int perScreenDataPoints;

  const ProductionChart({
    super.key,
    required this.cycles,
    this.horizontalScrollable = false,
    this.perScreenDataPoints = 8,
  });

  @override
  State<ProductionChart> createState() => _ProductionChartState();
}

class _ProductionChartState extends State<ProductionChart> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToEnd() {
    if (!widget.horizontalScrollable || !_scrollController.hasClients) return;

    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
  }

  @override
  void didUpdateWidget(covariant ProductionChart oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.cycles.length != widget.cycles.length ||
        oldWidget.horizontalScrollable != widget.horizontalScrollable ||
        oldWidget.perScreenDataPoints != widget.perScreenDataPoints) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cycles.isEmpty) {
      return const SizedBox();
    }

    final orderedCycles = widget.cycles.reversed
        .where((c) => c.cycleQuantity > 0)
        .toList();

    if (orderedCycles.isEmpty) {
      return const SizedBox();
    }

    final spots = orderedCycles
        .asMap()
        .entries
        .map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.cycleQuantity);
    }).toList();

    final highestValue = orderedCycles
        .map((c) => c.cycleQuantity)
        .reduce((a, b) => a > b ? a : b);

    final interval = math.max(1, (highestValue / 10).floor()).toDouble();
    final rawMaxY = highestValue * 1.2;
    final maxY = (rawMaxY / interval).ceil() * interval;

    Widget chartContent = LayoutBuilder(
      builder: (context, constraints) {
        final safePerScreenDataPoints =
        widget.perScreenDataPoints <= 0 ? 1 : widget.perScreenDataPoints;

        final chartWidth = widget.horizontalScrollable
            ? math.max(
          constraints.maxWidth,
          (orderedCycles.length / safePerScreenDataPoints) *
              constraints.maxWidth,
        )
            : constraints.maxWidth;

        return SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: widget.horizontalScrollable
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(
                right: 20,
                top: 12,
              ),
              child: SizedBox(
                width: chartWidth,
                child: LineChart(
                  LineChartData(
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final index = spot.x.toInt();
                            if (index < 0 || index >= orderedCycles.length) {
                              return null;
                            }

                            final cycle = orderedCycles[index];
                            return LineTooltipItem(
                              '${cycle.fullName}\n'
                                  'Declared ${spot.y.toInt()} units\n'
                                  'Total: ${cycle.totalProducedQuantity
                                  .toInt()} units\n'
                                  '${cycle.fullLabel}',
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
                      horizontalInterval: interval,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
                      getDrawingVerticalLine: (_) =>
                      const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
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
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: interval,
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
            )
        );
        },
    );

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
                right: 20,
                left: 20,
                top: 20,
                bottom: 20,
              ),
              child: chartContent,
            ),
          ),
        ],
      ),
    );
  }
}