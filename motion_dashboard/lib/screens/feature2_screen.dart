import 'package:flutter/material.dart';

class Feature2Screen extends StatefulWidget {
  const Feature2Screen({super.key});

  @override
  State<Feature2Screen> createState() => _Feature2ScreenState();
}

class _Feature2ScreenState extends State<Feature2Screen> {
  bool _notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Placeholder for export functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon')),
                );
              },
              child: const Text('Export Motion Logs'),
            ),
            const SizedBox(height: 16),
            const Text(
              'About',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Motion Detector App v1.0.0'),
            const Text('Developed by BSIT Group ')
          ],
        ),
      ),
    );
  }
}
