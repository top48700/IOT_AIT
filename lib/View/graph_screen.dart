import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GraphScreen extends StatefulWidget {
  final String accessToken;
  const GraphScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  String selectedRange = 'day';
  List<Map<String, dynamic>> sensorData = [];
  List<Map<String, dynamic>> electricityData = [];
  List<ChartSampleData> candleStickData = [];
  bool isLoading = false;
  bool isCandleLoading = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final double costPerUnit = 4.72;
  final double toKiloWatt = 1000;
  late TrackballBehavior _trackballBehavior;

  Map<String, List<FlSpot>> _lineChartData = {};
  Map<String, List<String>> _sensorTimes = {};
  String selectedMetric = 'powerConsumption';
  bool isLineChartLoading = false;
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
    fetchAllData();

    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: const InteractiveTooltip(
          format: 'Date: point.x \n'
              'Open: point.open \n'
              'High: point.high \n'
              'Low: point.low \n'
              'Close: point.close \n'),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchAllData() async {
  setState(() {
    isLoading = true;
    isCandleLoading = true;
    isLineChartLoading = true;
  });

  try {
    await Future.wait([
      fetchPieData(),
      fetchBarData(),
      fetchCandleStickData(),
      fetchLineChartData(),
    ]);
  } catch (e) {
    debugPrint('Error fetching data: $e');
  } finally {
    if (mounted) {
      setState(() {
        isLoading = false;
        isCandleLoading = false;
        isLineChartLoading = false;
      });
    }
  }
}


  Future<void> fetchPieData() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse(
        '${dotenv.env['BASE_URL']}/api/Graph/PieGraph/PieGraph?range=$selectedRange');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if(mounted){
          setState(() {
          sensorData = data
              .map((sensor) => {
                    'sensor': sensor['sensor'],
                    'sensorName': sensor['sensorName'],
                    'value': (sensor['value'] / 1000).toDouble(),
                    'percentage': sensor['percentage'].toDouble(),
                    'color': _parseColor(sensor['color']),
                  })
              .toList();
        });
        }
        
      } else {
        print("Error: ${response.statusCode}");
      }
    } catch (error) {
      print("Error fetching pie data: $error");
    }
    if(mounted){
      setState(() {
      isLoading = false;
    });
    }
    
  }

  Future<void> fetchBarData() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['BASE_URL']}/api/Graph/Barchart/graph_Barchart?months=12'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        if (decodedData != null && decodedData['data'] is List) {
          List<Map<String, dynamic>> fetchedData =
              (decodedData['data'] as List).map((item) {
            double energyDifference = (item['energyDifference'] is num)
                ? (item['energyDifference'] as num).toDouble()
                : 0.0;
            double electricityUsed = energyDifference / toKiloWatt;
            double electricityCost = electricityUsed * costPerUnit;

            return {
              'month': item['targetMonth'],
              'electricityUsed': electricityUsed,
              'electricityCost': electricityCost,
            };
          }).toList();

          if(mounted){
            setState(() {
            electricityData = fetchedData.reversed.toList();
          });
          }
          
        }
      } else {
        debugPrint('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching bar data: $e');
    }
  }

  Future<void> fetchCandleStickData() async {
    setState(() {
      isCandleLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            '${dotenv.env['BASE_URL']}/api/Graph/CandleStick/CandleStick'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<ChartSampleData> chartData = [];

        for (var item in data['data']) {
          DateTime date = DateTime.parse(item['date']);

          double? open = double.tryParse(item['open'].toString()) ?? 0.0;
          double? high = double.tryParse(item['high'].toString()) ?? 0.0;
          double? low = double.tryParse(item['low'].toString()) ?? 0.0;
          double? close = double.tryParse(item['close'].toString()) ?? 0.0;

          // Round to integers
        open = open.roundToDouble();
        high = high.roundToDouble();
        low = low.roundToDouble();
        close = close.roundToDouble();

          chartData.add(ChartSampleData(
            x: date,
            open: open,
            high: high,
            low: low,
            close: close,
          ));
        }

        chartData.sort((a, b) => a.x.compareTo(b.x));

        if(mounted){
          setState(() {
          candleStickData = chartData;
          isCandleLoading = false;
        });
        }
        
      } else {
        throw Exception('Failed to load candlestick data');
      }
    } catch (e) {
      print('Error fetching candlestick data: $e');
      if(mounted){
        setState(() {
        isCandleLoading = false;
      });
      }
      
    }
  }

  Future<void> fetchLineChartData() async {
    setState(() => isLineChartLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/api/Graph/linegraph/graph_line'),
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

        if(mounted){
          setState(() {
          _lineChartData = sensorSpots;
          _sensorTimes = sensorTimes;
        });
        }
        
      } else {
        debugPrint('Failed to fetch daily usage data');
      }
    } catch (e) {
      debugPrint('Error fetching line chart data: $e');
    } finally {
      if(mounted){
        setState(() => isLineChartLoading = false);
      }
    }
  }

  /// Normalize values to sum to 100%
  List<Map<String, dynamic>> normalizeData(List<Map<String, dynamic>> data) {
    double total = data.fold(0, (sum, item) => sum + item['value']);
    if (total == 0) return data;

    return data
        .map((item) => {
              'sensor': item['sensor'],
              'value': (item['value'] / total) * 100,
              'color': item['color'],
            })
        .toList();
  }

  /// Converts HSL or HEX color formats to a Flutter Color object.
  Color _parseColor(String colorStr) {
    if (colorStr.startsWith("#")) {
      return _hexToColor(colorStr);
    } else if (colorStr.startsWith("hsl")) {
      return _hslToColor(colorStr);
    } else {
      return _generateRandomColor();
    }
  }

  /// Converts HEX to Color
  Color _hexToColor(String hex) {
    hex = hex.replaceAll("#", "");
    return Color(int.parse("0xFF$hex"));
  }

  Color _hslToColor(String hsl) {
    final match = RegExp(r'hsl\((\d+),\s*(\d+)%,\s*(\d+)%\)').firstMatch(hsl);

    if (match != null && match.groupCount == 3) {
      int h = int.tryParse(match.group(1) ?? '') ?? 0;
      int s = int.tryParse(match.group(2) ?? '') ?? 0;
      int l = int.tryParse(match.group(3) ?? '') ?? 0;

      return _hslToRgb(h, s, l);
    }

    return _generateRandomColor();
  }

  /// Converts HSL values to RGB and returns a Color object
  Color _hslToRgb(int h, int s, int l) {
    double sD = s / 100.0;
    double lD = l / 100.0;
    double c = (1 - (2 * lD - 1).abs()) * sD;
    double x = c * (1 - ((h / 60) % 2 - 1).abs());
    double m = lD - c / 2;
    double r = 0, g = 0, b = 0;

    if (h < 60) {
      r = c;
      g = x;
    } else if (h < 120) {
      r = x;
      g = c;
    } else if (h < 180) {
      g = c;
      b = x;
    } else if (h < 240) {
      g = x;
      b = c;
    } else if (h < 300) {
      r = x;
      b = c;
    } else {
      r = c;
      b = x;
    }

    return Color.fromARGB(255, ((r + m) * 255).round(), ((g + m) * 255).round(),
        ((b + m) * 255).round());
  }

  Color _generateRandomColor() {
    Random random = Random();
    return Color.fromARGB(
        255, random.nextInt(256), random.nextInt(256), random.nextInt(256));
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        title: const Text('Chart'),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 255, 155, 155)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(
              height: 8,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [0, 1, 2, 3].map((index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.pinkAccent
                        : Colors.grey.withOpacity(0.5),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            // Sliding chart area
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: [
                  _buildPieChartView(),
                  _buildBarChartView(),
                  _buildCandleStickView(),
                  _buildLineChartView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartView() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Summarize power consumption',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 10),

            // Time Selection Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeButton('DAY'),
                _buildTimeButton('MONTH'),
                _buildTimeButton('YEAR'),
              ],
            ),

            const SizedBox(height: 10),

            // Pie Chart Container
            Container(
              padding: const EdgeInsets.all(12.0),
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildPieChart(),
            ),

            const SizedBox(height: 10),

            // Sensor Details Container
            Container(
              padding: const EdgeInsets.all(12.0),
              margin:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Sensor Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),

                  // Scrollable Sensor Grid
                  SizedBox(
                    height: 250,
                    child: sensorData.isEmpty
                        ? const Center(child: Text('No sensor data available'))
                        : GridView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 3.5,
                            ),
                            itemCount: sensorData.length,
                            itemBuilder: (context, index) {
                              final data = sensorData[index];
                              return Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: data['color'],
                                      radius: 8,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        // Show raw values for sensor details
                                        '${data['sensorName']}: ${data['value'].toStringAsFixed(2)} kW',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartView() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Monthly power consumption and costing",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: electricityData.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: List.generate(electricityData.length, (index) {
                        final data = electricityData[index];
                        return BarChartGroupData(
                          x: index, // Use index instead of monthOffset
                          barRods: [
                            BarChartRodData(
                              toY: data['electricityUsed'],
                              color: Colors.blue,
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: _getMaxBarValue() * 1.1,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                            BarChartRodData(
                              toY: data['electricityCost'] /
                                  20, // Scale for better visualization
                              color: Colors.red,
                              width: 12,
                              borderRadius: BorderRadius.circular(4),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: _getMaxBarValue() * 1.1,
                                color: Colors.grey.withOpacity(0.2),
                              ),
                            ),
                          ],
                        );
                      }),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text(
                                '${value.toInt()}',
                                style: const TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final int index = value.toInt();
                              final String month =
                                  index < electricityData.length
                                      ? electricityData[index]['month'] ??
                                          'Month ${index + 1}'
                                      : 'Month ${index + 1}';
                              return RotatedBox(
                                quarterTurns: 1,
                                child: Text(
                                  month,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(
                          show: true, drawHorizontalLine: true),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.circle, color: Colors.blue, size: 12),
              SizedBox(width: 4),
              Text("Energy Used (kWh)", style: TextStyle(fontSize: 12)),
              SizedBox(width: 16),
              Icon(Icons.circle, color: Colors.red, size: 12),
              SizedBox(width: 4),
              Text("Cost (THB/20)", style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCandleStickView() {
  return Container(
    margin: const EdgeInsets.all(8.0),
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: 2,
          offset: const Offset(0, 5),
        ),
      ],
    ),
    child: Column(
      children: [
        const Text(
          "Power Consumption Trend Analysis",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: isCandleLoading
              ? const Center(child: CircularProgressIndicator())
              : candleStickData.isEmpty
                  ? const Center(child: Text("No candlestick data available"))
                  : SfCartesianChart(
                      title: ChartTitle(text: 'Energy Usage Patterns'),
                      legend: Legend(isVisible: true),
                      trackballBehavior: _trackballBehavior,
                      zoomPanBehavior: ZoomPanBehavior(
                        enablePanning: true,
                        enablePinching: true,
                        enableDoubleTapZooming: true,
                        zoomMode: ZoomMode.x, 
                      ),
                      series: <CandleSeries>[
                        CandleSeries<ChartSampleData, DateTime>(
                          dataSource: candleStickData,
                          name: 'Energy Usage',
                          xValueMapper: (ChartSampleData sales, _) => sales.x,
                          lowValueMapper: (ChartSampleData sales, _) => sales.low,
                          highValueMapper: (ChartSampleData sales, _) => sales.high,
                          openValueMapper: (ChartSampleData sales, _) => sales.open,
                          closeValueMapper: (ChartSampleData sales, _) => sales.close,
                          bullColor: Colors.green,
                          bearColor: Colors.red,
                          enableSolidCandles: true, 
                          animationDuration: 1000, 
                        )
                      ],
                      primaryXAxis: DateTimeAxis(
                        dateFormat: DateFormat('dd/MM'),
                        intervalType: DateTimeIntervalType.days,
                        interval: 2,
                        majorGridLines: const MajorGridLines(width: 0),
                        title: AxisTitle(text: 'Date'),
                        autoScrollingDelta: 10, 
                        autoScrollingDeltaType: DateTimeIntervalType.days,
                        edgeLabelPlacement: EdgeLabelPlacement.shift,
                      ),
                      primaryYAxis: NumericAxis(
                        minimum: candleStickData.isNotEmpty
                            ? candleStickData
                                    .map((e) => e.low)
                                    .reduce((a, b) => a < b ? a : b) * 0.9
                            : 0,
                        maximum: candleStickData.isNotEmpty
                            ? candleStickData
                                    .map((e) => e.high)
                                    .reduce((a, b) => a > b ? a : b) * 1.1
                            : 100,
                        interval: 500,
                        title: AxisTitle(text: 'Power (kWatt)'),
                        labelFormat: '{value}',
                        numberFormat: NumberFormat('#,##0'), // Format for integers only
                      ),
                    ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.swipe, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                "Swipe left/right to view more data",
                style: TextStyle(fontSize: 14, color: Colors.blue.shade800),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildLineChartView() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Daily Power Usage by Sensor",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Metric selection dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Select Metric:",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: selectedMetric,
                items: const [
                  DropdownMenuItem(
                    value: 'powerConsumption',
                    child: Text("Power Consumption"),
                  ),
                  DropdownMenuItem(
                    value: 'powerFactor',
                    child: Text("Power Factor"),
                  ),
                  DropdownMenuItem(
                    value: 'reactivePower',
                    child: Text("Reactive Power"),
                  ),
                ],
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => selectedMetric = newValue);
                    fetchLineChartData();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Line Chart
          Expanded(
            child: isLineChartLoading
                ? const Center(child: CircularProgressIndicator())
                : _lineChartData.isEmpty
                    ? const Center(child: Text("No data available"))
                    : LineChart(
                        LineChartData(
                          lineBarsData: _lineChartData.entries.map((entry) {
                            int index =
                                _lineChartData.keys.toList().indexOf(entry.key);
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
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 50,
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget:
                                    (double value, TitleMeta meta) {
                                  return Text('${value.toInt()}:00',
                                      style: const TextStyle(fontSize: 12));
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
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
                              getTooltipItems:
                                  (List<LineBarSpot> touchedSpots) {
                                return touchedSpots.map((spot) {
                                  String sensorId = _lineChartData.keys
                                      .elementAt(spot.barIndex);
                                  int spotIndex = _lineChartData[sensorId]
                                          ?.indexWhere((s) => s.x == spot.x) ??
                                      -1;
                                  String time = (spotIndex >= 0 &&
                                          (_sensorTimes[sensorId]?.length ??
                                                  0) >
                                              spotIndex)
                                      ? _sensorTimes[sensorId]![spotIndex]
                                      : "Unknown";

                                  return LineTooltipItem(
                                    'Sensor: $sensorId\nValue: ${spot.y.toStringAsFixed(2)}\nTime: $time',
                                    TextStyle(
                                      color: sensorColors[_lineChartData.keys
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
          // Legend
          if (_lineChartData.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _lineChartData.keys.map((sensorId) {
                  int colorIndex =
                      _lineChartData.keys.toList().indexOf(sensorId) %
                          sensorColors.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          color: sensorColors[colorIndex],
                        ),
                        const SizedBox(width: 4),
                        Text("Sensor $sensorId",
                            style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  double _getMaxBarValue() {
    if (electricityData.isEmpty) return 100;

    double maxUsed = 0;
    double maxCost = 0;

    for (var data in electricityData) {
      if (data['electricityUsed'] > maxUsed) {
        maxUsed = data['electricityUsed'];
      }
      if (data['electricityCost'] / 20 > maxCost) {
        maxCost = data['electricityCost'] / 20;
      }
    }

    return maxUsed > maxCost ? maxUsed : maxCost;
  }

  Widget _buildTimeButton(String range) {
    bool isSelected = selectedRange == range.toLowerCase();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedRange = range.toLowerCase();
            fetchPieData();
          });
        },
        style: ElevatedButton.styleFrom(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: isSelected ? Colors.orangeAccent : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          elevation: isSelected ? 5 : 2,
        ),
        child: Text(range),
      ),
    );
  }

  Widget _buildPieChart() {
    if (sensorData.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(child: Text('No data available')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 200, 
          child: PieChart(
            PieChartData(
              sections: sensorData.map((data) {
                // Use percentage for the pie chart
                return PieChartSectionData(
                  value: data['percentage'],
                  color: data['color'],
                  title: '${data['percentage'].toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                );
              }).toList(),
              sectionsSpace: 2,
              centerSpaceRadius: 60,
            ),
          ),
        ),
      ],
    );
  }
}

class ChartSampleData {
  ChartSampleData({
    required this.x,
    required this.open,
    required this.close,
    required this.low,
    required this.high,
  });

  final DateTime x;
  final double open;
  final double close;
  final double low;
  final double high;
}
