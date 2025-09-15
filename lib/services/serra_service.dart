// lib/services/serra_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agricoltura/modulo_coltivazione.dart'; // Assicurati che ModuloColtivazione.fromFirestore sia (String id, Map data)

class SerraService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // NOTA: Questo metodo recupera ModuloColtivazione dalla collezione 'serre'.
  // Se la collezione 'serre' contiene documenti che rappresentano 'SerraIdroponica',
  // allora il tipo di ritorno e il factory dovrebbero essere SerraIdroponica.
  // Se 'serre' contiene effettivamente Moduli, allora il nome della collezione è fuorviante.
  Stream<List<ModuloColtivazione>> getSerre(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('serre') // Questa collezione contiene ModuloColtivazione secondo il codice
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) {
            // Gestisci il caso in cui i dati del documento sono nulli, se necessario
            print("Attenzione: dati nulli per il documento ${doc.id} nella collezione serre dell'utente $userId");
            // Potresti ritornare un ModuloColtivazione di default o lanciare un errore più specifico
            // Per ora, lo escludiamo o ritorniamo un oggetto non valido che potrebbe essere filtrato.
            // Questa situazione non dovrebbe accadere con documenti Firestore validi.
            // Se ModuloColtivazione.fromFirestore gestisce bene i dati parziali/nulli, va bene.
            // Altrimenti, considera di filtrare questi documenti.
            throw Exception("Dati nulli per il documento ${doc.id}");
          }
          // CORRETTO: Chiamata con (id, data)
          return ModuloColtivazione.fromFirestore(doc.id, data);
        }).toList();
      } catch (e) {
        print("Errore durante la deserializzazione dei moduli dalla collezione 'serre': $e");
        return <ModuloColtivazione>[]; // Ritorna una lista vuota in caso di errore
      }
    });
  }

  // Metodo di compatibilità per il nuovo nome
  // Questo implica che 'getSerre' in realtà ottiene Moduli.
  Stream<List<ModuloColtivazione>> getModuliColtivazione(String userId) {
    return getSerre(userId);
  }

  // Questo aggiunge un ModuloColtivazione alla collezione 'serre'.
  Future<void> addSerra(String userId, ModuloColtivazione modulo) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('serre') // Salva un ModuloColtivazione qui
          .doc(modulo.id)
          .set(modulo.toFirestore());
      print("Modulo ${modulo.id} aggiunto alla collezione 'serre' per l'utente $userId");
    } catch (e) {
      print('Errore aggiunta modulo alla collezione "serre": $e');
      rethrow;
    }
  }

  // Questo aggiorna un ModuloColtivazione nella collezione 'serre'.
  Future<void> updateSerra(String userId, ModuloColtivazione modulo) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('serre') // Aggiorna un ModuloColtivazione qui
          .doc(modulo.id)
          .update(modulo.toFirestore());
      print("Modulo ${modulo.id} aggiornato nella collezione 'serre' per l'utente $userId");
    } catch (e) {
      print('Errore aggiornamento modulo nella collezione "serre": $e');
      rethrow;
    }
  }

  // Questo elimina un ModuloColtivazione dalla collezione 'serre', usando moduloId.
  Future<void> deleteSerra(String userId, String moduloId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('serre') // Elimina un ModuloColtivazione da qui
          .doc(moduloId)
          .delete();
      print("Modulo $moduloId eliminato dalla collezione 'serre' per l'utente $userId");
    } catch (e) {
      print('Errore eliminazione modulo dalla collezione "serre": $e');
      rethrow;
    }
  }
}
