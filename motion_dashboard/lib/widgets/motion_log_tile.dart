import 'package:flutter/material.dart';
import '../models/motion_event.dart';
import 'package:intl/intl.dart';

class MotionLogTile extends StatelessWidget {
  final MotionEvent event;
  final VoidCallback? onDelete;
  final int number;  // New parameter for numbering

  const MotionLogTile({super.key, required this.event, this.onDelete, required this.number});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$number',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.greenAccent : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.motion_photos_on, color: isDark ? Colors.greenAccent : Colors.black),
        ],
      ),
      title: Text(
        'Motion Detected',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: Text(
        DateFormat('yyyy-MM-dd – hh:mm:ss a').format(event.timestamp),  // 12-hour format with AM/PM
        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[800]),
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: isDark ? Colors.redAccent : Colors.red),
        onPressed: onDelete,
        tooltip: 'Delete motion event',
      ),
    );
  }
}
