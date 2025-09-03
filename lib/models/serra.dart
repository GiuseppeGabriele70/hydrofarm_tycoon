import 'package:cloud_firestore/cloud_firestore.dart';

class Serra {
  final String id;
  final String nome;
  final int level;
  final int capienza;
  final int stato; // 0-100 (salute / manutenzione)
  final DateTime createdAt;

  Serra({
    required this.id,
    required this.nome,
    this.level = 1,
    this.capienza = 10,
    this.stato = 100,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Costruisce da Firestore
  factory Serra.fromFirestore(Map<String, dynamic> data, String id) {
    return Serra(
      id: id,
      nome: data['nome'] ?? 'Serra',
      level: data['level'] ?? 1,
      capienza: data['capienza'] ?? 10,
      stato: data['stato'] ?? 100,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Converte in JSON per Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'level': level,
      'capienza': capienza,
      'stato': stato,
      'createdAt': createdAt,
    };
  }
}
