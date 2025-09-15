// lib/models/agricoltura/centro_agricolo.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CentroAgricolo {
  final String id;
  final String nome;
  final String userId;
  final String ubicazione;
  final int livello;
  final int capacitaSerre;
  final List<String> serreIdroponicheIds;
  final DateTime dataFondazione;
  final double efficienzaTotale;
  final int statoManutenzione;

  CentroAgricolo({
    required this.id,
    required this.nome,
    required this.userId,
    this.ubicazione = 'Località Predefinita',
    this.livello = 1,
    this.capacitaSerre = 3,
    this.serreIdroponicheIds = const [],
    required this.dataFondazione,
    this.efficienzaTotale = 0.8,
    this.statoManutenzione = 100,
  });

  // MODIFICATO: Accetta (String id, Map<String, dynamic> data) per coerenza
  factory CentroAgricolo.fromFirestore(String id, Map<String, dynamic> data) {
    return CentroAgricolo(
      id: id, // Usa l'ID passato
      nome: data['nome'] as String? ?? 'Centro Agricolo',
      userId: data['userId'] as String? ?? '',
      ubicazione: data['ubicazione'] as String? ?? 'Località Predefinita',
      livello: data['livello'] as int? ?? 1,
      capacitaSerre: data['capacitaSerre'] as int? ?? 3,
      serreIdroponicheIds: List<String>.from(data['serreIdroponicheIds'] as List? ?? []),
      dataFondazione: (data['dataFondazione'] as Timestamp?)?.toDate() ?? DateTime.now(),
      efficienzaTotale: (data['efficienzaTotale'] as num?)?.toDouble() ?? 0.8,
      statoManutenzione: data['statoManutenzione'] as int? ?? 100,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'userId': userId,
      'ubicazione': ubicazione,
      'livello': livello,
      'capacitaSerre': capacitaSerre,
      'serreIdroponicheIds': serreIdroponicheIds,
      'dataFondazione': Timestamp.fromDate(dataFondazione),
      'efficienzaTotale': efficienzaTotale,
      'statoManutenzione': statoManutenzione,
      'ultimoAggiornamento': FieldValue.serverTimestamp(),
    };
  }

  // Se hai un fromMap, considera di allinearlo o di avere una logica chiara per quando usare quale.
  // Per ora, lo lascio implicito che si userà fromFirestore.
  // factory CentroAgricolo.fromMap(Map<String, dynamic> data, String id) {
  //   return CentroAgricolo.fromFirestore(id, data); // Esempio se vuoi allinearlo
  // }

  Map<String, dynamic> toMap() {
    return toFirestore();
  }

  bool get isPieno => serreIdroponicheIds.length >= capacitaSerre;
  int get serreLibere => capacitaSerre - serreIdroponicheIds.length;
  bool puoAggiungereSerra() {
    return serreIdroponicheIds.length < capacitaSerre;
  }

  CentroAgricolo copyWith({
    String? id,
    String? nome,
    String? userId,
    String? ubicazione,
    int? livello,
    int? capacitaSerre,
    List<String>? serreIdroponicheIds,
    DateTime? dataFondazione,
    double? efficienzaTotale,
    int? statoManutenzione,
  }) {
    return CentroAgricolo(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      userId: userId ?? this.userId,
      ubicazione: ubicazione ?? this.ubicazione,
      livello: livello ?? this.livello,
      capacitaSerre: capacitaSerre ?? this.capacitaSerre,
      serreIdroponicheIds: serreIdroponicheIds ?? this.serreIdroponicheIds,
      dataFondazione: dataFondazione ?? this.dataFondazione,
      efficienzaTotale: efficienzaTotale ?? this.efficienzaTotale,
      statoManutenzione: statoManutenzione ?? this.statoManutenzione,
    );
  }

  @override
  String toString() {
    return 'CentroAgricolo($nome, Lv.$livello, Serre: ${serreIdroponicheIds.length}/$capacitaSerre)';
  }
}

