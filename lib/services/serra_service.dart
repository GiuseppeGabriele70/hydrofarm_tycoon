import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/serra.dart';

class SerraService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Serra>> getSerre(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('serre')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Serra.fromFirestore(doc.data(), doc.id))
        .toList());
  }
}
