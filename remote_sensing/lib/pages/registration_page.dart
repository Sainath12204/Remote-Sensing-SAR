import 'package:flutter/material.dart';
import 'package:remote_sensing/services/auth_service.dart'; // Import your auth service
import 'package:remote_sensing/widgets/toast.dart'; // Import the Toast widget
import 'package:remote_sensing/pages/otp_verification_page.dart'; // Import the OTPVerificationPage widget
import 'package:remote_sensing/services/database_service.dart'; // Import Firestore service

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // Instances of services
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // State variables
  bool _obscurePassword = true; // For toggling password visibility
  String? _usernameError =
      'Username cannot be empty.'; // Error message for username validation
  String? _emailError =
      'Email cannot be empty.'; // Error message for email validation

  // Async validation for email
  Future<String?> _validateEmail(String? email) async {
    if (email == null || email.isEmpty) {
      return 'Email cannot be empty.';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');
    if (!emailRegex.hasMatch(email)) {
      return 'Invalid email format. Use xyz@gmail.com';
    }
    bool emailExists = await _firestoreService.isEmailUsed(email);
    if (emailExists) {
      return 'Email already in use. Please choose another one.';
    }
    return null;
  }

  // Async validation for username
  Future<String?> _validateUsername(String? username) async {
    if (username == null || username.isEmpty) {
      return 'Username cannot be empty.';
    }
    bool usernameExists = await _firestoreService.isUsernameUsed(username);
    if (usernameExists) {
      return 'Username already in use. Please choose another one.';
    }
    return null;
  }

  // Synchronous validation for password
  String? _validatePassword(String? password) {
    if (password == null || password.length < 6) {
      return 'Password must be at least 6 characters long.';
    }
    return null;
  }

  // Synchronous validation for name
  String? _validateName(String? name) {
    if (name == null || name.isEmpty) {
      return 'Name cannot be empty.';
    }
    return null;
  }

  // Registration function
  Future<void> _register() async {
    _usernameError = await _validateUsername(_usernameController.text);
    _emailError = await _validateEmail(_emailController.text);
    setState(() {}); // Update the UI to reflect validation result

    // Check if the form is valid
    if (_formKey.currentState!.validate()) {
      // Send OTP to the provided email
      bool emailOtpSent =
          await _authService.sendEmailOtp(_emailController.text);

      if (emailOtpSent) {
        // Show success toast and navigate to OTP verification page
        Toast.show(
          context,
          "OTP sent successfully to your email. Please check your inbox.",
          ToastType.success,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              email: _emailController.text,
              name: _nameController.text,
              username: _usernameController.text,
              password: _passwordController.text,
            ),
          ),
        );
      } else {
        // Show error toast if OTP sending fails
        Toast.show(
          context,
          "Failed to send OTP. Please ensure the email is correct and try again.",
          ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Unfocus all text fields when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Registration Page"),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(height: 40),
                  // Name field
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Name',
                        hintText: 'Enter your full name',
                      ),
                      validator: _validateName,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Username field
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Username',
                        hintText: 'Choose a username',
                      ),
                      validator: (value) => _usernameError,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Email field
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Email',
                        hintText: 'Enter valid email id as abc@gmail.com',
                      ),
                      validator: (value) => _emailError,
                    ),
                  ),
                  const SizedBox(height: 15),
                  // Password field
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'Password',
                        hintText: 'Enter secure password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Register button
                  FilledButton(
                    onPressed: _register,
                    child: const Text('Register'),
                  ),
                  const SizedBox(height: 30),
                  // Login navigation button
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Already have an account? Login'),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
