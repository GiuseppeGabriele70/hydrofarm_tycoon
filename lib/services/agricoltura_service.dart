// lib/services/agricoltura_service.dart
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
          .collectionGroup('moduli_coltivazione')
          .where('serraIdroponicaId', isEqualTo: serraId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Errore conteggio moduli per serra $serraId: $e');
      return 0;
    }
  }

  Future<int> contaSerrePerCentro(String centroId) async {
    try {
      final snapshot = await _firestore
          .collectionGroup('serre_idroponiche')
          .where('centroAgricoloId', isEqualTo: centroId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Errore conteggio serre per centro $centroId: $e');
      return 0;
    }
  }

  Future<int> contaModuliPerSerraAlternativo(String serraId) async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('moduli_coltivazione')
          .where('serraIdroponicaId', isEqualTo: serraId)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Errore conteggio moduli per serra (alt) $serraId: $e');
      return 0;
    }
  }

  Future<int> contaSerrePerCentroAlternativo(String centroId) async {
    try {
      final querySnapshot = await _firestore
          .collectionGroup('serre_idroponiche')
          .where('centroAgricoloId', isEqualTo: centroId)
          .get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Errore conteggio serre per centro (alt) $centroId: $e');
      return 0;
    }
  }

  // === METODI per MODULI di COLTIVAZIONE ===
  Future<void> aggiungiModuloColtivazione(ModuloColtivazione modulo, {String? pathPrefix}) async {
    try {
      CollectionReference moduliRef = _firestore.collection(
          pathPrefix != null ? '$pathPrefix/moduli_coltivazione' : 'moduli_coltivazione');
      await moduliRef.doc(modulo.id).set(modulo.toFirestore());
    } catch (e) {
      print('Errore aggiunta modulo coltivazione: $e');
      rethrow;
    }
  }

  Stream<List<ModuloColtivazione>> getModuliColtivazioneUtente(String userId) {
    return _firestore
        .collection('moduli_coltivazione') // Assumendo collezione root o un percorso gestito da field 'userId'
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          // CORRETTO: Passa id e data al factory
          return ModuloColtivazione.fromFirestore(doc.id, doc.data());
        }).toList();
      } catch (e) {
        print("Errore deserializzazione ModuliColtivazione: $e");
        return <ModuloColtivazione>[];
      }
    });
  }

  Future<void> aggiornaModuloColtivazione(ModuloColtivazione modulo, {String? pathPrefix}) async {
    try {
      CollectionReference moduliRef = _firestore.collection(
          pathPrefix != null ? '$pathPrefix/moduli_coltivazione' : 'moduli_coltivazione');
      await moduliRef.doc(modulo.id).update(modulo.toFirestore());
    } catch (e) {
      print('Errore aggiornamento modulo coltivazione: $e');
      rethrow;
    }
  }

  // === METODI per SERRE IDROPONICHE ===
  Future<void> aggiungiSerraIdroponica(SerraIdroponica serra, {String? pathPrefix}) async {
    try {
      CollectionReference serreRef = _firestore.collection(
          pathPrefix != null ? '$pathPrefix/serre_idroponiche' : 'serre_idroponiche');
      await serreRef.doc(serra.id).set(serra.toFirestore());
    } catch (e) {
      print('Errore aggiunta serra idroponica: $e');
      rethrow;
    }
  }

  Stream<List<SerraIdroponica>> getSerreIdroponicheUtente(String userId) {
    return _firestore
        .collection('serre_idroponiche') // Assumendo collezione root o un percorso gestito da field 'userId'
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          // CORRETTO: Passa id e data al factory
          // Assicurati che SerraIdroponica.fromFirestore sia (String id, Map<String, dynamic> data)
          return SerraIdroponica.fromFirestore(doc.id, doc.data());
        }).toList();
      } catch (e) {
        print("Errore deserializzazione SerreIdroponiche: $e");
        return <SerraIdroponica>[];
      }
    });
  }

  Future<void> aggiornaSerraIdroponica(SerraIdroponica serra, {String? pathPrefix}) async {
    try {
      CollectionReference serreRef = _firestore.collection(
          pathPrefix != null ? '$pathPrefix/serre_idroponiche' : 'serre_idroponiche');
      await serreRef.doc(serra.id).update(serra.toFirestore());
    } catch (e) {
      print('Errore aggiornamento serra idroponica: $e');
      rethrow;
    }
  }

  // === METODI per CENTRI AGRICOLI ===
  Future<void> aggiungiCentroAgricolo(CentroAgricolo centro, {String? pathPrefix}) async {
    try {
      CollectionReference centriRef = _firestore.collection(
          pathPrefix != null ? '$pathPrefix/centri_agricoli' : 'centri_agricoli');
      await centriRef.doc(centro.id).set(centro.toFirestore());
    } catch (e) {
      print('Errore aggiunta centro agricolo: $e');
      rethrow;
    }
  }

  Stream<List<CentroAgricolo>> getCentriAgricoliUtente(String userId) {
    return _firestore
        .collection('centri_agricoli') // Assumendo collezione root o un percorso gestito da field 'userId'
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          // CORRETTO: Passa id e data al factory
          // Assicurati che CentroAgricolo.fromFirestore sia (String id, Map<String, dynamic> data)
          return CentroAgricolo.fromFirestore(doc.id, doc.data());
        }).toList();
      } catch (e) {
        print("Errore deserializzazione CentriAgricoli: $e");
        return <CentroAgricolo>[];
      }
    });
  }

  Future<void> aggiornaCentroAgricolo(CentroAgricolo centro, {String? pathPrefix}) async {
    try {
      CollectionReference centriRef = _firestore.collection(
          pathPrefix != null ? '$pathPrefix/centri_agricoli' : 'centri_agricoli');
      await centriRef.doc(centro.id).update(centro.toFirestore());
    } catch (e) {
      print('Errore aggiornamento centro agricolo: $e');
      rethrow;
    }
  }

  // COMPATIBILITÀ
  Future<void> aggiungiSerraCompat(ModuloColtivazione modulo) async {
    return aggiungiModuloColtivazione(modulo);
  }

  Stream<List<ModuloColtivazione>> getSerreCompat(String userId) {
    return getModuliColtivazioneUtente(userId);
  }

  Future<void> aggiornaSerraCompat(ModuloColtivazione modulo) async {
    return aggiornaModuloColtivazione(modulo);
  }

  Future<bool> verificaCapacitaSerra(String serraId, {String? pathPrefixSerra}) async {
    try {
      DocumentReference serraDocRef = pathPrefixSerra != null
          ? _firestore.collection('$pathPrefixSerra/serre_idroponiche').doc(serraId)
          : _firestore.collection('serre_idroponiche').doc(serraId); // Assumendo collezione root se no prefix

      final serraDoc = await serraDocRef.get();

      if (!serraDoc.exists) {
        print("Verifica capacità: Serra $serraId non trovata.");
        return false;
      }
      final serraData = serraDoc.data() as Map<String, dynamic>?;
      if (serraData == null) {
        print("Verifica capacità: Dati nulli per serra $serraId.");
        return false;
      }
      // CORRETTO: Passa id e data al factory
      // Assicurati che SerraIdroponica.fromFirestore sia (String id, Map<String, dynamic> data)
      final serra = SerraIdroponica.fromFirestore(serraDoc.id, serraData);
      final conteggioModuli = await contaModuliPerSerra(serraId);

      return conteggioModuli < serra.capacitaModuli;
    } catch (e) {
      print('Errore verifica capacità serra $serraId: $e');
      return false;
    }
  }

  Future<bool> verificaCapacitaCentro(String centroId, {String? pathPrefixCentro}) async {
    try {
      DocumentReference centroDocRef = pathPrefixCentro != null
          ? _firestore.collection('$pathPrefixCentro/centri_agricoli').doc(centroId)
          : _firestore.collection('centri_agricoli').doc(centroId); // Assumendo collezione root se no prefix

      final centroDoc = await centroDocRef.get();

      if (!centroDoc.exists) {
        print("Verifica capacità: Centro $centroId non trovato.");
        return false;
      }
      final centroData = centroDoc.data() as Map<String, dynamic>?;
      if (centroData == null) {
        print("Verifica capacità: Dati nulli per centro $centroId.");
        return false;
      }
      // CORRETTO: Passa id e data al factory
      // Assicurati che CentroAgricolo.fromFirestore sia (String id, Map<String, dynamic> data)
      final centro = CentroAgricolo.fromFirestore(centroDoc.id, centroData);
      final conteggioSerre = await contaSerrePerCentro(centroId);

      return conteggioSerre < centro.capacitaSerre;
    } catch (e) {
      print('Errore verifica capacità centro $centroId: $e');
      return false;
    }
  }

  Stream<List<ModuloColtivazione>> getModuliPerSerra(String serraId, {String? collectionPath}) {
    // Se 'moduli_coltivazione' è una sottocollezione, potresti aver bisogno di costruire il path completo
    // o affidarti a collectionGroup se vuoi cercare in tutti i percorsi.
    Query query = _firestore.collectionGroup('moduli_coltivazione');
    query = query.where('serraIdroponicaId', isEqualTo: serraId);

    return query.snapshots().map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          // CORRETTO: Passa id e data al factory
          return ModuloColtivazione.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      } catch (e) {
        print("Errore deserializzazione Moduli per serra $serraId: $e");
        return <ModuloColtivazione>[];
      }
    });
  }

  Stream<List<SerraIdroponica>> getSerrePerCentro(String centroId, {String? collectionPath}) {
    // Simile a getModuliPerSerra, considera la struttura del DB per collectionGroup vs path diretti
    Query query = _firestore.collectionGroup('serre_idroponiche');
    query = query.where('centroAgricoloId', isEqualTo: centroId);

    return query.snapshots().map((snapshot) {
      try {
        return snapshot.docs.map((doc) {
          // CORRETTO: Passa id e data al factory
          // Assicurati che SerraIdroponica.fromFirestore sia (String id, Map<String, dynamic> data)
          return SerraIdroponica.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
        }).toList();
      } catch (e) {
        print("Errore deserializzazione Serre per centro $centroId: $e");
        return <SerraIdroponica>[];
      }
    });
  }

  Future<void> eliminaModuloColtivazione(String moduloId, {String? path}) async {
    try {
      DocumentReference docRef = path != null
          ? _firestore.doc('$path/$moduloId') // Es: path = 'users/uid/centri/cid/serre/sid/moduli_coltivazione'
          : _firestore.collection('moduli_coltivazione').doc(moduloId);
      await docRef.delete();
    } catch (e) {
      print('Errore eliminazione modulo coltivazione $moduloId: $e');
      rethrow;
    }
  }

  Future<void> eliminaSerraIdroponica(String serraId, {String? path}) async {
    try {
      DocumentReference docRef = path != null
          ? _firestore.doc('$path/$serraId') // Es: path = 'users/uid/centri/cid/serre_idroponiche'
          : _firestore.collection('serre_idroponiche').doc(serraId);
      await docRef.delete();
    } catch (e) {
      print('Errore eliminazione serra idroponica $serraId: $e');
      rethrow;
    }
  }

  Future<void> eliminaCentroAgricolo(String centroId, {String? path}) async {
    try {
      DocumentReference docRef = path != null
          ? _firestore.doc('$path/$centroId') // Es: path = 'users/uid/centri_agricoli'
          : _firestore.collection('centri_agricoli').doc(centroId);
      await docRef.delete();
    } catch (e) {
      print('Errore eliminazione centro agricolo $centroId: $e');
      rethrow;
    }
  }
}

