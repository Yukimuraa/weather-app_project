import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthService extends ChangeNotifier {
  static const String noInternetMessage =
      'Please check your internet connection and try again.';
  FirebaseAuth? _auth;
  GoogleSignIn? _googleSignIn;
  Stream<User?>? _authStateStream;

  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn();
    return _googleSignIn!;
  }

  FirebaseAuth? get authOrNull {
    if (_auth != null) {
      return _auth!;
    }
    try {
      // Check if Firebase is initialized - this might throw on web
      final apps = Firebase.apps;
      if (apps.isEmpty) {
        return null;
      }
      _auth = FirebaseAuth.instance;
      // Set up listener once auth is initialized
      _setupAuthListener();
      return _auth!;
    } catch (e) {
      // Firebase not initialized or error accessing it
      return null;
    }
  }

  Stream<User?>? get authStateChanges {
    if (_authStateStream != null) {
      return _authStateStream;
    }
    final auth = authOrNull;
    if (auth != null) {
      _authStateStream = auth.authStateChanges();
      return _authStateStream;
    }
    return null;
  }

  FirebaseAuth get auth {
    final authInstance = authOrNull;
    if (authInstance == null) {
      throw StateError('Firebase is not initialized. Call Firebase.initializeApp() first.');
    }
    return authInstance;
  }

  User? get currentUser {
    try {
      final authInstance = authOrNull;
      return authInstance?.currentUser;
    } catch (e) {
      return null;
    }
  }

  bool get isAuthenticated {
    try {
      return currentUser != null;
    } catch (e) {
      return false;
    }
  }

  AuthService() {
    // Don't initialize anything here - everything is lazy-loaded
    // to prevent issues during hot reload
  }

  void _setupAuthListener() {
    try {
      if (_auth != null && _authStateStream == null) {
        // Check if Firebase is initialized before setting up listener
        final apps = Firebase.apps;
        if (apps.isNotEmpty) {
          _authStateStream = _auth!.authStateChanges();
          _authStateStream!.listen((User? user) {
            debugPrint('Auth state changed: ${user?.uid ?? 'null'}');
            notifyListeners();
          });
        }
      }
    } catch (e) {
      // Ignore errors during setup - will retry on next auth access
      debugPrint('Error setting up auth listener: $e');
    }
  }

  // Email and Password Sign Up
  Future<UserCredential?> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    final hasConnection = await checkInternetConnection();
    if (!hasConnection) {
      throw noInternetMessage;
    }

    try {
      final UserCredential userCredential =
          await auth
              .createUserWithEmailAndPassword(
                email: email.trim(),
                password: password,
              )
              .timeout(const Duration(seconds: 8), onTimeout: () {
        throw 'Sign up timed out. Please try again.';
      });

      // Send email verification
      await userCredential.user?.sendEmailVerification().timeout(
        const Duration(seconds: 5),
        onTimeout: () => null,
      );

      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // Email and Password Sign In
  Future<UserCredential?> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    // Check internet connection first (timeboxed)
    final hasConnection = await checkInternetConnection();
    if (!hasConnection) {
      throw noInternetMessage;
    }

    try {
      final UserCredential userCredential =
          await auth
              .signInWithEmailAndPassword(
                email: email.trim(),
                password: password,
              )
              .timeout(const Duration(seconds: 8), onTimeout: () {
        throw 'Login timed out. Please try again.';
      });
      debugPrint('Sign in successful: ${userCredential.user?.uid}');
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('network') || errorMessage.contains('connection')) {
        throw 'Network error. Please check your internet connection and retry the action.';
      }
      throw 'An unexpected error occurred: ${e.toString()}\n\nPlease check your internet connection and ensure correct login credentials.';
    }
  }

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    // Check internet connection first (timeboxed)
    final hasConnection = await checkInternetConnection();
    if (!hasConnection) {
      throw noInternetMessage;
    }

    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn
          .signIn()
          .timeout(const Duration(seconds: 10), onTimeout: () => null);

      if (googleUser == null) {
        // User canceled the sign-in or timed out
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication
              .timeout(const Duration(seconds: 8), onTimeout: () {
        throw 'Google authentication timed out. Please try again.';
      });

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final UserCredential userCredential = await auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 8), onTimeout: () {
        throw 'Login timed out. Please try again.';
      });

      debugPrint('Google sign in successful: ${userCredential.user?.uid}');
      notifyListeners();
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('network') || errorMessage.contains('connection')) {
        throw 'Network error. Please check your internet connection and retry the action.';
      }
      throw 'An unexpected error occurred: ${e.toString()}\n\nPlease check your internet connection and retry the action.';
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    final hasConnection = await checkInternetConnection();
    if (!hasConnection) {
      throw noInternetMessage;
    }

    try {
      await auth
          .sendPasswordResetEmail(email: email.trim())
          .timeout(const Duration(seconds: 6), onTimeout: () {
        throw 'Password reset timed out. Please try again.';
      });
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      // Prepare Firebase sign out with a timeout as a safeguard
      final authSignOut = auth
          .signOut()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      // Check Google sign-in state with a timeout to avoid hangs
      bool googleWasSignedIn = false;
      try {
        googleWasSignedIn = await googleSignIn
            .isSignedIn()
            .timeout(const Duration(seconds: 2), onTimeout: () => false);
      } catch (_) {
        googleWasSignedIn = false;
      }

      // If signed in with Google, attempt sign out with a short timeout
      Future<void>? googleSignOutFuture;
      if (googleWasSignedIn) {
        googleSignOutFuture = googleSignIn
            .signOut()
            .timeout(const Duration(seconds: 3), onTimeout: () => null)
            .catchError((_) => null);
      }

      // Wait for both, but do not fail if one is slow; we already timeboxed them
      if (googleSignOutFuture != null) {
        await Future.wait([
          authSignOut,
          googleSignOutFuture,
        ]);
      } else {
        await authSignOut;
      }

      notifyListeners();
    } catch (e) {
      throw 'Error signing out: ${e.toString()}';
    }
  }

  // Check internet connectivity
  Future<bool> checkInternetConnection() async {
    try {
      final List<ConnectivityResult> connectivityResult = await Connectivity()
          .checkConnectivity()
          .timeout(const Duration(seconds: 3), onTimeout: () => [ConnectivityResult.mobile]);
      return connectivityResult
          .any((result) => result != ConnectivityResult.none);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      return false;
    }
  }

  // Helper method to handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists for that email. Please use a different email or sign in instead.';
      case 'user-not-found':
        return 'The email or password you entered is incorrect. Please check your credentials and try again.';
      case 'wrong-password':
        return 'The email or password you entered is incorrect. Please check your credentials and try again.';
      case 'invalid-credential':
        return 'The email or password you entered is incorrect. Please check your credentials and try again.';
      case 'invalid-email':
        return 'The email address is invalid. Please enter a valid email address.';
      case 'user-disabled':
        return 'This user account has been disabled. Please contact support for assistance.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support for assistance.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and retry the action.';
      default:
        return '${e.message ?? 'An authentication error occurred.'}\n\nPlease check your internet connection and ensure correct login credentials.';
    }
  }
}
