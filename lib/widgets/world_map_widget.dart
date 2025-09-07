import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class WorldMapWidget extends StatelessWidget {
  final List<Map<String, dynamic>> serre; // 🔹 lista passata dal parent
  final void Function(LatLng) onAddSerra;
  final void Function(int) onRemoveSerra;

  const WorldMapWidget({
    super.key,
    required this.serre,
    required this.onAddSerra,
    required this.onRemoveSerra,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(20, 0),
        initialZoom: 2,
        minZoom: 1,
        maxZoom: 6,
        onTap: (tapPosition, point) {
          onAddSerra(point); // 🔹 delega al parent
        },
      ),
      children: [
        TileLayer(
          urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
          userAgentPackageName: "com.example.hydrofarm",
        ),
        MarkerLayer(
          markers: serre.asMap().entries.map((entry) {
            final index = entry.key;
            final serra = entry.value;

            return Marker(
              point: LatLng(serra["lat"], serra["lng"]),
              width: 60,
              height: 60,
              child: GestureDetector(
                onLongPress: () => onRemoveSerra(index),
                child: const Icon(
                  Icons.agriculture,
                  size: 40,
                  color: Colors.green,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
