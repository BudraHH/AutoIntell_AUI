// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/historical_record.dart';
import '../theme/app_theme.dart';

class VisualizationScreen extends StatefulWidget {
  final List<HistoricalRecord> records;
  final String vehicleId;

  const VisualizationScreen({
    super.key,
    required this.records,
    required this.vehicleId,
  });

  @override
  State<VisualizationScreen> createState() => _VisualizationScreenState();
}

class _VisualizationScreenState extends State<VisualizationScreen> {
  int _selectedChartIndex = 0;
  final List<String> _chartTitles = [
    'Engine RPM Trend',
    'Temperature Analysis',
    'Pressure Analysis',
    'Health Distribution',
  ];

  Widget _buildChartTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Text(
        title,
        style: AppTheme.titleStyle.copyWith(fontSize: 18),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEngineRpmChart() {
    final spots =
        widget.records.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value.engineRpm);
        }).toList();

    // Calculate min and max RPM for better scale
    final maxRpm = widget.records.map((r) => r.engineRpm).reduce(max);
    final minRpm = widget.records.map((r) => r.engineRpm).reduce(min);
    final rpmInterval = ((maxRpm - minRpm) / 5).roundToDouble();

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: rpmInterval,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: AppTheme.cardColor, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                'RPM',
                style: AppTheme.labelStyle.copyWith(
                  color: AppTheme.textColorSecondary,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                interval: rpmInterval,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.textColorSecondary,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 5 != 0) return const SizedBox.shrink();
                  return Text(
                    'Record ${value.toInt() + 1}',
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.textColorSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
          ],
          minY: minRpm - (rpmInterval / 2),
          maxY: maxRpm + (rpmInterval / 2),
        ),
      ),
    );
  }

  Widget _buildTemperatureChart() {
    // Calculate min and max temperatures for better scale
    final maxTemp = max(
      widget.records.map((r) => r.lubOilTemp).reduce(max),
      widget.records.map((r) => r.coolantTemp).reduce(max),
    );
    final minTemp = min(
      widget.records.map((r) => r.lubOilTemp).reduce(min),
      widget.records.map((r) => r.coolantTemp).reduce(min),
    );
    final tempInterval = ((maxTemp - minTemp) / 4).roundToDouble();

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: tempInterval,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: AppTheme.cardColor, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                'Temperature (°C)',
                style: AppTheme.labelStyle.copyWith(
                  color: AppTheme.textColorSecondary,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                interval: tempInterval,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()}°C',
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.textColorSecondary,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 5 != 0) return const SizedBox.shrink();
                  return Text(
                    'Record ${value.toInt() + 1}',
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.textColorSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots:
                  widget.records.asMap().entries.map((entry) {
                    return FlSpot(entry.key.toDouble(), entry.value.lubOilTemp);
                  }).toList(),
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
            ),
            LineChartBarData(
              spots:
                  widget.records.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value.coolantTemp,
                    );
                  }).toList(),
              isCurved: true,
              color: AppTheme.warningColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.warningColor.withOpacity(0.1),
              ),
            ),
          ],
          minY: minTemp - (tempInterval / 2),
          maxY: maxTemp + (tempInterval / 2),
        ),
      ),
    );
  }

  Widget _buildPressureChart() {
    // Calculate min and max pressures for better scale
    final allPressures =
        widget.records
            .expand(
              (r) => [r.lubOilPressure, r.fuelPressure, r.coolantPressure],
            )
            .toList();
    final maxPressure = allPressures.reduce(max);
    final minPressure = allPressures.reduce(min);
    final pressureInterval = ((maxPressure - minPressure) / 4).roundToDouble();

    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: pressureInterval,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: AppTheme.cardColor, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              axisNameWidget: Text(
                'Pressure (kPa)',
                style: AppTheme.labelStyle.copyWith(
                  color: AppTheme.textColorSecondary,
                ),
              ),
              sideTitles: SideTitles(
                showTitles: true,
                interval: pressureInterval,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${value.toInt()} kPa',
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.textColorSecondary,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 5 != 0) return const SizedBox.shrink();
                  return Text(
                    'Record ${value.toInt() + 1}',
                    style: AppTheme.labelStyle.copyWith(
                      color: AppTheme.textColorSecondary,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots:
                  widget.records.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value.lubOilPressure,
                    );
                  }).toList(),
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots:
                  widget.records.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value.fuelPressure,
                    );
                  }).toList(),
              isCurved: true,
              color: AppTheme.successColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
            LineChartBarData(
              spots:
                  widget.records.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      entry.value.coolantPressure,
                    );
                  }).toList(),
              isCurved: true,
              color: AppTheme.warningColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
            ),
          ],
          minY: minPressure - (pressureInterval / 2),
          maxY: maxPressure + (pressureInterval / 2),
        ),
      ),
    );
  }

  Widget _buildHealthDistributionChart() {
    final healthyCount = widget.records.where((r) => r.isHealthy).length;
    final faultyCount = widget.records.where((r) => r.isFaulty).length;
    final unknownCount = widget.records.where((r) => r.isUnknown).length;

    return AspectRatio(
      aspectRatio: 1.7,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            if (healthyCount > 0)
              PieChartSectionData(
                color: AppTheme.successColor,
                value: healthyCount.toDouble(),
                title:
                    '${((healthyCount / widget.records.length) * 100).toStringAsFixed(1)}%',
                radius: 100,
                titleStyle: AppTheme.labelStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (faultyCount > 0)
              PieChartSectionData(
                color: AppTheme.warningColor,
                value: faultyCount.toDouble(),
                title:
                    '${((faultyCount / widget.records.length) * 100).toStringAsFixed(1)}%',
                radius: 100,
                titleStyle: AppTheme.labelStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (unknownCount > 0)
              PieChartSectionData(
                color: AppTheme.textColorSecondary,
                value: unknownCount.toDouble(),
                title:
                    '${((unknownCount / widget.records.length) * 100).toStringAsFixed(1)}%',
                radius: 100,
                titleStyle: AppTheme.labelStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    final List<Widget> legendItems = [];

    if (_selectedChartIndex == 1) {
      // Temperature chart legend
      legendItems.addAll([
        _buildLegendItem('Lub Oil Temp', AppTheme.primaryColor),
        const SizedBox(width: AppTheme.spacingM),
        _buildLegendItem('Coolant Temp', AppTheme.warningColor),
      ]);
    } else if (_selectedChartIndex == 2) {
      // Pressure chart legend
      legendItems.addAll([
        _buildLegendItem('Lub Oil', AppTheme.primaryColor),
        const SizedBox(width: AppTheme.spacingM),
        _buildLegendItem('Fuel', AppTheme.successColor),
        const SizedBox(width: AppTheme.spacingM),
        _buildLegendItem('Coolant', AppTheme.warningColor),
      ]);
    } else if (_selectedChartIndex == 3) {
      // Health distribution legend
      final healthyCount = widget.records.where((r) => r.isHealthy).length;
      final faultyCount = widget.records.where((r) => r.isFaulty).length;
      final unknownCount = widget.records.where((r) => r.isUnknown).length;

      if (healthyCount > 0) {
        legendItems.add(_buildLegendItem('Healthy', AppTheme.successColor));
        legendItems.add(const SizedBox(width: AppTheme.spacingM));
      }
      if (faultyCount > 0) {
        legendItems.add(_buildLegendItem('Faulty', AppTheme.warningColor));
        legendItems.add(const SizedBox(width: AppTheme.spacingM));
      }
      if (unknownCount > 0) {
        legendItems.add(
          _buildLegendItem('Unknown', AppTheme.textColorSecondary),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: legendItems,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTheme.labelStyle.copyWith(
            color: AppTheme.textColorSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Data Visualization', style: AppTheme.titleStyle),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: AppTheme.spacingM),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _chartTitles.length,
              itemBuilder: (context, index) {
                final isSelected = _selectedChartIndex == index;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_chartTitles[index]),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      if (selected) {
                        setState(() => _selectedChartIndex = index);
                      }
                    },
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.cardColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textColor,
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildChartTitle(_chartTitles[_selectedChartIndex]),
                  Container(
                    margin: const EdgeInsets.all(AppTheme.spacingM),
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      children: [
                        if (_selectedChartIndex == 0)
                          _buildEngineRpmChart()
                        else if (_selectedChartIndex == 1)
                          _buildTemperatureChart()
                        else if (_selectedChartIndex == 2)
                          _buildPressureChart()
                        else
                          _buildHealthDistributionChart(),
                        const SizedBox(height: AppTheme.spacingM),
                        _buildLegend(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
