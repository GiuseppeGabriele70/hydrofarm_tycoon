// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/plant.dart'; // Assumendo che Plant sia il tuo modello per i blueprint

// Importa i tuoi nuovi modelli se necessario per i tipi di ritorno o parametri fortemente tipizzati
// import '../models/centro_agricolo.dart';
// import '../models/serra_idroponica.dart';
// import '../models/modulo_coltivazione.dart';

class DatabaseService {
  final String uid; // Necessario per operazioni specifiche dell'utente
  final FirebaseFirestore _db = FirebaseFirestore.instance; // Istanza DB

  // Memorizza lo stream delle piante per evitare di ricrearlo
  final Stream<List<Plant>> _plantsStream;

  DatabaseService({required this.uid})
      : _plantsStream = FirebaseFirestore.instance // Potresti usare _db qui
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
        // Considera di lanciare un'eccezione o loggare più formalmente
        print("Dati nulli per plant blueprint con ID: ${doc.id}");
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
  // (Potresti definire anche riferimenti base per le sottocollezioni se usati frequentemente)
  DocumentReference<Map<String, dynamic>> get userDocRef =>
      _db.collection('users').doc(uid);

  /// Aggiorna i dati dell'utente (documento principale dell'utente)
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      await userDocRef.update(data);
    } catch (e, stackTrace) {
      print("DatabaseService updateUserData ERRORE: $e");
      print("StackTrace: $stackTrace");
      rethrow;
    }
  }

  /// Aggiunge una nuova SerraIdroponica a un CentroAgricolo specifico.
  /// NOTA: Questo metodo presuppone che tu abbia un CentroAgricolo e ora stai aggiungendo una Serra.
  /// Il tuo vecchio `addSerra` sembrava aggiungere direttamente sotto l'utente.
  /// Adatta il percorso se la tua struttura è diversa.
  Future<void> addSerraIdroponicaToCentro({
    required String centroId, // ID del Centro Agricolo a cui appartiene la serra
    required String nomeSerra,
    int level = 1,
    int capacitaModuli = 4, // Capacità di moduli, non di piante totali
    // Altri campi necessari per il tuo modello SerraIdroponica
  }) async {
    try {
      final serreCollectionRef = userDocRef
          .collection('centri_agricoli')
          .doc(centroId)
          .collection('serre_idroponiche');

      // Crea un nuovo documento Serra con ID automatico
      await serreCollectionRef.add({
        'nome': nomeSerra,
        'livello': level,
        'capacitaModuli': capacitaModuli,
        'tipo': 'base', // Valore di default
        'centroAgricoloId': centroId,
        'userId': uid,
        'moduliColtivazioneIds': [],
        'statoManutenzione': 100,
        'isAttiva': true,
        'dataCostruzione': FieldValue.serverTimestamp(), // O Timestamp.now()
        'consumoEnergetico': 2.5, // Valore di default
        'consumoAcqua': 1.2, // Valore di default
        'ultimoAggiornamento': FieldValue.serverTimestamp(),
      });
      print("Serra '$nomeSerra' aggiunta al centro '$centroId'");
    } catch (e, stackTrace) {
      print("DatabaseService addSerraIdroponicaToCentro ERRORE: $e");
      print("StackTrace: $stackTrace");
      rethrow;
    }
  }

  /// Recupera la lista delle serre dell'utente come stream
  /// MODIFICATO: per riflettere la struttura CentroAgricolo > Serre.
  /// Se hai un solo centro per utente, potresti dover ottenere prima l'ID del centro.
  Stream<List<Map<String, dynamic>>> getSerreIdroponicheStream(String centroId) {
    final serreCollectionRef = userDocRef
        .collection('centri_agricoli')
        .doc(centroId)
        .collection('serre_idroponiche');

    return serreCollectionRef.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return <Map<String, dynamic>>[];
      return snapshot.docs.map((doc) {
        // Qui potresti convertire in oggetti SerraIdroponica se hai il modello
        // return SerraIdroponica.fromFirestore(doc).toMap(); // Esempio
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  // --- NUOVI METODI PER MODULO COLTIVAZIONE ---

  /// Aggiorna un ModuloColtivazione per avviare una nuova coltivazione.
  Future<void> piantaInModulo({
    // required String userId, // Già disponibile come this.uid
    required String centroId,
    required String serraId,
    required String moduloId,
    required String piantaBlueprintId, // ID del tipo di pianta (dal tuo Plant model)
    required int finalGrowDurationSeconds, // Durata di crescita calcolata
  }) async {
    final now = DateTime.now();
    final moduloRef = _db
        .collection('users')
        .doc(uid) // Usa this.uid
        .collection('centri_agricoli')
        .doc(centroId)
        .collection('serre_idroponiche')
        .doc(serraId)
        .collection('moduli_coltivazione')
        .doc(moduloId);

    try {
      await moduloRef.update({
        'piantaAttiva': piantaBlueprintId,
        'plantedAt': Timestamp.fromDate(now),
        'growDurationSeconds': finalGrowDurationSeconds,
        // 'statoOperativoModulo': 'coltivazione', // Se hai un campo di stato specifico
        'ultimoAggiornamento': FieldValue.serverTimestamp(),
      });
      print(
          'Pianta $piantaBlueprintId piantata nel modulo $moduloId (Centro: $centroId, Serra: $serraId) per utente $uid con successo.');
    } catch (e, stackTrace) {
      print(
          'DatabaseService piantaInModulo ERRORE per modulo $moduloId (utente $uid): $e');
      print("StackTrace: $stackTrace");
      rethrow;
    }
  }

  /// Resetta un ModuloColtivazione dopo la raccolta (o se la coltivazione viene annullata).
  Future<void> raccogliDaModulo({
    // required String userId, // Già disponibile come this.uid
    required String centroId,
    required String serraId,
    required String moduloId,
  }) async {
    final moduloRef = _db
        .collection('users')
        .doc(uid) // Usa this.uid
        .collection('centri_agricoli')
        .doc(centroId)
        .collection('serre_idroponiche')
        .doc(serraId)
        .collection('moduli_coltivazione')
        .doc(moduloId);

    try {
      await moduloRef.update({
        'piantaAttiva': null,
        'plantedAt': null,
        'growDurationSeconds': null,
        // 'statoOperativoModulo': 'libero', // Se hai un campo di stato specifico
        'ultimoAggiornamento': FieldValue.serverTimestamp(),
      });
      print(
          'Raccolta/Reset per modulo $moduloId (Centro: $centroId, Serra: $serraId) per utente $uid completata.');
    } catch (e, stackTrace) {
      print(
          'DatabaseService raccogliDaModulo ERRORE per modulo $moduloId (utente $uid): $e');
      print("StackTrace: $stackTrace");
      rethrow;
    }
  }

// --- Esempi di altri metodi che potresti necessitare ---

// Future<void> addModuloColtivazioneToSerra({
//   required String centroId,
//   required String serraId,
//   required String nomeModulo,
//   int level = 1,
//   int capienza = 1, // Se un modulo ha una singola pianta/lotto
// }) async {
//   try {
//     final moduliCollectionRef = _db
//         .collection('users').doc(uid)
//         .collection('centri_agricoli').doc(centroId)
//         .collection('serre_idroponiche').doc(serraId)
//         .collection('moduli_coltivazione');
//
//     await moduliCollectionRef.add({
//       'nome': nomeModulo,
//       'level': level,
//       'capienza': capienza, // Assumendo capienza per il modello ModuloColtivazione
//       'statoManutenzione': 100,
//       'serraIdroponicaId': serraId,
//       'piantaAttiva': null,
//       'plantedAt': null,
//       'growDurationSeconds': null,
//       'createdAt': FieldValue.serverTimestamp(),
//       'ultimoAggiornamento': FieldValue.serverTimestamp(),
//     });
//     print("Modulo '$nomeModulo' aggiunto alla serra '$serraId'");
//   } catch (e, stackTrace) {
//     print("DatabaseService addModuloColtivazioneToSerra ERRORE: $e");
//     print("StackTrace: $stackTrace");
//     rethrow;
//   }
// }

// Potresti anche volere metodi per leggere i dati di un singolo modulo, serra o centro.
// Esempio:
// Future<ModuloColtivazione?> getModuloColtivazione({
//   required String centroId,
//   required String serraId,
//   required String moduloId,
// }) async {
//   try {
//     final docSnap = await _db
//         .collection('users').doc(uid)
//         .collection('centri_agricoli').doc(centroId)
//         .collection('serre_idroponiche').doc(serraId)
//         .collection('moduli_coltivazione').doc(moduloId)
//         .get();
//     if (docSnap.exists) {
//       return ModuloColtivazione.fromFirestore(docSnap.data()!, docSnap.id);
//     }
//     return null;
//   } catch (e, stackTrace) {
//     print("DatabaseService getModuloColtivazione ERRORE: $e");
//     print("StackTrace: $stackTrace");
//     rethrow;
//   }
// }
}
