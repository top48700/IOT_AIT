import 'package:ait_iot_app/View/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import 'package:intl/intl.dart';

class TableScreen extends StatefulWidget {
  final String accessToken;

  const TableScreen({Key? key, required this.accessToken}) : super(key: key);

  @override
  State<TableScreen> createState() => _TableScreenState();
}

class _TableScreenState extends State<TableScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      dataProvider.fetchDefaultData();
      dataProvider.fetchSensorOptions();
    });
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final dataProvider = Provider.of<DataProvider>(context, listen: false);
      if (!dataProvider.isFetchingMore) {
        dataProvider.fetchMoreData();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _showDateValidationAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 10),
              Text(
                'Invalid Date Range',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Text(
            'The end date cannot be earlier than the start date. Please select a valid date range.',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 10,
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      if (!isStartDate && dataProvider.startDate != null) {
        final startDateTime = dataProvider.startDate!;

        if (picked.isBefore(startDateTime)) {
          if (mounted) {
            _showDateValidationAlert(context);
          }

          return;
        }
      }

      if (isStartDate && dataProvider.endDate != null) {
        final endDateTime = dataProvider.endDate!;

        if (picked.isAfter(endDateTime)) {
          if(mounted){
            _showDateValidationAlert(context);
          }
          return;
        }
      }

      // Update the filter with valid date
      if (isStartDate) {
        dataProvider.updateFilters(newStartDate: picked);
      } else {
        dataProvider.updateFilters(newEndDate: picked);
      }
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final dataProvider = Provider.of<DataProvider>(context, listen: false);
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      final startDate = dataProvider.startDate;
      final endDate = dataProvider.endDate;

      if (startDate != null &&
          endDate != null &&
          startDate.year == endDate.year &&
          startDate.month == endDate.month &&
          startDate.day == endDate.day) {
        if (isStartTime && dataProvider.endTime != null) {
          if (picked.hour > dataProvider.endTime!.hour ||
              (picked.hour == dataProvider.endTime!.hour &&
                  picked.minute > dataProvider.endTime!.minute)) {
                    if(mounted){
                      _showTimeValidationAlert(context);
                    }
            return;
          }
        }

        if (!isStartTime && dataProvider.startTime != null) {
          if (picked.hour < dataProvider.startTime!.hour ||
              (picked.hour == dataProvider.startTime!.hour &&
                  picked.minute < dataProvider.startTime!.minute)) {
                    if(mounted){
                      _showTimeValidationAlert(context);
                    }
            return;
          }
        }
      }

      if (isStartTime) {
        dataProvider.updateFilters(start: picked);
      } else {
        dataProvider.updateFilters(end: picked);
      }
    }
  }

  // SweetAlert for time validation
  void _showTimeValidationAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.access_time,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 10),
              Text(
                'Invalid Time Range',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: const Text(
            'The end time cannot be earlier than the start time. Please select a valid time range.',
            textAlign: TextAlign.center,
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                ),
                child: const Text('OK'),
              ),
            ),
          ],
          backgroundColor: Colors.white,
          elevation: 10,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataProvider = Provider.of<DataProvider>(context);

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
        title: const Text('Information'),
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
            colors: [Colors.white, Color.fromARGB(255, 248, 187, 187)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Color.fromARGB(255, 255, 155, 155)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.4, 0.8],
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(
                      color: const Color.fromARGB(255, 248, 187, 187)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Picker
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () =>
                                _selectDate(context, true), // Select Start Date
                            child: _buildFilterField(
                              label: "Start Date",
                              value: dataProvider.startDate != null
                                  ? DateFormat('MM/dd/yyyy')
                                      .format(dataProvider.startDate!)
                                  : "mm/dd/yyyy",
                              fieldWidth: double.infinity,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () =>
                                _selectDate(context, false), // Select End Date
                            child: _buildFilterField(
                              label: "End Date",
                              value: dataProvider.endDate != null
                                  ? DateFormat('MM/dd/yyyy')
                                      .format(dataProvider.endDate!)
                                  : "mm/dd/yyyy",
                              fieldWidth: double.infinity,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Start Time Field
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => _selectTime(context, true),
                            child: _buildTimeField(
                              label: "Start Time",
                              value: dataProvider.startTime != null
                                  ? dataProvider.startTime!.format(context)
                                  : "00:00",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // End Time Field
                        Expanded(
                          flex: 1,
                          child: GestureDetector(
                            onTap: () => _selectTime(context, false),
                            child: _buildTimeField(
                              label: "End Time",
                              value: dataProvider.endTime != null
                                  ? dataProvider.endTime!.format(context)
                                  : "00:00",
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Sensors",
                                style: TextStyle(
                                    fontSize: 14, color: Colors.purple),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: const Color.fromARGB(
                                          255, 248, 187, 187)),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: dataProvider.isSensorLoading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : DropdownButton<String>(
                                        value: dataProvider.selectedSensor,
                                        isExpanded: true,
                                        underline: const SizedBox(),
                                        items: dataProvider.sensorOptions
                                            .map((String sensors) {
                                          return DropdownMenuItem<String>(
                                            value: sensors,
                                            child: Text(sensors),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            dataProvider.updateFilters(
                                                sensors: newValue);
                                          }
                                        },
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Data List Section
            Expanded(
              child: dataProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : dataProvider.errorMessage.isNotEmpty
                      ? Center(child: Text(dataProvider.errorMessage))
                      : dataProvider.filteredDataList.isEmpty
                          ? const Center(child: Text('No data available.'))
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: dataProvider.filteredDataList.length +
                                  (dataProvider.hasMoreData ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index ==
                                    dataProvider.filteredDataList.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final data =
                                    dataProvider.filteredDataList[index];
                                final formattedTime = data.measuredAt != null
                                    ? DateFormat('yyyy-MM-dd HH:mm').format(
                                        DateTime.parse(data.measuredAt!))
                                    : 'N/A';

                                return Card(
                                  elevation: 4.0,
                                  child: ListTile(
                                    title: Text(
                                        'Sensor ID: ${data.sensorId ?? "N/A"}'),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            'Accumulated Energy: ${data.accumulatedEnergyValue?.toStringAsFixed(2) ?? "N/A"}'),
                                        Text(
                                            'Power Consumption: ${data.powerConsumptionValue?.toStringAsFixed(2) ?? "N/A"}'),
                                        Text(
                                            'Power Factor: ${data.powerFactorValue?.toStringAsFixed(2) ?? "N/A"}'),
                                      ],
                                    ),
                                    trailing: Text('Time: $formattedTime'),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              DetailScreen(sensorData: data),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: dataProvider.fetchDefaultData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildTimeField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.purple)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 248, 187, 187)),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildFilterField({
    required String label,
    required String value,
    double? fieldWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.purple)),
        const SizedBox(height: 4),
        Container(
          width: fieldWidth ?? double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 248, 187, 187)),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }
}
