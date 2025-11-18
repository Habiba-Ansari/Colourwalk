import 'package:colourwalk/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  Map<String, dynamic> userData = {
    'name': 'Unknown',
    'email': 'Unknown',
    'favouriteColour': 'Not set',
    'age': 'Not set',
    'city': 'Not set',
    'profession': 'Not set',
    'gender': 'Not set',
    'points': 0,
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkUserAndLoadData();
  }

  void _checkUserAndLoadData() {
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToLoginPage();
      });
      return;
    }
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    
    try {
      // Count user's photos from Supabase (this is their points)
      final photosResponse = await _supabase
          .from('pics')
          .select()
          .eq('user_email', user!.email!);

      final photosCount = (photosResponse as List).length;
      
      // Load user data from Supabase
      final userResponse = await _supabase
          .from('users')
          .select()
          .eq('email', user!.email!)
          .single();

      if (userResponse != null) {
        setState(() {
          userData = Map<String, dynamic>.from(userResponse);
          userData['points'] = photosCount; // Override with actual photo count
          _isLoading = false;
        });
      } else {
        // Create user document with points equal to photo count
        await _supabase.from('users').insert({
          'name': 'Unknown',
          'email': user!.email!,
          'favouriteColour': 'Not set',
          'age': 'Not set',
          'city': 'Not set',
          'profession': 'Not set',
          'gender': 'Not set',
          'points': photosCount, // Set points = photo count
          'created_at': DateTime.now().toIso8601String(),
        });
        
        setState(() {
          userData['email'] = user!.email!;
          userData['points'] = photosCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      // If user doesn't exist, create one
      if (e.toString().contains('PGRST116')) {
        await _createUserWithPhotoCount();
      } else {
        print('Error loading user data: $e');
        setState(() {
          if (user != null) {
            userData['email'] = user!.email!;
            userData['points'] = 0;
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createUserWithPhotoCount() async {
    try {
      // Count photos first
      final photosResponse = await _supabase
          .from('pics')
          .select()
          .eq('user_email', user!.email!);

      final photosCount = (photosResponse as List).length;
      
      await _supabase.from('users').insert({
        'name': 'Unknown',
        'email': user!.email!,
        'favouriteColour': 'Not set',
        'age': 'Not set',
        'city': 'Not set',
        'profession': 'Not set',
        'gender': 'Not set',
        'points': photosCount, // Set points = photo count
        'created_at': DateTime.now().toIso8601String(),
      });
      
      setState(() {
        userData['email'] = user!.email!;
        userData['points'] = photosCount;
        _isLoading = false;
      });
    } catch (e) {
      print('Error creating user: $e');
      setState(() {
        userData['email'] = user!.email!;
        userData['points'] = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      _goToLoginPage();
    } catch (e) {
      print('Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout failed. Please try again.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performAccountDeletion();
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _performAccountDeletion() async {
    try {
      // Delete user data from Supabase
      await _supabase
          .from('users')
          .delete()
          .eq('email', user!.email!);

      // Delete user's photos from Supabase
      await _supabase
          .from('pics')
          .delete()
          .eq('user_email', user!.email!);

      // Delete user account from Firebase Auth
      await user!.delete();
      
      _goToLoginPage();
    } catch (e) {
      print('Delete account error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account. Please try again.')),
      );
    }
  }

  void _goToLoginPage() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _updateUserData(Map<String, dynamic> newData) {
    setState(() {
      userData = newData;
    });
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Thank you for your support! 🌟')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return _buildLoadingScreen();
    }

    if (_isLoading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
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
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8AAAE5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userData['name'],
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8AAAE5),
                    ),
                  ),
                  Text(
                    userData['email'],
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            userData: userData,
                            onProfileUpdated: _updateUserData,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8AAAE5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Profile Information
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
                    'Profile Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8AAAE5),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildInfoRow('Name', userData['name']),
                  _buildInfoRow('Points', '${userData['points'] ?? 0} photos'),
                  _buildInfoRow('Email', userData['email']),
                  _buildInfoRow('Favourite Colour', userData['favouriteColour']),
                  _buildInfoRow('Age', userData['age']),
                  _buildInfoRow('City', userData['city']),
                  _buildInfoRow('Profession', userData['profession']),
                  _buildInfoRow('Gender', userData['gender']),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
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
                  _buildActionButton(
                    'Rate Us',
                    Icons.star,
                    const Color(0xFFFFD54F),
                    _rateApp,
                  ),
                  const SizedBox(height: 10),
                  _buildActionButton(
                    'Logout',
                    Icons.logout,
                    const Color(0xFF8AAAE5),
                    _logout,
                  ),
                  const SizedBox(height: 10),
                  _buildActionButton(
                    'Delete Account',
                    Icons.delete,
                    Colors.red,
                    _deleteAccount,
                  ),
                ],
              ),
            ),
          ],
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
            const SizedBox(height: 20),
            const Text('Loading...', style: TextStyle(color: Color(0xFF8AAAE5))),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: value == 'Unknown' || value == 'Not set' 
                    ? Colors.grey 
                    : Colors.black87,
                fontStyle: value == 'Unknown' || value == 'Not set' 
                    ? FontStyle.italic 
                    : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}