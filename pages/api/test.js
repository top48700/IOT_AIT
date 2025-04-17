// import { queryData } from '../../connectDB/connectdb';
// import { validateToken } from '../../lib/middleware/authMiddleware';

// async function handler(req, res) {
//     if (req.method !== 'GET') {
//         return res.status(405).json({ message: 'Method Not Allowed' });
//     }

//     try {
//         // Get latest timestamp from the database
//         const latestTimestampQuery = `SELECT LAST(measuredAt) AS latestTime FROM PowerSensorValue`;
//         const latestTimeResult = await queryData(latestTimestampQuery);

//         if (!latestTimeResult?.length || !latestTimeResult[0].latestTime) {
//             return res.status(404).json({ error: 'No data found in the database' });
//         }

//         const latestTime = new Date(latestTimeResult[0].latestTime);
//         const year = latestTime.getUTCFullYear();
//         const month = latestTime.getUTCMonth();
        
//         const firstDayOfMonth = new Date(Date.UTC(year, month, 1, 0, 0, 0));
//         const lastDayOfMonth = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59));
        
//         const { startDate, endDate } = req.query;
//         const start = startDate ? new Date(startDate) : firstDayOfMonth;
//         const end = endDate ? new Date(endDate) : lastDayOfMonth;

//         console.log("Start Date (UTC):", start.toISOString());
//         console.log("End Date (UTC):", end.toISOString());

//         // Ensure start and end are valid dates
//         if (isNaN(start.getTime()) || isNaN(end.getTime())) {
//             return res.status(400).json({ error: 'Invalid date format' });
//         }

//         const firstDayQuery = `
//             SELECT FIRST(accumulatedEnergyValue) AS firstValue, sensorId
//             FROM PowerSensorValue
//             WHERE time >= '${start.toISOString()}' AND time < '${end.toISOString()}'
//             GROUP BY sensorId
//         `;
//         const firstDayResult = await queryData(firstDayQuery) || [];

//         const lastDayQuery = `
//             SELECT LAST(accumulatedEnergyValue) AS lastValue, sensorId
//             FROM PowerSensorValue
//             WHERE time >= '${start.toISOString()}' AND time <= '${end.toISOString()}'
//             GROUP BY sensorId
//         `;
//         const lastDayResult = await queryData(lastDayQuery) || [];

//         console.log("First Day Values:", firstDayResult);
//         console.log("Last Day Values:", lastDayResult);

//         const totalFirstDayValue = firstDayResult.reduce((sum, entry) => sum + (entry.firstValue || 0), 0);
//         const totalLastDayValue = lastDayResult.reduce((sum, entry) => sum + (entry.lastValue || 0), 0);

//         const energyDifference = totalLastDayValue - totalFirstDayValue;

//         res.status(200).json({
//             latestMonth: `${year}-${month + 1}`,
//             firstDayTimestamp: start.toISOString(),
//             lastDayTimestamp: end.toISOString(),
//             firstDayTotalValue: totalFirstDayValue,
//             lastDayTotalValue: totalLastDayValue,
//             energyDifference,
//             sensorFirstDayValues: firstDayResult.map(entry => ({
//                 sensorId: entry.sensorId,
//                 value: entry.firstValue || 0
//             })),
//             sensorLastDayValues: lastDayResult.map(entry => ({
//                 sensorId: entry.sensorId,
//                 value: entry.lastValue || 0
//             }))
//         });
//     } catch (error) {
//         console.error('Error fetching data:', error.message);
//         res.status(500).json({ error: 'Failed to fetch data' });
//     }
// }

// export default validateToken(handler);

import { queryData } from '../../connectDB/connectdb';
import { validateToken } from '../../lib/middleware/authMiddleware';

