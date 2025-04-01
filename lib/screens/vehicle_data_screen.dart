// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'prediction_screen.dart';

class VehicleDataScreen extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic> sensorData;

  const VehicleDataScreen({
    super.key,
    required this.vehicleId,
    required this.sensorData,
  });

  @override
  State<VehicleDataScreen> createState() => _VehicleDataScreenState();
}

class _VehicleDataScreenState extends State<VehicleDataScreen> {
  Widget _buildSensorCard(String label, dynamic value, String unit) {
    return Container(
      padding: AppTheme.paddingAll,
      decoration: AppTheme.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.labelStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value.toString(), style: AppTheme.valueStyle),
              const SizedBox(width: AppTheme.spacingXS),
              Text(unit, style: AppTheme.unitStyle),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sensorReadings = [
      {
        'label': 'Engine RPM',
        'value': widget.sensorData['engine_rpm'],
        'unit': 'RPM',
      },
      {
        'label': 'Lub Oil Pressure',
        'value': widget.sensorData['lub_oil_pressure'],
        'unit': 'kPa',
      },
      {
        'label': 'Fuel Pressure',
        'value': widget.sensorData['fuel_pressure'],
        'unit': 'kPa',
      },
      {
        'label': 'Coolant Pressure',
        'value': widget.sensorData['coolant_pressure'],
        'unit': 'kPa',
      },
      {
        'label': 'Lub Oil Temperature',
        'value': widget.sensorData['lub_oil_temp'],
        'unit': '°C',
      },
      {
        'label': 'Coolant Temperature',
        'value': widget.sensorData['coolant_temp'],
        'unit': '°C',
      },
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Sensor Readings', style: AppTheme.titleStyle),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: AppTheme.paddingAll,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: AppTheme.paddingAll,
              decoration: AppTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Vehicle Information', style: AppTheme.titleStyle),
                  const SizedBox(height: AppTheme.spacingM),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: AppTheme.spacingM),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Vehicle ID', style: AppTheme.labelStyle),
                          Text(
                            widget.vehicleId,
                            style: AppTheme.bodyStyle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            const Text('Sensor Readings', style: AppTheme.titleStyle),
            const SizedBox(height: AppTheme.spacingM),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: AppTheme.spacingM,
              crossAxisSpacing: AppTheme.spacingM,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              children:
                  sensorReadings
                      .map(
                        (reading) => _buildSensorCard(
                          reading['label'] as String,
                          reading['value'],
                          reading['unit'] as String,
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: AppTheme.spacingL),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => PredictionScreen(
                          vehicleId: widget.vehicleId,
                          sensorData: widget.sensorData,
                        ),
                  ),
                );
              },
              style: AppTheme.primaryButtonStyle,
              icon: const Icon(Icons.analytics),
              label: const Text(
                'ANALYZE DATA',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
