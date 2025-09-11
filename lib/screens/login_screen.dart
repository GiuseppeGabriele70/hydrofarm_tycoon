import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'register_screen.dart'; // Assicurati che questo file esista

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
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Per favore, inserisci email e password.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.signInWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Errore durante il login. Controlla le credenziali.')),
        );
      }
      // Se il login ha successo, AuthWrapper gestirà la navigazione
    } on FirebaseAuthException catch (e) {
      String message = 'Si è verificato un errore.';
      if (e.code == 'user-not-found' || e.code == 'INVALID_LOGIN_CREDENTIALS') { // Aggiunto INVALID_LOGIN_CREDENTIALS
        message = 'Credenziali non valide. Controlla email e password.';
      } else if (e.code == 'wrong-password') { // Potrebbe non essere più usato con le nuove versioni di Firebase Auth
        message = 'Password errata.';
      } else if (e.code == 'invalid-email') {
        message = 'L\'indirizzo email non è valido.';
      } else {
        message = e.message ?? 'Errore sconosciuto durante il login.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
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

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login - HydroFarm Tycoon')),
      body: Center( // Aggiunto Center per mantenere il contenuto centrato verticalmente
        child: SingleChildScrollView( // Widget per rendere il contenuto scrollabile
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Mantiene la Column centrata se c'è spazio
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Accedi al tuo Impero Idroponico!',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
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
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 25),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: _loginUser,
                  child: const Text('LOGIN'),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: _navigateToRegister,
                  child: const Text('Non hai un account? Registrati ora'),
                ),
              ],
            ),
          ),
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
