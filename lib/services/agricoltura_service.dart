import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agricoltura/modulo_coltivazione.dart';
import '../models/agricoltura/serra_idroponica.dart';
import '../models/agricoltura/centro_agricolo.dart';

class AgricolturaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // === METODI UTILITY CORRETTI ===
  Future<int> contaModuliPerSerra(String serraId) async {
    try {
      final snapshot = await _firestore
          .collection('moduli_coltivazione')
          .where('serraIdroponicaId', isEqualTo: serraId)
          .count()
          .get();
      return snapshot.count ?? 0; // FORZA il ritorno di int (non int?)
    } catch (e) {
      print('Errore conteggio moduli per serra: $e');
      return 0;
    }
  }

  Future<int> contaSerrePerCentro(String centroId) async {
    try {
      final snapshot = await _firestore
          .collection('serre_idroponiche')
          .where('centroAgricoloId', isEqualTo: centroId)
          .count()
          .get();
      return snapshot.count ?? 0; // FORZA il ritorno di int (non int?)
    } catch (e) {
      print('Errore conteggio serre per centro: $e');
      return 0;
    }
  }

  // === METODI ALTERNATIVI (se i count() danno problemi) ===
  Future<int> contaModuliPerSerraAlternativo(String serraId) async {
    try {
      final querySnapshot = await _firestore
          .collection('moduli_coltivazione')
          .where('serraIdroponicaId', isEqualTo: serraId)
          .get();
      return querySnapshot.docs.length; // Questo restituisce sempre int
    } catch (e) {
      print('Errore conteggio moduli per serra: $e');
      return 0;
    }
  }

  Future<int> contaSerrePerCentroAlternativo(String centroId) async {
    try {
      final querySnapshot = await _firestore
          .collection('serre_idroponiche')
          .where('centroAgricoloId', isEqualTo: centroId)
          .get();
      return querySnapshot.docs.length; // Questo restituisce sempre int
    } catch (e) {
      print('Errore conteggio serre per centro: $e');
      return 0;
    }
  }

  // === METODI per MODULI di COLTIVAZIONE ===
  Future<void> aggiungiModuloColtivazione(ModuloColtivazione modulo) async {
    try {
      await _firestore
          .collection('moduli_coltivazione')
          .doc(modulo.id)
          .set(modulo.toFirestore());
    } catch (e) {
      print('Errore aggiunta modulo coltivazione: $e');
      rethrow;
    }
  }

  Stream<List<ModuloColtivazione>> getModuliColtivazione(String userId) {
    return _firestore
        .collection('moduli_coltivazione')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ModuloColtivazione.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> aggiornaModuloColtivazione(ModuloColtivazione modulo) async {
    try {
      await _firestore
          .collection('moduli_coltivazione')
          .doc(modulo.id)
          .update(modulo.toFirestore());
    } catch (e) {
      print('Errore aggiornamento modulo coltivazione: $e');
      rethrow;
    }
  }

  // === METODI per SERRE IDROPONICHE ===
  Future<void> aggiungiSerraIdroponica(SerraIdroponica serra) async {
    try {
      await _firestore
          .collection('serre_idroponiche')
          .doc(serra.id)
          .set(serra.toFirestore());
    } catch (e) {
      print('Errore aggiunta serra idroponica: $e');
      rethrow;
    }
  }

  Stream<List<SerraIdroponica>> getSerreIdroponiche(String userId) {
    return _firestore
        .collection('serre_idroponiche')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SerraIdroponica.fromFirestore(doc))
        .toList());
  }

  Future<void> aggiornaSerraIdroponica(SerraIdroponica serra) async {
    try {
      await _firestore
          .collection('serre_idroponiche')
          .doc(serra.id)
          .update(serra.toFirestore());
    } catch (e) {
      print('Errore aggiornamento serra idroponica: $e');
      rethrow;
    }
  }

  // === METODI per CENTRI AGRICOLI ===
  Future<void> aggiungiCentroAgricolo(CentroAgricolo centro) async {
    try {
      await _firestore
          .collection('centri_agricoli')
          .doc(centro.id)
          .set(centro.toFirestore());
    } catch (e) {
      print('Errore aggiunta centro agricolo: $e');
      rethrow;
    }
  }

  Stream<List<CentroAgricolo>> getCentriAgricoli(String userId) {
    return _firestore
        .collection('centri_agricoli')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => CentroAgricolo.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  Future<void> aggiornaCentroAgricolo(CentroAgricolo centro) async {
    try {
      await _firestore
          .collection('centri_agricoli')
          .doc(centro.id)
          .update(centro.toFirestore());
    } catch (e) {
      print('Errore aggiornamento centro agricolo: $e');
      rethrow;
    }
  }

  // === METODI di COMPATIBILITÀ (vecchi nomi) ===
  Future<void> aggiungiSerra(ModuloColtivazione modulo) async {
    return aggiungiModuloColtivazione(modulo);
  }

  Stream<List<ModuloColtivazione>> getSerre(String userId) {
    return getModuliColtivazione(userId);
  }

  Future<void> aggiornaSerra(ModuloColtivazione modulo) async {
    return aggiornaModuloColtivazione(modulo);
  }

  Future<bool> verificaCapacitaSerra(String serraId) async {
    try {
      final serraDoc = await _firestore
          .collection('serre_idroponiche')
          .doc(serraId)
          .get();

      if (!serraDoc.exists) return false;

      final serra = SerraIdroponica.fromFirestore(serraDoc);
      final conteggioModuli = await contaModuliPerSerra(serraId);

      return conteggioModuli < serra.capacitaModuli;
    } catch (e) {
      print('Errore verifica capacità serra: $e');
      return false;
    }
  }

  Future<bool> verificaCapacitaCentro(String centroId) async {
    try {
      final centroDoc = await _firestore
          .collection('centri_agricoli')
          .doc(centroId)
          .get();

      if (!centroDoc.exists) return false;

      final centroData = centroDoc.data();
      if (centroData == null) return false;

      final centro = CentroAgricolo.fromFirestore(centroData, centroId);
      final conteggioSerre = await contaSerrePerCentro(centroId);

      return conteggioSerre < centro.capacitaSerre;
    } catch (e) {
      print('Errore verifica capacità centro: $e');
      return false;
    }
  }

  // Metodo per ottenere tutti i moduli di una specifica serra
  Stream<List<ModuloColtivazione>> getModuliPerSerra(String serraId) {
    return _firestore
        .collection('moduli_coltivazione')
        .where('serraIdroponicaId', isEqualTo: serraId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ModuloColtivazione.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Metodo per ottenere tutte le serre di un specifico centro
  Stream<List<SerraIdroponica>> getSerrePerCentro(String centroId) {
    return _firestore
        .collection('serre_idroponiche')
        .where('centroAgricoloId', isEqualTo: centroId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => SerraIdroponica.fromFirestore(doc))
        .toList());
  }

  // Metodo per eliminare un modulo di coltivazione
  Future<void> eliminaModuloColtivazione(String moduloId) async {
    try {
      await _firestore
          .collection('moduli_coltivazione')
          .doc(moduloId)
          .delete();
    } catch (e) {
      print('Errore eliminazione modulo coltivazione: $e');
      rethrow;
    }
  }

  // Metodo per eliminare una serra idroponica
  Future<void> eliminaSerraIdroponica(String serraId) async {
    try {
      await _firestore
          .collection('serre_idroponiche')
          .doc(serraId)
          .delete();
    } catch (e) {
      print('Errore eliminazione serra idroponica: $e');
      rethrow;
    }
  }

  // Metodo per eliminare un centro agricolo
  Future<void> eliminaCentroAgricolo(String centroId) async {
    try {
      await _firestore
          .collection('centri_agricoli')
          .doc(centroId)
          .delete();
    } catch (e) {
      print('Errore eliminazione centro agricolo: $e');
      rethrow;
    }
  }
}