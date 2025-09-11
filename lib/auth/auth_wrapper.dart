import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuthLib;
import 'package:flutter/foundation.dart';
import '../providers/user_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main_game_screen.dart';

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
              userProvider.setUserFromAuth(firebaseUser);
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