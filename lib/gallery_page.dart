import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _photos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final response = await _supabase
          .from('pics')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        _photos = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading photos: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupPhotosByDate() {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var photo in _photos) {
      try {
        // Handle different date formats safely
        DateTime date;
        if (photo['created_at'] is String) {
          date = DateTime.parse(photo['created_at']).toLocal();
        } else if (photo['created_at'] is DateTime) {
          date = (photo['created_at'] as DateTime).toLocal();
        } else {
          continue; // Skip if date format is invalid
        }
        
        final dateKey = '${date.year}-${date.month}-${date.day}';
        
        if (!grouped.containsKey(dateKey)) {
          grouped[dateKey] = [];
        }
        grouped[dateKey]!.add(photo);
      } catch (e) {
        print('Error parsing date for photo: $e');
        continue; // Skip this photo if date parsing fails
      }
    }
    
    return grouped;
  }

  String _formatDate(String dateKey) {
    try {
      final parts = dateKey.split('-');
      if (parts.length != 3) return dateKey;
      
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);
      
      final date = DateTime(year, month, day);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);
      
      if (date == today) {
        return 'Today';
      } else if (date == yesterday) {
        return 'Yesterday';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateKey; // Return original if formatting fails
    }
  }

  void _showPhotoDetail(int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PhotoDetailView(
          photos: _photos,
          initialIndex: index,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_photos.isEmpty) {
      return _buildEmptyState();
    }

    final groupedPhotos = _groupPhotosByDate();
    final dateKeys = groupedPhotos.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F5),
      appBar: AppBar(
        title: const Text('Gallery'),
        backgroundColor: const Color(0xFF8AAAE5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadPhotos,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: dateKeys.length,
          itemBuilder: (context, index) {
            final dateKey = dateKeys[index];
            final photos = groupedPhotos[dateKey]!;
            
            return _buildDateSection(_formatDate(dateKey), photos, dateKey);
          },
        ),
      ),
    );
  }

  Widget _buildDateSection(String title, List<Map<String, dynamic>> photos, String dateKey) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8AAAE5),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8AAAE5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${photos.length} photo${photos.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8AAAE5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return _buildPhotoItem(photos[index], index, photos);
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPhotoItem(Map<String, dynamic> photo, int index, List<Map<String, dynamic>> photos) {
    return GestureDetector(
      onTap: () => _showPhotoDetail(_photos.indexOf(photo)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              CachedNetworkImage(
                imageUrl: photo['image_url'],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.photo, color: Colors.grey),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.error, color: Colors.grey),
                ),
              ),
              
              // Color badge
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    photo['color_theme']?.toString().split(' ').first ?? 'Color',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF8AAAE5)),
            const SizedBox(height: 16),
            const Text('Loading your photos...', style: TextStyle(color: Color(0xFF8AAAE5))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No photos yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              'Capture your first color photo!',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8AAAE5),
              ),
              child: const Text('Go Capture', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// SIMPLE PHOTO DETAIL VIEW - Like normal phone gallery
class PhotoDetailView extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;

  const PhotoDetailView({
    super.key,
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<PhotoDetailView> createState() => _PhotoDetailViewState();
}

class _PhotoDetailViewState extends State<PhotoDetailView> {
  late PageController _pageController;
  late int _currentIndex;
  bool _showAppBar = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleAppBar() {
    setState(() {
      _showAppBar = !_showAppBar;
    });
  }

  String _formatDateTime(dynamic dateValue) {
    try {
      DateTime date;
      if (dateValue is String) {
        date = DateTime.parse(dateValue).toLocal();
      } else if (dateValue is DateTime) {
        date = dateValue.toLocal();
      } else {
        return 'Unknown date';
      }
      return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatLocation(dynamic lat, dynamic lng) {
    try {
      if (lat == null || lng == null) return 'Not available';
      final latValue = lat is double ? lat : double.parse(lat.toString());
      final lngValue = lng is double ? lng : double.parse(lng.toString());
      return '${latValue.toStringAsFixed(4)}°, ${lngValue.toStringAsFixed(4)}°';
    } catch (e) {
      return 'Invalid location';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _showAppBar
          ? AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              title: Text(
                '${_currentIndex + 1} of ${widget.photos.length}',
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: _showPhotoInfo,
                ),
              ],
            )
          : null,
      body: GestureDetector(
        onTap: _toggleAppBar,
        child: Stack(
          children: [
            // Photo Viewer
            PageView.builder(
              controller: _pageController,
              itemCount: widget.photos.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final photo = widget.photos[index];
                return InteractiveViewer(
                  child: Center(
                    child: CachedNetworkImage(
                      imageUrl: photo['image_url'],
                      fit: BoxFit.contain,
                      errorWidget: (context, url, error) => const Icon(
                        Icons.error,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Swipe indicator (only show when app bar is hidden)
            if (!_showAppBar)
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.photos.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPhotoInfo() {
    final photo = widget.photos[_currentIndex];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Photo Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8AAAE5),
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Color Theme', photo['color_theme']?.toString() ?? 'Unknown'),
            _buildInfoRow('Date & Time', _formatDateTime(photo['created_at'])),
            if (photo['latitude'] != null && photo['longitude'] != null)
              _buildInfoRow(
                'Location',
                _formatLocation(photo['latitude'], photo['longitude']),
              ),
            _buildInfoRow('User', photo['user_email']?.toString() ?? 'Unknown'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}