import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  final dynamic sensorData;

  const DetailScreen({Key? key, required this.sensorData}) : super(key: key);

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54, fontSize: 16),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color.fromARGB(255, 255, 155, 155)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16.0),
              ),
            ),
          ),
          title: const Text('Detail Screen'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 255, 155, 155)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                      'Sensor ID:', sensorData.sensorId?.toString() ?? "N/A"),
                  const Divider(),
                  _infoRow(
                      'Time:',
                      sensorData.time?.toString() ??
                          sensorData.measuredAt?.toString() ??
                          "N/A"),
                  _infoRow(
                      'Accumulated Energy:',
                      sensorData.accumulatedEnergyValue != null
                          ? sensorData.accumulatedEnergyValue.toStringAsFixed(2)
                          : "N/A"),
                  _infoRow(
                      'Power Consumption:',
                      sensorData.powerConsumptionValue != null
                          ? sensorData.powerConsumptionValue.toStringAsFixed(2)
                          : "0.00"),
                  _infoRow(
                      'Power Factor:',
                      sensorData.powerFactorValue != null
                          ? sensorData.powerFactorValue.toStringAsFixed(2)
                          : "N/A"),
                  _infoRow('Measured At:',
                      sensorData.measuredAt?.toString() ?? "N/A"),
                  const Divider(),
                  _infoRow('Day:', sensorData.iox_day?.toString() ?? "N/A"),
                  _infoRow('Month:', sensorData.iox_month?.toString() ?? "N/A"),
                  _infoRow('Week:', sensorData.iox_week?.toString() ?? "N/A"),
                  _infoRow(
                      'Weekday:', sensorData.iox_weekday?.toString() ?? "N/A"),
                  _infoRow('Year:', sensorData.iox_year?.toString() ?? "N/A"),
                  _infoRow('M Value:', sensorData.mvalue?.toString() ?? "N/A"),
                  _infoRow(
                      'Reactive Power:',
                      sensorData.reactivePowerValue != null
                          ? sensorData.reactivePowerValue.toStringAsFixed(2)
                          : "N/A"),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("🔙 Back"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
