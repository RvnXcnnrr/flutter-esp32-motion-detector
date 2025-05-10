

class EnvironmentData {
  final int id;
  final DateTime timestamp;
  final double temperature;
  final double humidity;

  const EnvironmentData({
    required this.id,
    required this.timestamp,
    required this.temperature,
    required this.humidity,
  });

  factory EnvironmentData.fromJson(Map<String, dynamic> json) {
    return EnvironmentData(
      id: json['id'] ?? 0,
      timestamp: DateTime.parse(json['timestamp'] ?? '').toLocal(),
      temperature: (json['temperature'] ?? 0).toDouble(),
      humidity: (json['humidity'] ?? 0).toDouble(),
    );
  }

  @override
  String toString() {
    return 'EnvironmentData{id: $id, timestamp: $timestamp, temperature: $temperature, humidity: $humidity}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnvironmentData &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          timestamp == other.timestamp &&
          temperature == other.temperature &&
          humidity == other.humidity;

  @override
  int get hashCode =>
      id.hashCode ^
      timestamp.hashCode ^
      temperature.hashCode ^
      humidity.hashCode;
}