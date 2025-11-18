import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import 'services/color_detection_service.dart';
import 'services/points_service.dart';

class CameraScreen extends StatefulWidget {
  final String todaysColor;
  final Color todaysColorValue;

  const CameraScreen({
    super.key,
    required this.todaysColor,
    required this.todaysColorValue,
  });

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isFrontCamera = false;
  bool _isLoading = false;
  XFile? _capturedImage;
  Position? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getCurrentLocation();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = _isFrontCamera && cameras.length > 1 ? cameras[1] : cameras.first;
    
    _controller = CameraController(camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          debugPrint('Location services are disabled');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (kDebugMode) {
            debugPrint('Location permissions denied');
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (kDebugMode) {
          debugPrint('Location permissions permanently denied');
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      setState(() {
        _currentLocation = position;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting location: $e');
      }
    }
  }

  Future<void> _switchCamera() async {
    setState(() => _isFrontCamera = !_isFrontCamera);
    await _controller.dispose();
    _initializeCamera();
  }

  Future<void> _capturePhoto() async {
    try {
      await _initializeControllerFuture;
      final XFile image = await _controller.takePicture();
      setState(() => _capturedImage = image);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to capture: $e')),
      );
    }
  }

  Future<void> _savePhoto() async {
    if (_capturedImage == null) return;
    
    try {
      setState(() => _isLoading = true);
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      // COLOR DETECTION CHECK
      final File imageFile = File(_capturedImage!.path);
      final bool containsColor = await ColorDetectionService.doesImageContainColor(
        imageFile,
        widget.todaysColorValue,
      );

      if (!containsColor) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ No ${widget.todaysColor} detected! Try again.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // If color detected, proceed with upload
      final fileBytes = await imageFile.readAsBytes();
      final fileName = '${user.email}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Supabase
      await Supabase.instance.client.storage
          .from('photos')
          .uploadBinary(fileName, fileBytes);

      final imageUrl = Supabase.instance.client.storage
          .from('photos')
          .getPublicUrl(fileName);

      // Save to pics table with location
      await Supabase.instance.client.from('pics').insert({
        'user_email': user.email,
        'image_url': imageUrl,
        'color_theme': widget.todaysColor,
        'created_at': DateTime.now().toIso8601String(),
        'latitude': _currentLocation?.latitude,
        'longitude': _currentLocation?.longitude,
      });

      // Award point for successful color match
      await PointsService.addPointForNewPhoto();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Color matched! +1 Point! 🎉'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _retakePhoto() {
    setState(() {
      _capturedImage = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_capturedImage != null) {
      return _buildPreviewScreen();
    }
    
    return _buildCameraScreen();
  }

  Widget _buildCameraScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  Expanded(
                    child: Text(
                      'Capture ${widget.todaysColor}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),

            Expanded(
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  return snapshot.connectionState == ConnectionState.done
                      ? CameraPreview(_controller)
                      : const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FloatingActionButton.large(
                onPressed: _capturePhoto,
                backgroundColor: Colors.white,
                child: const Icon(Icons.camera_alt, size: 30, color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const Expanded(
                    child: Text(
                      'Preview Photo',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: Center(
                child: Image.file(
                  File(_capturedImage!.path),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: _retakePhoto,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.refresh, color: Colors.white),
                  ),
                  
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _savePhoto,
                    backgroundColor: Colors.green,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.check, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}