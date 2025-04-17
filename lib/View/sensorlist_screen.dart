import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'SensorDetailScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SensorListScreen extends StatefulWidget {
  final String accessToken;

  const SensorListScreen({Key? key, required this.accessToken})
      : super(key: key);

  @override
  _SensorListScreenState createState() => _SensorListScreenState();
}

class _SensorListScreenState extends State<SensorListScreen> {
  Future<List<Map<String, dynamic>>>? _sensorFuture;
  String filter = "Online";

  @override
  void initState() {
    super.initState();
    _sensorFuture = fetchSensorStatus();
  }

  Future<List<Map<String, dynamic>>> fetchSensorStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/api/GetsensorTIME'),
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        List<Map<String, dynamic>> sensorList =
            List<Map<String, dynamic>>.from(json.decode(response.body));

        sensorList.sort((a, b) {
          int idA = int.tryParse(a['id'].toString()) ?? 0;
          int idB = int.tryParse(b['id'].toString()) ?? 0;
          return idA.compareTo(idB);
        });

        if (mounted) {
        setState(() {});
      }

        return sensorList;
      } else {
        throw Exception("Failed to load sensor status");
      }
    } catch (e) {
      return [];
    }
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
          title: const Text('Sensor Device Lists'),
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _sensorFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(child: Text("No sensor data available"));
            }

            List<Map<String, dynamic>> sensors = snapshot.data!;
            final filteredSensors =
                sensors.where((sensor) => sensor['status'] == filter).toList();

            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Row(
                    children: ["Online", "Warning", "Offline"].map((status) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if(mounted){
                              setState(() {
                              filter = status;
                              _sensorFuture =
                                  fetchSensorStatus(); // Refresh data when changing filter
                            });
                            }
                            
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: status == "Online"
                                  ? Colors.green
                                  : status == "Warning"
                                      ? Colors.orange
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                sensors.any((s) => s['status'] == status)
                                    ? "$status (${sensors.where((s) => s['status'] == status).length})"
                                    : "No Data $status",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: filteredSensors.isEmpty
                      ? Center(
                          child: Text(
                            "No Data $filter",
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredSensors.length,
                          itemBuilder: (context, index) {
                            final sensor = filteredSensors[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                title: Text(
                                  "Sensor Name: ${sensor['sensorName'] ?? 'Unknown'}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Sensor ID: ${sensor['id']}"),
                                    Text(
                                        "Branch ID: ${sensor['branchId'] ?? 'N/A'}"),
                                    Text(
                                        "Tenant ID: ${sensor['tenantId'] ?? 'N/A'}"),
                                    Text(
                                        "Gateway ID: ${sensor['gatewayId'] ?? 'N/A'}"),
                                    Text(
                                        "Created At: ${sensor['createdAt'] ?? 'N/A'}"),
                                    Text(
                                        "Created By: ${sensor['createdBy'] ?? 'N/A'}"),
                                    Text(
                                        "Location: ${sensor['location'] ?? 'Unknown'}"),
                                    Text(
                                        "Last Update: ${sensor['lastUpdate'] ?? 'N/A'}"),
                                  ],
                                ),
                                trailing: Text(
                                  sensor['status'],
                                  style: TextStyle(
                                    color: sensor['status'] == "Online"
                                        ? Colors.green
                                        : sensor['status'] == "Warning"
                                            ? Colors.orange
                                            : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SensorDetailScreen(
                                          sensorId: int.tryParse(
                                                  sensor['id'].toString()) ??
                                              0),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
