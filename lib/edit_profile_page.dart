import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Function(Map<String, dynamic>) onProfileUpdated;

  const EditProfilePage({
    super.key, 
    required this.userData, 
    required this.onProfileUpdated
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final User? user = FirebaseAuth.instance.currentUser;
  
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _ageController;
  late TextEditingController _cityController;
  late TextEditingController _professionController;

  String _selectedGender = 'Not set';
  String _selectedColour = 'Not set';

  final List<String> _genders = ['Male', 'Female', 'Other', 'Prefer not to say', 'Not set'];
  final List<String> _colours = ['Red', 'Blue', 'Green', 'Yellow', 'Purple', 'Orange', 'Pink', 'Black', 'White', 'Not set'];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current data or empty values
    _nameController = TextEditingController(text: 
        widget.userData['name'] != 'Unknown' ? widget.userData['name'] : '');
    _emailController = TextEditingController(text: 
        widget.userData['email'] != 'Unknown' ? widget.userData['email'] : '');
    _ageController = TextEditingController(text: 
        widget.userData['age'] != 'Not set' ? widget.userData['age'] : '');
    _cityController = TextEditingController(text: 
        widget.userData['city'] != 'Not set' ? widget.userData['city'] : '');
    _professionController = TextEditingController(text: 
        widget.userData['profession'] != 'Not set' ? widget.userData['profession'] : '');
    
    _selectedGender = widget.userData['gender'];
    _selectedColour = widget.userData['favouriteColour'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No user logged in!')),
    );
    return;
  }

  setState(() => _isSaving = true);

  try {
    // Prepare updated data
    Map<String, dynamic> updatedData = {
      'name': _nameController.text.isNotEmpty ? _nameController.text : 'Unknown',
      'email': _emailController.text.isNotEmpty ? _emailController.text : 'Unknown',
      'favouriteColour': _selectedColour,
      'age': _ageController.text.isNotEmpty ? _ageController.text : 'Not set',
      'city': _cityController.text.isNotEmpty ? _cityController.text : 'Not set',
      'profession': _professionController.text.isNotEmpty ? _professionController.text : 'Not set',
      'gender': _selectedGender,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Save to Supabase
    await Supabase.instance.client
        .from('users')
        .update(updatedData)
        .eq('email', user!.email!);

    // Update the UI through callback
    widget.onProfileUpdated(updatedData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved successfully! ✅'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    Navigator.of(context).pop();
  } catch (e) {
    print('Error saving profile: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error saving profile: $e'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  } finally {
    setState(() => _isSaving = false);
  }
}
  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirecting to app store...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F5),
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: const Color(0xFF8AAAE5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile Picture Section
              Container(
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
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8AAAE5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8AAAE5),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        // Add photo picker functionality
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Photo upload feature coming soon!')),
                        );
                      },
                      child: const Text('Change Photo'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Form Fields
              Container(
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
                    _buildTextField(_nameController, 'Full Name', Icons.person, hint: 'Enter your full name'),
                    const SizedBox(height: 15),
                    _buildTextField(_emailController, 'Email', Icons.email, hint: 'Enter your email', isEmail: true),
                    const SizedBox(height: 15),
                    _buildDropdown('Favourite Colour', _selectedColour, _colours, Icons.color_lens, (value) {
                      setState(() => _selectedColour = value!);
                    }),
                    const SizedBox(height: 15),
                    _buildTextField(_ageController, 'Age', Icons.cake, hint: 'Enter your age', isNumber: true),
                    const SizedBox(height: 15),
                    _buildTextField(_cityController, 'City', Icons.location_city, hint: 'Enter your city'),
                    const SizedBox(height: 15),
                    _buildTextField(_professionController, 'Profession', Icons.work, hint: 'Enter your profession'),
                    const SizedBox(height: 15),
                    _buildDropdown('Gender', _selectedGender, _genders, Icons.people, (value) {
                      setState(() => _selectedGender = value!);
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Container(
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
                      'Rate Our App',
                      Icons.star,
                      const Color(0xFFFFD54F),
                      _rateApp,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8AAAE5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, 
      {bool isEmail = false, bool isNumber = false, String hint = ''}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF8AAAE5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8AAAE5)),
        ),
      ),
      keyboardType: isEmail ? TextInputType.emailAddress : isNumber ? TextInputType.number : TextInputType.text,
      validator: (value) {
        if (isEmail && value!.isNotEmpty && !value.contains('@')) {
          return 'Please enter a valid email';
        }
        return null; // All fields are optional
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, IconData icon, ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8AAAE5)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8AAAE5)),
        ),
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
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