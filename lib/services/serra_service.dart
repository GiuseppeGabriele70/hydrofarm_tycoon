import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/agricoltura/modulo_coltivazione.dart';

class SerraService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ModuloColtivazione>> getSerre(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('serre')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ModuloColtivazione.fromFirestore(doc.data(), doc.id))
        .toList());
  }

  // Metodo di compatibilità per il nuovo nome
  Stream<List<ModuloColtivazione>> getModuliColtivazione(String userId) {
    return getSerre(userId);
  }

  Future<void> addSerra(String userId, ModuloColtivazione modulo) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('serre')
          .doc(modulo.id)
          .set(modulo.toFirestore());
    } catch (e) {
      print('Errore aggiunta modulo: $e');
      rethrow;
    }
  }

  Future<void> updateSerra(String userId, ModuloColtivazione modulo) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('serre')
          .doc(modulo.id)
          .update(modulo.toFirestore());
    } catch (e) {
      print('Errore aggiornamento modulo: $e');
      rethrow;
    }
  }

  Future<void> deleteSerra(String userId, String moduloId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('serre')
          .doc(moduloId)
          .delete();
    } catch (e) {
      print('Errore eliminazione modulo: $e');
      rethrow;
    }
  }
}