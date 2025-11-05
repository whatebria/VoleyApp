// lib/screens/player_link_code_screen.dart
import 'package:flutter/material.dart';

class PlayerLinkCodeScreen extends StatelessWidget {
  const PlayerLinkCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar con Entrenador'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Mi Código: [XXXX-XXXX]',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
              TextField(
                decoration:
                    InputDecoration(labelText: 'Ingresar código de entrenador'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: null, // Deshabilitado por ahora
                child: Text('Vincular'),
              )
            ],
          ),
        ),
      ),
    );
  }
}