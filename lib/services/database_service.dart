// lib/services/database_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // Aggiunto per kDebugMode
import '../models/plant.dart'; // Assicurati che il percorso sia corretto
import '../models/agricoltura/modulo_coltivazione.dart'; // Assicurati che il percorso sia corretto

class DatabaseService {
  final String? uid; // Può essere null se non c'è un utente loggato
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // _plantsStream è stato rimosso per semplificare, dato che UserProvider gestisce i blueprint.
  // Se necessario per altre funzionalità specifiche di DatabaseService, può essere reintegrato.

  DatabaseService({required this.uid});

  DocumentReference<Map<String, dynamic>> get userDocRef {
    if (uid == null) {
      throw Exception("UID utente non disponibile per userDocRef (DatabaseService)");
    }
    return _db.collection('users').doc(uid);
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (uid == null) {
      if (kDebugMode) print("DatabaseService updateUserData ERRORE: UID utente nullo.");
      throw Exception("UID utente nullo durante updateUserData.");
    }
    try {
      await userDocRef.update(data);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("DatabaseService updateUserData ERRORE: $e");
        print("StackTrace: $stackTrace");
      }
      rethrow;
    }
  }

  Future<void> addSerraIdroponicaToCentro({
    required String centroId,
    required String nomeSerra,
    int level = 1,
    int capacitaModuli = 4,
  }) async {
    if (uid == null) {
      if (kDebugMode) print("DatabaseService addSerraIdroponicaToCentro ERRORE: UID utente nullo.");
      throw Exception("UID utente nullo durante addSerraIdroponicaToCentro.");
    }
    try {
      final serreCollectionRef = userDocRef
          .collection('centri_agricoli')
          .doc(centroId)
          .collection('serre_idroponiche');

      await serreCollectionRef.add({
        'nome': nomeSerra,
        'livello': level,
        'capacitaModuli': capacitaModuli,
        'tipo': 'base', // Esempio, potresti volerlo parametrizzare
        'centroAgricoloId': centroId,
        'userId': uid, // Salva l'UID dell'utente proprietario della serra
        'moduliColtivazioneIds': [], // Lista degli ID dei moduli in questa serra
        'statoManutenzione': 100,
        'isAttiva': true,
        'dataCostruzione': FieldValue.serverTimestamp(),
        'consumoEnergetico': 2.5, // Esempio
        'consumoAcqua': 1.2,     // Esempio
        'ultimoAggiornamento': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) print(">>> DatabaseService: Serra '$nomeSerra' aggiunta al centro '$centroId' per utente $uid");
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("DatabaseService addSerraIdroponicaToCentro ERRORE: $e");
        print("StackTrace: $stackTrace");
      }
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getSerreIdroponicheStream(String centroId) {
    if (uid == null) {
      if (kDebugMode) print("DatabaseService getSerreIdroponicheStream ERRORE: UID utente nullo.");
      // Restituisce uno stream vuoto o gestisci l'errore come preferisci
      return Stream.value(<Map<String, dynamic>>[]);
    }
    final serreCollectionRef = userDocRef
        .collection('centri_agricoli')
        .doc(centroId)
        .collection('serre_idroponiche');

    return serreCollectionRef.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return <Map<String, dynamic>>[];
      return snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    });
  }

  // --- METODI DEPRECATI (logica ora gestita da updateModuloSlots e FarmingProvider) ---
  // Future<void> piantaInModulo({ ... }) async { ... }
  // Future<void> raccogliDaModulo({ ... }) async { ... }
  // --- FINE METODI DEPRECATI ---


  // ***** NUOVO METODO PER AGGIORNARE GLI SLOT DI UN MODULO *****
  Future<void> updateModuloSlots(
      String callingUserId, // L'UID dell'utente che effettua l'operazione (passato da FarmingProvider)
      String centroId,
      String serraId,
      String moduloId,
      List<Map<String, dynamic>> slotsData, // Lista di slot serializzati
      ) async {
    // Verifica che l'UID del servizio (this.uid) corrisponda all'UID dell'utente che chiama, per sicurezza
    if (this.uid == null || this.uid != callingUserId) {
      final errorMessage = "DatabaseService updateModuloSlots ERRORE: UID non corrispondente o nullo. Service UID: ${this.uid}, Calling UID: $callingUserId";
      if (kDebugMode) print(errorMessage);
      throw Exception(errorMessage);
    }

    // Costruisci il percorso completo al documento del modulo
    final String path = 'users/${this.uid}/centri_agricoli/$centroId/serre_idroponiche/$serraId/moduli_coltivazione/$moduloId';

    try {
      // Aggiorna il campo 'slots' con la nuova lista di dati e imposta 'ultimoAggiornamento'
      await _db.doc(path).update({
        'slots': slotsData,
        'ultimoAggiornamento': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print(">>> DatabaseService: Slots aggiornati per modulo $moduloId al percorso $path. Numero slot dati inviati: ${slotsData.length}");
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(">>> DatabaseService: ERRORE durante updateModuloSlots per modulo $moduloId al percorso $path: $e");
        print("StackTrace: $stackTrace");
      }
      rethrow; // Rilancia l'eccezione per essere gestita dal chiamante (es. FarmingProvider)
    }
  }


  Future<ModuloColtivazione?> getModulo(
      String centroId,
      String serraId,
      String moduloId,
      ) async {
    if (uid == null) {
      if (kDebugMode) print("DatabaseService getModulo ERRORE: UID utente nullo.");
      return null;
    }

    final String docPath = 'users/$uid/centri_agricoli/$centroId/serre_idroponiche/$serraId/moduli_coltivazione/$moduloId';

    if (kDebugMode) {
      print('>>> DatabaseService.getModulo DEBUG PATH: Tentativo di leggere il documento al percorso: "$docPath"');
    }

    try {
      final docSnap = await _db.doc(docPath).get();

      if (docSnap.exists && docSnap.data() != null) {
        if (kDebugMode) print(">>> DatabaseService: Modulo $moduloId (percorso: $docPath) TROVATO.");
        // Assicurati che ModuloColtivazione.fromFirestore gestisca correttamente il nuovo campo 'slots'
        return ModuloColtivazione.fromFirestore(docSnap.id, docSnap.data()!);
      } else {
        if (kDebugMode) print(">>> DatabaseService: Modulo $moduloId (percorso: $docPath) NON trovato.");
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print(">>> DatabaseService: ERRORE fatale durante getModulo per modulo $moduloId (percorso: $docPath, utente $uid): $e");
        print("StackTrace: $stackTrace");
      }
      return null; // Restituisce null in caso di errore per evitare crash, l'errore è loggato
    }
  }
}


