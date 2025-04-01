import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_otp/email_otp.dart';
import 'package:remote_sensing/services/database_service.dart'; // Import Firestore service
import 'dart:async';

class AuthService {
  // Private constructor
  AuthService._privateConstructor();

  // Static instance of AuthService
  static final AuthService _instance = AuthService._privateConstructor();

  // Factory method to return the same instance
  factory AuthService() {
    return _instance;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService =
      FirestoreService(); // Instance of Firestore service
  bool emailOtpSent = false; // Flag for email OTP sent
  bool emailVerified = false; // Flag for email OTP verified

  // Function to send OTP to email
  Future<bool> sendEmailOtp(String email) async {
    emailOtpSent = await EmailOTP.sendOTP(email: email);
    return emailOtpSent;
  }

  // Function to verify email OTP
  bool verifyEmailOtp(String otp) {
    emailVerified = EmailOTP.verifyOTP(otp: otp);
    return emailVerified;
  }

  Future<User?> registerUser({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestoreService.createUser(
      userCredential.user!.uid,
      email,
      username,
      name,
    );

    userCredential.user?.updateDisplayName(username);

    return userCredential.user; // Return the User object at the end
  }

  // Function to log in a user with username and password
  Future<UserCredential?> login({
    required String username,
    required String password,
  }) async {
    Map<String, dynamic>? userData =
        await _firestoreService.getUserByUsername(username);

    if (userData == null) {
      throw FirebaseAuthException(
          message: 'User not found', code: 'user-not-found');
    }

    String email = userData['email'];

    UserCredential user = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update the lastLogin field in Firestore
    _firestoreService.updateLastLogin(user.user!.uid);

    return user;
  }
}
