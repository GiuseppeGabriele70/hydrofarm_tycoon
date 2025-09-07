// lib/widgets/warehouse_bar.dart
import 'package:flutter/material.dart';

class WarehouseBar extends StatelessWidget {
  const WarehouseBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onPressed: () {
                // TODO: Naviga a Sito
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  "Sito",
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onPressed: () {
                // TODO: Naviga a Panoramica
              },
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  "Panoramica",
                  style: TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
