import 'package:flutter/material.dart';
import 'time_bloom_game_screen.dart';
import 'services/time_bloom_service.dart';
import 'services/daily_color_service.dart';

class TimeBloomIntroScreen extends StatefulWidget {
  const TimeBloomIntroScreen({super.key});

  @override
  State<TimeBloomIntroScreen> createState() => _TimeBloomIntroScreenState();
}

class _TimeBloomIntroScreenState extends State<TimeBloomIntroScreen> {
  Color _randomColor = Colors.blue;
  String _colorName = "Blue";

  @override
  void initState() {
    super.initState();
    _generateRandomColor();
  }

  void _generateRandomColor() {
    // Generate a random color for this session
    final randomColor = DailyColorService.getTodaysColor();
    final colorNames = [
      'Red',
      'Blue',
      'Green',
      'Yellow',
      'Purple',
      'Orange',
      'Pink',
    ];
    final random = DateTime.now().millisecond % colorNames.length;

    setState(() {
      _randomColor = randomColor;
      _colorName = colorNames[random];
    });
  }

  void _startGame() async {
    try {
      // Create a new session
      final session = await TimeBloomService.createSession(
        targetColor: _randomColor,
        colorName: _colorName,
      );

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => TimeBloomGameScreen(
                targetColor: _randomColor,
                colorName: _colorName,
                session: session, // Pass the session to game screen
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to start game: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F5),
      appBar: AppBar(
        title: const Text('Time Bloom'),
        backgroundColor: const Color(0xFF8AAAE5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Game Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: _randomColor.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: _randomColor, width: 3),
              ),
              child: Icon(Icons.timer, size: 50, color: _randomColor),
            ),

            const SizedBox(height: 30),

            // Game Title
            Text(
              'Time Bloom Challenge',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _randomColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // Target Color Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _randomColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _randomColor),
              ),
              child: Text(
                'Find: $_colorName',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _randomColor,
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Rules Card
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎮 Game Rules',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8AAAE5),
                    ),
                  ),

                  const SizedBox(height: 15),

                  _buildRuleItem('⏱️', '5 minutes timer'),
                  _buildRuleItem('📸', 'Capture 10 $_colorName photos'),
                  _buildRuleItem('✅', 'Complete = 100 points!'),
                  _buildRuleItem('❌', 'Fail = No points, no photos saved'),
                  _buildRuleItem('💾', 'Photos saved only if completed'),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Start Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _randomColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 5,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 24),
                    SizedBox(width: 10),
                    Text(
                      'START CHALLENGE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Points Info
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.amber),
              ),
              child: const Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Complete the challenge to earn 100 bonus points!',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
