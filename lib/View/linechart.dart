import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class GraphScreen extends StatefulWidget {
  final String accessToken;

  const GraphScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  _GraphScreenState createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  Map<String, List<FlSpot>> _sensorData = {};
  Map<String, List<String>> _sensorTimes = {};
  String selectedMetric = 'powerConsumption';
  bool isLoading = false;
  final List<Color> sensorColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple
  ];

  @override
  void initState() {
    super.initState();
    _fetchDailyUsageData();
  }

  Future<void> _fetchDailyUsageData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://192.168.62.5:3000/api/Graph/linegraph/graph_line'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body)['data'];
        Map<String, List<FlSpot>> sensorSpots = {};
        Map<String, List<String>> sensorTimes = {};

        for (var entry in decodedData) {
          double hour = double.parse(entry['hour'].split('T')[1].split(':')[0]);
          double metricValue = (entry[selectedMetric] as num? ?? 0).toDouble();
          String sensorId = entry['sensorId'].toString();
          String time = entry['hour'].split('T')[1].substring(0, 5);

          sensorSpots.putIfAbsent(sensorId, () => []);
          sensorTimes.putIfAbsent(sensorId, () => []);

          sensorSpots[sensorId]!.add(FlSpot(hour, metricValue));
          sensorTimes[sensorId]!.add(time);
        }

        setState(() {
          _sensorData = sensorSpots;
          _sensorTimes = sensorTimes;
        });
      } else {
        debugPrint('Failed to fetch daily usage data');
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Daily Power Usage by Sensor")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("Select Metric:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: selectedMetric,
                    items: const [
                      DropdownMenuItem(
                          value: 'powerConsumption',
                          child: Text("Power Consumption")),
                      DropdownMenuItem(
                          value: 'powerFactor', child: Text("Power Factor")),
                      DropdownMenuItem(
                          value: 'reactivePower',
                          child: Text("Reactive Power")),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => selectedMetric = newValue);
                        _fetchDailyUsageData();
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        lineBarsData: _sensorData.entries.map((entry) {
                          int index =
                              _sensorData.keys.toList().indexOf(entry.key);
                          return LineChartBarData(
                            spots: entry.value,
                            isCurved: true,
                            color: sensorColors[index % sensorColors.length],
                            barWidth: 3,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(show: false),
                            dotData: const FlDotData(show: true),
                          );
                        }).toList(),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles:
                                SideTitles(showTitles: true, reservedSize: 50),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                return Text('${value.toInt()}:00',
                                    style: const TextStyle(fontSize: 12));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(
                            show: true, drawHorizontalLine: true),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            tooltipBgColor: Colors.black87,
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipMargin: 10,
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((spot) {
                                String sensorId =
                                    _sensorData.keys.elementAt(spot.barIndex);
                                int spotIndex = _sensorData[sensorId]
                                        ?.indexWhere((s) => s.x == spot.x) ??
                                    -1;
                                String time = (spotIndex >= 0 &&
                                        (_sensorTimes[sensorId]?.length ?? 0) >
                                            spotIndex)
                                    ? _sensorTimes[sensorId]![spotIndex]
                                    : "Unknown";

                                debugPrint(
                                    'Sensor ID: $sensorId, Spot Index: $spotIndex, Time: $time');

                                return LineTooltipItem(
                                  'Sensor: $sensorId\nValue: ${spot.y.toStringAsFixed(2)}\nTime: $time',
                                  TextStyle(
                                    color: sensorColors[_sensorData.keys
                                            .toList()
                                            .indexOf(sensorId) %
                                        sensorColors.length],
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                          handleBuiltInTouches: true,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
