import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
  );
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _signupEmailController = TextEditingController();
  final TextEditingController _signupPasswordController = TextEditingController();
  final TextEditingController _signupConfirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureSignupConfirmPassword = true;
  bool _showSignup = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    User? user = _auth.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToHome();
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _signupEmailController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    try {
      final UserCredential user = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user.user != null) {
        print('✅ Logged in: ${user.user!.email}');
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login failed";
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = "No user found with this email";
          break;
        case 'wrong-password':
          errorMessage = "Incorrect password";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled";
          break;
        case 'too-many-requests':
          errorMessage = "Too many attempts. Try again later";
          break;
        default:
          errorMessage = e.message ?? "Login failed";
      }
      
      _showError(errorMessage);
    } catch (e) {
      _showError("An unexpected error occurred");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    if (_signupPasswordController.text != _signupConfirmPasswordController.text) {
      _showError("Passwords don't match");
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final UserCredential user = await _auth.createUserWithEmailAndPassword(
        email: _signupEmailController.text.trim(),
        password: _signupPasswordController.text.trim(),
      );

      if (user.user != null) {
        print('✅ Signed up: ${user.user!.email}');
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Sign up failed";
      
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = "Email already in use";
          break;
        case 'weak-password':
          errorMessage = "Password is too weak";
          break;
        case 'invalid-email':
          errorMessage = "Invalid email address";
          break;
        default:
          errorMessage = e.message ?? "Sign up failed";
      }
      
      _showError(errorMessage);
    } catch (e) {
      _showError("An unexpected error occurred");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      // First try to sign in silently (if user was previously signed in)
      GoogleSignInAccount? googleUser = await _googleSignIn.signInSilently();
      
      // If silent sign-in fails, show the account picker
      if (googleUser == null) {
        googleUser = await _googleSignIn.signIn();
      }

      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Verify we have both tokens
      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        throw Exception("Google authentication failed - missing tokens");
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential user = await _auth.signInWithCredential(credential);

      if (user.user != null) {
        print('✅ Google sign-in successful: ${user.user!.displayName}');
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      
      String errorMessage = "Google sign-in failed";
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage = "Account already exists with different sign-in method";
          break;
        case 'invalid-credential':
          errorMessage = "Invalid credentials provided";
          break;
        case 'operation-not-allowed':
          errorMessage = "Google sign-in is not enabled";
          break;
        case 'user-disabled':
          errorMessage = "This account has been disabled";
          break;
        case 'user-not-found':
          errorMessage = "No user found with these credentials";
          break;
        default:
          errorMessage = e.message ?? "Google sign-in failed";
      }
      
      _showError(errorMessage);
    } catch (e) {
      print('Google Sign-In Error: $e');
      _showError("Google sign-in failed. Please try again.");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomePage())
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  void _toggleSignupPasswordVisibility() {
    setState(() {
      _obscureSignupPassword = !_obscureSignupPassword;
    });
  }

  void _toggleSignupConfirmPasswordVisibility() {
    setState(() {
      _obscureSignupConfirmPassword = !_obscureSignupConfirmPassword;
    });
  }

  void _toggleSignup() {
    setState(() {
      _showSignup = !_showSignup;
      // Clear form when switching modes
      if (_showSignup) {
        _emailController.clear();
        _passwordController.clear();
      } else {
        _signupEmailController.clear();
        _signupPasswordController.clear();
        _signupConfirmPasswordController.clear();
      }
    });
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: "Email",
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return "Please enter your email";
              if (!_isValidEmail(value)) return "Please enter a valid email";
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: "Password",
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                onPressed: _togglePasswordVisibility,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            obscureText: _obscurePassword,
            validator: (value) {
              if (value == null || value.isEmpty) return "Please enter your password";
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _loginWithEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8AAAE5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Login", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _signupEmailController,
            decoration: InputDecoration(
              labelText: "Email",
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return "Please enter your email";
              if (!_isValidEmail(value)) return "Please enter a valid email";
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupPasswordController,
            decoration: InputDecoration(
              labelText: "Password",
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureSignupPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: _toggleSignupPasswordVisibility,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            obscureText: _obscureSignupPassword,
            validator: (value) {
              if (value == null || value.isEmpty) return "Please enter a password";
              if (value.length < 6) return "Password must be at least 6 characters";
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _signupConfirmPasswordController,
            decoration: InputDecoration(
              labelText: "Confirm Password",
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(_obscureSignupConfirmPassword ? Icons.visibility : Icons.visibility_off),
                onPressed: _toggleSignupConfirmPasswordVisibility,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
            obscureText: _obscureSignupConfirmPassword,
            validator: (value) {
              if (value == null || value.isEmpty) return "Please confirm your password";
              if (value != _signupPasswordController.text) return "Passwords don't match";
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signUpWithEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8AAAE5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text("Sign Up", style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 12)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF8AAAE5),
                  child: Icon(Icons.color_lens, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text("Colour Walk", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF8AAAE5))),
                const SizedBox(height: 8),
                Text(_showSignup ? "Create your account" : "Sign in to continue", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 24),
                
                // Login or Signup Form
                _showSignup ? _buildSignupForm() : _buildLoginForm(),
                
                const SizedBox(height: 16),
                
                // OR Divider
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("OR", style: TextStyle(color: Colors.grey[600]))),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ]),
                const SizedBox(height: 16),
                
                // Google Sign-In
                SizedBox(
                  width: double.infinity,
                  child: SignInButton(
                    Buttons.Google,
                    onPressed: _isLoading ? null : _loginWithGoogle,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Toggle between Login/Signup
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_showSignup ? "Already have an account?" : "Don't have an account?"),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleSignup,
                    child: Text(_showSignup ? "Login" : "Sign Up", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8AAAE5))),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}