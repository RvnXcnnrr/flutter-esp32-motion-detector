import 'package:flutter/material.dart';

class Feature1Screen extends StatelessWidget {
  const Feature1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    // Placeholder for Motion Statistics page
    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion Statistics'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Motion Event Statistics',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Total motion events: 0'),
            const SizedBox(height: 8),
            const Text('Events per day:'),
            // Placeholder for chart or list
            Container(
              height: 150,
              alignment: Alignment.center,
              child: const Text(
                'Motion statistics coming soon',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Peak motion detection times:'),
            Container(
              height: 100,
              alignment: Alignment.center,
              child: const Text(
                'Motion statistics coming soon',
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
