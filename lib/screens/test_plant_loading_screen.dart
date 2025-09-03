// lib/test_plant_loading_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ASSICURATI CHE QUESTO PERCORSO SIA CORRETTO PER IL TUO MODELLO PLANT:
// Se plant.dart è in lib/models/plant.dart, allora:
import '../models/plant.dart';
// Se plant.dart è direttamente in lib/plant.dart, allora:
// import 'plant.dart';

class TestPlantLoadingScreen extends StatefulWidget {
  const TestPlantLoadingScreen({super.key});

  @override
  _TestPlantLoadingScreenState createState() => _TestPlantLoadingScreenState();
}

class _TestPlantLoadingScreenState extends State<TestPlantLoadingScreen> {
  List<Plant> _plants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPlants();
  }

  Future<void> _fetchPlants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      print(">>> TestPlantLoadingScreen: Tentativo di fetch dalla collezione 'plant_blueprints'...");
      // 1. Ottieni un riferimento alla collezione 'plant_blueprints'
      // **** QUESTA È LA RIGA DA CORREGGERE SE NON L'HAI GIÀ FATTO ****
      QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('plant_blueprints').get();
      // precedentemente potresti aver avuto 'plants' qui, assicurati che sia 'plant_blueprints'

      if (snapshot.docs.isEmpty) {
        print(">>> TestPlantLoadingScreen: Nessun documento trovato nella collezione 'plant_blueprints'.");
        setState(() {
          _errorMessage = "Nessuna pianta trovata nel database ('plant_blueprints').";
          _isLoading = false;
        });
        return;
      }

      print(">>> TestPlantLoadingScreen: Trovati ${snapshot.docs.length} documenti dalla collezione 'plant_blueprints'.");

      // 2. Mappa i documenti in oggetti Plant
      List<Plant> loadedPlants = [];
      for (var doc in snapshot.docs) {
        print(">>> TestPlantLoadingScreen: Processo il documento con ID: ${doc.id}");
        try {
          // Qui usiamo il factory constructor dal tuo modello Plant
          // Passiamo l'ID del documento e i dati (Map<String, dynamic>)
          loadedPlants.add(Plant.fromFirestore(doc.id, doc.data() as Map<String, dynamic>));
        } catch (e, s) {
          print(">>> TestPlantLoadingScreen: ERRORE durante la conversione del documento ${doc.id} in oggetto Plant: $e");
          print(">>> Stack Trace dell'errore di conversione: $s");
          // Puoi decidere se aggiungere un placeholder, saltare la pianta, o gestire l'errore diversamente
        }
      }

      setState(() {
        _plants = loadedPlants;
        _isLoading = false;
      });

      if (_plants.isNotEmpty) {
        print(">>> TestPlantLoadingScreen: Piante caricate con successo nella lista _plants:");
        for (var plant in _plants) {
          print(">>> - ${plant.name} (ID: ${plant.id}, GrowTime: ${plant.growTime}, SellPrice: ${plant.sellPrice})");
        }
      } else if (snapshot.docs.isNotEmpty && _plants.isEmpty) {
        print(">>> TestPlantLoadingScreen: ATTENZIONE - Documenti trovati in Firestore, ma la lista _plants è vuota. Controllare errori di conversione in Plant.fromFirestore.");
        _errorMessage = "Trovate piante nel DB, ma errore nella conversione. Controlla i log.";
      } else {
        print(">>> TestPlantLoadingScreen: La lista _plants è vuota dopo il caricamento.");
      }

    } catch (e, s) {
      print(">>> TestPlantLoadingScreen: ERRORE CATTURATO durante _fetchPlants: $e");
      print(">>> Stack Trace dell'errore generale: $s");
      setState(() {
        _errorMessage = "Errore generale durante il caricamento: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Test Caricamento Piante'),
      ),
      body: Center(
        child: _isLoading
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Caricamento piante..."),
          ],
        )
            : _errorMessage != null
            ? Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('ERRORE:\n$_errorMessage',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red, fontSize: 16)),
        )
            : _plants.isEmpty
            ? Text('Nessuna pianta da mostrare. Controlla i log.')
            : ListView.builder(
          itemCount: _plants.length,
          itemBuilder: (context, index) {
            final plant = _plants[index];
            return Card(
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: plant.imageUrl.isNotEmpty
                    ? Image.network(
                  plant.imageUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print(">>> Errore caricamento immagine per ${plant.name}: $error");
                    return Icon(Icons.broken_image, size: 50);
                  },
                  loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                )
                    : Icon(Icons.local_florist, size: 50, color: Colors.green),
                title: Text(plant.name, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ID: ${plant.id}'),
                    Text('Crescita: ${plant.growTime}s'),
                    Text('Vendita: \$${plant.sellPrice} - Acquisto Semi: \$${plant.seedPurchasePrice}'),
                    Text('Lvl Richiesto: ${plant.requiredLevel}'),
                    if(plant.description.isNotEmpty) Text('Desc: ${plant.description}', maxLines: 2, overflow: TextOverflow.ellipsis),
                    if(plant.plantType.isNotEmpty) Text('Tipo: ${plant.plantType}'),
                    if(plant.rarity.isNotEmpty) Text('Rarità: ${plant.rarity}'),
                    if(plant.buffs.isNotEmpty) Text('Buffs: ${plant.buffs.join(", ")}'),
                  ],
                ),
                isThreeLine: true, // Adatta in base al contenuto
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchPlants,
        tooltip: 'Ricarica Piante',
        child: Icon(Icons.refresh),
      ),
    );
  }
}
