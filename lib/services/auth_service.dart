import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Web Client ID iz google-services.json (client_type: 3)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '110517099884-dvt7ndjtps59n3uhhpvav20cukcd5vfr.apps.googleusercontent.com',
  );

  // Trenutni uporabnik
  User? get currentUser => _auth.currentUser;

  // Stream za spremljanje stanja avtentikacije
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Prijava z email in geslom
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Registracija z email in geslom
  Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Prijava z Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Odjavi prejšnjo sejo če obstaja
      await _googleSignIn.signOut();
      
      // Začni Google prijavo
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Uporabnik je preklical prijavo
        return null;
      }

      // Pridobi avtentikacijske podatke
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Preveri ali imamo potrebne tokene
      if (googleAuth.idToken == null) {
        throw AuthException('Ni bilo mogoče pridobiti ID tokena. Preverite konfiguracijo.');
      }

      // Ustvari Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Prijavi se v Firebase
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Napaka pri Google prijavi: $e');
    }
  }

  // Ponastavitev gesla
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Odjava
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Obdelava Firebase napak
  AuthException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return AuthException('Uporabnik s tem emailom ne obstaja.');
      case 'wrong-password':
        return AuthException('Napačno geslo.');
      case 'email-already-in-use':
        return AuthException('Email je že v uporabi.');
      case 'weak-password':
        return AuthException('Geslo je prešibko. Uporabite vsaj 6 znakov.');
      case 'invalid-email':
        return AuthException('Neveljaven email naslov.');
      case 'user-disabled':
        return AuthException('Ta račun je onemogočen.');
      case 'too-many-requests':
        return AuthException('Preveč poskusov. Počakajte nekaj minut.');
      case 'invalid-credential':
        return AuthException('Napačni prijavni podatki.');
      default:
        return AuthException('Napaka: ${e.message ?? e.code}');
    }
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
