import 'dart:async'; // Per Timer
import 'package:flutter/foundation.dart';
// Manteniamo User di FirebaseAuth
import 'package:firebase_auth/firebase_auth.dart' as FirebaseAuthLib show User; // Alias per User di Firebase Auth
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/plant.dart'; // Assicurati che il percorso sia corretto

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoadingUserData = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Plant? _currentGrowingPlantDetails;
  bool _isCurrentPlantReadyToHarvest = false;
  Duration? _currentPlantRemainingGrowTime;
  Timer? _growthTimer;

  UserModel? get user => _user;
  bool get isLoadingUserData => _isLoadingUserData;

  Plant? get currentGrowingPlantDetails => _currentGrowingPlantDetails;
  bool isCurrentPlantReadyToHarvest() => _isCurrentPlantReadyToHarvest;
  Duration? get currentPlantRemainingGrowTime => _currentPlantRemainingGrowTime;

  /// ===========================
  /// UTILITY PUBBLICHE AGGIUNTE
  /// ===========================

  /// Aggiorna il credito dell'utente e persiste su Firestore
  void updateMoney(int nuovoCredito) {
    if (_user == null) return;
    _user!.money = nuovoCredito;
    notifyListeners();

    // Aggiorna Firestore
    _firestore.collection('users').doc(_user!.uid).update({"money": nuovoCredito});
  }

  /// ===========================
  /// Gestione utente e dati Firestore
  /// ===========================

  void setUserFromAuth(FirebaseAuthLib.User? firebaseUser) {
    if (firebaseUser == null) {
      clearUser();
    } else {
      initializeUserBaseData(firebaseUser.uid, firebaseUser.email ?? 'email_sconosciuta@example.com');
      loadAndSetPersistentUserData(firebaseUser.uid);
    }
  }

  void updateUserData(Map<String, dynamic> data) {
    if (_user != null) {
      _user = UserModel(
        uid: _user!.uid,
        email: data['email'] ?? _user!.email,
        money: data['money'] ?? _user!.money,
        loan: data['loan'] ?? _user!.loan,
        serre: data['serre'] ?? _user!.serre,
        createdAt: _user!.createdAt,
        currentPlantId: data['currentPlantId'] ?? _user!.currentPlantId,
        currentPlantName: data['currentPlantName'] ?? _user!.currentPlantName,
        plantedAt: data['plantedAt'] is Timestamp
            ? (data['plantedAt'] as Timestamp).toDate()
            : (data['plantedAt'] is DateTime ? data['plantedAt'] : _user!.plantedAt),
        level: data['level'] ?? _user!.level,
      );
      notifyListeners();
    }
  }

  void clearUser() {
    _user = null;
    _isLoadingUserData = false;
    _clearGrowingPlantStateAndNotify();
  }

  void _clearGrowingPlantStateInternal() {
    _growthTimer?.cancel();
    _growthTimer = null;
    _currentGrowingPlantDetails = null;
    _isCurrentPlantReadyToHarvest = false;
    _currentPlantRemainingGrowTime = null;
  }

  void _clearGrowingPlantStateAndNotify() {
    bool hadPlant = _currentGrowingPlantDetails != null || _currentPlantRemainingGrowTime != null;
    _clearGrowingPlantStateInternal();
    if (hadPlant) notifyListeners();
  }

  void initializeUserBaseData(String uid, String email) {
    if (_user == null || _user!.uid != uid) {
      _user = UserModel(
        uid: uid,
        email: email,
        money: 100,
        loan: 0,
        serre: 1,
        createdAt: DateTime.now(),
        level: 0,
      );
      _clearGrowingPlantStateInternal();
    }
  }

  Future<void> loadAndSetPersistentUserData(String uid) async {
    if (_isLoadingUserData && _user?.uid == uid) return;

    _isLoadingUserData = true;
    bool shouldNotifyAfterLoad = false;

    if (_user == null || _user!.uid != uid) shouldNotifyAfterLoad = true;

    try {
      final docSnap = await _firestore.collection('users').doc(uid).get();
      if (docSnap.exists && docSnap.data() != null) {
        _user = UserModel.fromFirestore(docSnap);
        if (_user!.currentPlantId != null && _user!.plantedAt != null) {
          await _fetchAndSetGrowingPlantDetails(_user!.currentPlantId!);
          _startOrUpdateGrowthTimer();
        } else {
          _clearGrowingPlantStateInternal();
        }
      } else {
        initializeUserBaseData(uid, _user?.email ?? 'email_fallback@example.com');
        await _firestore.collection('users').doc(uid).set(_user!.toMap());
      }
    } catch (e) {
      _clearGrowingPlantStateInternal();
    } finally {
      _isLoadingUserData = false;
      if (shouldNotifyAfterLoad || (_user?.currentPlantId == null && _user?.plantedAt == null)) notifyListeners();
    }
  }

  Future<void> _fetchAndSetGrowingPlantDetails(String plantId) async {
    try {
      final doc = await _firestore.collection('plant_blueprints').doc(plantId).get();
      if (doc.exists && doc.data() != null) {
        _currentGrowingPlantDetails = Plant.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      } else {
        _currentGrowingPlantDetails = null;
        if (_user != null) {
          _user!.currentPlantId = null;
          _user!.currentPlantName = null;
          _user!.plantedAt = null;
          await _updateUserDocument({'currentPlantId': null, 'currentPlantName': null, 'plantedAt': null});
        }
      }
    } catch (e) {
      _currentGrowingPlantDetails = null;
    }
  }

  bool canPlantNewSeedInAnySerre() => _user?.currentPlantId == null && _user?.plantedAt == null;
  bool canUserAffordPlant(Plant plant) => (_user?.money ?? 0) >= plant.seedPurchasePrice;
  bool doesUserMeetLevelForPlant(Plant plant) => (_user?.level ?? 0) >= plant.requiredLevel;

  Future<void> plantSeed(Plant plantToGrow) async {
    if (_user == null || !canPlantNewSeedInAnySerre() || !canUserAffordPlant(plantToGrow) || !doesUserMeetLevelForPlant(plantToGrow)) return;

    _isLoadingUserData = true;
    notifyListeners();

    final prevMoney = _user!.money;
    final prevPlantId = _user!.currentPlantId;
    final prevPlantName = _user!.currentPlantName;
    final prevPlantedAt = _user!.plantedAt;

    try {
      _user!.money -= plantToGrow.seedPurchasePrice;
      _user!.currentPlantId = plantToGrow.id;
      _user!.currentPlantName = plantToGrow.name;
      _user!.plantedAt = DateTime.now();
      _currentGrowingPlantDetails = plantToGrow;
      _isCurrentPlantReadyToHarvest = false;

      await _updateUserDocument({
        'money': _user!.money,
        'currentPlantId': _user!.currentPlantId,
        'currentPlantName': _user!.currentPlantName,
        'plantedAt': Timestamp.fromDate(_user!.plantedAt!),
      });

      _startOrUpdateGrowthTimer();
    } catch (e) {
      // Rollback
      _user!.money = prevMoney;
      _user!.currentPlantId = prevPlantId;
      _user!.currentPlantName = prevPlantName;
      _user!.plantedAt = prevPlantedAt;
      _clearGrowingPlantStateInternal();
      if (prevPlantId != null) await _fetchAndSetGrowingPlantDetails(prevPlantId);
      _startOrUpdateGrowthTimer();
    } finally {
      _isLoadingUserData = false;
      notifyListeners();
    }
  }

  void _startOrUpdateGrowthTimer() {
    _growthTimer?.cancel();

    if (_user?.plantedAt == null || _currentGrowingPlantDetails == null) {
      _clearGrowingPlantStateInternal();
      notifyListeners();
      return;
    }

    _updateGrowthStatusInternalLogic();

    if (!_isCurrentPlantReadyToHarvest) {
      _growthTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_user?.uid == null || _user?.plantedAt == null || _currentGrowingPlantDetails == null) {
          timer.cancel();
          _clearGrowingPlantStateInternal();
          return;
        }
        _updateGrowthStatusInternalLogic();
        notifyListeners();
        if (_isCurrentPlantReadyToHarvest) timer.cancel();
      });
    }
    notifyListeners();
  }

  void _updateGrowthStatusInternalLogic() {
    if (_user?.plantedAt == null || _currentGrowingPlantDetails == null) return;

    final growDuration = Duration(seconds: _currentGrowingPlantDetails!.growTime);
    final readyTime = _user!.plantedAt!.add(growDuration);
    final now = DateTime.now();
    Duration newRemainingTime = readyTime.difference(now);
    if (newRemainingTime.isNegative) newRemainingTime = Duration.zero;
    _currentPlantRemainingGrowTime = newRemainingTime;
    _isCurrentPlantReadyToHarvest = now.isAfter(readyTime);
  }

  Future<void> harvestAndSellPlant() async {
    if (_user == null || _currentGrowingPlantDetails == null || !_isCurrentPlantReadyToHarvest) return;

    _isLoadingUserData = true;
    notifyListeners();

    final plantBeingHarvested = _currentGrowingPlantDetails!;
    final originalMoney = _user!.money;

    try {
      _user!.money += plantBeingHarvested.sellPrice;
      _user!.currentPlantId = null;
      _user!.currentPlantName = null;
      _user!.plantedAt = null;
      _clearGrowingPlantStateInternal();

      await _updateUserDocument({
        'money': _user!.money,
        'currentPlantId': null,
        'currentPlantName': null,
        'plantedAt': null,
      });
    } catch (e) {
      _user!.money = originalMoney;
      _user!.currentPlantId = plantBeingHarvested.id;
      _user!.currentPlantName = plantBeingHarvested.name;
      _currentGrowingPlantDetails = plantBeingHarvested;
      _startOrUpdateGrowthTimer();
    } finally {
      _isLoadingUserData = false;
      notifyListeners();
    }
  }

  Future<void> _updateUserDocument(Map<String, dynamic> dataToUpdate) async {
    if (_user?.uid == null) return;
    await _firestore.collection('users').doc(_user!.uid).update(dataToUpdate);
  }
}
