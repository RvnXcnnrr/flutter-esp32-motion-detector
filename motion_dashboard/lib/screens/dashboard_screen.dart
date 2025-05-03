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

  bool _isLoading = false;
 
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    _focusedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    _fetchMotionEvents();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchMotionEvents();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
      // Simulate loading delay if needed, or remove if instant update is preferred
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
                // Already on Dashboard, no navigation needed
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
