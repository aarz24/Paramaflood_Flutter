import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthDomainException implements Exception {
  final String message;
  final String? email;
  const AuthDomainException(this.message, {this.email});

  @override
  String toString() => message;
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Whitelisted campus domains for Universitas Paramadina
  static const List<String> allowedDomains = [
    '@paramadina.ac.id',
    '@students.paramadina.ac.id',
  ];

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if the user is currently authenticated with a valid campus email
  bool get isAuthenticated {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;
    return isAllowedCampusEmail(user.email!);
  }

  /// Verify if the given email belongs to the Paramadina campus domain
  static bool isAllowedCampusEmail(String email) {
    final cleanEmail = email.trim().toLowerCase();
    return allowedDomains.any((domain) => cleanEmail.endsWith(domain.toLowerCase()));
  }

  /// Get formatted campus role based on email domain
  static String getCampusRole(String? email) {
    if (email == null) return 'Pengguna';
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.endsWith('@students.paramadina.ac.id')) {
      return 'Mahasiswa Paramadina';
    } else if (cleanEmail.endsWith('@paramadina.ac.id')) {
      return 'Dosen / Staf Akademik';
    }
    return 'Sivitas Akademika';
  }

  /// Sign in with Google and enforce Paramadina campus email domain restriction
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in dialog
        return null;
      }

      final email = googleUser.email;
      debugPrint('Google Sign-In attempted with: $email');

      // 2. Validate campus domain restriction
      if (!isAllowedCampusEmail(email)) {
        // Immediately disconnect & sign out to prevent unauthorized session
        await _googleSignIn.signOut();
        throw AuthDomainException(
          'Akses Ditolak: Email "$email" bukan akun resmi Universitas Paramadina. '
          'Silakan gunakan akun Google dengan domain @paramadina.ac.id atau @students.paramadina.ac.id.',
          email: email,
        );
      }

      // 3. Obtain authentication details from request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 4. Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Sign in to Firebase with the Google credentials
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final firebaseUser = userCredential.user;
      if (firebaseUser != null && !isAllowedCampusEmail(firebaseUser.email ?? '')) {
        await signOut();
        throw AuthDomainException(
          'Akses Ditolak: Domain akun tidak valid.',
          email: firebaseUser.email,
        );
      }

      debugPrint('Successfully authenticated campus user: ${firebaseUser?.email}');
      return firebaseUser;
    } on AuthDomainException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error: [${e.code}] ${e.message}');
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      debugPrint('Sign in unexpected error: $e');
      if (e is AuthDomainException) rethrow;
      throw Exception('Gagal melakukan login dengan Google: ${e.toString()}');
    }
  }

  /// Sign out from both Firebase and Google session
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      debugPrint('User successfully signed out.');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  static String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'Akun sudah terdaftar dengan metode masuk yang berbeda.';
      case 'invalid-credential':
        return 'Kredensial login tidak valid atau sudah kadaluarsa.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan oleh administrator.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Periksa koneksi Anda.';
      case 'operation-not-allowed':
        return 'Metode Google Sign-In belum diaktifkan di Firebase Console.';
      default:
        return e.message ?? 'Terjadi kesalahan saat otentikasi.';
    }
  }
}
