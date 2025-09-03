import 'package:cloud_firestore/cloud_firestore.dart'; // Necessario per Timestamp
import 'package:flutter/foundation.dart'; // Necessario per kDebugMode

class UserModel {
  final String uid;
  final String email;
  int money;
  int loan;
  int serre;
  final DateTime createdAt;
  int level; // <-- NUOVO CAMPO: Livello dell'utente

  String? currentPlantId;
  String? currentPlantName;
  DateTime? plantedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.money,
    required this.loan,
    required this.serre,
    required this.createdAt,
    this.level = 1, // <-- Default a livello 1 per nuovi utenti o se non specificato
    this.currentPlantId,
    this.currentPlantName,
    this.plantedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'money': money,
      'loan': loan,
      'serre': serre,
      'createdAt': Timestamp.fromDate(createdAt),
      'level': level, // <-- AGGIUNGI level ALLA MAPPA
      'currentPlantId': currentPlantId,
      'currentPlantName': currentPlantName,
      'plantedAt': plantedAt != null ? Timestamp.fromDate(plantedAt!) : null,
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    if (kDebugMode) {
      print(">>> UserModel.fromFirestore - Dati grezzi ricevuti per doc ID ${doc.id}: $data");
    }

    if (data == null) {
      throw StateError("Dati mancanti per il documento utente: ${doc.id}");
    }

    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      money: data['money'] as int? ?? 0,
      loan: data['loan'] as int? ?? 0,
      serre: data['serre'] as int? ?? 1,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      level: data['level'] as int? ?? 1, // <-- LEGGI level DA FIRESTORE, default a 1
      currentPlantId: data['currentPlantId'] as String?,
      currentPlantName: data['currentPlantName'] as String?,
      plantedAt: (data['plantedAt'] as Timestamp?)?.toDate(),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    if (kDebugMode) {
      print(">>> UserModel.fromMap - Dati grezzi ricevuti per doc ID $documentId: $map");
    }
    return UserModel(
      uid: documentId,
      email: map['email'] as String? ?? '',
      money: map['money'] as int? ?? 0,
      loan: map['loan'] as int? ?? 0,
      serre: map['serre'] as int? ?? 1,
      createdAt: map['createdAt'] is String
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : (map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now()),
      level: map['level'] as int? ?? 1, // <-- LEGGI level DALLA MAPPA, default a 1
      currentPlantId: map['currentPlantId'] as String?,
      currentPlantName: map['currentPlantName'] as String?,
      plantedAt: map['plantedAt'] is String
          ? DateTime.tryParse(map['plantedAt'] as String)
          : (map['plantedAt'] is Timestamp
          ? (map['plantedAt'] as Timestamp).toDate()
          : null),
    );
  }

  // Potresti aggiungere un metodo copyWith per facilitare gli aggiornamenti immutabili
  UserModel copyWith({
    String? uid,
    String? email,
    int? money,
    int? loan,
    int? serre,
    DateTime? createdAt,
    int? level,
    String? currentPlantId,
    // Usa Object() per distinguere un valore esplicitamente nullo da nessun valore fornito
    dynamic currentPlantName = const Object(), // Per permettere di settare currentPlantName a null
    dynamic plantedAt = const Object(),       // Per permettere di settare plantedAt a null
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      money: money ?? this.money,
      loan: loan ?? this.loan,
      serre: serre ?? this.serre,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      currentPlantId: currentPlantId ?? this.currentPlantId,
      currentPlantName: currentPlantName is String? ? currentPlantName : this.currentPlantName,
      plantedAt: plantedAt is DateTime? ? plantedAt : this.plantedAt,
    );
  }
}
