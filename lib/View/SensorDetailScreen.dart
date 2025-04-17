import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SensorDetailScreen extends StatefulWidget {
  final int sensorId;

  const SensorDetailScreen({Key? key, required this.sensorId})
      : super(key: key);

  @override
  _SensorDetailScreenState createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  Map<String, dynamic>? sensorData;
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchSensorDetails();
  }

  Future<void> fetchSensorDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString("access_token");

      if (token == null || token.isEmpty) {
        print("No token found, redirecting to login...");
        setState(() {
          hasError = true;
          isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('${dotenv.env['BASE_URL']}/api/GetsensorTIME'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print("Response status: \${response.statusCode}");
      print("Response body: \${response.body}");
      print(jsonEncode(response.body));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        final sensor = data.firstWhere(
          (s) => s["id"].toString() == widget.sensorId.toString(),
          orElse: () => null,
        );

        if (sensor != null) {
          setState(() {
            sensorData = sensor;
            hasError = false;
            isLoading = false;
          });
        } else {
          print("Sensor ID \${widget.sensorId} not found!");
          setState(() {
            hasError = true;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching sensor details: $e");
      setState(() {
        hasError = true;
        isLoading = false;
      });
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
          title: const Text('Sensor Detail'),
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : hasError || sensorData == null
                ? const Center(child: Text("Failed to load sensor details"))
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow("Sensor Name", sensorData!["sensorName"]),
                            _infoRow("Status", sensorData!["status"]),
                            _infoRow("Last Update", sensorData!["lastUpdate"]),
                            _infoRow(
                                "Branch", sensorData!["branchId"].toString()),
                            _infoRow(
                                "Gateway", sensorData!["gatewayId"].toString()),
                            _infoRow("Location", sensorData!["location"]),
                            _infoRow("Created At", sensorData!["createdAt"]),
                            _infoRow("Branch Name",
                                sensorData!["branchName"] ?? "N/A"),
                            _infoRow("Branch Created By",
                                sensorData!["branchCreatedBy"] ?? "N/A"),
                            _infoRow("Gateway Name",
                                sensorData!["gatewayName"] ?? "N/A"),
                            _infoRow(
                                "Gateway Created By", sensorData!["createdBy"]),
                            _infoRow(
                                "Sensor Type", sensorData!["type"] ?? "N/A"),
                            _infoRow("Min Value",
                                sensorData!["minValue"].toString()),
                            _infoRow("Max Value",
                                sensorData!["maxValue"].toString()),
                            _infoRow(
                                "Time Zone", sensorData!["timeZone"] ?? "N/A"),
                            _infoRow("Updated By",
                                sensorData!["updatedBy"] ?? "N/A"),
                            _infoRow("Disabled Status",
                                sensorData!["disabled"].toString()),
                            // _infoRow("Device State",
                            //     sensorData!["deviceState"]?["state"] ?? "N/A"),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black54),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
