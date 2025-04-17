import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'table_screen.dart';
import 'electricity_screen.dart';
import 'sensorlist_screen.dart';
import 'login_screen.dart';
import 'graph_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DashboardPage extends StatefulWidget {
  final String accessToken;

  const DashboardPage({Key? key, required this.accessToken}) : super(key: key);

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String username = "";
  double totalElectricityCost = 0.0;
  double totalEnergyUsed = 0.0;
  double toKiloWatt = 1000;
  double costPerUnit = 4.72;
  double totalEnergyKWatt = 0.0;
  DateTimeRange? selectedRange;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _fetchElectricityData();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('username') ?? 'Guest';
    });
  }

  Future<void> _fetchElectricityData(
      {DateTime? startDate, DateTime? endDate}) async {
    final prefs = await SharedPreferences.getInstance();
    String? accessToken = prefs.getString('access_token');

    if (accessToken == null) {
      print("No access token found. Please log in again.");
      return;
    }

    String  apiUrl = '${dotenv.env['BASE_URL']}/api/getLatestMonthlyData';

    if (startDate != null && endDate != null) {
      apiUrl +=
          '?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}';
    }

    final url = Uri.parse(apiUrl);
    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $accessToken'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        double energyUsed =
            (data['energyDifference'] as num?)?.toDouble().abs() ?? 0.0;

        setState(() {
          totalEnergyUsed = energyUsed;
          totalEnergyKWatt = totalEnergyUsed / toKiloWatt;
          totalElectricityCost = totalEnergyKWatt * costPerUnit;
        });
      } else {
        print('Failed to fetch electricity data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching electricity data: $e');
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    if(!mounted) return;
    
    DateTime? pickedStart = await showDatePicker(
      context: context,
      initialDate: selectedRange?.start ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedStart != null && mounted) {
      DateTime? pickedEnd = await showDatePicker(
        context: context,
        initialDate: pickedStart.add(const Duration(days: 1)),
        firstDate: pickedStart,
        lastDate: DateTime(2100),
      );

      if (pickedEnd != null) {
        setState(() {
          selectedRange = DateTimeRange(start: pickedStart, end: pickedEnd);
        });
        _fetchElectricityData(startDate: pickedStart, endDate: pickedEnd);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
          automaticallyImplyLeading: false,
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
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Padding(
            padding: EdgeInsets.only(top: 35.0),
            child: Text(
              'Dashboard',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: IconButton(
                icon: const Icon(Icons.logout, size: 30.0, color: Colors.black),
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('username');
                  await prefs.remove('access_token');
                  await prefs.remove('refresh_token');

                  if(mounted){
                    Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                  }
                },
              ),
            ),
          ],
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32.5,
                    backgroundColor: Colors.grey[300],
                    child:
                        const Icon(Icons.person, size: 39, color: Colors.black),
                  ),
                  const SizedBox(width: 15.6),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 18.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        username,
                        style: const TextStyle(fontSize: 18.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Grid of Buttons
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildRectangularButton(
                    imagePath: 'assets/images/001a.png',
                    label: 'Graph',
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      String? accessToken = prefs.getString('access_token');

                      if (accessToken == null) {
                        print("Access token not found. Redirecting to login.");

                        if(mounted){
                          Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
                          (route) => false,
                        );
                        }
                        return;
                      }

                      if(mounted){
                        Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              GraphScreen(accessToken: accessToken),
                        ),
                      );
                      }
                      
                    },
                  ),
                  _buildRectangularButton(
                    imagePath: 'assets/images/002a.png',
                    label: 'Information',
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      String? accessToken = prefs.getString('access_token');

                      if (accessToken == null) {
                        print("Access token not found. Redirecting to login.");
                        if(mounted){
                          Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                        }
                        return;
                      }

                      if(mounted){
                          Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TableScreen(accessToken: accessToken),
                        ),
                      );
                        }
                      
                    },
                  ),
                  _buildRectangularButton(
                    imagePath: 'assets/images/003a.png',
                    label: 'Sensor Device List',
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      String? accessToken = prefs.getString('access_token');

                      if (accessToken == null) {
                        print("Access token not found. Redirecting to login.");

                        if(mounted){
                          Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                        }
                        return;
                      }
                      if(mounted){
                          Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SensorListScreen(accessToken: accessToken),
                        ),
                      );
                        }
                      
                    },
                  ),
                  _buildRectangularButton(
                    imagePath: 'assets/images/004a.png',
                    label: 'Electricity',
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      String? accessToken = prefs.getString('access_token');

                      if (accessToken == null) {
                        print("Access token not found. Redirecting to login.");
                        if(mounted){
                          Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                        }
                        return;
                      }

                      if(mounted){
                          Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ElectricityScreen(accessToken: accessToken),
                        ),
                      );
                        }
                      
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Summary Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDateRange(context),
                    child: _buildSummaryCard(
                      label: 'Total Electricity Cost',
                      value: totalElectricityCost.toStringAsFixed(2),
                      unit: 'THB',
                      scaleFactor: 1.3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _selectDateRange(context),
                    child: _buildSummaryCard(
                      label: 'Accumulated Energy',
                      value: totalEnergyKWatt.toStringAsFixed(2),
                      unit: 'kW',
                      scaleFactor: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Rectangular Button Widget
  Widget _buildRectangularButton({
    required String imagePath,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color.fromARGB(255, 255, 155, 155)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 64, height: 64),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Summary Card Widget
  Widget _buildSummaryCard({
    required String label,
    required String value,
    required String unit,
    double scaleFactor = 1.0,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12 * scaleFactor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12 * scaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12 * scaleFactor,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
