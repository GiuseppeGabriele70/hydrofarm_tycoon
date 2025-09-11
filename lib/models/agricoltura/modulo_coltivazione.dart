import 'package:cloud_firestore/cloud_firestore.dart';

class ModuloColtivazione {
  final String id;
  final String nome;
  final int level;
  final int capienza; // numero di slot = numero di piante contemporanee
  final int stato; // 0-100 (salute / manutenzione)
  final String serraIdroponicaId; // riferimento alla serra che lo contiene
  final DateTime createdAt;

  // 🔥 nuovi campi
  final String? piantaAttiva; // es. "basilico", "rucola"
  final DateTime? plantedAt; // quando è stata avviata la coltivazione
  final int? growDurationSeconds; // tempo di crescita in secondi

  ModuloColtivazione({
    required this.id,
    required this.nome,
    this.level = 1,
    this.capienza = 10,
    this.stato = 100,
    required this.serraIdroponicaId,
    DateTime? createdAt,
    this.piantaAttiva,
    this.plantedAt,
    this.growDurationSeconds,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Costruisce da Firestore
  factory ModuloColtivazione.fromFirestore(Map<String, dynamic> data, String id) {
    return ModuloColtivazione(
      id: id,
      nome: data['nome'] ?? 'Modulo Coltivazione',
      level: data['level'] ?? 1,
      capienza: data['capienza'] ?? 10,
      stato: data['stato'] ?? 100,
      serraIdroponicaId: data['serraIdroponicaId'] ?? data['serraId'] ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      piantaAttiva: data['piantaAttiva'],
      plantedAt: (data['plantedAt'] is Timestamp)
          ? (data['plantedAt'] as Timestamp).toDate()
          : null,
      growDurationSeconds: data['growDurationSeconds'],
    );
  }

  /// Converte in JSON per Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'level': level,
      'capienza': capienza,
      'stato': stato,
      'serraIdroponicaId': serraIdroponicaId,
      'createdAt': Timestamp.fromDate(createdAt),
      'piantaAttiva': piantaAttiva,
      'plantedAt': plantedAt != null ? Timestamp.fromDate(plantedAt!) : null,
      'growDurationSeconds': growDurationSeconds,
    };
  }

  /// Factory di compatibilità
  factory ModuloColtivazione.fromMap(Map<String, dynamic> data, String id) {
    return ModuloColtivazione.fromFirestore(data, id);
  }

  Map<String, dynamic> toMap() {
    return toFirestore();
  }

  /// 👀 helper per sapere se il raccolto è pronto
  bool get isMature {
    if (plantedAt == null || growDurationSeconds == null) return false;
    final end = plantedAt!.add(Duration(seconds: growDurationSeconds!));
    return DateTime.now().isAfter(end);
  }
}
