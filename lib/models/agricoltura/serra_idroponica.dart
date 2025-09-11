import 'package:cloud_firestore/cloud_firestore.dart';

class SerraIdroponica {
  final String id;
  final String nome;
  final String tipo;
  final int livello;
  final int capacitaModuli;
  final String centroAgricoloId;
  final String userId;
  final List<String> moduliColtivazioneIds;
  final int statoManutenzione; // 0-100%
  final bool isAttiva;
  final DateTime dataCostruzione;
  final DateTime? dataUltimaManutenzione;
  final double consumoEnergetico; // kWh
  final double consumoAcqua; // litri/ora

  SerraIdroponica({
    required this.id,
    required this.nome,
    this.tipo = 'base',
    this.livello = 1,
    this.capacitaModuli = 4,
    required this.centroAgricoloId,
    required this.userId,
    this.moduliColtivazioneIds = const [],
    this.statoManutenzione = 100,
    this.isAttiva = true,
    required this.dataCostruzione,
    this.dataUltimaManutenzione,
    this.consumoEnergetico = 2.5,
    this.consumoAcqua = 1.2,
  });

  factory SerraIdroponica.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SerraIdroponica(
      id: doc.id,
      nome: data['nome'] ?? 'Serra Idroponica',
      tipo: data['tipo'] ?? 'base',
      livello: data['livello'] ?? 1,
      capacitaModuli: data['capacitaModuli'] ?? 4,
      centroAgricoloId: data['centroAgricoloId'] ?? '',
      userId: data['userId'] ?? '',
      moduliColtivazioneIds: List<String>.from(data['moduliColtivazioneIds'] ?? []),
      statoManutenzione: data['statoManutenzione'] ?? 100,
      isAttiva: data['isAttiva'] ?? true,
      dataCostruzione: (data['dataCostruzione'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataUltimaManutenzione: (data['dataUltimaManutenzione'] as Timestamp?)?.toDate(),
      consumoEnergetico: (data['consumoEnergetico'] ?? 2.5).toDouble(),
      consumoAcqua: (data['consumoAcqua'] ?? 1.2).toDouble(),
    );
  }

  factory SerraIdroponica.fromMap(Map<String, dynamic> data, String id) {
    return SerraIdroponica(
      id: id,
      nome: data['nome'] ?? 'Serra Idroponica',
      tipo: data['tipo'] ?? 'base',
      livello: data['livello'] ?? 1,
      capacitaModuli: data['capacitaModuli'] ?? 4,
      centroAgricoloId: data['centroAgricoloId'] ?? '',
      userId: data['userId'] ?? '',
      moduliColtivazioneIds: List<String>.from(data['moduliColtivazioneIds'] ?? []),
      statoManutenzione: data['statoManutenzione'] ?? 100,
      isAttiva: data['isAttiva'] ?? true,
      dataCostruzione: (data['dataCostruzione'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dataUltimaManutenzione: (data['dataUltimaManutenzione'] as Timestamp?)?.toDate(),
      consumoEnergetico: (data['consumoEnergetico'] ?? 2.5).toDouble(),
      consumoAcqua: (data['consumoAcqua'] ?? 1.2).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'tipo': tipo,
      'livello': livello,
      'capacitaModuli': capacitaModuli,
      'centroAgricoloId': centroAgricoloId,
      'userId': userId,
      'moduliColtivazioneIds': moduliColtivazioneIds,
      'statoManutenzione': statoManutenzione,
      'isAttiva': isAttiva,
      'dataCostruzione': Timestamp.fromDate(dataCostruzione),
      'dataUltimaManutenzione': dataUltimaManutenzione != null
          ? Timestamp.fromDate(dataUltimaManutenzione!)
          : null,
      'consumoEnergetico': consumoEnergetico,
      'consumoAcqua': consumoAcqua,
      'ultimoAggiornamento': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMap() {
    return toFirestore();
  }

  // Metodi utility
  bool get isPiena => moduliColtivazioneIds.length >= capacitaModuli;

  int get moduliLiberi => capacitaModuli - moduliColtivazioneIds.length;

  double get efficienza {
    final baseEfficienza = 0.7 + (livello * 0.1);
    return baseEfficienza * (statoManutenzione / 100);
  }

  bool puoAggiungereModulo() {
    return moduliColtivazioneIds.length < capacitaModuli && isAttiva;
  }

  SerraIdroponica copyWith({
    String? id,
    String? nome,
    String? tipo,
    int? livello,
    int? capacitaModuli,
    String? centroAgricoloId,
    String? userId,
    List<String>? moduliColtivazioneIds,
    int? statoManutenzione,
    bool? isAttiva,
    DateTime? dataCostruzione,
    DateTime? dataUltimaManutenzione,
    double? consumoEnergetico,
    double? consumoAcqua,
  }) {
    return SerraIdroponica(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      livello: livello ?? this.livello,
      capacitaModuli: capacitaModuli ?? this.capacitaModuli,
      centroAgricoloId: centroAgricoloId ?? this.centroAgricoloId,
      userId: userId ?? this.userId,
      moduliColtivazioneIds: moduliColtivazioneIds ?? this.moduliColtivazioneIds,
      statoManutenzione: statoManutenzione ?? this.statoManutenzione,
      isAttiva: isAttiva ?? this.isAttiva,
      dataCostruzione: dataCostruzione ?? this.dataCostruzione,
      dataUltimaManutenzione: dataUltimaManutenzione ?? this.dataUltimaManutenzione,
      consumoEnergetico: consumoEnergetico ?? this.consumoEnergetico,
      consumoAcqua: consumoAcqua ?? this.consumoAcqua,
    );
  }

  @override
  String toString() {
    return 'SerraIdroponica($nome, Lv.$livello, Moduli: ${moduliColtivazioneIds.length}/$capacitaModuli)';
  }
}