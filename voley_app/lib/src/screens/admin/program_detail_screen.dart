// lib/src/screens/admin/program_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ProgramDetailScreen extends StatelessWidget {
  final DocumentSnapshot programDoc;

  const ProgramDetailScreen({super.key, required this.programDoc});

  @override
  Widget build(BuildContext context) {
    final data = programDoc.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'Sin nombre';
    final description = data['description'] ?? '';
    final phase = data['phase'] ?? '';
    final focus = data['focus'] ?? '';
    final startDate = (data['startDate'] as Timestamp?)?.toDate();
    final endDate = (data['endDate'] as Timestamp?)?.toDate();

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 12),
          Text("Fase: $phase"),
          Text("Foco: $focus"),
          if (startDate != null && endDate != null)
            Text("Duración: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}"),
          const Divider(),
          FutureBuilder(
            future: FirebaseFirestore.instance.collection('exercises')
                .where(FieldPath.documentId, whereIn: List<String>.from(data['exerciseIds'] ?? []))
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final exercises = snapshot.data!.docs;
              return ExpansionTile(
                title: const Text('Ejercicios'),
                children: exercises.map((e) => ListTile(title: Text(e['name']))).toList(),
              );
            },
          ),
          FutureBuilder(
            future: FirebaseFirestore.instance.collection('tests')
                .where(FieldPath.documentId, whereIn: List<String>.from(data['testIds'] ?? []))
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final tests = snapshot.data!.docs;
              return ExpansionTile(
                title: const Text('Tests'),
                children: tests.map((t) => ListTile(title: Text(t['name']))).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
