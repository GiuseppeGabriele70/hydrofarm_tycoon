// lib/debug/farming_debug_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/agricoltura/modulo_coltivazione.dart';
import '../models/plant.dart';
import '../providers/farming_provider.dart';
import '../providers/user_provider.dart';
import '../services/database_service.dart';

class FarmingDebugScreen extends StatefulWidget {
  static const routeName = '/debug-farming';

  const FarmingDebugScreen({super.key});

  @override
  _FarmingDebugScreenState createState() => _FarmingDebugScreenState();
}

class _FarmingDebugScreenState extends State<FarmingDebugScreen> {
  final _userIdController = TextEditingController();
  final _centroIdController = TextEditingController();
  final _serraIdController = TextEditingController();
  final _moduloIdController = TextEditingController();

  FarmingProvider? _farmingProvider;
  DatabaseService? _databaseService;
  String? _selectedPlantIdForDropdown; // Pianta selezionata nel dropdown generale

  @override
  void initState() {
    super.initState();
    // È meglio ottenere l'UID dell'utente loggato da UserProvider o Auth service
    // Inizializza i controller con valori di default o da UserProvider
    _centroIdController.text = "Gj7P6yXm8Yd8S6rB4eQk"; // ID Centro Esempio
    _serraIdController.text = "rYJ3U7sLpWdGvH2aTqM4";  // ID Serra Esempio
    _moduloIdController.text = "a2sR9hK3bFjV6mPzXoLg"; // ID Modulo Esempio con capienza > 1

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user != null) {
        _userIdController.text = userProvider.user!.uid;
      } else {
        // Se non c'è utente, potresti mettere un placeholder o lasciare vuoto
        // _userIdController.text = "SOSTITUISCI_CON_UID_UTENTE_TEST";
        print(">>> FarmingDebugScreen: UserProvider non ha un utente all'avvio, l'UID sarà vuoto a meno che non sia inserito manualmente.");
      }
      if (userProvider.plantBlueprints.isEmpty && !userProvider.isLoadingUserData) {
        userProvider.loadPlantBlueprints();
      }
      // Dopo aver caricato i blueprints, se l'userProvider è pronto e farmingProvider no, inizializzalo
      if (userProvider.user != null && _farmingProvider == null && _userIdController.text.isNotEmpty) {
        // _initServicesAndProvider(); // Potrebbe essere chiamato qui o dall'utente
      }
    });
  }

  void _initServicesAndProvider() {
    if (_userIdController.text.isEmpty ||
        _centroIdController.text.isEmpty ||
        _serraIdController.text.isEmpty ||
        _moduloIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Per favore, inserisci tutti gli ID (User, Centro, Serra, Modulo).")),
      );
      return;
    }

    _farmingProvider?.removeListener(_updateState);
    _farmingProvider?.dispose(); // Dispose del provider precedente

    _databaseService = DatabaseService(uid: _userIdController.text);
    _farmingProvider = FarmingProvider(
      databaseService: _databaseService!,
      userId: _userIdController.text,
      centroId: _centroIdController.text,
      serraId: _serraIdController.text,
      moduloId: _moduloIdController.text,
    );
    _farmingProvider!.addListener(_updateState);
    _farmingProvider!.loadModuloData(); // Carica i dati del modulo all'inizializzazione

    if (mounted) {
      setState(() {});
    }
  }

  void _updateState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _centroIdController.dispose();
    _serraIdController.dispose();
    _moduloIdController.dispose();
    _farmingProvider?.removeListener(_updateState);
    _farmingProvider?.dispose();
    super.dispose();
  }

  Future<void> _attemptPlantInSpecificSlot(int slotIndex) async {
    if (_farmingProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Provider non inizializzato.")));
      return;
    }
    if (_selectedPlantIdForDropdown == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Seleziona una pianta dal dropdown generale.")));
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final Plant? plantToPlant = userProvider.getPlantBlueprintById(_selectedPlantIdForDropdown!);

    if (plantToPlant == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Blueprint '$_selectedPlantIdForDropdown' non trovato.")));
      return;
    }

    // ***** CHIAMATA CORRETTA QUI *****
    bool success = await _farmingProvider!.attemptToPlantInSlot(plantToPlant, userProvider, slotIndex);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success
          ? "${plantToPlant.name} piantata in slot $slotIndex! Saldo: ${userProvider.user?.money}"
          : "Errore piantagione in slot $slotIndex. Errore: ${_farmingProvider?.errorMessage ?? 'N/D'}")),
    );
  }

  Future<void> _attemptHarvestFromSpecificSlot(int slotIndex) async {
    if (_farmingProvider == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Provider non inizializzato.")));
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    bool success = await _farmingProvider!.attemptToHarvestFromSlot(slotIndex, userProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success
          ? "Raccolta da slot $slotIndex OK! Saldo: ${userProvider.user?.money}"
          : "Errore raccolta da slot $slotIndex. Errore: ${_farmingProvider?.errorMessage ?? 'N/D'}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final List<Plant> allPlantBlueprints = userProvider.plantBlueprints;
    final int currentModuloLevel = _farmingProvider?.modulo?.level ?? 0;
    final int currentUserMoney = userProvider.user?.money ?? 0;

    if (_userIdController.text.isEmpty && userProvider.user != null) {
      _userIdController.text = userProvider.user!.uid;
    }
    final String currentUserIdForDisplay = _userIdController.text;

    List<Plant> piantabili = [];
    List<Plant> nonPiantabili = [];

    if (_farmingProvider?.modulo != null) {
      for (var plant in allPlantBlueprints) {
        if (plant.requiredLevel <= currentModuloLevel) {
          piantabili.add(plant);
        } else {
          nonPiantabili.add(plant);
        }
      }
      piantabili.sort((a, b) => b.requiredLevel.compareTo(a.requiredLevel));
      nonPiantabili.sort((a, b) => a.requiredLevel.compareTo(b.requiredLevel));
    }
    List<Plant> semiOrdinatiPerDropdown = [...piantabili, ...nonPiantabili];
    if (_farmingProvider?.modulo == null && allPlantBlueprints.isNotEmpty) {
      semiOrdinatiPerDropdown = List.from(allPlantBlueprints);
      semiOrdinatiPerDropdown.sort((a,b) => a.requiredLevel.compareTo(b.requiredLevel));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Debug Slots Modulo (Saldo: $currentUserMoney)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("User ID (per Service/Provider): $currentUserIdForDisplay"),
            TextField(controller: _userIdController, decoration: const InputDecoration(labelText: 'User ID (puoi sovrascrivere)')),
            TextField(controller: _centroIdController, decoration: const InputDecoration(labelText: 'Centro ID')),
            TextField(controller: _serraIdController, decoration: const InputDecoration(labelText: 'Serra ID')),
            TextField(controller: _moduloIdController, decoration: const InputDecoration(labelText: 'Modulo ID')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _initServicesAndProvider,
              child: const Text('Carica Modulo / Inizializza Provider'),
            ),
            const Divider(height: 30),

            if (_farmingProvider != null) ...[
              Text('Stato Provider:', style: Theme.of(context).textTheme.titleLarge),
              if (_farmingProvider!.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_farmingProvider!.modulo == null)
                Text("Modulo non caricato o non trovato. Premi 'Carica Modulo'. Errore: ${_farmingProvider!.errorMessage ?? ''}")
              else ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Seme Selezionato per Piantare:', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  if (allPlantBlueprints.isEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Nessun blueprint di pianta caricato da UserProvider."),
                        ElevatedButton(onPressed: () => userProvider.loadPlantBlueprints(), child: const Text("Carica Blueprints Piante"))
                      ],
                    )
                  else
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Seleziona Pianta da Seminare', border: OutlineInputBorder()),
                      value: _selectedPlantIdForDropdown,
                      hint: const Text('Scegli una pianta'),
                      isExpanded: true,
                      items: semiOrdinatiPerDropdown.map((Plant plant) {
                        bool canPlantByLevel = _farmingProvider?.modulo == null ? true : plant.requiredLevel <= currentModuloLevel;
                        bool canAfford = currentUserMoney >= plant.seedPurchasePrice;
                        String plantLabel = "${plant.name} (Lvl: ${plant.requiredLevel}, Costo: ${plant.seedPurchasePrice})";

                        if (_farmingProvider?.modulo != null) {
                          if (!canPlantByLevel) plantLabel += " - Lvl Modulo Insuff.";
                          else if (!canAfford) plantLabel += " - Denaro Insuff.";
                        } else if (!canAfford) {
                          plantLabel += " - Denaro Insuff.";
                        }

                        return DropdownMenuItem<String>(
                          value: plant.id,
                          enabled: (_farmingProvider?.modulo == null) ? canAfford : (canPlantByLevel && canAfford),
                          child: Text(
                              plantLabel,
                              style: TextStyle(
                                  color: ((_farmingProvider?.modulo == null) ? canAfford : (canPlantByLevel && canAfford)) ? null : Colors.grey[600],
                                  fontStyle: ((_farmingProvider?.modulo == null) ? canAfford : (canPlantByLevel && canAfford)) ? FontStyle.normal : FontStyle.italic
                              )
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue == null) return;
                        final selectedPlantBlueprint = userProvider.getPlantBlueprintById(newValue);
                        if (selectedPlantBlueprint != null) {
                          bool canPlantByLevelCheck = _farmingProvider?.modulo == null ? true : selectedPlantBlueprint.requiredLevel <= currentModuloLevel;
                          bool canAffordCheck = currentUserMoney >= selectedPlantBlueprint.seedPurchasePrice;
                          if (canPlantByLevelCheck && canAffordCheck) {
                            setState(() { _selectedPlantIdForDropdown = newValue; });
                          } else {
                            String reason = "";
                            if(!canPlantByLevelCheck) reason = "Livello modulo ($currentModuloLevel) non sufficiente. ";
                            if(!canAffordCheck) reason += "Denaro non sufficiente (costo: ${selectedPlantBlueprint.seedPurchasePrice}).";
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Impossibile selezionare ${selectedPlantBlueprint.name}: $reason')),
                            );
                            setState(() { _selectedPlantIdForDropdown = null; });
                          }
                        }
                      },
                      validator: (value) => value == null ? 'Scegli una pianta da piantare' : null,
                    ),
                  const SizedBox(height: 20),
                  _buildModuloAndSlotsDetails(_farmingProvider!.modulo!, userProvider),
                ],
              if (_farmingProvider!.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text('ERRORE PROVIDER: ${_farmingProvider!.errorMessage!}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
            ] else
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Provider del modulo non ancora inizializzato. Inserisci gli ID e clicca "Carica Modulo".'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuloAndSlotsDetails(ModuloColtivazione modulo, UserProvider userProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Dettagli Modulo Caricato:', style: Theme.of(context).textTheme.titleMedium),
        ),
        Text('ID: ${modulo.id} - Nome: ${modulo.nome}'),
        Text('Livello Modulo: ${modulo.level} - Capienza: ${modulo.capienza} slots'),
        Text('Stato Efficienza: ${modulo.statoEfficienza}%'),
        const SizedBox(height: 15),
        Text('Slots del Modulo:', style: Theme.of(context).textTheme.titleMedium),
        if (modulo.slots.isEmpty && modulo.capienza > 0)
          Text("Il modulo ha ${modulo.capienza} slot, ma la lista 'slots' è vuota. Dovrebbe inizializzarsi dopo il caricamento.")
        else if (modulo.capienza == 0)
          const Text("Questo modulo ha una capienza di 0 slot.")
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: modulo.capienza,
            itemBuilder: (context, index) {
              SlotColtivazione slot;
              if (index < modulo.slots.length) {
                slot = modulo.slots[index];
              } else {
                print(">>> WARNING: Slot $index non trovato in modulo.slots, ma capienza è ${modulo.capienza}. Creo placeholder.");
                slot = SlotColtivazione(slotIndex: index);
              }
              return _buildSlotItem(slot, userProvider, modulo.level);
            },
          ),
      ],
    );
  }

  Widget _buildSlotItem(SlotColtivazione slot, UserProvider userProvider, int moduloLevel) {
    Plant? activePlantDetails;
    if (slot.piantaAttivaId != null && slot.piantaAttivaId!.isNotEmpty) {
      activePlantDetails = userProvider.getPlantBlueprintById(slot.piantaAttivaId!);
    }
    final bool isSlotOccupied = slot.piantaAttivaId != null && slot.piantaAttivaId!.isNotEmpty;

    final bool isGrowing = _farmingProvider?.isSlotGrowing(slot.slotIndex) ?? false;
    final bool isReady = _farmingProvider?.isSlotReadyToHarvest(slot.slotIndex) ?? false;
    final Duration remainingTime = _farmingProvider?.getRemainingTimeForSlot(slot.slotIndex) ?? Duration.zero;

    final Plant? plantSelectedInDropdown = _selectedPlantIdForDropdown != null
        ? userProvider.getPlantBlueprintById(_selectedPlantIdForDropdown!)
        : null;

    bool canPlantThisSeedInThisSlot = !isSlotOccupied &&
        plantSelectedInDropdown != null &&
        plantSelectedInDropdown.requiredLevel <= moduloLevel &&
        (userProvider.user?.money ?? 0) >= plantSelectedInDropdown.seedPurchasePrice;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Slot ${slot.slotIndex}', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(),
            if (isSlotOccupied) ...[
              Text('Pianta: ${activePlantDetails?.name ?? slot.nomePianta ?? slot.piantaAttivaId}'),
              Text('Piantata il: ${slot.plantedAt?.toLocal().toString().substring(0, 16) ?? "N/A"}'),
              if (isGrowing)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Tempo Rimanente: ${_formatDuration(remainingTime)}', style: const TextStyle(color: Colors.orange)),
                )
              else if (isReady)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0),
                  child: Text('PRONTA PER RACCOLTA!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                )
              else if (slot.growDurationSeconds != null && slot.growDurationSeconds == 0)
                  const Text('Questa pianta non ha un tempo di crescita (immediata o errore dati).')
                else
                  const Text('Stato crescita: N/D'),
            ] else ...[
              const Text('Slot Vuoto', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isSlotOccupied)
                  ElevatedButton(
                    onPressed: canPlantThisSeedInThisSlot && !(_farmingProvider?.isLoading ?? true)
                        ? () => _attemptPlantInSpecificSlot(slot.slotIndex)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canPlantThisSeedInThisSlot ? Theme.of(context).colorScheme.primary : Colors.grey,
                      foregroundColor: canPlantThisSeedInThisSlot ? Theme.of(context).colorScheme.onPrimary : Colors.black54,

                    ),
                    child: const Text('Pianta Qui'),
                  ),
                if (isSlotOccupied && isReady)
                  ElevatedButton(
                    onPressed: !(_farmingProvider?.isLoading ?? true)
                        ? () => _attemptHarvestFromSpecificSlot(slot.slotIndex)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Raccogli'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}

