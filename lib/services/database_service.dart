// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant.dart';

class DatabaseService {
  final String uid; // Necessario per operazioni specifiche dell'utente (es. userData)

  // Memorizza lo stream delle piante per evitare di ricrearlo
  final Stream<List<Plant>> _plantsStream;

  DatabaseService({required this.uid})
      : _plantsStream = FirebaseFirestore.instance
      .collection('plant_blueprints')
      .snapshots()
      .map(_plantListFromSnapshot)
      .asBroadcastStream();

  // Getter pubblico per lo stream delle piante
  Stream<List<Plant>> get plants {
    return _plantsStream;
  }

  // Helper per convertire QuerySnapshot in List<Plant>
  static List<Plant> _plantListFromSnapshot(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) return <Plant>[];
    return snapshot.docs.map((doc) {
      final rawData = doc.data() as Map<String, dynamic>?;
      if (rawData == null) {
        return Plant(
            id: doc.id,
            name: 'ERRORE DATI NULLI',
            growTime: 0,
            sellPrice: 0,
            seedPurchasePrice: 0,
            requiredLevel: 0,
            description: 'Dati mancanti',
            imageUrl: '',
            plantType: 'Sconosciuto',
            buffs: [],
            rarity: 'Errore');
      }
      return Plant.fromFirestore(doc.id, rawData);
    }).toList();
  }

  // Collection reference agli utenti
  final CollectionReference<Map<String, dynamic>> usersCollection =
  FirebaseFirestore.instance.collection('users');

  /// Aggiorna i dati dell'utente
  Future<void> updateUserData(Map<String, dynamic> data) async {
    return await usersCollection.doc(uid).update(data);
  }

  /// Aggiunge una nuova serra per l'utente
  Future<void> addSerra({
    required String nome,
    int level = 1,
    int capienza = 10,
  }) async {
    try {
      final serreCollection = usersCollection.doc(uid).collection('serre');

      // Documento con ID automatico
      await serreCollection.add({
        'nome': nome,
        'level': level,
        'capienza': capienza,
        'stato': 0, // Percentuale iniziale di occupazione o produttività
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      print("DatabaseService addSerra ERRORE: $e");
      print("StackTrace: $stackTrace");
      rethrow;
    }
  }

  /// Recupera la lista delle serre dell'utente come stream
  Stream<List<Map<String, dynamic>>> getSerre() {
    final serreCollection = usersCollection.doc(uid).collection('serre');
    return serreCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }
}

