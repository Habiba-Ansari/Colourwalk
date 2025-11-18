import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PointsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Calculate points based on gallery photos
  static Future<int> calculateUserPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    try {
      // Count user's photos in Supabase
      final response = await _supabase
          .from('pics')
          .select()
          .eq('user_email', user.email!);

      final photos = List<Map<String, dynamic>>.from(response);
      final points = photos.length;

      // Update points in Firebase
      await _updatePointsInFirebase(user.uid, points);
      
      return points;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating points: $e');
      }
      return 0;
    }
  }

  // Update points in Firebase
  static Future<void> _updatePointsInFirebase(String userId, int points) async {
    await _firestore.collection('users').doc(userId).set({
      'points': points,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get current points from Firebase
  static Future<int> getCurrentPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return doc.data()?['points'] ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting points: $e');
      }
      return 0;
    }
  }

  // Add point when new photo is saved
  static Future<void> addPointForNewPhoto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get current points
      final currentPoints = await getCurrentPoints();
      
      // Update points (+1)
      await _firestore.collection('users').doc(user.uid).set({
        'points': currentPoints + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error adding point: $e');
      }
    }
  }
}