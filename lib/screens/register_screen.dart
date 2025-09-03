// lib/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Per FirebaseAuthException
import '../services/auth_service.dart';
// Non importiamo DatabaseService qui se la creazione dati è gestita da UserProvider
// Non importiamo UserProvider qui se non lo usiamo direttamente

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _registerUser() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Per favore, compila tutti i campi.')),
        );
      }
      return;
    }

    if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le password non coincidono.')),
        );
      }
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La password deve contenere almeno 6 caratteri.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.registerWithEmailPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Se la registrazione ha successo (user non è null),
      // Firebase effettua il login automatico.
      // AuthWrapper rileverà questo, chiamerà initializeUserBaseData
      // e poi loadAndSetPersistentUserData in UserProvider.
      // È loadAndSetPersistentUserData che dovrebbe occuparsi di creare il record
      // in Firestore se non esiste.

      if (user != null && mounted) {
        // Registrazione Firebase riuscita.
        // Non è necessario chiamare DatabaseService.createUserData qui.
        // AuthWrapper e UserProvider se ne occuperanno.
        Navigator.pop(context); // Torna indietro
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registrazione avvenuta con successo!')),
        );
      } else if (user == null && mounted) {
        // Se AuthService.registerWithEmailPassword restituisce null in caso di errore
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore durante la registrazione. Riprova.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Si è verificato un errore.';
      if (e.code == 'weak-password') {
        message = 'La password fornita è troppo debole.';
      } else if (e.code == 'email-already-in-use') {
        message = 'L\'account esiste già per questa email.';
      } else if (e.code == 'invalid-email') {
        message = 'L\'indirizzo email non è valido.';
      } else {
        message = e.message ?? 'Errore sconosciuto durante la registrazione.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registrazione fallita: ${e.toString()}')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Registrazione - HydroFarm Tycoon')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Crea il Tuo Account Idroponico',
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
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password (min. 6 caratteri)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Conferma Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: _registerUser,
              child: const Text('REGISTRATI'),
            ),
            const SizedBox(height: 15),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Torna alla schermata di login
              },
              child: const Text('Hai già un account? Accedi'),
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
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

