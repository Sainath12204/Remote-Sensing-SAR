import 'package:flutter/material.dart';
import 'package:remote_sensing/services/auth_service.dart'; // Import the auth service for registering the user
import 'package:remote_sensing/widgets/toast.dart'; // Custom toast widget
import 'package:firebase_auth/firebase_auth.dart'; // For User class
import 'dart:developer' as developer;
import 'package:remote_sensing/pages/home_page.dart'; // Import the HomePage widget

class OTPVerificationPage extends StatefulWidget {
  final String email;
  final String phone;
  final String name;
  final String username;
  final String password;

  const OTPVerificationPage({
    super.key,
    required this.email,
    required this.phone,
    required this.name,
    required this.username,
    required this.password,
  });

  @override
  OTPVerificationPageState createState() => OTPVerificationPageState();
}

class OTPVerificationPageState extends State<OTPVerificationPage> {
  final TextEditingController _emailOtpController = TextEditingController();
  final TextEditingController _phoneOtpController = TextEditingController();
  final AuthService _authService = AuthService(); // Instance of AuthService

  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;

  Future<void> _verifyOTP() async {
    // Verify email OTP
    _isEmailVerified = _authService.verifyEmailOtp(_emailOtpController.text);

    // Verify phone OTP
    _isPhoneVerified = _authService.verifyPhoneOtp(_phoneOtpController.text);
    developer.log(
        'Email OTP verified: $_isEmailVerified , otp: ${_emailOtpController.text}');

    // Handle the combinations of email and phone OTP verification
    if (_isEmailVerified && _isPhoneVerified) {
      // Both OTPs are verified
      Toast.show(context, 'Both email and phone OTPs verified');

      // Register the user
      User? user = await _authService.registerUser(
        email: widget.email,
        password: widget.password,
        phoneNumber: widget.phone,
        name: widget.name,
        username: widget.username,
      );

      if (user != null) {
        Toast.show(context, 'User registered successfully');

        // Navigate to the homepage and clear the navigation stack
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
    } else if (_isEmailVerified && !_isPhoneVerified) {
      // Email OTP is verified, but phone OTP is not
      Toast.show(context, 'Email OTP verified, but phone OTP is invalid');
    } else if (!_isEmailVerified && _isPhoneVerified) {
      // Phone OTP is verified, but email OTP is not
      Toast.show(context, 'Phone OTP verified, but email OTP is invalid');
    } else {
      // Neither OTP is verified
      Toast.show(context, 'Both email and phone OTPs are invalid');
    }
  }

  // The _resendOtps function
  Future<void> _resendOtps() async {
    // Send Email OTP and check if it was successful
    bool emailOtpSent = await _authService.sendEmailOtp(widget.email);

    // Send Phone OTP and check if it was successful
    bool phoneOtpSent = await _authService.sendPhoneOtp(widget.phone);

    // Show appropriate toast messages based on OTP send results
    if (emailOtpSent && phoneOtpSent) {
      Toast.show(context, 'Both Email and Phone OTPs sent successfully');
    } else if (emailOtpSent && !phoneOtpSent) {
      Toast.show(
          context, 'Email OTP sent successfully, but failed to send Phone OTP');
    } else if (!emailOtpSent && phoneOtpSent) {
      Toast.show(
          context, 'Phone OTP sent successfully, but failed to send Email OTP');
    } else {
      Toast.show(context, 'Failed to send both Email and Phone OTPs');
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
              'Enter the OTPs sent to your email and phone',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _emailOtpController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Email OTP',
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _phoneOtpController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter Phone OTP',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _verifyOTP,
              child: const Text('Verify OTPs'),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                await _resendOtps();
              },
              child: const Text('Resend OTPs'),
            ),
          ],
        ),
      ),
    );
  }
}
