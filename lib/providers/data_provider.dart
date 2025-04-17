import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/sensor_data_model/data_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DataProvider with ChangeNotifier {
  final Uri baseUrl = Uri.parse('${dotenv.env['BASE_URL']}/api');

  List<DataModel> dataList = [];
  List<DataModel> filteredDataList = [];
  List<String> sensorOptions = ['All'];

  bool isLoading = false;
  bool isSensorLoading = false;
  bool isFetchingMore = false;
  String errorMessage = '';

  int page = 1;
  int limit = 20;
  bool hasMoreData = true;

  DateTime? startDate;
  DateTime? endDate;
  String? accessToken;
  TimeOfDay? startTime;
  TimeOfDay? endTime;
  String selectedSensor = "All";

  void resetFilters() {
    startDate = null;
    endDate = null;
    startTime = null;
    endTime = null;
    selectedSensor = "All";
    dataList = [];
    filteredDataList = [];
    errorMessage = '';
    page = 1;
    hasMoreData = true;
    notifyListeners();
  }

// Fetch default data from /api/db
  Future<void> fetchDefaultData() async {
    isLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/db'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        dataList = data.map((item) => DataModel.fromJson(item)).toList();
        filteredDataList = dataList;

        if (dataList.isNotEmpty) {
          dataList.sort((a, b) => DateTime.parse(b.measuredAt!)
              .compareTo(DateTime.parse(a.measuredAt!)));
          DateTime latestDate = DateTime.parse(dataList.first.measuredAt!);
          startDate = latestDate;
          endDate = latestDate;
        }
      } else {
        errorMessage = 'Failed to fetch default data: ${response.statusCode}';
      }
    } catch (error) {
      errorMessage = 'Error fetching default data: $error';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Fetch sensor options from /api/getsensorId
  Future<void> fetchSensorOptions() async {
    isSensorLoading = true;
    errorMessage = '';
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getsensorId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse.containsKey('sensors') &&
            jsonResponse['sensors'] is List) {
          final List<dynamic> dynamicSensors = jsonResponse['sensors'];

          // Prepend 'All' and convert sensors to string
          sensorOptions = [
            'All',
            ...dynamicSensors.map((sensor) => sensor.toString()).toList()
          ];
        } else {
          errorMessage =
              'Invalid response format: "sensors" key missing or invalid';
        }
      } else {
        errorMessage = 'Failed to fetch sensors: ${response.statusCode}';
      }
    } catch (e) {
      errorMessage = 'An error occurred: $e';
    } finally {
      isSensorLoading = false;
      notifyListeners();
    }
  }

  // Fetch data with filters from /api/searchbar
  Future<void> fetchFilteredData({bool isLoadMore = false}) async {
    if (isLoadMore && isFetchingMore) return;

    if (!isLoadMore) {
      isLoading = true;
      page = 1;
      hasMoreData = true;
    } else {
      isFetchingMore = true;
    }

    errorMessage = '';
    notifyListeners();

    try {
      final queryParams = {
        'limit': limit.toString(),
        'page': page.toString(),
        if (startDate != null)
          'startDate': DateFormat('yyyy-MM-dd').format(startDate!),
        if (endDate != null)
          'endDate': DateFormat('yyyy-MM-dd').format(endDate!),
        if (startTime != null)
          'startTime':
              '${DateFormat("yyyy-MM-dd\'T\'HH:mm:ss").format(DateTime(startDate!.year, startDate!.month, startDate!.day, startTime!.hour, startTime!.minute))}Z',
        if (endTime != null)
          'endTime':
              '${DateFormat("yyyy-MM-dd\'T\'HH:mm:ss").format(DateTime(endDate!.year, endDate!.month, endDate!.day, endTime!.hour, endTime!.minute, 59))}Z',
        if (selectedSensor != "All") 'sensorId': selectedSensor,
      };

      final uri =
          Uri.parse('$baseUrl/searchbar').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];

        if (isLoadMore) {
          filteredDataList
              .addAll(data.map((item) => DataModel.fromJson(item)).toList());
        } else {
          filteredDataList =
              data.map((item) => DataModel.fromJson(item)).toList();
        }

        if (data.length < limit) {
          hasMoreData = false;
        } else {
          page++;
        }
      } else {
        errorMessage = 'Failed to fetch filtered data: ${response.statusCode}';
      }
    } catch (error) {
      errorMessage = 'Error fetching filtered data: $error';
    } finally {
      isLoading = false;
      isFetchingMore = false;
      notifyListeners();
    }
  }

  void updateFilters({
    DateTime? newStartDate,
    DateTime? newEndDate,
    TimeOfDay? start,
    TimeOfDay? end,
    String? sensors,
  }) {
    startDate = newStartDate ?? startDate;
    endDate = newEndDate ?? endDate;
    startTime = start ?? startTime;
    endTime = end ?? endTime;
    selectedSensor = sensors ?? "All";

    fetchFilteredData();
  }

  void fetchMoreData() {
    if (hasMoreData) {
      fetchFilteredData(isLoadMore: true);
    }
  }
}
