import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/motion_event.dart';
import '../providers/theme_provider.dart';
import '../widgets/motion_log_tile.dart';
import '../services/backend_service.dart';
import 'feature1_screen.dart';
import 'feature2_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<MotionEvent> _motionLogs = [];
  DateTime _selectedDate = DateTime.now().toLocal();
  DateTime _focusedDay = DateTime.now().toLocal();
  double _currentTemperature = 23.5; // Example temperature value
  double _currentHumidity = 45.0;    // Example humidity value
  bool _isLoading = false;
  Timer? _refreshTimer;
  Timer? _envRefreshTimer;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    _fetchMotionEvents();
    _fetchEnvironmentData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchMotionEvents();
    });
    _envRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchEnvironmentData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _envRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchEnvironmentData() async {
    // In a real app, you would fetch this from your DHT22 sensor
    // For now, we'll simulate small variations in the values
    setState(() {
      _currentTemperature = 23.5 + (DateTime.now().second % 10) * 0.1;
      _currentHumidity = 45.0 + (DateTime.now().second % 10) * 0.5;
    });
  }

  Future<void> _fetchMotionEvents() async {
    if (!mounted) return;
    debugPrint('Fetching motion events...');
    List<MotionEvent> events = [];
    bool isNewData = false;

    try {
      events = await BackendService.getMotionEvents();
      debugPrint('Fetched ${events.length} motion events');

      if (!mounted) return;

      if (events.length != _motionLogs.length) {
        isNewData = true;
      } else {
        for (int i = 0; i < events.length; i++) {
          if (events[i].timestamp != _motionLogs[i].timestamp) {
            isNewData = true;
            break;
          }
        }
      }

      if (isNewData) {
        debugPrint('New data detected, updating motion logs');
        setState(() {
          _isLoading = true;
          _motionLogs = events;
        });
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        debugPrint('No new data detected');
      }
    } catch (e) {
      debugPrint('Error fetching motion events: $e');
    }
  }

  List<MotionEvent> get _filteredMotionLogs {
    return _motionLogs.where((event) {
      return event.timestamp.year == _selectedDate.year &&
             event.timestamp.month == _selectedDate.month &&
             event.timestamp.day == _selectedDate.day;
    }).toList();
  }

  Set<DateTime> get _motionEventDates {
    return _motionLogs
        .map((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion Detector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete All Motion Events',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Delete All'),
                    content: const Text('Are you sure you want to delete all motion events?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Delete All'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  if (!mounted) return;
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  try {
                    for (final event in _motionLogs) {
                      await BackendService.deleteMotionEvent(event.id);
                    }
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('All motion events deleted')),
                    );
                    _fetchMotionEvents();
                  } catch (e) {
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Failed to delete all motion events: \$e')),
                    );
                  }
                }
              },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.featured_play_list),
              title: const Text('Feature 1'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Feature1Screen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.featured_play_list),
              title: const Text('Feature 2'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Feature2Screen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
              title: Text(themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode'),
              onTap: () {
                themeProvider.toggleTheme();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Environment Data Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Temperature Card
                Expanded(
                  child: Card(
                    elevation: 4,
                    color: isDarkMode ? Colors.grey[800] : Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.thermostat,
                                color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
                                size: 30,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Temperature',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_currentTemperature.toStringAsFixed(1)}°C',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
                            ),
                          ),
                          LinearProgressIndicator(
                            value: _currentTemperature / 50, // Assuming max temp is 50°C
                            backgroundColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _currentTemperature > 30 
                                ? Colors.red 
                                : (_currentTemperature < 20 ? Colors.blue : Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Humidity Card
                Expanded(
                  child: Card(
                    elevation: 4,
                    color: isDarkMode ? Colors.grey[800] : Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.water_drop,
                                color: isDarkMode ? Colors.green[200] : Colors.green[700],
                                size: 30,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Humidity',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_currentHumidity.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.green[200] : Colors.green[700],
                            ),
                          ),
                          LinearProgressIndicator(
                            value: _currentHumidity / 100,
                            backgroundColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _currentHumidity > 70 
                                ? Colors.blue 
                                : (_currentHumidity < 30 ? Colors.amber : Colors.teal),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month',
            },
            selectedDayPredicate: (day) {
              final selected = _selectedDate;
              return day.year == selected.year &&
                  day.month == selected.month &&
                  day.day == selected.day;
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, day, focusedDay) {
                if (_motionEventDates.contains(DateTime(day.year, day.month, day.day))) {
                  return Container(
                    margin: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(128),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }
                return null;
              },
              selectedBuilder: (context, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(6.0),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMotionLogs.isEmpty
                    ? const Center(child: Text('No motion detected for selected date.'))
                    : ListView.builder(
                        itemCount: _filteredMotionLogs.length,
                        itemBuilder: (context, index) {
                          final reversedIndex = _filteredMotionLogs.length - 1 - index;
                          final event = _filteredMotionLogs[reversedIndex];
                          return MotionLogTile(
                            event: event,
                            number: index + 1,
                            onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text('Are you sure you want to delete this motion event?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  if (!mounted) return;
                                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                                  try {
                                    await BackendService.deleteMotionEvent(event.id);
                                    if (!mounted) return;
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(content: Text('Motion event deleted')),
                                    );
                                    _fetchMotionEvents();
                                  } catch (e) {
                                    if (!mounted) return;
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(content: Text('Failed to delete motion event: \$e')),
                                    );
                                  }
                                }
                              },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}