import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/motion_event.dart';
import '../models/environment_data.dart';
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
  EnvironmentData? _currentEnvironment;
  DateTime _selectedDate = DateTime.now().toLocal();
  DateTime _focusedDay = DateTime.now().toLocal();
  bool _isLoading = false;
  Timer? _refreshTimer;
  Timer? _envRefreshTimer;
  int _currentPage = 0;
  final int _itemsPerPage = 4;

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
    try {
      final data = await BackendService.getLatestEnvironmentData();
      if (!mounted) return;
      setState(() {
        _currentEnvironment = data;
      });
    } catch (e) {
      debugPrint('Error fetching environment data: $e');
    }
  }

  Future<void> _fetchMotionEvents() async {
    if (!mounted) return;
    debugPrint('Fetching motion events...');
    List<MotionEvent> events = [];
    bool isNewData = false;

    try {
      events = await BackendService.getMotionEvents();
      // Sort events by timestamp in descending order (newest first)
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
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
          _currentPage = 0;
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

  List<MotionEvent> get _paginatedMotionLogs {
    final filtered = _filteredMotionLogs;
    final startIndex = _currentPage * _itemsPerPage;
    if (startIndex >= filtered.length) {
      return [];
    }
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);
    return filtered.sublist(startIndex, endIndex);
  }

  int get _totalPages {
    return (_filteredMotionLogs.length / _itemsPerPage).ceil();
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
                    SnackBar(content: Text('Failed to delete all motion events: $e')),
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
          // Calendar at the top
          Card(
            margin: const EdgeInsets.all(8),
            elevation: 4,
            child: TableCalendar(
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
                  _currentPage = 0;
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
          ),

          // Temperature and Humidity Cards
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
                            _currentEnvironment != null 
                              ? '${_currentEnvironment!.temperature.toStringAsFixed(1)}°C'
                              : '--.-°C',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
                            ),
                          ),
                          LinearProgressIndicator(
                            value: _currentEnvironment != null 
                              ? _currentEnvironment!.temperature / 50 
                              : 0.0,
                            backgroundColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _currentEnvironment != null && _currentEnvironment!.temperature > 30 
                                ? Colors.red 
                                : (_currentEnvironment != null && _currentEnvironment!.temperature < 20 
                                    ? Colors.blue 
                                    : Colors.green),
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
                            _currentEnvironment != null
                              ? '${_currentEnvironment!.humidity.toStringAsFixed(1)}%'
                              : '--.-%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.green[200] : Colors.green[700],
                            ),
                          ),
                          LinearProgressIndicator(
                            value: _currentEnvironment != null 
                              ? _currentEnvironment!.humidity / 100 
                              : 0.0,
                            backgroundColor: isDarkMode ? Colors.grey[600] : Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _currentEnvironment != null && _currentEnvironment!.humidity > 70 
                                ? Colors.blue 
                                : (_currentEnvironment != null && _currentEnvironment!.humidity < 30 
                                    ? Colors.amber 
                                    : Colors.teal),
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

          // Motion Detected List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Motion Detected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                if (_totalPages > 1)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, 
                            size: 16, 
                            color: _currentPage > 0 
                                ? (isDarkMode ? Colors.white : Colors.black) 
                                : Colors.grey),
                        onPressed: _currentPage > 0
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                            : null,
                      ),
                      Text(
                        '${_currentPage + 1}/$_totalPages',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios, 
                            size: 16, 
                            color: _currentPage < _totalPages - 1
                                ? (isDarkMode ? Colors.white : Colors.black) 
                                : Colors.grey),
                        onPressed: _currentPage < _totalPages - 1
                            ? () {
                                setState(() {
                                  _currentPage++;
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Motion Detected List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMotionLogs.isEmpty
                    ? Center(
                        child: Text(
                          'No motion detected for selected date.',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _paginatedMotionLogs.length,
                        itemBuilder: (context, index) {
                          final event = _paginatedMotionLogs[index];
                          return MotionLogTile(
                            event: event,
                            number: (_currentPage * _itemsPerPage) + index + 1,
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
                                    SnackBar(content: Text('Failed to delete motion event: $e')),
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