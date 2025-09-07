// lib/widgets/greenhouse_list.dart
import 'package:flutter/material.dart';

class GreenhouseList extends StatelessWidget {
  final List<Map<String, dynamic>> serre;

  const GreenhouseList({super.key, required this.serre});

  @override
  Widget build(BuildContext context) {
    // 🔹 Ordinamento per tempo rimanente
    final sortedSerre = [...serre]..sort(
          (a, b) {
        final t1 = a["tempoRimanente"] as Duration;
        final t2 = b["tempoRimanente"] as Duration;
        return t1.compareTo(t2);
      },
    );

    return ListView.builder(
      itemCount: sortedSerre.length,
      itemBuilder: (context, index) {
        final serra = sortedSerre[index];
        final tempo = serra["tempoRimanente"] as Duration;

        // Format timer → mm:ss
        String tempoText =
            "${tempo.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(tempo.inSeconds % 60).toString().padLeft(2, '0')}";

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 🔹 Nome Serra
              Text(
                serra["nome"],
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              // 🔹 Percentuale degrado (solo numero)
              Text(
                "${serra["degrado"]}%",
                style: const TextStyle(color: Colors.white),
              ),

              // 🔹 Timer
              Text(
                tempoText,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}
