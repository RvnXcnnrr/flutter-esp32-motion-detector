import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/motion_event.dart';
import '../models/environment_data.dart';

class BackendService {
  static const String baseUrl = 'https://detector-backend.onrender.com';

  // Fetch all motion events
  static Future<List<MotionEvent>> getMotionEvents() async {
    final uri = Uri.parse('$baseUrl/motion-events');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      // Filter out entries with null id
      final filteredData = data.where((json) => json['id'] != null).toList();
      return filteredData
          .map((json) => MotionEvent(
                id: json['id'],
                timestamp: DateTime.parse(json['timestamp']),
              ))
          .toList();
    } else {
      throw Exception('Failed to load motion events: ${response.statusCode}');
    }
  }

  // Add a new motion event
  static Future<void> addMotionEvent(MotionEvent event) async {
    final uri = Uri.parse('$baseUrl/motion-events');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'timestamp': event.timestamp.toIso8601String()}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add motion event: ${response.statusCode}');
    }
  }

  // Delete a motion event by id
  static Future<void> deleteMotionEvent(int id) async {
    final uri = Uri.parse('$baseUrl/motion-events/$id');
    final response = await http.delete(uri);

    if (response.statusCode != 204) {
      throw Exception('Failed to delete motion event: ${response.statusCode}');
    }
  }

  // Fetch latest environment data
  static Future<EnvironmentData> getLatestEnvironmentData() async {
    final uri = Uri.parse('$baseUrl/environment-data/latest');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final dynamic data = json.decode(response.body);
      return EnvironmentData.fromJson(data);
    } else {
      throw Exception('Failed to load environment data: ${response.statusCode}');
    }
  }
}