import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import corretto per il tuo progetto
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/main_game_screen.dart';
import 'screens/lista_serre_screen.dart'; // <-- IMPORT
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseApp app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('----------------------------------------------------------------------');
  print('>>> FIREBASE DEBUG: Initialized Firebase App Name: ${app.name}');
  print('>>> FIREBASE DEBUG: Project ID: ${app.options.projectId}');
  print('----------------------------------------------------------------------');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        Provider<AuthService>(create: (_) => AuthService(FirebaseAuth.instance)),
        ProxyProvider<UserProvider, DatabaseService?>(
          update: (context, userProvider, previousDbService) {
            final uid = userProvider.user?.uid;
            if (uid == null) return null;
            if (previousDbService == null || previousDbService.uid != uid) {
              return DatabaseService(uid: uid);
            }
            return previousDbService;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HydroFarm Tycoon',
      theme: ThemeData(primarySwatch: Colors.green),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/main': (context) => const MainGameScreen(),
        '/serre': (context) => const ListaSerreScreen(), // <-- TEST VERSIONE SEMPLICE
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Errore di autenticazione.")),
          );
        }

        final firebaseUser = snapshot.data;

        if (firebaseUser != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final userProvider = context.read<UserProvider>();
            if (userProvider.user == null || userProvider.user!.uid != firebaseUser.uid) {
              userProvider.initializeUserBaseData(
                  firebaseUser.uid, firebaseUser.email ?? 'email.mancante@example.com');
              userProvider.loadAndSetPersistentUserData(firebaseUser.uid);
            }
          });
          return const MainGameScreen();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final userProvider = context.read<UserProvider>();
            if (userProvider.user != null) {
              userProvider.clearUser();
            }
          });
          return LoginScreen();
        }
      },
    );
  }
}
