// File: lib/providers/user_provider.dart (CORRETTO dagli errori hasListeners)
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuthLib show User;
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
  bool _isDisposed = false; // Flag per tracciare lo stato di dispose

  UserModel? get user => _user;
  bool get isLoadingUserData => _isLoadingUserData;

  List<Plant> get plantBlueprints => List.unmodifiable(_plantBlueprints);

  Plant? getPlantBlueprintInSerra(int serraIndex) => _growingPlantDetailsMap[serraIndex];
  bool isSerraReadyToHarvest(int serraIndex) => _isPlantReadyMap[serraIndex] ?? false;
  Duration? getRemainingGrowTimeInSerra(int serraIndex) => _remainingTimeMap[serraIndex];
  int get occupiedSerreCount => _user?.growingPlants.length ?? 0;
  int get totalSerreCount => _user?.moduliColtivazione ?? 0;

  bool isSerraOccupied(int serraIndex) {
    return _user?.growingPlants.any((gp) => gp.serraIndex == serraIndex) ?? false;
  }

  Plant? getPlantBlueprintById(String plantId) {
    try {
      return _plantBlueprints.firstWhere((p) => p.id == plantId);
    } catch (e) {
      if (kDebugMode) {
        print(">>> UserProvider: Blueprint non trovato per ID '$plantId' in _plantBlueprints.");
      }
      return null;
    }
  }

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
    if (!_isDisposed) notifyListeners();
  }

  Future<void> loadPlantBlueprints() async {
    if (_plantBlueprints.isNotEmpty && kDebugMode) {
      print(">>> UserProvider: Blueprints già caricati (${_plantBlueprints.length}). Salto ricaricamento.");
      // return; // Commenta per forzare il ricaricamento se necessario per test
    }
    _isLoadingUserData = true;
    if (!_isDisposed) notifyListeners();

    if (kDebugMode) print(">>> UserProvider: Inizio caricamento blueprints piante...");
    try {
      final snapshot = await _firestore.collection('plant_blueprints').get();
      _plantBlueprints.clear();
      for (var doc in snapshot.docs) {
        try {
          _plantBlueprints.add(Plant.fromFirestore(doc.id, doc.data() as Map<String, dynamic>));
        } catch (e) {
          if (kDebugMode) print(">>> UserProvider: Errore conversione blueprint ${doc.id}: $e");
        }
      }
      if (kDebugMode) print(">>> UserProvider: Caricati ${_plantBlueprints.length} blueprint di piante.");
    } catch (e) {
      if (kDebugMode) print(">>> UserProvider: Errore FATALE caricamento blueprints piante: $e");
    } finally {
      _isLoadingUserData = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> loadAndSetPersistentUserData(String uid, String? email) async {
    if (_isLoadingUserData && _user?.uid == uid && _plantBlueprints.isNotEmpty) return;

    _isLoadingUserData = true;
    if (!_isDisposed) notifyListeners();

    if (_plantBlueprints.isEmpty) {
      await loadPlantBlueprints();
    }

    try {
      final docSnap = await _firestore.collection('users').doc(uid).get();
      if (docSnap.exists && docSnap.data() != null) {
        _user = UserModel.fromFirestore(docSnap);
        if (kDebugMode) print(">>> UserProvider: Dati utente caricati per ${_user?.email}. Saldo: ${_user?.money}, Moduli: ${_user?.moduliColtivazione}, Piante in crescita: ${_user?.growingPlants.length}");
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
        if (kDebugMode) print(">>> UserProvider: Nuovo utente creato e salvato su Firestore. Saldo: ${_user!.money}");
      }
    } catch (e) {
      if (kDebugMode) print(">>> UserProvider: ERRORE in loadAndSetPersistentUserData: $e");
      _user = null;
      _clearAllGrowingPlantStatesInternal();
    } finally {
      _isLoadingUserData = false;
      _startOrUpdateGrowthTimer(); // Chiamato qui dopo che _isLoadingUserData è false
      // notifyListeners(); // _startOrUpdateGrowthTimer e _synchronizePlantStatesFromUserModel notificano se necessario
    }
  }

  void _synchronizePlantStatesFromUserModel() {
    _clearAllGrowingPlantStatesInternal();
    if (_user == null || _user!.growingPlants.isEmpty) {
      if (kDebugMode) print(">>> UserProvider: Nessuna pianta in crescita da sincronizzare.");
      _startOrUpdateGrowthTimer(); // Assicura che il timer sia gestito correttamente
      return;
    }
    if (kDebugMode) print(">>> UserProvider: Sincronizzazione stati per ${_user!.growingPlants.length} piante...");

    bool needsBlueprintCheck = false;
    for (var gp in _user!.growingPlants) {
      Plant? blueprint;
      try {
        blueprint = _plantBlueprints.firstWhere((bp) => bp.id == gp.plantId);
      } catch (e) {
        if (kDebugMode) print(">>> UserProvider (Sync): Blueprint non trovato localmente per plantId ${gp.plantId}. (eccezione: $e)");
        needsBlueprintCheck = true;
        continue;
      }
      _growingPlantDetailsMap[gp.serraIndex] = blueprint;
      if (kDebugMode) print(">>> UserProvider (Sync): Mappa dettagli popolata per serra ${gp.serraIndex} con ${blueprint.name}");
    }

    if (needsBlueprintCheck && _plantBlueprints.isEmpty) {
      if (kDebugMode) print(">>> UserProvider (Sync): Lista blueprint vuota e ID mancanti. Considera ricaricamento.");
    }
    _updateAllGrowthStatesLogic(); // Questo calcola lo stato ma non notifica
    _startOrUpdateGrowthTimer();   // Questo avvia il timer e notifica se necessario
  }

  void _clearAllGrowingPlantStatesInternal() {
    _growingPlantDetailsMap.clear();
    _isPlantReadyMap.clear();
    _remainingTimeMap.clear();
    if (kDebugMode) print(">>> UserProvider: Mappe di stato locali (_growingPlantDetailsMap, etc.) resettate.");
  }

  bool canUserAffordPlant(Plant plant) => (_user?.money ?? 0) >= plant.seedPurchasePrice;
  bool doesUserMeetLevelForPlant(Plant plant) => (_user?.level ?? 0) >= plant.requiredLevel;

  Future<void> plantSeed(Plant plantToGrow, int serraIndex) async {
    if (kDebugMode) print(">>> UserProvider (plantSeed): Tentativo di piantare '${plantToGrow.name}' in serra $serraIndex");
    if (_user == null) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): Utente nullo.");
      return;
    }
    if (serraIndex >= (_user!.moduliColtivazione ?? 0)) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): Indice serra non valido.");
      return;
    }
    if (isSerraOccupied(serraIndex)) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): Serra $serraIndex già occupata.");
      return;
    }
    if (!canUserAffordPlant(plantToGrow)) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): Denaro insufficente per ${plantToGrow.name}. Saldo: ${_user!.money}, Costo: ${plantToGrow.seedPurchasePrice}");
      return;
    }
    if (!doesUserMeetLevelForPlant(plantToGrow)) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): Livello insufficiente.");
      return;
    }

    _isLoadingUserData = true;
    if (!_isDisposed) notifyListeners();

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
      _remainingTimeMap[serraIndex] = Duration(seconds: plantToGrow.growTime);

      await _updateUserDocument(_user!.toMap());
      if (kDebugMode) print(">>> UserProvider (plantSeed): ${plantToGrow.name} piantata. Nuovo saldo: ${_user!.money}. Firestore aggiornato.");
      _startOrUpdateGrowthTimer();
    } catch (e) {
      if (kDebugMode) print(">>> UserProvider (plantSeed): ERRORE $e. Rollback...");
      _user = _user!.copyWith(money: prevMoney, growingPlants: prevGrowingPlants);
      _synchronizePlantStatesFromUserModel();
    } finally {
      _isLoadingUserData = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  void _startOrUpdateGrowthTimer() {
    _growthTimer?.cancel();
    if (kDebugMode) print(">>> UserProvider (Timer Man.): _startOrUpdateGrowthTimer chiamato.");

    // ***** CORREZIONE: Controlla _isDisposed e se _user è null *****
    if (_isDisposed || _user == null || _user!.growingPlants.isEmpty) {
      if (kDebugMode) {
        if(_isDisposed) print(">>> UserProvider (Timer Man.): Provider disposed. Timer non avviato.");
        else print(">>> UserProvider (Timer Man.): Nessun utente o nessuna pianta. Timer non avviato.");
      }
      _clearAllGrowingPlantStatesInternal(); // Assicura che le mappe siano pulite
      if (!_isDisposed) notifyListeners(); // Notifica solo se non disposed
      return;
    }

    _updateAllGrowthStatesLogic(); // Calcola/aggiorna lo stato di tutte le piante una volta

    bool hasAnyUnreadyPlant = _user!.growingPlants.any((gp) => !(_isPlantReadyMap[gp.serraIndex] ?? true));

    if (hasAnyUnreadyPlant) {
      if (kDebugMode) print(">>> UserProvider (Timer Man.): Almeno una pianta non pronta. Avvio Timer.periodic.");
      _growthTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // ***** CORREZIONE: Controlla _isDisposed e se _user è null *****
        if (_isDisposed || _user == null || _user!.growingPlants.isEmpty) {
          if (kDebugMode) {
            if(_isDisposed) print(">>> UserProvider (Timer Tick): Provider disposed. Cancello timer.");
            else print(">>> UserProvider (Timer Tick): Utente nullo o piante finite. Cancello timer.");
          }
          timer.cancel();
          _clearAllGrowingPlantStatesInternal();
          if (!_isDisposed) notifyListeners(); // Notifica solo se non disposed
          return;
        }

        _updateAllGrowthStatesLogic(); // Ricalcola lo stato ad ogni tick
        if (!_isDisposed) notifyListeners(); // Notifica la UI ad ogni tick

        bool stillHasUnreadyPlants = _user!.growingPlants.any((gp) => !(_isPlantReadyMap[gp.serraIndex] ?? true));
        if (!stillHasUnreadyPlants) {
          if (kDebugMode) print(">>> UserProvider (Timer Tick): Tutte le piante sono ora pronte. Cancello timer.");
          timer.cancel();
        }
      });
    } else {
      if (kDebugMode) print(">>> UserProvider (Timer Man.): Tutte le piante già pronte o nessuna. Timer non avviato.");
    }
    if (!_isDisposed) notifyListeners(); // Notifica lo stato iniziale del timer (se è partito o meno)
  }

  void _updateAllGrowthStatesLogic() {
    if (_user == null) {
      // if (kDebugMode) print(">>> UserProvider (_updateAllGrowthStatesLogic): Utente nullo, esco.");
      return;
    }
    // if (kDebugMode) print(">>> UserProvider (_updateAllGrowthStatesLogic): START - Controllo ${_user!.growingPlants.length} piante.");

    final Set<int> activeSerraIndexes = _user!.growingPlants.map((gp) => gp.serraIndex).toSet();
    _growingPlantDetailsMap.removeWhere((key, value) => !activeSerraIndexes.contains(key));
    _isPlantReadyMap.removeWhere((key, value) => !activeSerraIndexes.contains(key));
    _remainingTimeMap.removeWhere((key, value) => !activeSerraIndexes.contains(key));

    for (var gp in _user!.growingPlants) {
      Plant? blueprint = _growingPlantDetailsMap[gp.serraIndex];
      if (blueprint == null) {
        try {
          blueprint = _plantBlueprints.firstWhere((bp) => bp.id == gp.plantId);
          _growingPlantDetailsMap[gp.serraIndex] = blueprint;
        } catch (e) {
          if (kDebugMode) print(">>> UserProvider (_updateLogic): Blueprint NON TROVATO per ${gp.plantId} in serra ${gp.serraIndex}. Stato non aggiornabile.");
          _isPlantReadyMap[gp.serraIndex] = false;
          _remainingTimeMap[gp.serraIndex] = Duration.zero;
          continue;
        }
      }

      final growDuration = Duration(seconds: blueprint.growTime);
      final readyTime = gp.plantedAt.add(growDuration);
      final now = DateTime.now();
      Duration newRemainingTime = readyTime.difference(now);
      bool isReadyCurrentPlant = false;

      if (newRemainingTime.isNegative) {
        newRemainingTime = Duration.zero;
        isReadyCurrentPlant = true;
      } else {
        isReadyCurrentPlant = now.isAfter(readyTime) || now.isAtSameMomentAs(readyTime);
      }
      _remainingTimeMap[gp.serraIndex] = newRemainingTime;
      _isPlantReadyMap[gp.serraIndex] = isReadyCurrentPlant;
    }
    // if (kDebugMode) print(">>> UserProvider (_updateAllGrowthStatesLogic): END - Mappe aggiornate.");
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
    } catch (e) { /* plantInSerra rimane null */ }

    if (plantInSerra == null) {
      if (kDebugMode) print(">>> UserProvider (harvest): Nessuna pianta in serra $serraIndex.");
      return;
    }

    if (!(_isPlantReadyMap[serraIndex] ?? false)) {
      if (kDebugMode) print(">>> UserProvider (harvest): Pianta in serra $serraIndex non pronta.");
      return;
    }

    Plant? plantDetails = _growingPlantDetailsMap[serraIndex];
    if (plantDetails == null) {
      try {
        plantDetails = _plantBlueprints.firstWhere((bp) => bp.id == plantInSerra!.plantId);
        _growingPlantDetailsMap[serraIndex] = plantDetails;
      } catch (e) {
        if (kDebugMode) print(">>> UserProvider (harvest): Blueprint non trovato per ${plantInSerra!.plantId}. Impossibile raccogliere.");
        return;
      }
    }

    final int earnings = plantDetails.sellPrice;
    _isLoadingUserData = true;
    if (!_isDisposed) notifyListeners();

    final prevMoney = _user!.money;
    final List<GrowingPlant> prevGrowingPlants = List.from(_user!.growingPlants);

    try {
      final updatedGrowingPlants = _user!.growingPlants.where((gp) => gp.serraIndex != serraIndex).toList();
      _user = _user!.copyWith(
        growingPlants: updatedGrowingPlants,
      );

      _growingPlantDetailsMap.remove(serraIndex);
      _isPlantReadyMap.remove(serraIndex);
      _remainingTimeMap.remove(serraIndex);

      await _firestore.collection('users').doc(_user!.uid).update({
        'growingPlants': updatedGrowingPlants.map((gp) => gp.toMap()).toList(),
      });
      if (kDebugMode) print(">>> UserProvider (harvest): Piante aggiornate su Firestore dopo raccolta.");

      await addMoney(earnings);

      if (kDebugMode) print(">>> UserProvider (harvest): ${plantDetails.name} raccolta. Guadagno: $earnings. Saldo aggiornato.");
      _startOrUpdateGrowthTimer();
    } catch (e) {
      if (kDebugMode) print(">>> UserProvider (harvest): ERRORE $e. Rollback...");
      _user = _user!.copyWith(money: prevMoney, growingPlants: prevGrowingPlants);
      _synchronizePlantStatesFromUserModel();
    } finally {
      _isLoadingUserData = false;
      if (!_isDisposed) notifyListeners();
    }
  }

  Future<void> _updateUserDocument(Map<String, dynamic> dataToUpdate) async {
    if (_user?.uid == null) {
      if (kDebugMode) print(">>> UserProvider (_updateUserDocument): UID utente nullo.");
      return;
    }
    await _firestore.collection('users').doc(_user!.uid).set(dataToUpdate, SetOptions(merge: true));
  }

  Future<void> addMoney(int amountToAdd) async {
    if (_user == null) {
      if (kDebugMode) print(">>> UserProvider: addMoney chiamato ma utente nullo.");
      return;
    }
    if (amountToAdd == 0 && kDebugMode) {
      print(">>> UserProvider: addMoney chiamato con importo 0.");
      // return; // Potrebbe essere valido aggiungere 0, quindi non esco
    }
    if (kDebugMode) print(">>> UserProvider: Tentativo di aggiungere $amountToAdd al saldo. Saldo attuale: ${_user!.money}");

    final int newMoney = _user!.money + amountToAdd;
    _user = _user!.copyWith(money: newMoney);
    if (!_isDisposed) notifyListeners();

    try {
      await _firestore.collection('users').doc(_user!.uid).update({'money': newMoney});
      if (kDebugMode) print(">>> UserProvider: Saldo aggiornato su Firestore a $newMoney.");
    } catch (e) {
      if (kDebugMode) print(">>> UserProvider: Errore aggiornamento saldo su Firestore: $e. L'aggiornamento locale rimane. Considerare rollback.");
      // QUI POTRESTI VOLER FARE UN ROLLBACK DEL MODELLO LOCALE SE L'UPDATE DEL DB FALLISCE
      // _user = _user!.copyWith(money: _user!.money - amountToAdd);
      // if (!_isDisposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      print(">>> UserProvider DISPOSED");
    }
    _growthTimer?.cancel();
    _isDisposed = true; // Imposta il flag qui
    super.dispose();
  }
}

