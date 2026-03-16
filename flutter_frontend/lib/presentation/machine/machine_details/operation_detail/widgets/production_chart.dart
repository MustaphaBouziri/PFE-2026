import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProductionChart extends StatefulWidget {
  const ProductionChart({super.key});

  @override
  State<ProductionChart> createState() => _ProductionChartState();
}

class _ProductionChartState extends State<ProductionChart> {
  // just random value i copied from flutter docu
  // static data for now — each spot = (time index, quantity declared)
  final List<FlSpot> spots = const [
    FlSpot(0, 10),
    FlSpot(1, 25),
    FlSpot(2, 15),
    FlSpot(3, 40),
    FlSpot(4, 30),
    FlSpot(5, 50),
    FlSpot(6, 45),
  ];

  // static time labels matching x indexes
  final List<String> timeLabels = const [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
  ];

  @override
  Widget build(BuildContext context) {
    return  Container(
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
            // title
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
                    // tooltip when touching a point
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              'Declared ${spot.y.toInt()} units\nat ${timeLabels[spot.x.toInt()]}',
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
                      // x axis — time
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= timeLabels.length) {
                              return const SizedBox();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              child: Text(
                                timeLabels[index],
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // y axis — quantity
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
                    maxX: 6,
                    minY: 0,
                    maxY: 60,
      
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