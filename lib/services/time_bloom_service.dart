import 'dart:ui';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TimeBloomSession {
  final String id;
  final String userEmail;
  final Color targetColor;
  final String colorName;
  final int timeLimit; // in seconds
  final int photosRequired;
  
  int photosCaptured;
  DateTime startTime;
  DateTime? endTime;
  bool completed;
  int pointsAwarded;
  
  TimeBloomSession({
    required this.id,
    required this.userEmail,
    required this.targetColor,
    required this.colorName,
    this.timeLimit = 300, // 5 minutes
    this.photosRequired = 10,
    this.photosCaptured = 0,
    required this.startTime,
    this.endTime,
    this.completed = false,
    this.pointsAwarded = 0,
  });

  // Get remaining time in seconds
  int get remainingTime {
    final now = DateTime.now();
    final elapsed = now.difference(startTime).inSeconds;
    return timeLimit - elapsed;
  }

  // Check if time is up
  bool get isTimeUp => remainingTime <= 0;

  // Check if game is completed
  bool get isCompleted => photosCaptured >= photosRequired;

  // Format time as MM:SS
  String get formattedTime {
    final minutes = (remainingTime ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingTime % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class TimeBloomService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new Time Bloom session
  static Future<TimeBloomSession> createSession({
    required Color targetColor,
    required String colorName,
    int timeLimit = 300,
    int photosRequired = 10,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    // Generate a session ID
    final sessionId = 'time_bloom_${DateTime.now().millisecondsSinceEpoch}';

    // Convert Color to hex for storage
    final colorHex = '#${targetColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';

    // Save session to database
    final response = await _supabase
        .from('time_bloom_sessions')
        .insert({
          'user_email': user.email!,
          'target_color': colorHex,
          'color_name': colorName,
          'time_limit': timeLimit,
          'photos_required': photosRequired,
          'photos_captured': 0,
          'start_time': DateTime.now().toIso8601String(),
          'completed': false,
          'points_awarded': 0,
        })
        .select()
        .single();

    // Create session object
    return TimeBloomSession(
      id: response['id'],
      userEmail: user.email!,
      targetColor: targetColor,
      colorName: colorName,
      timeLimit: timeLimit,
      photosRequired: photosRequired,
      startTime: DateTime.now(),
    );
  }

  // Update session when photo is captured
  static Future<void> updatePhotoCount(String sessionId, int newCount) async {
    await _supabase
        .from('time_bloom_sessions')
        .update({
          'photos_captured': newCount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId);
  }

  // Complete session (success)
  static Future<void> completeSession(String sessionId, int points) async {
    await _supabase
        .from('time_bloom_sessions')
        .update({
          'photos_captured': 10, // Ensure it's exactly 10
          'completed': true,
          'points_awarded': points,
          'end_time': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId);
  }

  // Save Time Bloom photo
static Future<void> savePhoto({
  required String sessionId,
  required String imageUrl,
  required String colorName,
  required double? latitude,
  required double? longitude,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await _supabase
      .from('pics')
      .insert({
        'user_email': user.email!,
        'image_url': imageUrl,
        'color_theme': colorName,
        'game_mode': 'time_bloom',
        'session_id': sessionId,
        'latitude': latitude,
        'longitude': longitude,
        'created_at': DateTime.now().toIso8601String(),
      });
}

  // Fail session (time up)
  static Future<void> failSession(String sessionId) async {
    await _supabase
        .from('time_bloom_sessions')
        .update({
          'completed': false,
          'points_awarded': 0,
          'end_time': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', sessionId);
  }
  // Award points to user
  static Future<void> awardPoints(int points) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Get current points
    final userResponse = await _supabase
        .from('users')
        .select('points')
        .eq('email', user.email!)
        .single();

    final currentPoints = userResponse['points'] ?? 0;
    final newPoints = currentPoints + points;

    // Update points
    await _supabase
        .from('users')
        .update({
          'points': newPoints,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('email', user.email!);
  }

  // Get user's Time Bloom history
  static Future<List<Map<String, dynamic>>> getUserSessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('time_bloom_sessions')
        .select()
        .eq('user_email', user.email!)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}