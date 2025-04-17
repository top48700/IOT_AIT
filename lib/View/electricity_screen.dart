import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ElectricityScreen extends StatefulWidget {
  final String accessToken; // Add this line

  const ElectricityScreen({Key? key, required this.accessToken})
      : super(key: key);

  @override
  _ElectricityScreenState createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  late Timer _timer;
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    _fetchData();

    // Refresh data every 5 minutes
    _timer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
  try {
    List<int> offsets = [2, 3, 4, 5, 6];

    // ทำให้ Request ทำงานพร้อมกันโดยใช้ Future.wait
    List<Future<http.Response>> requests = offsets.map((monthOffset) {
      return http.get(
        Uri.parse(
            '${dotenv.env['BASE_URL']}/api/getPreviousMonth?offset=$monthOffset'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));
    }).toList();

    // รอให้ทุก Request เสร็จ
    List<http.Response> responses = await Future.wait(requests);

    List<Map<String, dynamic>> fetchedData = [];
    for (var response in responses) {
      if (response.statusCode == 200) {
        fetchedData.add(json.decode(response.body));
      } else {
        debugPrint('Failed to fetch data for one request');
      }
    }

    if (mounted) {
      setState(() {
        _data = fetchedData;
      });
    }
  } on TimeoutException catch (_) {
    debugPrint('Request timeout! Try again later.');
  } catch (e) {
    debugPrint('Error fetching data: $e');
  }
}


  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
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
          title: const Text('Electricity'),
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
        padding: const EdgeInsets.all(16.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 248, 187, 187)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView.builder(
          itemCount: _data.isEmpty ? 5 : _data.length,
          itemBuilder: (context, index) {
            final monthData = _data.isNotEmpty ? _data[index] : null;
            return Column(
              children: [
                FloorCard(
                  previousMonth: index + 1,
                  data: monthData,
                ),
                const SizedBox(height: 12.0),
              ],
            );
          },
        ),
      ),
    );
  }
}

class FloorCard extends StatelessWidget {
  final int previousMonth;
  final Map<String, dynamic>? data;

  const FloorCard({Key? key, required this.previousMonth, this.data})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Electricity cost calculation
    double energyDifference = (data?['energyDifference'] as num?)?.toDouble() ?? 0.0;
    double costPerUnit = 4.72;
    double toKiloWatt = 1000;
    double electricityUsed = energyDifference / toKiloWatt;
    double electricityCost = electricityUsed * costPerUnit;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6.0),
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color.fromARGB(255, 225, 155, 94)],
              begin: Alignment.bottomLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '$previousMonth Month ago',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            InfoBox(
              label: 'Total Electricity Cost',
              value: electricityCost.toStringAsFixed(2),
              unit: 'THB',
            ),
            const SizedBox(width: 8.0),
            InfoBox(
              label: 'Accumulated Energy',
              value: electricityUsed.toStringAsFixed(2),
              unit: 'kWatt',
            ),
          ],
        ),
      ],
    );
  }
}

class InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const InfoBox(
      {Key? key, required this.label, required this.value, required this.unit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4.0,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              '$value $unit',
              style: const TextStyle(
                fontSize: 16.0,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
