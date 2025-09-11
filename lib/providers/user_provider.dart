// File: lib/providers/user_provider.dart (CORRETTO)
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuthLib show User; // Alias per User
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/plant.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoadingUserData = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Plant> _plantBlueprints = [];
  final Map<int, Plant> _growingPlantDetailsMap = {};
  final Map<int, bool> _isPlantReadyMap = {};
  final Map<int, Duration> _remainingTimeMap = {};
  Timer? _growthTimer;

  UserModel? get user => _user;
  bool get isLoadingUserData => _isLoadingUserData;

  Plant? getPlantBlueprintInSerra(int serraIndex) => _growingPlantDetailsMap[serraIndex];
  bool isSerraReadyToHarvest(int serraIndex) => _isPlantReadyMap[serraIndex] ?? false;
  Duration? getRemainingGrowTimeInSerra(int serraIndex) => _remainingTimeMap[serraIndex];
  int get occupiedSerreCount => _user?.growingPlants.length ?? 0;
  int get totalSerreCount => _user?.moduliColtivazione ?? 0;

  bool isSerraOccupied(int serraIndex) {
    return _user?.growingPlants.any((gp) => gp.serraIndex == serraIndex) ?? false;
  }

  // Utilizziamo l'alias FirebaseAuthLib.User per chiarezza se User fosse definito altrove
  void setUserFromAuth(FirebaseAuthLib.User? firebaseUser) {
    if (firebaseUser == null) {
      clearUser();
    } else {
      loadAndSetPersistentUserData(firebaseUser.uid, firebaseUser.email);
    }
  }

  void clearUser() {
    _user = null;
    _isLoadingUserData = false;
    _clearAllGrowingPlantStatesInternal();
    _growthTimer?.cancel();
    _growthTimer = null;
    if (kDebugMode) print(">>> UserProvider: Dati utente e stati piante resettati.");
    notifyListeners();
  }

  Future<void> loadPlantBlueprints() async {
    if (_plantBlueprints.isNotEmpty) return;
    try {
      final snapshot = await _firestore.collection('plant_blueprints').get();
      _plantBlueprints.clear();
      for (var doc in snapshot.docs) {
        _plantBlueprints.add(Plant.fromFirestore(doc.id, doc.data()));
      }
      if (kDebugMode) print(">>> UserProvider: Caricati ${_plantBlueprints.length} blueprint di piante.");
    } catch (e) {
      if (kDebugMode) print(">>> UserProvider: Errore caricamento blueprints piante: $e");
    }
  }

  Future<void> loadAndSetPersistentUserData(String uid, String? email) async {
    if (_isLoadingUserData && _user?.uid == uid) return;
    _isLoadingUserData = true;
    notifyListeners();

    if (_plantBlueprints.isEmpty) {
      await loadPlantBlueprints();
    }

    try {
      final docSnap = await _firestore.collection('users').doc(uid).get();
      if (docSnap.exists && docSnap.data() != null) {
        _user = UserModel.fromFirestore(docSnap);
        if (kDebugMode) print(">>> UserProvider: Dati utente caricati per ${_user?.email}. Moduli: ${_user?.moduliColtivazione}, Piante in crescita: ${_user?.growingPlants.length}");
        _synchronizePlantStatesFromUserModel();
      } else {
        if (kDebugMode) print(">>> UserProvider: Nessun documento per UID $uid. Creo nuovo utente.");
        _user = UserModel(
          uid: uid,
          email: email ?? 'utente_${uid.substring(0, 5)}@example.com',
          money: 100,
          loan: 0,
          moduliColtivazione: 1,
          createdAt: DateTime.now(),
          level: 1,
          growingPlants: [],
        );
        await _firestore.collection('users').doc(uid).set(_user!.toMap());
        _clearAllGrowingPlantStatesInternal();
        if (kDebugMode) print(">>> UserProvider: Nuovo utente creato e salvato su Firestore.");
      }
    } catch (e) {
      if (kDebugMode) print(">>> UserProvider: ERRORE in loadAndSetPersistentUserData: $e");
      _user = null;
      _clearAllGrowingPlantStatesInternal();
    } finally {
      _isLoadingUserData = false;
      _startOrUpdateGrowthTimer();
      notifyListeners();
    }
  }

  void _synchronizePlantStatesFromUserModel() {
    _clearAllGrowingPlantStatesInternal();
    if (_user == null || _user!.growingPlants.isEmpty) {
      if (kDebugMode) print(">>> UserProvider: Nessuna pianta in crescita da sincronizzare.");
      return;
    }
    if (kDebugMode) print(">>> UserProvider: Sincronizzazione stati per ${_user!.growingPlants.length} piante...");

    for (var gp in _user!.growingPlants) {
      Plant? blueprint;
      try {
        blueprint = _plantBlueprints.firstWhere((bp) => bp.id == gp.plantId);
      } catch (e) {
        if (kDebugMode) print(">>> UserProvider (Sync): Blueprint non trovato per plantId ${gp.plantId} (eccezione: $e). Salto questa pianta.");
        // Non aggiungere a _growingPlantDetailsMap se non trovato
        continue; // Salta al prossimo gp
      }

      // Non è più necessario il controllo 'if (blueprint != null)' qui
      // perché il 'continue' nel catch gestisce il caso di non trovato.
      // Tuttavia, per chiarezza, se si rimuove il continue, il controllo è necessario.
      // Per ora, con il continue, è implicito che blueprint non sia null.
      _growingPlantDetailsMap[gp.serraIndex] = blueprint; // blueprint è garantito non nullo qui
      if (kDebugMode) print(">>> UserProvider (Sync): Mappa dettagli popolata per serra ${gp.serraIndex} con ${blueprint.name}");
    }
    _updateAllGrowthStatesLogic();
  }

  void _clearAllGrowingPlantStatesInternal() {
    _growingPlantDetailsMap.clear();
    _isPlantReadyMap.clear();
    _remainingTimeMap.clear();
    if (kDebugMode) print(">>> UserProvider: Mappe di stato (_growingPlantDetailsMap, etc.) resettate.");
  }

  bool canUserAffordPlant(Plant plant) => (_user?.money ?? 0) >= plant.seedPurchasePrice;
  bool doesUserMeetLevelForPlant(Plant plant) => (_user?.level ?? 0) >= plant.requiredLevel;

  Future<void> plantSeed(Plant plantToGrow, int serraIndex) async {
    if (kDebugMode) print(">>> UserProvider (plantSeed): Tentativo di piantare '${plantToGrow.name}' in serra $serraIndex");
    if (_user == null) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): Utente nullo, impossibile piantare.");
      return;
    }
    if (serraIndex >= _user!.moduliColtivazione) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): Indice serra $serraIndex non valido (max ${_user!.moduliColtivazione -1}).");
      return;
    }
    if (isSerraOccupied(serraIndex)) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): Serra $serraIndex già occupata.");
      return;
    }
    if (!canUserAffordPlant(plantToGrow)) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): Denaro insufficente per ${plantToGrow.name}.");
      return;
    }
    if (!doesUserMeetLevelForPlant(plantToGrow)) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): Livello insufficiente per ${plantToGrow.name}.");
      return;
    }

    _isLoadingUserData = true;
    notifyListeners();

    final prevMoney = _user!.money;
    final List<GrowingPlant> prevGrowingPlants = List.from(_user!.growingPlants);

    try {
      final newGrowingPlant = GrowingPlant(
        plantId: plantToGrow.id,
        plantName: plantToGrow.name,
        plantedAt: DateTime.now(),
        serraIndex: serraIndex,
      );
      final updatedGrowingPlants = [..._user!.growingPlants, newGrowingPlant];
      _user = _user!.copyWith(
        money: _user!.money - plantToGrow.seedPurchasePrice,
        growingPlants: updatedGrowingPlants,
      );
      _growingPlantDetailsMap[serraIndex] = plantToGrow;
      _isPlantReadyMap[serraIndex] = false;
      await _updateUserDocument(_user!.toMap());
      if (kDebugMode) print(">>> UserProvider (plantSeed): ${plantToGrow.name} piantata in serra $serraIndex. Firestore aggiornato.");
      _startOrUpdateGrowthTimer();
    } catch (e) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): ERRORE $e. Rollback...");
      _user = _user!.copyWith(
        money: prevMoney,
        growingPlants: prevGrowingPlants,
      );
      _synchronizePlantStatesFromUserModel();
      _startOrUpdateGrowthTimer();
    } finally {
      _isLoadingUserData = false;
    }
  }

  void _startOrUpdateGrowthTimer() {
    _growthTimer?.cancel();
    if (kDebugMode) print(">>> UserProvider (Timer Man.): _startOrUpdateGrowthTimer chiamato.");

    if (_user == null || _user!.growingPlants.isEmpty) {
      if (kDebugMode) print(">>> UserProvider (Timer Man.): Nessun utente o nessuna pianta in crescita. Timer non avviato. Mappe resettate.");
      _clearAllGrowingPlantStatesInternal();
      notifyListeners();
      return;
    }
    _updateAllGrowthStatesLogic();
    bool hasAnyUnreadyPlant = _user!.growingPlants.any((gp) => !(_isPlantReadyMap[gp.serraIndex] ?? true));

    if (hasAnyUnreadyPlant) {
      if (kDebugMode) print(">>> UserProvider (Timer Man.): Almeno una pianta non pronta. Avvio Timer.periodic.");
      _growthTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_user == null || _user!.growingPlants.isEmpty) {
          if (kDebugMode) print(">>> UserProvider (Timer Tick): Utente nullo o piante finite durante il tick. Cancello timer.");
          timer.cancel();
          _clearAllGrowingPlantStatesInternal();
          notifyListeners();
          return;
        }
        _updateAllGrowthStatesLogic();
        notifyListeners();
        bool stillHasUnreadyPlants = _user!.growingPlants.any((gp) => !(_isPlantReadyMap[gp.serraIndex] ?? true));
        if (!stillHasUnreadyPlants) {
          if (kDebugMode) print(">>> UserProvider (Timer Tick): Tutte le piante sono ora pronte. Cancello timer.");
          timer.cancel();
        }
      });
    } else {
      if (kDebugMode) print(">>> UserProvider (Timer Man.): Tutte le piante in crescita sono già pronte o nessuna pianta. Timer non avviato.");
    }
    notifyListeners();
  }

  void _updateAllGrowthStatesLogic() {
    if (_user == null) return;
    if (kDebugMode) print(">>> UserProvider (_updateAllGrowthStatesLogic): START - Controllo ${_user!.growingPlants.length} piante.");

    final Set<int> activeSerraIndexes = _user!.growingPlants.map((gp) => gp.serraIndex).toSet();
    _growingPlantDetailsMap.removeWhere((key, value) => !activeSerraIndexes.contains(key));
    _isPlantReadyMap.removeWhere((key, value) => !activeSerraIndexes.contains(key));
    _remainingTimeMap.removeWhere((key, value) => !activeSerraIndexes.contains(key));

    for (var gp in _user!.growingPlants) {
      Plant? blueprint = _growingPlantDetailsMap[gp.serraIndex];
      if (blueprint == null) {
        Plant? foundBlueprint;
        try {
          foundBlueprint = _plantBlueprints.firstWhere((bp) => bp.id == gp.plantId);
        } catch (e) {
          if (kDebugMode) print(">>> UserProvider (_updateAllGrowthStatesLogic): Blueprint NON TROVATO per ${gp.plantId} in serra ${gp.serraIndex}. Eccezione: $e");
          // foundBlueprint rimane null
        }

        if (foundBlueprint != null) {
          _growingPlantDetailsMap[gp.serraIndex] = foundBlueprint;
          blueprint = foundBlueprint;
        } else {
          // Se il blueprint non è stato trovato, saltiamo questa pianta per il calcolo della crescita
          if (kDebugMode) print(">>> UserProvider (_updateAllGrowthStatesLogic): Blueprint ancora NON TROVATO per ${gp.plantId} in serra ${gp.serraIndex} dopo tentativo. Stato non aggiornabile.");
          _isPlantReadyMap[gp.serraIndex] = false; // O un altro stato di default
          _remainingTimeMap[gp.serraIndex] = Duration.zero; // O un altro stato di default
          continue; // Passa alla prossima pianta
        }
      }

      final growDuration = Duration(seconds: blueprint.growTime);
      final readyTime = gp.plantedAt.add(growDuration);
      final now = DateTime.now();
      Duration newRemainingTime = readyTime.difference(now);
      bool isReady = false;
      if (newRemainingTime.isNegative) {
        newRemainingTime = Duration.zero;
        isReady = true;
      } else {
        isReady = now.isAfter(readyTime) || now.isAtSameMomentAs(readyTime);
      }
      _remainingTimeMap[gp.serraIndex] = newRemainingTime;
      _isPlantReadyMap[gp.serraIndex] = isReady;
    }
    if (kDebugMode) print(">>> UserProvider (_updateAllGrowthStatesLogic): END - Mappe aggiornate.");
  }

  Future<void> harvestAndSellPlant(int serraIndex) async {
    if (kDebugMode) print(">>> UserProvider (harvest): Tentativo di raccolta da serra $serraIndex.");
    if (_user == null) {
      if (kDebugMode) print(">>> UserProvider (harvest): Utente nullo.");
      return;
    }

    GrowingPlant? plantInSerra;
    try {
      plantInSerra = _user!.growingPlants.firstWhere((gp) => gp.serraIndex == serraIndex);
    } catch (e) {
      // plantInSerra rimane null
    }

    if (plantInSerra == null) {
      if (kDebugMode) print(">>> UserProvider (harvest): Nessuna pianta trovata in serra $serraIndex per il raccolto.");
      return;
    }

    if (!(_isPlantReadyMap[serraIndex] ?? false)) {
      if (kDebugMode) print(">>> UserProvider (harvest): Pianta in serra $serraIndex (${plantInSerra.plantName}) non ancora pronta.");
      return;
    }

    Plant? plantDetails = _growingPlantDetailsMap[serraIndex];
    if (plantDetails == null) {
      Plant? foundBlueprint;
      // Dato che plantInSerra è garantito non essere null qui (a causa del controllo precedente),
      // possiamo accedere a plantInSerra.plantId.
      final String currentPlantId = plantInSerra.plantId; // Nessun '!' necessario, null check già fatto.
      try {
        foundBlueprint = _plantBlueprints.firstWhere((bp) => bp.id == currentPlantId);
      } catch (e) {
        if (kDebugMode) print(">>> UserProvider (harvest): Eccezione cercando blueprint per $currentPlantId durante il raccolto: $e");
        // foundBlueprint rimane null
      }

      if (foundBlueprint != null) {
        _growingPlantDetailsMap[serraIndex] = foundBlueprint;
        plantDetails = foundBlueprint;
      }
    }

    if (plantDetails == null) {
      // Se plantDetails è ancora null qui, significa che non siamo riusciti a trovare/caricare il blueprint.
      // plantInSerra.plantName è sicuro qui perché plantInSerra non è null.
      if (kDebugMode) print(">>> UserProvider (harvest): Dettagli Blueprint ancora NON TROVATI per ${plantInSerra.plantName} (ID: ${plantInSerra.plantId}). Impossibile raccogliere.");
      return;
    }

    final int earnings = plantDetails.sellPrice;
    _isLoadingUserData = true;
    notifyListeners();

    final prevMoney = _user!.money;
    final List<GrowingPlant> prevGrowingPlants = List.from(_user!.growingPlants);

    try {
      final updatedGrowingPlants = _user!.growingPlants.where((gp) => gp.serraIndex != serraIndex).toList();
      _user = _user!.copyWith(
        money: _user!.money + earnings,
        growingPlants: updatedGrowingPlants,
      );
      _growingPlantDetailsMap.remove(serraIndex);
      _isPlantReadyMap.remove(serraIndex);
      _remainingTimeMap.remove(serraIndex);
      await _updateUserDocument(_user!.toMap());
      if (kDebugMode) print(">>> UserProvider (harvest): ${plantDetails.name} raccolta da serra $serraIndex. Guadagno: $earnings. Firestore aggiornato.");
      _startOrUpdateGrowthTimer();
    } catch (e) {
      if (kDebugMode) print(">>> UserProvider (harvest): ERRORE $e. Rollback...");
      _user = _user!.copyWith(
        money: prevMoney,
        growingPlants: prevGrowingPlants,
      );
      _synchronizePlantStatesFromUserModel();
      _startOrUpdateGrowthTimer();
    } finally {
      _isLoadingUserData = false;
    }
  }

  Future<void> _updateUserDocument(Map<String, dynamic> dataToUpdate) async {
    if (_user?.uid == null) {
      if (kDebugMode) print(">>> UserProvider (_updateUserDocument): UID utente nullo, impossibile aggiornare.");
      return;
    }
    await _firestore.collection('users').doc(_user!.uid).set(dataToUpdate);
  }

  void updateMoney(int nuovoCredito) {
    if (_user == null) return;
    _user!.money = nuovoCredito;
    notifyListeners();
    _firestore.collection('users').doc(_user!.uid).update({"money": nuovoCredito});
  }

  @override
  void dispose() {
    _growthTimer?.cancel();
    super.dispose();
  }
}

