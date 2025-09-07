import 'package:flutter/material.dart';
import '../widgets/warehouse_bar.dart';
import '../widgets/greenhouse_list.dart';
import '../widgets/world_map_widget.dart'; // ⬅️ importa la mappa
import 'package:latlong2/latlong.dart';

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  bool isSidebarOpen = true;

  // 🔹 Mock serre con coordinate
  final List<Map<String, dynamic>> serreMock = [
    {
      "nome": "Serra 1",
      "degrado": 10,
      "tempoRimanente": const Duration(minutes: 5, seconds: 30),
      "lat": 41.9,
      "lng": 12.5,
    },
    {
      "nome": "Serra 2",
      "degrado": 25,
      "tempoRimanente": const Duration(minutes: 12, seconds: 45),
      "lat": 40.4,
      "lng": -3.7,
    },
    {
      "nome": "Serra 3",
      "degrado": 50,
      "tempoRimanente": const Duration(seconds: 0),
      "lat": 48.8,
      "lng": 2.3,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("HydroFarm Tycoon"),
      ),
      body: Stack(
        children: [
          // 🔹 Mappa centrale
          Positioned.fill(
            child: WorldMapWidget(
              serre: serreMock,
              onAddSerra: (point) {
                setState(() {
                  serreMock.add({
                    "nome": "Nuova Serra",
                    "degrado": 0,
                    "tempoRimanente": const Duration(minutes: 15),
                    "lat": point.latitude,
                    "lng": point.longitude,
                  });
                });
              },
              onRemoveSerra: (index) {
                setState(() {
                  serreMock.removeAt(index);
                });
              },
            ),
          ),

          // 🔹 Sidebar sinistra
          Align(
            alignment: Alignment.centerLeft,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSidebarOpen ? 220 : 60,
              color: isSidebarOpen ? Colors.blueGrey.shade900 : Colors.transparent,
              child: isSidebarOpen
                  ? Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        isSidebarOpen = false;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  const WarehouseBar(),
                  const SizedBox(height: 8),
                  Expanded(child: GreenhouseList(serre: serreMock)),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    color: Colors.blueGrey.shade800,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.spa, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.shopping_basket, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.hourglass_empty, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.build, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              )
                  : SizedBox(
                width: 60,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward, color: Colors.grey[300]),
                  onPressed: () {
                    setState(() {
                      isSidebarOpen = true;
                    });
                  },
                ),
              ),
            ),
          ),

          // 🔹 Sidebar destra
          Align(
            alignment: Alignment.centerRight,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isSidebarOpen ? 200 : 80, // minimo indispensabile
              color: Colors.grey.shade200.withOpacity(isSidebarOpen ? 1 : 0.3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Sidebar Destra",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Icon(Icons.info_outline),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
