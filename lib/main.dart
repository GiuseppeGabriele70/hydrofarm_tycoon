// File: lib/main.dart (CORRETTO)
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuthLib;
import 'package:flutter/foundation.dart';

// Import corretto per il tuo progetto
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_game_screen.dart';
import 'firebase_options.dart';

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
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// CORRETTO: AuthWrapper con gestione semplificata
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FirebaseAuthLib.User?>(
      stream: FirebaseAuthLib.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (kDebugMode) {
          print(">>> AuthWrapper Stream Emission: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, userUID=${snapshot.data?.uid}");
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          if (kDebugMode) print(">>> AuthWrapper: Stream in attesa...");
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final firebaseUser = snapshot.data;
        final userProvider = Provider.of<UserProvider>(context, listen: false);

        if (firebaseUser != null) {
          if (kDebugMode) print(">>> AuthWrapper: Firebase user presente (${firebaseUser.uid}).");

          // Sincronizza con UserProvider
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (userProvider.user == null || userProvider.user!.uid != firebaseUser.uid) {
              if (kDebugMode) print(">>> AuthWrapper: Sincronizzazione UserProvider");
              userProvider.setUserFromAuth(firebaseUser); // Passa l'oggetto User, non la stringa
            }
          });

          return const MainGameScreen();
        } else {
          if (kDebugMode) print(">>> AuthWrapper: Firebase user assente.");

          // Pulisci UserProvider
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (userProvider.user != null) {
              if (kDebugMode) print(">>> AuthWrapper: Pulizia UserProvider");
              userProvider.clearUser();
            }
          });

          return const LoginScreen();
        }
      },
    );
  }
}