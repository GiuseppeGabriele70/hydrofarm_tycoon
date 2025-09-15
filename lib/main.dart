// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuthLib;
import 'package:flutter/foundation.dart';

// Import per il tuo progetto
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_game_screen.dart';
import 'firebase_options.dart';
import 'debug/farming_debug_screen.dart'; // <-- IMPORT PER LA SCHERMATA DI DEBUG

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseApp app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    print('----------------------------------------------------------------------');
    print('>>> FIREBASE DEBUG: Initialized Firebase App Name: ${app.name}');
    print('>>> FIREBASE DEBUG: Project ID: ${app.options.projectId}');
    print('----------------------------------------------------------------------');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        Provider<AuthService>(create: (_) => AuthService(FirebaseAuthLib.FirebaseAuth.instance)),
        ProxyProvider<UserProvider, DatabaseService?>(
          update: (context, userProvider, previousDbService) {
            final uid = userProvider.user?.uid;
            if (uid == null) {
              // if (kDebugMode) print(">>> ProxyProvider<DatabaseService>: UID nullo, restituisco null per DatabaseService.");
              return null;
            }
            if (previousDbService == null || previousDbService.uid != uid) {
              // if (kDebugMode) print(">>> ProxyProvider<DatabaseService>: Creo/Aggiorno DatabaseService per UID: $uid");
              return DatabaseService(uid: uid);
            }
            // if (kDebugMode) print(">>> ProxyProvider<DatabaseService>: Restituisco DatabaseService esistente per UID: $uid");
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
      home: const AuthWrapper(), // AuthWrapper gestisce la logica iniziale
      debugShowCheckedModeBanner: false,
      // Definisci qui le tue rotte
      routes: {
        // Assicurati che LoginScreen e MainGameScreen abbiano un routeName statico definito
        // Esempio: LoginScreen.routeName: (ctx) => const LoginScreen(),
        // Esempio: MainGameScreen.routeName: (ctx) => const MainGameScreen(),
        FarmingDebugScreen.routeName: (ctx) => const FarmingDebugScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FirebaseAuthLib.User?>(
      stream: FirebaseAuthLib.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Stampa di debug ridotta per chiarezza
        // if (kDebugMode) {
        //   print(">>> AuthWrapper Stream: hasData=${snapshot.hasData}, userUID=${snapshot.data?.uid}");
        // }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final firebaseUser = snapshot.data;
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        // Uso addPostFrameCallback per evitare errori di setState durante il build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (firebaseUser != null) {
            if (userProvider.user == null || userProvider.user!.uid != firebaseUser.uid) {
              if (kDebugMode) print(">>> AuthWrapper: Sincronizzazione UserProvider per ${firebaseUser.uid}");
              userProvider.setUserFromAuth(firebaseUser);
            }
          } else {
            if (userProvider.user != null) {
              if (kDebugMode) print(">>> AuthWrapper: Pulizia UserProvider");
              userProvider.clearUser();
            }
          }
        });

        if (firebaseUser != null) {
          // Se l'utente è loggato, mostra MainGameScreen.
          return const MainGameScreen();
        } else {
          // Se l'utente non è loggato, mostra LoginScreen.
          return const LoginScreen();
        }
      },
    );
  }
}
