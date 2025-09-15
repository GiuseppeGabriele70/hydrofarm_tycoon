// lib/providers/farming_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
// Il percorso del modello ModuloColtivazione è cruciale
import '../models/agricoltura/modulo_coltivazione.dart';
import '../models/plant.dart';
import '../services/database_service.dart';
import './user_provider.dart';

class FarmingProvider with ChangeNotifier {
  final DatabaseService databaseService;
  final String userId;
  final String centroId;
  final String serraId;
  final String moduloId;

  ModuloColtivazione? _modulo;
  bool _isLoading = false;
  String? _errorMessage;

  // Mappa per i timer dei singoli slot: Key = slotIndex, Value = Timer
  final Map<int, Timer?> _slotTimers = {};
  // Mappa per il tempo rimanente dei singoli slot: Key = slotIndex, Value = Duration
  final Map<int, Duration> _slotRemainingTimes = {};
  bool _isDisposed = false;


  ModuloColtivazione? get modulo => _modulo;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Metodi per interrogare lo stato degli slot
  Duration getRemainingTimeForSlot(int slotIndex) {
    if (_modulo == null || slotIndex < 0 || slotIndex >= _modulo!.slots.length) return Duration.zero;
    return _slotRemainingTimes[slotIndex] ?? Duration.zero;
  }

  bool isSlotGrowing(int slotIndex) {
    if (_modulo == null || slotIndex < 0 || slotIndex >= _modulo!.slots.length) return false;
    final slot = _modulo!.slots[slotIndex];
    return slot.piantaAttivaId != null &&
        slot.piantaAttivaId!.isNotEmpty &&
        (getRemainingTimeForSlot(slotIndex).inSeconds > 0);
  }

  bool isSlotReadyToHarvest(int slotIndex) {
    if (_modulo == null || slotIndex < 0 || slotIndex >= _modulo!.slots.length) return false;
    final slot = _modulo!.slots[slotIndex];
    // Considera anche il caso in cui growDurationSeconds sia 0 o null per una pianta che non cresce
    if (slot.piantaAttivaId == null || slot.piantaAttivaId!.isEmpty || slot.growDurationSeconds == null || slot.growDurationSeconds! <= 0) {
      return false; // Non può essere pronta se non c'è una pianta che cresce
    }
    return getRemainingTimeForSlot(slotIndex).inSeconds <= 0;
  }

  bool get hasAnySlotReadyToHarvest => _modulo?.slots.any((s) => isSlotReadyToHarvest(s.slotIndex)) ?? false;
  int get busySlotsCount => _modulo?.slots.where((s) => s.piantaAttivaId != null && s.piantaAttivaId!.isNotEmpty).length ?? 0;


  FarmingProvider({
    required this.databaseService,
    required this.userId,
    required this.centroId,
    required this.serraId,
    required this.moduloId,
  }) {
    loadModuloData();
  }

