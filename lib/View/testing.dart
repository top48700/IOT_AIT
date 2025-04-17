import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<ChartSampleData> _chartData = [];
  late TrackballBehavior _trackballBehavior;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _trackballBehavior = TrackballBehavior(
      enable: true,
      activationMode: ActivationMode.singleTap,
      tooltipSettings: InteractiveTooltip(
          format: 'Date: point.x \n'
              'Open: point.open \n'
              'High: point.high \n'
              'Low: point.low \n'
              'Close: point.close \n'),
    );

    fetchChartData();
  }

  Future<void> fetchChartData() async {
    try {
      final response = await http
          .get(Uri.parse('http://192.168.4.5:3000/api/Graph/CandleStick'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<ChartSampleData> chartData = [];

        for (var item in data['data']) {
          DateTime date = DateTime.parse(item['date']);

          double? open = double.tryParse(item['open'].toString()) ?? 0.0;
          double? high = double.tryParse(item['high'].toString()) ?? 0.0;
          double? low = double.tryParse(item['low'].toString()) ?? 0.0;
          double? close = double.tryParse(item['close'].toString()) ?? 0.0;

          chartData.add(ChartSampleData(
            x: date,
            open: open,
            high: high,
            low: low,
            close: close,
          ));
        }

        setState(() {
          _chartData = chartData;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching chart data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _chartData.isEmpty
              ? Center(child: Text("No data available"))
              : SfCartesianChart(
                  title: ChartTitle(text: 'OHLC Chart'),
                  legend: Legend(isVisible: true),
                  trackballBehavior: _trackballBehavior,
                  series: <CandleSeries>[
                    CandleSeries<ChartSampleData, DateTime>(
                      dataSource: _chartData,
                      name: 'OHLC',
                      xValueMapper: (ChartSampleData sales, _) => sales.x,
                      lowValueMapper: (ChartSampleData sales, _) => sales.low,
                      highValueMapper: (ChartSampleData sales, _) => sales.high,
                      openValueMapper: (ChartSampleData sales, _) => sales.open,
                      closeValueMapper: (ChartSampleData sales, _) =>
                          sales.close,
                    )
                  ],
                  primaryXAxis: DateTimeAxis(
                    dateFormat: DateFormat('yyyy-MM-dd'),
                    majorGridLines: MajorGridLines(width: 0),
                  ),
                  primaryYAxis: NumericAxis(
                    minimum: _chartData.isNotEmpty
                        ? _chartData
                                .map((e) => e.low)
                                .reduce((a, b) => a < b ? a : b) -
                            100
                        : 0,
                    maximum: _chartData.isNotEmpty
                        ? _chartData
                                .map((e) => e.high)
                                .reduce((a, b) => a > b ? a : b) +
                            100
                        : 100,
                    interval: 500,
                  ),
                ),
    ));
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
