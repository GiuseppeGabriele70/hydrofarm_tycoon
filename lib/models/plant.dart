// In C:/Users/Peppe/Documents/FlutterProjects/hydrofarm_tycoon/lib/models/plant.dart

class Plant {
  final String id;
  final String name; // Nome visualizzato della pianta
  final int growTime; // Proprietà della classe (prenderà baseGrowTime o growTime da Firestore)
  final int sellPrice; // Proprietà della classe (prenderà matureSellPrice o sellPrice da Firestore)
  final int seedPurchasePrice;
  final int requiredLevel;
  final String description;
  final String imageUrl;
  final String plantType;
  final List<String> buffs;
  final String rarity;

  Plant({
    required this.id,
    required this.name,
    required this.growTime,
    required this.sellPrice,
    required this.seedPurchasePrice,
    required this.requiredLevel,
    this.description = '',
    this.imageUrl = '',
    this.plantType = 'Sconosciuto',
    this.buffs = const [],
    this.rarity = 'Comune',
  });

  factory Plant.fromFirestore(String docId, Map<String, dynamic> data) {
    try {
      print(
          ">>> Plant.fromFirestore: Tentativo di creare Plant con id '$docId'. Dati ricevuti: $data");

      // NOME PIANTA
      // Il tuo codice attuale per 'name' va bene se 'name' è il campo per il nome visualizzato in Firestore
      final String plantName = data['name'] as String? ?? 'Nome Pianta Mancante';

      // GROW TIME (con fallback)
      int actualGrowTime;
      if (data.containsKey('baseGrowTime') && data['baseGrowTime'] is num) {
        actualGrowTime = (data['baseGrowTime'] as num).toInt();
      } else if (data.containsKey('growTime') && data['growTime'] is num) { // Fallback a 'growTime'
        actualGrowTime = (data['growTime'] as num).toInt();
        print(">>> Plant.fromFirestore: INFO - Usato fallback 'growTime' per id '$docId'. Valore: $actualGrowTime");
      } else {
        print(
            ">>> Plant.fromFirestore: ATTENZIONE - 'baseGrowTime' o 'growTime' non validi per id '$docId'. Dati: ${data['baseGrowTime'] ?? data['growTime']}. Impostazione a 0.");
        actualGrowTime = 0;
      }

      // SELL PRICE (con fallback)
      int actualSellPrice;
      if (data.containsKey('matureSellPrice') && data['matureSellPrice'] is num) {
        actualSellPrice = (data['matureSellPrice'] as num).toInt();
      } else if (data.containsKey('sellPrice') && data['sellPrice'] is num) { // Fallback a 'sellPrice'
        actualSellPrice = (data['sellPrice'] as num).toInt();
        print(">>> Plant.fromFirestore: INFO - Usato fallback 'sellPrice' per id '$docId'. Valore: $actualSellPrice");
      } else {
        print(
            ">>> Plant.fromFirestore: ATTENZIONE - 'matureSellPrice' o 'sellPrice' non validi per id '$docId'. Dati: ${data['matureSellPrice'] ?? data['sellPrice']}. Impostazione a 0.");
        actualSellPrice = 0;
      }

      // SEED PURCHASE PRICE
      final int seedPriceFromData;
      if (data['seedPurchasePrice'] is num) {
        seedPriceFromData = (data['seedPurchasePrice'] as num).toInt();
      } else {
        print(
            ">>> Plant.fromFirestore: ATTENZIONE - 'seedPurchasePrice' non è un numero per id '$docId'. Dati: ${data['seedPurchasePrice']}. Impostazione a 0.");
        seedPriceFromData = 0;
      }

      // REQUIRED LEVEL
      final int levelFromData;
      if (data['requiredLevel'] is num) {
        levelFromData = (data['requiredLevel'] as num).toInt();
      } else {
        print(
            ">>> Plant.fromFirestore: ATTENZIONE - 'requiredLevel' non è un numero per id '$docId'. Dati: ${data['requiredLevel']}. Impostazione a 0.");
        levelFromData = 0;
      }

      final String plantDescription = data['description'] as String? ?? 'Nessuna descrizione';
      final String imgUrl = data['imageUrl'] as String? ?? '';
      final String type = data['plantType'] as String? ?? 'Sconosciuto';
      final List<String> plantBuffs = List<String>.from(data['buffs'] as List? ?? []);
      final String plantRarity = data['rarity'] as String? ?? 'Comune';

      final plant = Plant(
        id: docId,
        name: plantName,
        growTime: actualGrowTime, // Usa il valore determinato con fallback
        sellPrice: actualSellPrice, // Usa il valore determinato con fallback
        seedPurchasePrice: seedPriceFromData,
        requiredLevel: levelFromData,
        description: plantDescription,
        imageUrl: imgUrl,
        plantType: type,
        buffs: plantBuffs,
        rarity: plantRarity,
      );
      print(
          ">>> Plant.fromFirestore: Plant creata con successo per id '$docId': ${plant.name}");
      return plant;
    } catch (e, s) {
      print(">>> Plant.fromFirestore: ERRORE DESERIALIZZANDO Plant con id '$docId': $e");
      print(">>> Plant.fromFirestore: Stack Trace: $s");
      print(">>> Plant.fromFirestore: Dati del documento problematico: $data");
      // Ritorna un oggetto Plant placeholder in caso di errore catastrofico
      return Plant(
        id: docId,
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
    // Quando salvi, usa i nomi dei campi standard che preferisci per i nuovi blueprint
    // o per aggiornare quelli esistenti. Qui uso i nomi "base" come da tue piante esistenti.
    return {
      'name': name, // Nome visualizzato della pianta
      'baseGrowTime': growTime, // Salva la proprietà growTime della classe come baseGrowTime
      'matureSellPrice': sellPrice, // Salva la proprietà sellPrice della classe come matureSellPrice
      'seedPurchasePrice': seedPurchasePrice,
      'requiredLevel': requiredLevel,
      'description': description,
      'imageUrl': imageUrl,
      'plantType': plantType,
      'buffs': buffs,
      'rarity': rarity,
    };
  }

  @override
  String toString() {
    return 'Plant(id: $id, name: $name, growTime: $growTime, sellPrice: $sellPrice, seedPurchasePrice: $seedPurchasePrice, requiredLevel: $requiredLevel, description: $description, imageUrl: $imageUrl, plantType: $plantType, buffs: $buffs, rarity: $rarity)';
  }
}
