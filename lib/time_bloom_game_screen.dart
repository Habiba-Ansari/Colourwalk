import 'package:flutter/material.dart';
import 'dart:async';
import 'services/time_bloom_service.dart';
import 'time_bloom_camera_screen.dart';
import 'time_bloom_results_screen.dart';

class TimeBloomGameScreen extends StatefulWidget {
  final Color targetColor;
  final String colorName;
  final TimeBloomSession session;

  const TimeBloomGameScreen({
    super.key,
    required this.targetColor,
    required this.colorName,
    required this.session,
  });

  @override
  State<TimeBloomGameScreen> createState() => _TimeBloomGameScreenState();
}

class _TimeBloomGameScreenState extends State<TimeBloomGameScreen> {
  late Timer _timer;
  late TimeBloomSession _session;
  bool _isGameActive = true;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        // Update session time
        _session = TimeBloomSession(
          id: _session.id,
          userEmail: _session.userEmail,
          targetColor: _session.targetColor,
          colorName: _session.colorName,
          timeLimit: _session.timeLimit,
          photosRequired: _session.photosRequired,
          photosCaptured: _session.photosCaptured,
          startTime: _session.startTime,
          endTime: _session.endTime,
          completed: _session.completed,
          pointsAwarded: _session.pointsAwarded,
        );

        // Check if time is up
        if (_session.isTimeUp && _isGameActive) {
          _isGameActive = false;
          _endGame(success: false);
        }

        // Check if completed
        if (_session.isCompleted && _isGameActive) {
          _isGameActive = false;
          _endGame(success: true);
        }
      });
    });
  }

  void _endGame({required bool success}) async {
    _timer.cancel();
    
    if (success) {
      // Award points and complete session
      await TimeBloomService.completeSession(_session.id, 100);
      await TimeBloomService.awardPoints(100);
    } else {
      // Fail session
      await TimeBloomService.failSession(_session.id);
    }

    // Navigate to results screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => TimeBloomResultsScreen(
            success: success,
            photosCaptured: _session.photosCaptured,
            colorName: _session.colorName,
            pointsAwarded: success ? 100 : 0,
          ),
        ),
      );
    }
  }

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TimeBloomCameraScreen(
          session: _session,
          onPhotoCaptured: _onPhotoCaptured,
        ),
      ),
    );
  }

  void _onPhotoCaptured() {
    if (!mounted) return;
    
    setState(() {
      _session = TimeBloomSession(
        id: _session.id,
        userEmail: _session.userEmail,
        targetColor: _session.targetColor,
        colorName: _session.colorName,
        timeLimit: _session.timeLimit,
        photosRequired: _session.photosRequired,
        photosCaptured: _session.photosCaptured + 1,
        startTime: _session.startTime,
        endTime: _session.endTime,
        completed: _session.completed,
        pointsAwarded: _session.pointsAwarded,
      );
    });

    // Update database
    TimeBloomService.updatePhotoCount(_session.id, _session.photosCaptured);
  }

  void _giveUp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Give Up?'),
        content: const Text('Are you sure you want to give up? You will lose all progress.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _endGame(success: false);
            },
            child: const Text(
              'Give Up',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F5),
      appBar: AppBar(
        title: const Text('Time Bloom Challenge'),
        backgroundColor: const Color(0xFF8AAAE5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _giveUp,
            tooltip: 'Give Up',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Timer Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _session.isTimeUp ? Colors.red.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: _session.isTimeUp ? Colors.red : Colors.transparent,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _session.isTimeUp ? 'TIME\'S UP!' : 'TIME REMAINING',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _session.isTimeUp ? Colors.red : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _session.formattedTime,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _session.isTimeUp ? Colors.red : const Color(0xFF8AAAE5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Progress Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'FIND: ${_session.colorName.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _session.targetColor,
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // Progress Bar
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: (MediaQuery.of(context).size.width - 88) * (_session.photosCaptured / _session.photosRequired),
                          decoration: BoxDecoration(
                            color: _session.targetColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    '${_session.photosCaptured}/${_session.photosRequired} PHOTOS',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Instructions
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📸 How to Play:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8AAAE5),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildInstruction('1. Tap "Capture Photo" below'),
                    _buildInstruction('2. Find and capture $_session.colorName objects'),
                    _buildInstruction('3. Color detection will verify your photo'),
                    _buildInstruction('4. Complete 10 photos before time runs out'),
                    _buildInstruction('5. Earn 100 bonus points if you succeed!'),
                    
                    const Spacer(),
                    
                    if (_session.isTimeUp)
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.red),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.timer_off, color: Colors.red),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Time\'s up! The game will end automatically.',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Capture Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _session.isTimeUp ? null : _openCamera,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _session.isTimeUp ? Colors.grey : _session.targetColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'CAPTURE PHOTO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}