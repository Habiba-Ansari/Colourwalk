import 'package:flutter/material.dart';

class TimeBloomResultsScreen extends StatefulWidget {
  final bool success;
  final int photosCaptured;
  final String colorName;
  final int pointsAwarded;

  const TimeBloomResultsScreen({
    super.key,
    required this.success,
    required this.photosCaptured,
    required this.colorName,
    required this.pointsAwarded,
  });

  @override
  State<TimeBloomResultsScreen> createState() => _TimeBloomResultsScreenState();
}

class _TimeBloomResultsScreenState extends State<TimeBloomResultsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F5),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.success ? Icons.celebration : Icons.timer_off,
                size: 80,
                color: widget.success ? Colors.green : Colors.red,
              ),
              SizedBox(height: 20),
              Text(
                widget.success ? '🎉 SUCCESS!' : '⏰ TIME\'S UP!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: widget.success ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(height: 20),
              Text(
                widget.success 
                  ? 'You found 10 ${widget.colorName} photos!'
                  : 'You found ${widget.photosCaptured}/10 ${widget.colorName} photos',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Points: ${widget.pointsAwarded}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text('BACK TO HOME'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}