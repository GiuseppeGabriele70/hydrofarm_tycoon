// lib/screens/main_game_screen.dart
import 'package:flutter/foundation.dart'; // Per kDebugMode
import 'package:flutter/material.dart';
// Rinominato per evitare conflitti
import 'package:provider/provider.dart'; // Per accedere a AuthService se necessario per logout

// Importa i tuoi servizi e widget
import '../services/auth_service.dart'; // Assicurati che il percorso sia corretto
import '../widgets/warehouse_bar.dart';
import '../widgets/greenhouse_list.dart';
import '../widgets/world_map_widget.dart';
import '../debug/farming_debug_screen.dart'; // <-- AGGIUNTO IMPORT

class MainGameScreen extends StatefulWidget {
  static const routeName = '/main-game'; // Buona pratica aggiungere un nome di rotta

  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  bool isSidebarOpen = true;

  final List<Map<String, dynamic>> serreMock = [
    {"nome": "Serra 1", "degrado": 10, "tempoRimanente": const Duration(minutes: 5, seconds: 30), "lat": 41.9, "lng": 12.5,},
    {"nome": "Serra 2", "degrado": 25, "tempoRimanente": const Duration(minutes: 12, seconds: 45), "lat": 40.4, "lng": -3.7,},
    {"nome": "Serra 3", "degrado": 50, "tempoRimanente": const Duration(seconds: 0), "lat": 48.8, "lng": 2.3,},
  ];

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Sei sicuro di voler uscire?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Esci')),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Prendi AuthService da Provider se è registrato globalmente
        // Oppure istanzialo direttamente se preferisci per questa azione specifica
        final authService = Provider.of<AuthService>(context, listen: false);
        await authService.signOut();

        // Dopo il logout, AuthWrapper dovrebbe gestire la navigazione a LoginScreen.
        // Non è necessario Navigator.pushReplacementNamed(context, '/login') qui
        // se AuthWrapper funziona correttamente.

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout effettuato con successo')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il logout: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HydroFarm Tycoon"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: WorldMapWidget(
              serre: serreMock,
              onAddSerra: (point) {
                setState(() {
                  serreMock.add({
                    "nome": "Nuova Serra", "degrado": 0, "tempoRimanente": const Duration(minutes: 15),
                    "lat": point.latitude, "lng": point.longitude,
                  });
                });
              },
              onRemoveSerra: (index) {
                setState(() {
                  serreMock.removeAt(index);
                });
              },
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSidebarOpen ? 220 : 60,
              color: isSidebarOpen ? Colors.blueGrey.shade900 : Colors.transparent,
              child: isSidebarOpen
                  ? Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => isSidebarOpen = false),
                  ),
                  const SizedBox(height: 10),
                  const WarehouseBar(),
                  const SizedBox(height: 8),
                  Expanded(child: GreenhouseList(serre: serreMock)),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.blueGrey.shade800,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(onPressed: () {}, icon: const Icon(Icons.spa, color: Colors.white)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.shopping_basket, color: Colors.white)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.hourglass_empty, color: Colors.white)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.build, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              )
                  : SizedBox(
                width: 60,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward, color: Colors.grey[300]),
                  onPressed: () => setState(() => isSidebarOpen = true),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSidebarOpen ? 200 : 80, // Esempio, adatta come preferisci
              color: Colors.grey.shade200.withOpacity(isSidebarOpen ? 1 : 0.3), // Esempio
              child: isSidebarOpen // Mostra contenuto solo se la sidebar è "aperta" (larga)
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("Sidebar Destra", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Icon(Icons.info_outline),
                  // Aggiungi qui altri widget per la sidebar destra
                ],
              )
                  : Container(), // Non mostrare nulla se la sidebar è "chiusa" (stretta)
            ),
          ),
        ],
      ),
      // AGGIUNTO FAB PER DEBUG
      floatingActionButton: kDebugMode
          ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(FarmingDebugScreen.routeName);
        },
        tooltip: 'Debug Farming',
        child: const Icon(Icons.bug_report),
      )
          : null,
    );
  }
}

