// In C:/Users/Peppe/Documents/FlutterProjects/hydrofarm_tycoon/lib/models/plant.dart

class Plant {
  final String id;
  final String name;
  final int growTime; // Questa proprietà ora corrisponderà a 'baseGrowTime' da Firestore
  final int sellPrice; // Questa proprietà ora corrisponderà a 'matureSellPrice' da Firestore
  final int seedPurchasePrice; // <-- AGGIUNTA
  final int requiredLevel;   // <-- AGGIUNTA
  final String description;
  final String imageUrl;
  final String plantType;     // <-- AGGIUNTA
  final List<String> buffs;   // <-- AGGIUNTA
  final String rarity;        // <-- AGGIUNTA

  Plant({
    required this.id,
    required this.name,
    required this.growTime,
    required this.sellPrice,
    required this.seedPurchasePrice, // <-- AGGIUNTA
    required this.requiredLevel,   // <-- AGGIUNTA
    this.description = '',
    this.imageUrl = '',
    this.plantType = 'Sconosciuto', // <-- AGGIUNTA
    this.buffs = const [],        // <-- AGGIUNTA
    this.rarity = 'Comune',       // <-- AGGIUNTA
  });

  factory Plant.fromFirestore(String id, Map<String, dynamic> data) {
    try {
      print(">>> Plant.fromFirestore: Tentativo di creare Plant con id '$id'. Dati ricevuti: $data");

      final String name = data['name'] as String? ?? 'Nome Pianta Mancante';

      final int baseGrowTimeFromData;
      if (data['baseGrowTime'] is num) {
        baseGrowTimeFromData = (data['baseGrowTime'] as num).toInt();
      } else {
        print(">>> Plant.fromFirestore: ATTENZIONE - 'baseGrowTime' non è un numero per id '$id'. Dati: ${data['baseGrowTime']}. Impostazione a 0.");
        baseGrowTimeFromData = 0;
      }

      final int matureSellPriceFromData;
      if (data['matureSellPrice'] is num) {
        matureSellPriceFromData = (data['matureSellPrice'] as num).toInt();
      } else {
        print(">>> Plant.fromFirestore: ATTENZIONE - 'matureSellPrice' non è un numero per id '$id'. Dati: ${data['matureSellPrice']}. Impostazione a 0.");
        matureSellPriceFromData = 0;
      }

      final int seedPurchasePriceFromData; // <-- AGGIUNTA
      if (data['seedPurchasePrice'] is num) {
        seedPurchasePriceFromData = (data['seedPurchasePrice'] as num).toInt();
      } else {
        print(">>> Plant.fromFirestore: ATTENZIONE - 'seedPurchasePrice' non è un numero per id '$id'. Dati: ${data['seedPurchasePrice']}. Impostazione a 0.");
        seedPurchasePriceFromData = 0;
      }

      final int requiredLevelFromData; // <-- AGGIUNTA
      if (data['requiredLevel'] is num) {
        requiredLevelFromData = (data['requiredLevel'] as num).toInt();
      } else {
        print(">>> Plant.fromFirestore: ATTENZIONE - 'requiredLevel' non è un numero per id '$id'. Dati: ${data['requiredLevel']}. Impostazione a 0.");
        requiredLevelFromData = 0;
      }

      final String description = data['description'] as String? ?? 'Nessuna descrizione';
      final String imageUrl = data['imageUrl'] as String? ?? '';
      final String plantType = data['plantType'] as String? ?? 'Sconosciuto'; // <-- AGGIUNTA
      final List<String> buffs = List<String>.from(data['buffs'] as List? ?? []); // <-- AGGIUNTA
      final String rarity = data['rarity'] as String? ?? 'Comune'; // <-- AGGIUNTA

      final plant = Plant(
        id: id,
        name: name,
        growTime: baseGrowTimeFromData,    // Assegna baseGrowTimeFromData a growTime della classe
        sellPrice: matureSellPriceFromData, // Assegna matureSellPriceFromData a sellPrice della classe
        seedPurchasePrice: seedPurchasePriceFromData, // <-- AGGIUNTA
        requiredLevel: requiredLevelFromData,     // <-- AGGIUNTA
        description: description,
        imageUrl: imageUrl,
        plantType: plantType,         // <-- AGGIUNTA
        buffs: buffs,                 // <-- AGGIUNTA
        rarity: rarity,               // <-- AGGIUNTA
      );
      print(">>> Plant.fromFirestore: Plant creata con successo per id '$id': ${plant.name}");
      return plant;

    } catch (e, s) {
      print(">>> Plant.fromFirestore: ERRORE DESERIALIZZANDO Plant con id '$id': $e");
      print(">>> Plant.fromFirestore: Stack Trace: $s");
      print(">>> Plant.fromFirestore: Dati del documento problematico: $data");
      return Plant( // Placeholder con tutti i campi
        id: id,
        name: 'ERRORE CARICAMENTO PIANTA',
        growTime: 0,
        sellPrice: 0,
        seedPurchasePrice: 0,
        requiredLevel: 0,
        description: 'Dati corrotti o mancanti: $e',
        imageUrl: '',
        plantType: 'ERRORE',
        buffs: [],
        rarity: 'ERRORE',
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'baseGrowTime': growTime,
      'matureSellPrice': sellPrice,
      'seedPurchasePrice': seedPurchasePrice, // <-- AGGIUNTA
      'requiredLevel': requiredLevel,     // <-- AGGIUNTA
      'description': description,
      'imageUrl': imageUrl,
      'plantType': plantType,         // <-- AGGIUNTA
      'buffs': buffs,                 // <-- AGGIUNTA
      'rarity': rarity,               // <-- AGGIUNTA
    };
  }

  @override
  String toString() {
    return 'Plant(id: $id, name: $name, growTime: $growTime, sellPrice: $sellPrice, seedPurchasePrice: $seedPurchasePrice, requiredLevel: $requiredLevel, description: $description, imageUrl: $imageUrl, plantType: $plantType, buffs: $buffs, rarity: $rarity)';
  }
}
