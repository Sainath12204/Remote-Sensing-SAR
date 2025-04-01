import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Method to create a user
  Future<bool> createUser(
      String uid, String email, String username, String name) async {
    try {
      await _db.collection('users').doc(uid).set({
        'email': email,
        'username': username,
        'name': name,
        'createdAt': DateTime.now(),
        'lastLogin': DateTime.now(), // Can update this on login
      });
      return true; // Return true if user is successfully created
    } catch (e) {
      return false; // Return false if there was an error
    }
  }

  // Method to check if a username is already used
  Future<bool> isUsernameUsed(String username) async {
    final QuerySnapshot queryResult = await _db
        .collection('users')
        .where('username', isEqualTo: username)
        .get();

    return queryResult.docs.isNotEmpty; // Returns true if username exists
  }

  // Method to check if an email is already used
  Future<bool> isEmailUsed(String email) async {
    final QuerySnapshot queryResult =
        await _db.collection('users').where('email', isEqualTo: email).get();

    return queryResult.docs.isNotEmpty; // Returns true if email exists
  }

  // Method to get user data by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      QuerySnapshot querySnapshot = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data() as Map<String, dynamic>;
      }
    } catch (e) {
      return null;
    }
    return null; // Return null if no user is found or if an error occurs
  }

  Future<void> updateLastLogin(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'lastLogin': DateTime.now(),
      });
    } catch (e) {
      return;
    }
  }

  // Method to delete a user
  Future<bool> deleteUser(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
      return true; // Return true if user is successfully deleted
    } catch (e) {
      return false; // Return false if there was an error
    }
  }
}
