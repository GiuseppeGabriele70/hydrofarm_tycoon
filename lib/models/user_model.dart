// File: lib/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// --- INIZIO CLASSE GrowingPlant ---
// Modello per una pianta in crescita in una specifica serra/modulo
class GrowingPlant {
  final String plantId;    // ID del blueprint della pianta (es. "arugula")
  final String plantName;  // Nome del blueprint della pianta (es. "Rucola") - denormalizzato
  final DateTime plantedAt;  // Quando questo batch/modulo è stato piantato
  final int serraIndex;   // Indice del modulo/serra (0, 1, 2...) in cui questo batch sta crescendo

  GrowingPlant({
    required this.plantId,
    required this.plantName,
    required this.plantedAt,
    required this.serraIndex,
  });

  Map<String, dynamic> toMap() {
    return {
      'plantId': plantId,
      'plantName': plantName,
      'plantedAt': Timestamp.fromDate(plantedAt), // Salva come Timestamp Firestore
      'serraIndex': serraIndex,
    };
  }

  factory GrowingPlant.fromMap(Map<String, dynamic> map) {
    if (map['plantId'] == null || map['plantedAt'] == null || map['serraIndex'] == null) {
      // Potresti voler gestire questo in modo più robusto,
      // ad esempio, fornendo valori di default o loggando un errore più specifico.
      throw ArgumentError('Dati mancanti per creare GrowingPlant dalla mappa: $map');
    }
    return GrowingPlant(
      plantId: map['plantId'] as String,
      plantName: map['plantName'] as String? ?? '', // Default a stringa vuota se plantName non c'è
      plantedAt: (map['plantedAt'] as Timestamp).toDate(), // Converti Timestamp in DateTime
      serraIndex: map['serraIndex'] as int,
    );
  }

  @override
  String toString() {
    return 'GrowingPlant(plantId: $plantId, plantName: $plantName, plantedAt: $plantedAt, serraIndex: $serraIndex)';
  }
}
// --- FINE CLASSE GrowingPlant ---

class UserModel {
  final String uid;
  final String email;
  int money;
  int loan;
  int moduliColtivazione; // Numero totale di serre/moduli che l'utente possiede
  final DateTime createdAt;
  int level;
  final List<String> centriAgricoliIds;
  final List<String> serreIdroponicheIds; // Considera se questo è ancora necessario o se moduliColtivazione è sufficiente

  // MODIFICATO: Lista delle piante/batch attualmente in crescita
  final List<GrowingPlant> growingPlants;

  UserModel({
    required this.uid,
    required this.email,
    required this.money,
    required this.loan,
    required this.moduliColtivazione,
    required this.createdAt,
    this.level = 1, // Default per level
    this.centriAgricoliIds = const [],
    this.serreIdroponicheIds = const [],
    this.growingPlants = const [], // Default a lista vuota
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid, // Includere l'UID è una buona pratica
      'email': email,
      'money': money,
      'loan': loan,
      'moduliColtivazione': moduliColtivazione,
      // 'serre': moduliColtivazione, // Rimosso 'serre' se 'moduliColtivazione' è il campo ufficiale.
      // Se serve per retrocompatibilità stringente, puoi tenerlo.
      'createdAt': Timestamp.fromDate(createdAt),
      'level': level,
      'centriAgricoliIds': centriAgricoliIds,
      'serreIdroponicheIds': serreIdroponicheIds,
      'growingPlants': growingPlants.map((plant) => plant.toMap()).toList(), // Serializza la lista
    };
  }

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    if (kDebugMode) {
      print(">>> UserModel.fromFirestore - Dati grezzi ricevuti per doc ID ${doc.id}: $data");
    }

    if (data == null || data.isEmpty) {
      if (kDebugMode) print(">>> UserModel.fromFirestore - Documento vuoto o nullo per ID ${doc.id}. Creo UserModel di default.");
      // Fornisce valori di default sensati per un nuovo utente o un documento vuoto/corrotto
      return UserModel(
        uid: doc.id,
        email: '', // L'email potrebbe essere impostata successivamente dal flusso di autenticazione
        money: 100,
        loan: 0,
        moduliColtivazione: 1, // Default a 1 modulo/serra
        createdAt: DateTime.now(),
        level: 1,
        centriAgricoliIds: [],
        serreIdroponicheIds: [],
        growingPlants: [],
      );
    }

    List<GrowingPlant> loadedGrowingPlants = [];
    if (data['growingPlants'] != null && data['growingPlants'] is List) {
      loadedGrowingPlants = (data['growingPlants'] as List).map((plantData) {
        try {
          return GrowingPlant.fromMap(plantData as Map<String, dynamic>);
        } catch (e) {
          if (kDebugMode) {
            print(">>> UserModel.fromFirestore - Errore nel deserializzare una GrowingPlant: $e. Dati pianta: $plantData. La salto.");
          }
          return null;
        }
      }).whereType<GrowingPlant>().toList(); // Filtra via i null se qualche pianta è corrotta
    } else if (kDebugMode && data['growingPlants'] != null) {
      print(">>> UserModel.fromFirestore - campo 'growingPlants' presente ma non è una Lista: ${data['growingPlants'].runtimeType}");
    }

    // Gestione compatibilità per 'serre' e 'moduliColtivazione'
    int moduli = data['moduliColtivazione'] as int? ?? data['serre'] as int? ?? 1;

    // Rimozione dei campi deprecati se presenti nei dati ma non più nel costruttore
    // data.remove('currentPlantId');
    // data.remove('currentPlantName');
    // data.remove('plantedAt');

    return UserModel(
      uid: doc.id,
      email: data['email'] as String? ?? '',
      money: data['money'] as int? ?? 0,
      loan: data['loan'] as int? ?? 0,
      moduliColtivazione: moduli,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      level: data['level'] as int? ?? 1,
      centriAgricoliIds: List<String>.from(data['centriAgricoliIds'] as List<dynamic>? ?? []),
      serreIdroponicheIds: List<String>.from(data['serreIdroponicheIds'] as List<dynamic>? ?? []),
      growingPlants: loadedGrowingPlants,
    );
  }

  // Getter di compatibilità se vuoi mantenere 'serre' come alias
  int get serre => moduliColtivazione;

  bool hasCentroAgricolo(String centroId) => centriAgricoliIds.contains(centroId);
  bool hasSerraIdroponica(String serraId) => serreIdroponicheIds.contains(serraId);

  UserModel copyWith({
    String? uid,
    String? email,
    int? money,
    int? loan,
    int? moduliColtivazione,
    DateTime? createdAt,
    int? level,
    List<String>? centriAgricoliIds,
    List<String>? serreIdroponicheIds,
    List<GrowingPlant>? growingPlants, // Aggiornato per accettare una nuova lista
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      money: money ?? this.money,
      loan: loan ?? this.loan,
      moduliColtivazione: moduliColtivazione ?? this.moduliColtivazione,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
      centriAgricoliIds: centriAgricoliIds ?? this.centriAgricoliIds,
      serreIdroponicheIds: serreIdroponicheIds ?? this.serreIdroponicheIds,
      growingPlants: growingPlants ?? this.growingPlants, // Aggiornato
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, money: $money, moduliColtivazione: $moduliColtivazione, level: $level, growingPlantsCount: ${growingPlants.length})';
  }
}
