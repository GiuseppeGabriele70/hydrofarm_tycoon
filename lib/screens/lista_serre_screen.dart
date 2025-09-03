// lib/screens/lista_serre_screen.dart
import 'package:flutter/material.dart';

class ListaSerreScreen extends StatelessWidget {
  const ListaSerreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Test Pulsante Serra")),
      body: Column(
        children: [
          // Mostriamo solo una pianta fissa (rucola)
          Expanded(
            child: ListView(
              children: const [
                Card(
                  margin: EdgeInsets.all(16),
                  child: ListTile(
                    title: Text("Rucola"),
                    subtitle: Text("Livello: 1 • Capienza: 10 • Stato: 100%"),
                  ),
                ),
              ],
            ),
          ),

          // Pulsante fisso per test
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Pulsante funzionante!")),
                );
              },
              child: const Text("Acquista nuova serra"),
            ),
          ),
        ],
      ),
    );
  }
}
