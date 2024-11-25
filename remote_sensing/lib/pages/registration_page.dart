import 'package:flutter/material.dart';
import 'package:remote_sensing/services/auth_service.dart'; // Import your auth service
import 'package:remote_sensing/widgets/toast.dart'; // Import the Toast widget
import 'package:remote_sensing/pages/otp_verification_page.dart'; // Import the OTPVerificationPage widget

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  RegistrationPageState createState() => RegistrationPageState();
}

class RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  final AuthService _authService = AuthService(); // Instance of AuthService

  bool _obscurePassword = true; // For toggling password visibility
  bool _isEmailEntered = false;
  bool _isPhoneEntered = false;

  Future<void> _register() async {
    // Check that both email and phone are entered
    if (_isEmailEntered && _isPhoneEntered) {
      bool emailOtpSent =
          await _authService.sendEmailOtp(_emailController.text);
      bool phoneOtpSent =
          await _authService.sendPhoneOtp(_phoneController.text);

      // Navigate only if both OTPs were successfully sent
      if (emailOtpSent && phoneOtpSent) {
        Toast.show(context, "OTP sent successfully to email and phone.");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              email: _emailController.text,
              phone: _phoneController.text,
              name: _nameController.text,
              username: _usernameController.text,
              password: _passwordController.text,
            ),
          ),
        );
      } else {
        Toast.show(context, "Failed to send OTPs. Check your entered details and try again.");
      }
    } else {
      Toast.show(context, "Please enter both email and phone number.");
    }
  }

  void _onEmailChanged(String value) {
    setState(() {
      _isEmailEntered = value.isNotEmpty;
    });
  }

  void _onPhoneChanged(String value) {
    setState(() {
      _isPhoneEntered = value.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registration Page"),
        centerTitle: true,
      ),
      body: Center(
        // Centering the Column
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center vertically
            crossAxisAlignment:
                CrossAxisAlignment.center, // Center horizontally
            children: <Widget>[
              const SizedBox(height: 40), // Space at the top
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Name',
                    hintText: 'Enter your full name',
                  ),
                ),
              ),
              const SizedBox(
                  height: 15), // Space between name and username fields
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                    hintText: 'Choose a username',
                  ),
                ),
              ),
              const SizedBox(
                  height: 15), // Space between username and email fields
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: TextField(
                  controller: _emailController,
                  onChanged: _onEmailChanged,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                    hintText: 'Enter valid email id as abc@gmail.com',
                  ),
                ),
              ),
              const SizedBox(
                  height: 15), // Space between divider and phone fields
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: TextField(
                  controller: _phoneController,
                  onChanged: _onPhoneChanged,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Phone',
                    hintText: 'Enter your phone number',
                  ),
                ),
              ),
              const SizedBox(
                  height: 15), // Space between phone and password fields
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // Controlled by toggle
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
                          _obscurePassword =
                              !_obscurePassword; // Toggle visibility
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Space before the register button
              FilledButton(
                onPressed: _register,
                child: const Text('Register'),
              ),
              const SizedBox(height: 30), // Space after the register button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Already have an account? Login'),
              ),
              const SizedBox(height: 50), // Space at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
