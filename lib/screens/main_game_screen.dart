// lib/screens/main_game_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Per kDebugMode
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../providers/user_provider.dart';
import '../models/user_model.dart';
import '../models/plant.dart';

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(">>> MainGameScreen BUILD (${DateTime.now().toIso8601String()})");

    final authService = Provider.of<AuthService>(context, listen: false);
    final userProvider = context.watch<UserProvider>();
    final UserModel? currentUser = userProvider.user;
    final DatabaseService? databaseService = context.watch<DatabaseService?>();

    if (userProvider.isLoadingUserData && currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 10),
              Text("Caricamento dati utente..."),
            ],
          ),
        ),
      );
    }

    if (currentUser == null || databaseService == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("HydroFarm Tycoon")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.error_outline, color: Colors.red, size: 40),
              SizedBox(height: 10),
              Text('Dati utente o servizio database non disponibili.'),
            ],
          ),
        ),
      );
    }

    // 🔹 Dati finti per la lista serre (per ora placeholder)
    final serre = [
      {"nome": "Serra 1", "progress": 0.3},
      {"nome": "Serra 2", "progress": 0.7},
      {"nome": "Serra 3", "progress": 1.0},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'HydroFarm Tycoon - ${currentUser.email.split('@')[0]}',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              if (kDebugMode) print(">>> MainGameScreen: Logout richiesto.");
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // 🔹 Colonna sinistra: elenco serre
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.green[50],
              child: ListView.builder(
                itemCount: serre.length,
                itemBuilder: (context, index) {
                  final serra = serre[index];
                  return Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(serra["nome"] as String),
                      subtitle: LinearProgressIndicator(
                        value: serra["progress"] as double,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 🔹 Colonna destra: contenuto principale (il tuo layout esistente)
          Expanded(
            flex: 8,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Utente: ${currentUser.email}', style: const TextStyle(fontSize: 16)),
                  Consumer<UserProvider>(
                    builder: (context, up, child) {
                      return Text(
                        'Denaro: \$${up.user?.money ?? 0}',
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
                  Text('Serre disponibili: ${currentUser.serre}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/serre');
                    },
                    child: const Text("Gestisci Serre"),
                  ),

                  const SizedBox(height: 20),
                  _buildGreenhouseArea(context, userProvider),
                  const SizedBox(height: 20),

                  const Text(
                    'Piante disponibili per la coltivazione:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Plant>>(
                      stream: databaseService.plants,
                      builder: (context, plantSnapshot) {
                        if (plantSnapshot.connectionState == ConnectionState.waiting &&
                            !plantSnapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (plantSnapshot.hasError) {
                          return Center(
                            child: Text(
                              'Errore caricamento piante: ${plantSnapshot.error}',
                            ),
                          );
                        }
                        final availablePlantBlueprints = plantSnapshot.data ?? [];
                        if (availablePlantBlueprints.isEmpty) {
                          return const Center(
                            child: Text('Nessuna pianta disponibile nel negozio.'),
                          );
                        }

                        return ListView.builder(
                          itemCount: availablePlantBlueprints.length,
                          itemBuilder: (context, index) {
                            final plantBlueprint = availablePlantBlueprints[index];
                            final bool canUserPlantThisSeed =
                                userProvider.canUserAffordPlant(plantBlueprint) &&
                                    userProvider.doesUserMeetLevelForPlant(plantBlueprint) &&
                                    userProvider.canPlantNewSeedInAnySerre();

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                title: Text(
                                  plantBlueprint.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  'Crescita: ${plantBlueprint.growTime}s - '
                                      'Vendi per: \$${plantBlueprint.sellPrice}\n'
                                      'Costo Semi: \$${plantBlueprint.seedPurchasePrice} - '
                                      'Lvl: ${plantBlueprint.requiredLevel}',
                                ),
                                isThreeLine: true,
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    canUserPlantThisSeed ? Colors.green : Colors.grey,
                                  ),
                                  onPressed: canUserPlantThisSeed
                                      ? () {
                                    userProvider.plantSeed(plantBlueprint);
                                  }
                                      : null,
                                  child: const Text('Pianta'),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreenhouseArea(BuildContext context, UserProvider userProvider) {
    final growingPlantDetails = userProvider.currentGrowingPlantDetails;
    final plantedAt = userProvider.user?.plantedAt;
    final isReady = userProvider.isCurrentPlantReadyToHarvest();
    final remainingTime = userProvider.currentPlantRemainingGrowTime;

    if (growingPlantDetails != null && plantedAt != null) {
      String statusText;
      if (isReady) {
        statusText = "Serra: ${growingPlantDetails.name} è PRONTA!";
      } else if (remainingTime != null && !remainingTime.isNegative) {
        statusText =
        "Serra: ${growingPlantDetails.name} - Pronta tra: ${remainingTime.inMinutes}m ${remainingTime.inSeconds.remainder(60)}s";
      } else {
        statusText = "Serra: ${growingPlantDetails.name} - Calcolo tempo...";
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(statusText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isReady ? Colors.orange : Colors.grey,
            ),
            onPressed: isReady
                ? () {
              userProvider.harvestAndSellPlant();
            }
                : null,
            child: Text(isReady ? 'Raccogli e Vendi' : 'In Crescita'),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Serra: Vuota. Scegli una pianta!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      );
    }
  }
}
