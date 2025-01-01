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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _usernameFocusNode = FocusNode();

  final AuthService _authService = AuthService(); // Instance of AuthService
  final FirestoreService _firestoreService =
      FirestoreService(); // Instance of Firestore service

  bool _obscurePassword = true; // For toggling password visibility
  final bool _isEmailEntered = false;
  final bool _isPhoneEntered = false;
  final bool _isUsernameEntered = false;
  bool _isEmailValid = true;
  bool _isPhoneValid = true;
  bool _isUsernameValid = true;
  bool _isPasswordValid = true;
  String _emailErrorText = '';
  String _phoneErrorText = '';

  @override
  void initState() {
    super.initState();

    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _checkEmail(_emailController.text);
      }
    });

    _phoneFocusNode.addListener(() {
      if (!_phoneFocusNode.hasFocus) {
        _checkPhone(_phoneController.text);
      }
    });

    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) {
        _checkUsername(_usernameController.text);
      }
    });

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        setState(() {
          _isPasswordValid = validatePassword(_passwordController.text);
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkEmail(String email) async {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@gmail\.com$');

    if(email.isEmpty){
      return;
    }
    
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _isEmailValid = false;
        _emailErrorText = 'Invalid email format. Use xyz@gmail.com';
      });
      return;
    }

    bool emailExists = await _firestoreService.isEmailUsed(email);
    setState(() {
      _isEmailValid = !emailExists;
      _emailErrorText =
          emailExists ? 'Email already in use. Please choose another one.' : '';
    });
  }

  Future<void> _checkPhone(String phone) async {
    final phoneRegex = RegExp(r'^\+91\d{10}$');

    if(phone.isEmpty){
      return;
    }

    if (!phoneRegex.hasMatch(phone)) {
      setState(() {
        _isPhoneValid = false;
        _phoneErrorText = 'Invalid phone number format. Use +91XXXXXXXXXX';
      });
      return;
    }

    bool phoneExists = await _firestoreService.isPhoneNumberUsed(phone);
    setState(() {
      _isPhoneValid = !phoneExists;
      _phoneErrorText = phoneExists
          ? 'Phone number already in use. Please choose another one.'
          : '';
    });
  }

  Future<void> _checkUsername(String username) async {
    bool usernameExists = await _firestoreService.isUsernameUsed(username);
    setState(() {
      _isUsernameValid = !usernameExists;
    });
  }

  bool validatePassword(String password) {
    return password.length >= 6;
  }

  Future<void> _register() async {
    // Check that both email and phone are entered and valid
    if (_isEmailEntered &&
        _isPhoneEntered &&
        _isUsernameEntered &&
        _isEmailValid &&
        _isPhoneValid &&
        _isUsernameValid) {
      bool emailOtpSent =
          await _authService.sendEmailOtp(_emailController.text);
      bool phoneOtpSent =
          await _authService.sendPhoneOtp(_phoneController.text);

      // Navigate only if both OTPs were successfully sent
      if (emailOtpSent && phoneOtpSent) {
        Toast.show(context, "OTP sent successfully to email and phone.", ToastType.success);
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
        Toast.show(context,
            "Failed to send OTPs. Check your entered details and try again.", ToastType.error);
      }
    } else {
      Toast.show(
          context, "Please enter valid email, phone number, and username.", ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _emailFocusNode.unfocus();
        _phoneFocusNode.unfocus();
        _passwordFocusNode.unfocus();
        _usernameFocusNode.unfocus();
      },
      child: Scaffold(
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
                    focusNode: _usernameFocusNode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Username',
                      hintText: 'Choose a username',
                      errorText: _isUsernameValid
                          ? null
                          : 'Username already in use. Please choose another one.',
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
                    focusNode: _emailFocusNode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Email',
                      hintText: 'Enter valid email id as abc@gmail.com',
                      errorText: _isEmailValid ? null : _emailErrorText,
                    ),
                  ),
                ),
                const SizedBox(
                    height: 15), // Space between email and phone fields
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  child: TextField(
                    controller: _phoneController,
                    focusNode: _phoneFocusNode,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Phone',
                      hintText: 'Enter your phone number as +91XXXXXXXXXX',
                      errorText: _isPhoneValid ? null : _phoneErrorText,
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
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword, // Controlled by toggle
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'Password',
                      hintText: 'Enter secure password',
                      errorText: _isPasswordValid
                          ? null
                          : 'Password must be at least 6 characters long',
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
                  onPressed: _isEmailValid &&
                          _isPhoneValid &&
                          _isUsernameValid &&
                          _isPasswordValid
                      ? _register
                      : null,
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
      ),
    );
  }
}
