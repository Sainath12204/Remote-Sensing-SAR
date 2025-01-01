import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:remote_sensing/pages/registration_page.dart';
import 'package:remote_sensing/pages/home_page.dart';
import 'package:remote_sensing/widgets/toast.dart'; // Adjust the import path as needed
import 'package:remote_sensing/services/auth_service.dart'; // Adjust the import path as needed

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService(); // Instance of AuthService
  bool _obscurePassword = true; // For toggling password visibility

  Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    if (password.length < 6) {
      Toast.show(context, 'Password must be at least 6 characters long', ToastType.info);
      return;
    }

    try {
      // Call the login method from AuthService
      UserCredential? userCredential =
          await _authService.login(username: username, password: password);

      if (userCredential == null) {
        // Show a toast message if the userCredential is null
        Toast.show(context, 'An error occurred. Please try again.', ToastType.error);
        return;
      }

      // Redirect to HomePage after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomePage(user: userCredential.user!, username: username),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase authentication errors
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that username.';
          break;
        case 'invalid-credential':
          errorMessage = 'Incorrect password. Please try again.';
          break;
        default:
          errorMessage =
              'An unexpected error occurred. Please try again later.';
      }

      // Show a toast message for the error
      Toast.show(context, errorMessage, ToastType.error);
    } catch (e) {
      // Handle any other exceptions
      Toast.show(context, 'An error occurred. Please try again.', ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login Page"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 70), // Space at the top
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Username',
                    hintText: 'Enter your username',
                  ),
                ),
              ),
              const SizedBox(
                  height: 15), // Space between email and password fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // Controlled by the toggle
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
              const SizedBox(height: 15), // Space before the login button
              FilledButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
              const SizedBox(height: 30), // Space after the login button
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegistrationPage()),
                  );
                },
                child: const Text('New User? Create Account'),
              ),
              const SizedBox(height: 50), // Space at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
