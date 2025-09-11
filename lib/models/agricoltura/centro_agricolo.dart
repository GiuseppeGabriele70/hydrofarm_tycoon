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

  factory CentroAgricolo.fromFirestore(Map<String, dynamic> data, String id) {
    return CentroAgricolo(
      id: id,
      nome: data['nome'] ?? 'Centro Agricolo',
      userId: data['userId'] ?? '',
      ubicazione: data['ubicazione'] ?? 'Località Predefinita',
      livello: data['livello'] ?? 1,
      capacitaSerre: data['capacitaSerre'] ?? 3,
      serreIdroponicheIds: List<String>.from(data['serreIdroponicheIds'] ?? []),
      dataFondazione: (data['dataFondazione'] as Timestamp?)?.toDate() ?? DateTime.now(),
      efficienzaTotale: (data['efficienzaTotale'] ?? 0.8).toDouble(),
      statoManutenzione: data['statoManutenzione'] ?? 100,
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

  Map<String, dynamic> toMap() {
    return toFirestore();
  }

  // Metodi utility
  bool get isPieno => serreIdroponicheIds.length >= capacitaSerre;

  int get serreLibere => capacitaSerre - serreIdroponicheIds.length;

  bool puoAggiungereSerra() {
    return serreIdroponicheIds.length < capacitaSerre;
  }

  // RIMOSSO IL METODO PROBLEMATICO - può essere implementato altrove
  // double calcolaEfficienzaTotale(List<SerraIdroponica> serre) {
  //   if (serre.isEmpty) return efficienzaTotale;

  //   final efficienzaMedia = serre
  //       .where((s) => serreIdroponicheIds.contains(s.id))
  //       .map((s) => s.efficienza)
  //       .reduce((a, b) => a + b) / serre.length;

  //   return efficienzaMedia * (statoManutenzione / 100);
  // }

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