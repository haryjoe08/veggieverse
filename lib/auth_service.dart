import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getCurrentUserRole() async {
    try {
      User? user = _auth.currentUser;
      print('Current user: ${user?.uid}');
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        print('Firestore document exists: ${doc.exists}');
        if (doc.exists) {
          String? role = doc.get('role') as String?;
          print('User role: $role');
          return role;
        } else {
          print('User document does not exist in Firestore');
          return null;
        }
      }
    } catch (e) {
      print('Error in getCurrentUserRole: $e');
    }
    return null;
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      print('Attempting to sign in with email: $email');
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Sign in successful for user: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during sign in: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error during sign in: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}