async function handler(req, res) {
    if (req.method === 'GET') {
        try {
            const latestTimestampQuery = `
                SELECT LAST(measuredAt) AS latestTime FROM PowerSensorValue`;
            const latestTimeResult = await queryData(latestTimestampQuery);

            if (!latestTimeResult || latestTimeResult.length === 0 || !latestTimeResult[0].latestTime) {
                return res.status(404).json({ error: 'No data found in the database' });
            }

            const latestTime = new Date(latestTimeResult[0].latestTime);
            const year = latestTime.getUTCFullYear();
            const month = latestTime.getUTCMonth();
            const firstDayOfMonth = new Date(Date.UTC(year, month, 1));
            const lastDayOfMonth = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59));
            const { startDate, endDate } = req.query;
            const start = startDate ? new Date(startDate) : firstDayOfMonth;
            const end = endDate ? new Date(endDate) : lastDayOfMonth;

            const totalEnergyQuery = `
                SELECT 
    (LAST(accumulatedEnergyValue) - FIRST(accumulatedEnergyValue)) AS dailyEnergy, 
    time
FROM PowerSensorValue
WHERE time >= '${start.toISOString()}' AND time <= '${end.toISOString()}'
GROUP BY time(1d)
            `;
            const energyResult = await queryData(totalEnergyQuery);
            
            console.log('Energy Result:', energyResult); // Debugging 

            const dailyEnergy = energyResult.map(entry => ({
                date: entry.time ? new Date(entry.time).toISOString().split('T')[0] : null, // Check if time exists
                totalEnergy: entry.dailyEnergy || 0 // Ensure totalEnergy has a default value
            }));

            res.status(200).json({
                latestMonth: `${year}-${month + 1}`,
                firstDayTimestamp: start.toISOString(),
                lastDayTimestamp: end.toISOString(),
                dailyEnergyConsumption: dailyEnergy
            });
        } catch (error) {
            console.error('Error fetching energy data:', error.message);
            res.status(500).json({ error: 'Failed to fetch energy data' });
        }
    } else {
        res.status(405).json({ message: 'Method Not Allowed' });
    }
}

export default validateToken(handler);



// 'http://192.168.4.5:3000/api/Graph/PieGraph?range=$selectedRange');

// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:math';

// class GraphScreen extends StatefulWidget {
//   final String accessToken;
//   const GraphScreen({Key? key, required this.accessToken}) : super(key: key);

//   @override
//   State<GraphScreen> createState() => _GraphScreenState();
// }

// class _GraphScreenState extends State<GraphScreen> {
//   String selectedRange = 'day';
//   List<Map<String, dynamic>> sensorData = [];
//   List<Map<String, dynamic>> electricityData = [];
//   bool isLoading = false;

//   final double costPerUnit = 4.72; // Cost per kWh
//   final double toKiloWatt = 1000; // Convert to kWh

//   @override
//   void initState() {
//     super.initState();
//     fetchPieChartData();
//     fetchBarChartData();
//   }

//   Future<void> fetchPieChartData() async {
//     setState(() => isLoading = true);

//     final url = Uri.parse('http://192.168.4.5:3000/api/Graph/PieGraph?range=$selectedRange');

//     try {
//       final response = await http.get(url);

//       if (response.statusCode == 200) {
//         final List<dynamic> data = jsonDecode(response.body);
//         setState(() {
//           sensorData = normalizeData(data
//               .map((sensor) => {
//                     'sensor': sensor['sensor'],
//                     'value': sensor['value'].toDouble(),
//                     'color': _parseColor(sensor['color']),
//                   })
//               .toList());
//         });
//       } else {
//         print("Error: ${response.statusCode}");
//       }
//     } catch (error) {
//       print("Error fetching Pie Chart data: $error");
//     }

//     setState(() => isLoading = false);
//   }

//   Future<void> fetchBarChartData() async {
//     try {
//       List<Map<String, dynamic>> fetchedData = [];

//       for (int monthOffset = 1; monthOffset <= 12; monthOffset++) {
//         final response = await http.get(
//           Uri.parse('http://192.168.42.47:3000/api/Graph/BarChart?offset=$monthOffset'),
//           headers: {
//             'Authorization': 'Bearer ${widget.accessToken}',
//             'Content-Type': 'application/json',
//           },
//         );

//         if (response.statusCode == 200) {
//           final decodedData = json.decode(response.body);
//           if (decodedData != null) {
//             double energyDifference = (decodedData['energyDifference'] as num).toDouble();
//             double electricityUsed = energyDifference / toKiloWatt;
//             double electricityCost = electricityUsed * costPerUnit;

