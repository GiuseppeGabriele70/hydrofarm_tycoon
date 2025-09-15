import 'package:cloud_firestore/cloud_firestore.dart';

// Nuovo modello per rappresentare uno slot di coltivazione all'interno di un modulo
class SlotColtivazione {
  final int slotIndex; // Indice dello slot (0, 1, 2...)
  String? piantaAttivaId; // ID del blueprint della pianta
  String? nomePianta;
  DateTime? plantedAt;
  int? growDurationSeconds;
  // Potresti aggiungere altri stati specifici dello slot, es. se è fertilizzato

  SlotColtivazione({
    required this.slotIndex,
    this.piantaAttivaId,
    this.nomePianta,
    this.plantedAt,
    this.growDurationSeconds,
  });

  factory SlotColtivazione.fromMap(Map<String, dynamic> data, int index) {
    return SlotColtivazione(
      slotIndex: index, // L'indice viene passato dalla lista
      piantaAttivaId: data['piantaAttivaId'] as String?,
      nomePianta: data['nomePianta'] as String?,
      plantedAt: (data['plantedAt'] is Timestamp)
          ? (data['plantedAt'] as Timestamp).toDate()
          : null,
      growDurationSeconds: data['growDurationSeconds'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'slotIndex' non è necessario salvarlo esplicitamente se l'ordine nella lista lo definisce
      'piantaAttivaId': piantaAttivaId,
      'nomePianta': nomePianta,
      'plantedAt': plantedAt != null ? Timestamp.fromDate(plantedAt!) : null,
      'growDurationSeconds': growDurationSeconds,
    };
  }

  // Helper per calcolare se questo specifico slot è maturo
  bool get isMature {
    if (plantedAt == null || growDurationSeconds == null || growDurationSeconds! <= 0) return false;
    final endTime = plantedAt!.add(Duration(seconds: growDurationSeconds!));
    return DateTime.now().isAfter(endTime);
  }

  Duration get remainingTime {
    if (plantedAt == null || growDurationSeconds == null || growDurationSeconds! <= 0) return Duration.zero;
    final endTime = plantedAt!.add(Duration(seconds: growDurationSeconds!));
    final diff = endTime.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

class ModuloColtivazione {
  final String id;
  final String nome;
  final int level;
  final int capienza; // Numero di slot totali in questo modulo
  final int statoEfficienza; // 0-100 (salute / manutenzione) - rinominato per chiarezza
  final String serraIdroponicaId;
  final DateTime createdAt;

  // Lista di slot di coltivazione
  List<SlotColtivazione> slots; // Ogni elemento rappresenta uno slot

  ModuloColtivazione({
    required this.id,
    required this.nome,
    this.level = 1,
    required this.capienza, // Ora è mandatoria
    this.statoEfficienza = 100,
    required this.serraIdroponicaId,
    DateTime? createdAt,
    List<SlotColtivazione>? slots, // Permetti di passare gli slot
  })  : createdAt = createdAt ?? DateTime.now(),
  // Inizializza la lista di slot. Se non vengono passati, crea slot vuoti fino alla capienza.
        slots = slots ?? List.generate(capienza, (index) => SlotColtivazione(slotIndex: index));

  factory ModuloColtivazione.fromFirestore(String id, Map<String, dynamic> data) {
    int moduleCapacity = (data['capienza'] as num?)?.toInt() ?? 1; // Default a 1 se non presente
    List<SlotColtivazione> parsedSlots = [];
    if (data['slots'] is List) {
      List<dynamic> slotsData = data['slots'] as List<dynamic>;
      for (int i = 0; i < slotsData.length; i++) {
        if (slotsData[i] is Map<String, dynamic>) {
          // Passiamo l'indice 'i' che corrisponde allo slotIndex
          parsedSlots.add(SlotColtivazione.fromMap(slotsData[i] as Map<String, dynamic>, i));
        }
      }
    }
    // Se gli slot letti sono meno della capienza, o se 'slots' non esiste,
    // popola gli slot mancanti/iniziali fino alla capienza.
    // Questo garantisce che `this.slots.length` sia sempre uguale a `this.capienza`.
    if (parsedSlots.length < moduleCapacity) {
      for (int i = parsedSlots.length; i < moduleCapacity; i++) {
        parsedSlots.add(SlotColtivazione(slotIndex: i));
      }
    }


    return ModuloColtivazione(
      id: id,
      nome: data['nome'] as String? ?? 'Modulo Coltivazione',
      level: (data['level'] as num?)?.toInt() ?? 1,
      capienza: moduleCapacity,
      statoEfficienza: (data['statoEfficienza'] as num?)?.toInt() ?? (data['stato'] as num?)?.toInt() ?? 100, // compatibilità con 'stato'
      serraIdroponicaId: data['serraIdroponicaId'] as String? ?? '',
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt'] as String? ?? '') ?? DateTime.now(),
      slots: parsedSlots,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'level': level,
      'capienza': capienza,
      'statoEfficienza': statoEfficienza,
      'serraIdroponicaId': serraIdroponicaId,
      'createdAt': Timestamp.fromDate(createdAt),
      'slots': slots.map((slot) => slot.toMap()).toList(), // Salva la lista di slot
    };
  }

  ModuloColtivazione copyWith({
    String? id,
    String? nome,
    int? level,
    int? capienza,
    int? statoEfficienza,
    String? serraIdroponicaId,
    DateTime? createdAt,
    List<SlotColtivazione>? slots,
  }) {
    return ModuloColtivazione(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      level: level ?? this.level,
      capienza: capienza ?? this.capienza, // Se la capienza cambia, la logica degli slot deve essere rivista
      statoEfficienza: statoEfficienza ?? this.statoEfficienza,
      serraIdroponicaId: serraIdroponicaId ?? this.serraIdroponicaId,
      createdAt: createdAt ?? this.createdAt,
      // Se viene passato un nuovo valore per `slots`, usa quello, altrimenti mantieni gli slot esistenti.
      // Se la capienza cambia, questo `copyWith` semplice potrebbe non essere sufficiente
      // e dovresti rigenerare gli slot in base alla nuova capienza.
      slots: slots ?? this.slots.map((s) => SlotColtivazione( // Crea copie profonde degli slot
          slotIndex: s.slotIndex,
          piantaAttivaId: s.piantaAttivaId,
          nomePianta: s.nomePianta,
          plantedAt: s.plantedAt,
          growDurationSeconds: s.growDurationSeconds
      )).toList(),
    );
  }

  // Helper per trovare il primo slot libero
  SlotColtivazione? getPrimoSlotLibero() {
    try {
      return slots.firstWhere((slot) => slot.piantaAttivaId == null || slot.piantaAttivaId!.isEmpty);
    } catch (e) {
      return null; // Nessuno slot libero
    }
  }

  // Helper per ottenere tutti gli slot pronti per la raccolta
  List<SlotColtivazione> getSlotsProntiPerRaccolta() {
    return slots.where((slot) => slot.piantaAttivaId != null && slot.piantaAttivaId!.isNotEmpty && slot.isMature).toList();
  }
}
