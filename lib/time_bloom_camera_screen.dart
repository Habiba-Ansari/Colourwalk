import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'services/time_bloom_service.dart';
import 'services/color_detection_service.dart';

class TimeBloomCameraScreen extends StatefulWidget {
  final TimeBloomSession session;
  final VoidCallback onPhotoCaptured;

  const TimeBloomCameraScreen({
    super.key,
    required this.session,
    required this.onPhotoCaptured,
  });

  @override
  State<TimeBloomCameraScreen> createState() => _TimeBloomCameraScreenState();
}

class _TimeBloomCameraScreenState extends State<TimeBloomCameraScreen> {
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
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      setState(() {
        _currentLocation = position;
      });
    } catch (e) {
      print('Error getting location: $e');
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
      
      // COLOR DETECTION CHECK for Time Bloom target color
      final File imageFile = File(_capturedImage!.path);
      final bool containsColor = await ColorDetectionService.doesImageContainColor(
        imageFile,
        widget.session.targetColor,
        hueTolerance: 30.0, // Same loose matching as daily mode
      );

      if (!containsColor) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ No ${widget.session.colorName} detected! Try again.'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // If color detected, proceed with upload
      final fileBytes = await imageFile.readAsBytes();
      final fileName = 'timebloom_${widget.session.userEmail}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Upload to Supabase
      await Supabase.instance.client.storage
          .from('photos')
          .uploadBinary(fileName, fileBytes);

      final imageUrl = Supabase.instance.client.storage
          .from('photos')
          .getPublicUrl(fileName);

      // Save to pics table with Time Bloom game mode
      await TimeBloomService.savePhoto(
        sessionId: widget.session.id,
        imageUrl: imageUrl,
        colorName: widget.session.colorName,
        latitude: _currentLocation?.latitude,
        longitude: _currentLocation?.longitude,
      );

      // Notify parent about photo capture
      widget.onPhotoCaptured();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Color matched! Photo saved!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();

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
            // Header with game info
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Time Bloom - ${widget.session.colorName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Time: ${widget.session.formattedTime} | Photos: ${widget.session.photosCaptured}/${widget.session.photosRequired}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                    onPressed: _switchCamera,
                  ),
                ],
              ),
            ),

            // Camera preview with overlay
            Expanded(
              child: Stack(
                children: [
                  FutureBuilder<void>(
                    future: _initializeControllerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return CameraPreview(_controller);
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      }
                    },
                  ),
                  
                  // Target color overlay
                  Positioned(
                    top: 20,
                    left: 0,
                    right: 0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: widget.session.targetColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'FIND: ${widget.session.colorName.toUpperCase()}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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

            // Capture button area
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Timer display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      widget.session.formattedTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // Capture button
                  FloatingActionButton.large(
                    onPressed: _capturePhoto,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.camera_alt, size: 30, color: Colors.black),
                  ),
                  
                  // Progress indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: Text(
                      '${widget.session.photosCaptured}/${widget.session.photosRequired}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
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

  Widget _buildPreviewScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
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

            // Image preview
            Expanded(
              child: Center(
                child: Image.file(
                  File(_capturedImage!.path),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Action buttons
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Retry button
                  FloatingActionButton(
                    onPressed: _retakePhoto,
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.refresh, color: Colors.white),
                  ),
                  
                  // Save button
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