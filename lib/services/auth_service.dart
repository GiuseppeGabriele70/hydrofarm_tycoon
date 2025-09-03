// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  // Rinominiamo _auth in _firebaseAuth per coerenza e per evitare confusioni
  // se ci fossero altre variabili chiamate _auth in altri contesti.
  // Sarà final perché assegnata nel costruttore e non più cambiata.
  final FirebaseAuth _firebaseAuth;

  // Costruttore che accetta un'istanza di FirebaseAuth.
  // Questo permette di passare FirebaseAuth.instance da dove AuthService viene creato.
  AuthService(this._firebaseAuth);

  // Lo stream per ascoltare i cambiamenti dello stato di autenticazione.
  // Ora usa l'istanza _firebaseAuth passata al costruttore.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Metodo per il login con email e password
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) { // È buona pratica specificare il tipo di eccezione
      print('AuthService Error - signInWithEmailPassword: ${e.code} - ${e.message}');
      // Potresti voler ritornare e.code o un messaggio più user-friendly
      // a seconda di come vuoi gestire gli errori nella UI.
      return null;
    } catch (e) { // Catch generico per altri errori imprevisti
      print('AuthService Error - signInWithEmailPassword (Generic): $e');
      return null;
    }
  }

  // Metodo per la registrazione con email e password
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // NON creiamo il documento utente qui.
      // Questa responsabilità è stata spostata a UserProvider,
      // chiamato tramite AuthWrapper dopo che questo metodo ha successo.
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('AuthService Error - registerWithEmailAndPassword: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('AuthService Error - registerWithEmailAndPassword (Generic): $e');
      return null;
    }
  }

  // Metodo per effettuare il logout
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      print('AuthService: Utente disconnesso con successo.');
    } catch (e) {
      print('AuthService Error - signOut: $e');
      // Anche qui, considera come gestire l'errore se il logout fallisce.
    }
  }

// Potresti aggiungere un metodo per ottenere l'utente corrente, se necessario,
// anche se spesso lo stream authStateChanges è sufficiente per la UI.
// User? getCurrentUser() {
//   return _firebaseAuth.currentUser;
// }
}

