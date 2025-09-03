// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Per FirebaseAuthException
import '../services/auth_service.dart';
// Non importiamo UserProvider qui se non lo usiamo direttamente per setUser
// Non importiamo MainGameScreen qui se non navighiamo esplicitamente

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _loginUser() async {
    // Semplice validazione per campi vuoti
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Per favore, inserisci email e password.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      // signInWithEmailPassword ora potrebbe rilanciare un'eccezione
      // o restituire null come nel tuo AuthService originale.
      // Adattiamo per gestire entrambi i casi (preferendo l'eccezione per info dettagliate)
      final user = await authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Se signInWithEmailPassword restituisce null in caso di errore (come il tuo AuthService attuale)
      if (user == null && mounted) { // Aggiunto controllo "mounted"
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante il login. Controlla le credenziali.')),
        );
      }
      // Se il login ha successo (user non è null), AuthWrapper gestirà la navigazione.
      // Non è necessario fare altro qui. Lo stato _isLoading verrà gestito nel finally.

    } on FirebaseAuthException catch (e) {
      // Questo blocco verrà eseguito se AuthService rilancia FirebaseAuthException
      String message = 'Si è verificato un errore.';
      if (e.code == 'user-not-found') {
        message = 'Nessun utente trovato per questa email.';
      } else if (e.code == 'wrong-password') {
        message = 'Password errata.';
      } else if (e.code == 'invalid-email') {
        message = 'L\'indirizzo email non è valido.';
      } else {
        message = e.message ?? 'Errore sconosciuto.'; // Messaggio di fallback dall'eccezione
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      // Catch per altri errori generici o se signInWithEmailPassword lancia un errore non FirebaseAuthException
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login fallito: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Il tuo layout è già buono, lo mantengo.
    // Ho solo rimosso UserProvider se non strettamente necessario qui.
    // final authService = Provider.of<AuthService>(context); // Non serve qui se usi listen:false in _loginUser

    return Scaffold(
      appBar: AppBar(title: const Text('Login - HydroFarm Tycoon')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch, // Aggiunto per ElevatedButton
          children: [
            // Potresti aggiungere un titolo carino
            const Text(
              'Accedi al tuo Impero Idroponico!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15), // Ridotto spazio
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 25), // Ridotto spazio
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                // backgroundColor: Colors.green, // Colore primario del tema
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: _loginUser, // Chiamata al metodo di login
              child: const Text('LOGIN'),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                // Naviga alla schermata di registrazione usando le named routes definite in main.dart
                Navigator.pushNamed(context, '/register');
              },
              child: const Text('Non hai un account? Registrati ora'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
