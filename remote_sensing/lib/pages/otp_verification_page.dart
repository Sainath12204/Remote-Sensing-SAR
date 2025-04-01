import 'package:flutter/material.dart';
import 'package:remote_sensing/services/auth_service.dart'; // Import the auth service for registering the user
import 'package:remote_sensing/widgets/toast.dart'; // Custom toast widget
import 'package:firebase_auth/firebase_auth.dart'; // For User class
import 'package:remote_sensing/pages/home_page.dart'; // Import the HomePage widget

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final String name;
  final String username;
  final String password;

  const OTPVerificationPage({
    super.key,
    required this.email,
    required this.name,
    required this.username,
    required this.password,
  });

  @override
  OTPVerificationPageState createState() => OTPVerificationPageState();
}

class OTPVerificationPageState extends State<OTPVerificationPage> {
  final TextEditingController _emailOtpController = TextEditingController();
  final AuthService _authService = AuthService(); // Instance of AuthService

  bool _isEmailVerified =
      false; // State variable to track email OTP verification

  // Function to verify the OTP entered by the user
  Future<void> _verifyOTP() async {
    // Verify email OTP
    _isEmailVerified = _authService.verifyEmailOtp(_emailOtpController.text);

    if (_isEmailVerified) {
      // If OTP is verified, show success toast
      Toast.show(
          context, 'Email OTP verified successfully.', ToastType.success);

      // Register the user
      User? user = await _authService.registerUser(
        email: widget.email,
        password: widget.password,
        name: widget.name,
        username: widget.username,
      );

      if (user != null) {
        // If user registration is successful, show success toast
        Toast.show(context, 'User registered successfully.', ToastType.success);

        // Navigate to the homepage and clear the navigation stack
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              user: user, // Pass the User object
              username: widget.username, // Pass the username
            ),
          ),
          (Route<dynamic> route) => false, // Remove all previous routes
        );
      }
    } else {
      // If OTP verification fails, show error toast
      Toast.show(context, 'Failed to verify Email OTP. Please try again.',
          ToastType.error);
    }
  }

  // Function to resend the OTP to the user's email
  Future<void> _resendOtps() async {
    // Send Email OTP and check if it was successful
    bool emailOtpSent = await _authService.sendEmailOtp(widget.email);

    // Show appropriate toast messages based on OTP send results
    if (emailOtpSent) {
      Toast.show(
          context, 'OTP sent to your email successfully.', ToastType.success);
    } else {
      Toast.show(context, 'Failed to send OTP to your email. Please try again.',
          ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Enter the OTP sent to your registered email address.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Input field for entering the OTP
            TextField(
              controller: _emailOtpController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Email OTP',
                hintText: 'Enter the OTP received in your email',
              ),
            ),
            const SizedBox(height: 20),
            // Button to verify the OTP
            FilledButton(
              onPressed: _verifyOTP,
              child: const Text('Verify OTP'),
            ),
            const SizedBox(height: 20),
            // Button to resend the OTP
            TextButton(
              onPressed: () async {
                await _resendOtps();
              },
              child: const Text('Resend OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