  Future<void> loadModuloData() async {
    if (_isDisposed) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _modulo = await databaseService.getModulo(
        centroId,
        serraId,
        moduloId,
      );

      if (_modulo != null) {
        if (kDebugMode) {
          print(">>> FarmingProvider: Modulo ${_modulo!.id} caricato. Livello: ${_modulo!.level}, Capienza: ${_modulo!.capienza}, Slots Occupati: $busySlotsCount");
        }
        _initializeAllSlotStates();
      } else {
        _errorMessage = "Modulo non trovato (ID: $moduloId). Controlla gli ID forniti.";
        if (kDebugMode) {
          print(">>> FarmingProvider: ERRORE - Modulo non trovato. Percorso: users/$userId/centri_agricoli/$centroId/serre_idroponiche/$serraId/moduli_coltivazione/$moduloId");
        }
        _clearAllSlotTimersAndStates();
      }
    } catch (e, s) {
      _errorMessage = "Errore durante il caricamento del modulo: $e";
      if (kDebugMode) {
        print(">>> FarmingProvider: ERRORE durante loadModuloData: $e\n$s");
      }
      _clearAllSlotTimersAndStates();
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void _initializeAllSlotStates() {
    if (_isDisposed || _modulo == null) return;
    _clearAllSlotTimersAndStatesInternal(); // Pulisce timer e tempi rimanenti, ma non notifica

    for (var slot in _modulo!.slots) {
      if (slot.piantaAttivaId != null && slot.piantaAttivaId!.isNotEmpty && slot.plantedAt != null && slot.growDurationSeconds != null && slot.growDurationSeconds! > 0) {
        _calculateRemainingTimeForSlot(slot);
        if ((_slotRemainingTimes[slot.slotIndex]?.inSeconds ?? 0) > 0) {
          _startTimerForSlot(slot);
        } else {
          // Se il tempo è 0 o negativo, è già pronto, non serve timer
          if (kDebugMode) print(">>> FarmingProvider: Slot ${slot.slotIndex} già maturo all'inizializzazione.");
        }
      } else {
        _slotRemainingTimes[slot.slotIndex] = Duration.zero;
      }
    }
    if (!_isDisposed) notifyListeners();
  }

  void _calculateRemainingTimeForSlot(SlotColtivazione slot) {
    if (slot.plantedAt == null || slot.growDurationSeconds == null || slot.growDurationSeconds! <= 0) {
      _slotRemainingTimes[slot.slotIndex] = Duration.zero;
      return;
    }
    final growDuration = Duration(seconds: slot.growDurationSeconds!);
    final readyTime = slot.plantedAt!.add(growDuration);
    final now = DateTime.now();
    Duration remaining = readyTime.difference(now);
    _slotRemainingTimes[slot.slotIndex] = remaining.isNegative ? Duration.zero : remaining;
  }

  void _startTimerForSlot(SlotColtivazione slot) {
    if (_isDisposed) return;
    final slotIndex = slot.slotIndex;
    _slotTimers[slotIndex]?.cancel();

    _slotTimers[slotIndex] = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        _slotTimers.remove(slotIndex);
        return;
      }

      final currentModulo = _modulo; // Snapshot
      if (currentModulo == null || slotIndex >= currentModulo.slots.length) {
        timer.cancel();
        _slotTimers.remove(slotIndex);
        return;
      }
      // Ottieni lo stato più recente dello slot dal modulo
      final SlotColtivazione currentSlotState = currentModulo.slots[slotIndex];

      // Se lo slot è stato resettato o i dati sono mancanti, ferma il timer
      if (currentSlotState.piantaAttivaId == null || currentSlotState.piantaAttivaId!.isEmpty ||
          currentSlotState.plantedAt == null || currentSlotState.growDurationSeconds == null || currentSlotState.growDurationSeconds! <= 0) {
        timer.cancel();
        _slotTimers.remove(slotIndex);
        _slotRemainingTimes[slotIndex] = Duration.zero;
        if (!_isDisposed) notifyListeners();
        return;
      }

      _calculateRemainingTimeForSlot(currentSlotState);
      if (!_isDisposed) notifyListeners();

      if ((_slotRemainingTimes[slotIndex]?.inSeconds ?? 1) <= 0) { // Se è <=0, è pronto
        timer.cancel();
        _slotTimers.remove(slotIndex); // Rimuovi il timer una volta completato
        if (kDebugMode) {
          print(">>> FarmingProvider (Timer): Pianta '${currentSlotState.nomePianta}' nello slot $slotIndex del modulo ${currentModulo.id} è MATURA!");
        }
        // Non è necessario notificare di nuovo qui, l'ultimo notifyListeners() lo ha fatto
      }
    });
  }

  void _clearAllSlotTimersAndStatesInternal() {
    _slotTimers.forEach((_, timer) => timer?.cancel());
    _slotTimers.clear();
    _slotRemainingTimes.clear();
  }

  void _clearAllSlotTimersAndStates() {
    _clearAllSlotTimersAndStatesInternal();
    if (!_isDisposed) notifyListeners();
  }


  Future<bool> attemptToPlantInSlot(Plant plantToPlant, UserProvider userProvider, int targetSlotIndex) async {
    if (_isDisposed) return false;
    if (_modulo == null) {
      _errorMessage = "Impossibile piantare: modulo non caricato.";
      if (!_isDisposed) notifyListeners();
      return false;
    }
    if (targetSlotIndex < 0 || targetSlotIndex >= _modulo!.capienza) {
      _errorMessage = "Indice slot ($targetSlotIndex) non valido per la capienza di ${_modulo!.capienza}.";
      if (!_isDisposed) notifyListeners();
      return false;
    }

    final SlotColtivazione targetSlot = _modulo!.slots[targetSlotIndex];

    if (targetSlot.piantaAttivaId != null && targetSlot.piantaAttivaId!.isNotEmpty) {
      _errorMessage = "Slot $targetSlotIndex già occupato da '${targetSlot.nomePianta}'.";
      if (!_isDisposed) notifyListeners();
      return false;
    }

    if (plantToPlant.requiredLevel > _modulo!.level) {
      _errorMessage = "Livello modulo (${_modulo!.level}) insuff. per ${plantToPlant.name} (rich. ${plantToPlant.requiredLevel})";
      if (!_isDisposed) notifyListeners();
      return false;
    }

    if (userProvider.user == null || userProvider.user!.money < plantToPlant.seedPurchasePrice) {
      _errorMessage = "Denaro insuff. per ${plantToPlant.name}. Costo: ${plantToPlant.seedPurchasePrice}, Hai: ${userProvider.user?.money ?? 0}";
      if (!_isDisposed) notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    final originalModuloState = _modulo!.copyWith(); // Assicurati che copyWith faccia una copia profonda degli slots

    DateTime plantedTime = DateTime.now();

    // Aggiorna lo slot target nel modulo locale
    // La lista _modulo.slots è già referenziata da targetSlot, quindi le modifiche a targetSlot si riflettono su _modulo.slots[targetSlotIndex]
    targetSlot.piantaAttivaId = plantToPlant.id;
    targetSlot.nomePianta = plantToPlant.name;
    targetSlot.plantedAt = plantedTime;
    targetSlot.growDurationSeconds = plantToPlant.growTime;

    _calculateRemainingTimeForSlot(targetSlot);
    _startTimerForSlot(targetSlot);

    // Non è necessario notificare qui, il blocco finally lo farà

    try {
      if (kDebugMode) {
        print(">>> FarmingProvider: Tentativo DB per piantare ${plantToPlant.name} in slot $targetSlotIndex e addebito costo.");
      }

      // Crea la lista di mappe per Firestore
      List<Map<String, dynamic>> slotsDataForFirestore = _modulo!.slots.map((s) => s.toMap()).toList();

      // **CHIAMATA IPOTETICA AL DATABASE SERVICE - DA IMPLEMENTARE/ADATTARE**
      await databaseService.updateModuloSlots(
          userId, centroId, serraId, moduloId,
          slotsDataForFirestore
      );

      await userProvider.addMoney(-plantToPlant.seedPurchasePrice);
      _errorMessage = null; // Resetta l'errore solo se tutto va a buon fine
      if (kDebugMode) print(">>> FarmingProvider: Pianta ${plantToPlant.name} seminata in slot $targetSlotIndex. Costo addebitato.");
      return true;
    } catch (e, s) {
      _errorMessage = "Errore DB/Saldo semina slot: $e";
      if (kDebugMode) { print(">>> FarmingProvider: ERRORE DB/Saldo semina slot: $e \n$s"); }

      _modulo = originalModuloState; // Ripristina lo stato precedente del modulo
      _initializeAllSlotStates(); // Re-inizializza tutti i timer e stati basati sul modulo ripristinato
      // Non è necessario notificare qui, il blocco finally lo farà
      return false;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> attemptToHarvestFromSlot(int slotIndex, UserProvider userProvider) async {
    if (_isDisposed) return false;
    if (_modulo == null || slotIndex < 0 || slotIndex >= _modulo!.slots.length) {
      _errorMessage = "Modulo non caricato o slot index non valido.";
      if (!_isDisposed) notifyListeners();
      return false;
    }

    final SlotColtivazione slotToHarvest = _modulo!.slots[slotIndex];

    if (slotToHarvest.piantaAttivaId == null || slotToHarvest.piantaAttivaId!.isEmpty) {
      _errorMessage = "Nessuna pianta nello slot $slotIndex da raccogliere.";
      if (!_isDisposed) notifyListeners();
      return false;
    }
    if (!isSlotReadyToHarvest(slotIndex)) {
      _errorMessage = "Pianta nello slot $slotIndex non ancora matura.";
      if (!_isDisposed) notifyListeners();
      return false;
    }

    Plant? plantDetails = userProvider.getPlantBlueprintById(slotToHarvest.piantaAttivaId!);
    if (plantDetails == null) {
      _errorMessage = "Dettagli pianta (ID: ${slotToHarvest.piantaAttivaId}) non trovati per vendita.";
      if (!_isDisposed) notifyListeners();
      return false;
    }
    final int earnings = plantDetails.sellPrice;

    _isLoading = true;
    _errorMessage = null;
    if (!_isDisposed) notifyListeners();

    final originalModuloState = _modulo!.copyWith(); // Copia profonda

    // Resetta lo slot localmente
    slotToHarvest.piantaAttivaId = null;
    slotToHarvest.nomePianta = null;
    slotToHarvest.plantedAt = null;
    slotToHarvest.growDurationSeconds = null;

    _slotRemainingTimes[slotIndex] = Duration.zero; // Resetta il tempo rimanente per questo slot
    _slotTimers[slotIndex]?.cancel();               // Ferma e rimuovi il timer per questo slot
    _slotTimers.remove(slotIndex);

    // Non notificare qui, il finally lo farà

    try {
      if (kDebugMode) {
        print(">>> FarmingProvider: Tentativo DB raccolta da slot $slotIndex. Guadagno: $earnings");
      }
      List<Map<String, dynamic>> slotsDataForFirestore = _modulo!.slots.map((s) => s.toMap()).toList();

      // **CHIAMATA IPOTETICA AL DATABASE SERVICE - DA IMPLEMENTARE/ADATTARE**
      await databaseService.updateModuloSlots(
          userId, centroId, serraId, moduloId,
          slotsDataForFirestore
      );

      await userProvider.addMoney(earnings);
      _errorMessage = null;
      if (kDebugMode) print(">>> FarmingProvider: Raccolto da slot $slotIndex e vendita di '${plantDetails.name}' completata. Guadagno: $earnings.");
      return true;
    } catch (e, s) {
      _errorMessage = "Errore DB/Saldo raccolta slot: $e";
      if (kDebugMode) { print(">>> FarmingProvider: ERRORE DB/Saldo raccolta slot: $e \n$s"); }

      _modulo = originalModuloState;
      _initializeAllSlotStates();
      // Non notificare qui, il finally lo farà
      return false;
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print(">>> FarmingProvider DISPOSED per modulo: $moduloId");
    }
    _isDisposed = true;
    _clearAllSlotTimersAndStatesInternal(); // Cancella tutti i timer e resetta le mappe di stato
    super.dispose();
  }
}


