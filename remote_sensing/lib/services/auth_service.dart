import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_otp/email_otp.dart';
import 'package:remote_sensing/services/database_service.dart'; // Import Firestore service
import 'dart:developer' as developer;

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
  String? _verificationId; // Store verification ID for phone OTP
  PhoneAuthCredential? phoneCredential; // Store the phone credential
  bool emailOtpSent = false; // Flag for email OTP sent
  bool phoneOtpSent = false; // Flag for phone OTP sent
  bool emailVerified = false; // Flag for email OTP verified
  bool phoneVerified = false; // Flag for phone OTP verified

  // Function to send OTP to email
  Future<bool> sendEmailOtp(String email) async {
    emailOtpSent = await EmailOTP.sendOTP(email: email);
    return emailOtpSent;
  }

  // Function to send OTP to phone
  Future<bool> sendPhoneOtp(String phone) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          phoneVerified = false;
          throw FirebaseAuthException(
              message: 'Invalid phone number', code: e.code);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          phoneOtpSent = true;
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
      return true;
    } on Exception catch (e) {
      developer.log('Error sending phone OTP: $e');
      return false;
    }
  }

  // Function to verify email OTP
  bool verifyEmailOtp(String otp) {
    emailVerified = EmailOTP.verifyOTP(otp: otp);
    return emailVerified;
  }

  // Function to verify phone OTP
  bool verifyPhoneOtp(String otp) {
    try {
      phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      phoneVerified = true;
      return true;
    } on Exception catch (e) {
      developer.log('Error verifying phone OTP: $e');
      return false;
    }
  }

Future<User?> registerUser({
  required String email,
  required String password,
  required String name,
  required String phoneNumber,
  required String username,
}) async {
  UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
    email: email,
    password: password,
  );

  if (phoneVerified && phoneCredential != null) {
    await userCredential.user?.linkWithCredential(phoneCredential!);
  }

  await _firestoreService.createUser(
    userCredential.user!.uid,
    email,
    phoneNumber,
    username,
    name,
  );

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

    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
