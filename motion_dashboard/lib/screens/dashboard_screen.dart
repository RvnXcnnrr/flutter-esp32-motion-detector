import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/motion_event.dart';
import '../providers/theme_provider.dart';
import '../widgets/motion_log_tile.dart';
import '../services/backend_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<MotionEvent> _motionLogs = [];
  DateTime? _selectedDate;
 
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
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
        _motionLogs = events;
      });
    } else {
      debugPrint('No new data detected');
    }
  } catch (e) {
    debugPrint('Error fetching motion events: $e');
  }
}

  List<MotionEvent> get _filteredMotionLogs {
    if (_selectedDate == null) {
      return _motionLogs;
    } else {
      return _motionLogs.where((event) {
        return event.timestamp.year == _selectedDate!.year &&
               event.timestamp.month == _selectedDate!.month &&
               event.timestamp.day == _selectedDate!.day;
      }).toList();
    }
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
            icon: Icon(themeProvider.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: () {
              themeProvider.toggleTheme();
            },
          )
        ],
      ),
      body: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _selectedDate ?? DateTime.now(),
                  selectedDayPredicate: (day) {
                    return _selectedDate != null &&
                        day.year == _selectedDate!.year &&
                        day.month == _selectedDate!.month &&
                        day.day == _selectedDate!.day;
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDate = selectedDay;
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
                  child: _filteredMotionLogs.isEmpty
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
                                  final scaffoldContext = context;
                                  try {
                                    await BackendService.deleteMotionEvent(event.id);
                                    if (!mounted) return;
                                    final scaffoldMessenger = ScaffoldMessenger.of(scaffoldContext);
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(content: Text('Motion event deleted')),
                                    );
                                    _fetchMotionEvents();
                                  } catch (e) {
                                    if (!mounted) return;
                                    final scaffoldMessenger = ScaffoldMessenger.of(scaffoldContext);
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