//             fetchedData.add({
//               'monthOffset': monthOffset,
//               'electricityUsed': electricityUsed,
//               'electricityCost': electricityCost,
//             });
//           }
//         } else {
//           print('Failed to fetch data for month $monthOffset');
//         }
//       }

//       setState(() {
//         electricityData = fetchedData.reversed.toList();
//       });
//     } catch (e) {
//       print('Error fetching Bar Chart data: $e');
//     }
//   }

//   /// Normalize values to sum to 100%
//   List<Map<String, dynamic>> normalizeData(List<Map<String, dynamic>> data) {
//     double total = data.fold(0, (sum, item) => sum + item['value']);
//     if (total == 0) return data;

//     return data.map((item) => {
//           'sensor': item['sensor'],
//           'value': (item['value'] / total) * 100, // Normalize to 100%
//           'color': item['color'],
//         }).toList();
//   }

//   /// Converts HEX or HSL color to Flutter Color
//   Color _parseColor(String colorStr) {
//     if (colorStr.startsWith("#")) return _hexToColor(colorStr);
//     if (colorStr.startsWith("hsl")) return _hslToColor(colorStr);
//     return _generateRandomColor();
//   }

//   Color _hexToColor(String hex) {
//     hex = hex.replaceAll("#", "");
//     return Color(int.parse("0xFF$hex"));
//   }

//   Color _hslToColor(String hsl) {
//     final regex = RegExp(r'hsl\((\d+),\s*(\d+)%,\s*(\d+)%\)');
//     final match = regex.firstMatch(hsl);
//     if (match != null) {
//       int h = int.parse(match.group(1)!);
//       int s = int.parse(match.group(2)!);
//       int l = int.parse(match.group(3)!);
//       return _hslToRgb(h.toDouble(), s.toDouble(), l.toDouble());
//     }
//     return _generateRandomColor();
//   }

//   Color _hslToRgb(double h, double s, double l) {
//     s /= 100;
//     l /= 100;
//     double c = (1 - (2 * l - 1).abs()) * s;
//     double x = c * (1 - ((h / 60) % 2 - 1).abs());
//     double m = l - c / 2;
//     double r = 0, g = 0, b = 0;
//     if (h < 60) { r = c; g = x; } else if (h < 120) { r = x; g = c; }
//     else if (h < 180) { g = c; b = x; } else if (h < 240) { g = x; b = c; }
//     else if (h < 300) { r = x; b = c; } else { r = c; b = x; }
//     return Color.fromARGB(255, ((r + m) * 255).round(), ((g + m) * 255).round(), ((b + m) * 255).round());
//   }

//   Color _generateRandomColor() {
//     Random random = Random();
//     return Color.fromARGB(255, random.nextInt(256), random.nextInt(256), random.nextInt(256));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Electricity Usage & Costs')),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 // Time selection buttons
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     _buildTimeButton('DAY'),
//                     _buildTimeButton('MONTH'),
//                     _buildTimeButton('YEAR'),
//                   ],
//                 ),
//                 const SizedBox(height: 20),

//                 /// Scrollable Charts
//                 SingleChildScrollView(
//                   scrollDirection: Axis.horizontal,
//                   child: Row(
//                     children: [
//                       SizedBox(width: 300, child: _buildPieChart()),
//                       const SizedBox(width: 20),
//                       SizedBox(width: 300, child: _buildBarChart()),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }

//   Widget _buildPieChart() {
//     return PieChart(PieChartData(
//       sections: sensorData.map((data) {
//         return PieChartSectionData(
//           value: data['value'],
//           color: data['color'],
//           title: '${data['value'].toStringAsFixed(1)}%',
//         );
//       }).toList(),
//     ));
//   }

//   Widget _buildBarChart() {
//     return BarChart(BarChartData(
//       barGroups: electricityData.map((data) {
//         return BarChartGroupData(x: data['monthOffset'], barRods: [
//           BarChartRodData(toY: data['electricityUsed'], color: Colors.blue),
//         ]);
//       }).toList(),
//     ));
//   }

//   Widget _buildTimeButton(String range) {
//     return ElevatedButton(
//       onPressed: () {
//         setState(() {
//           selectedRange = range.toLowerCase();
//           fetchPieChartData();
//         });
//       },
//       child: Text(range),
//     );
//   }
// }
