import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedInjuries() async {
  final injuriesRef = FirebaseFirestore.instance.collection('injuries');

  final injuries = [
    {
      "name": "Esguince de tobillo leve",
      "excludedTags": ["Saltos", "Pliometría", "Cambio de dirección"],
      "recommendTags": ["Movilidad", "Fuerza ligera", "Equilibrio"],
      "duration": 3,
      "notes": "Evitar impacto alto; incluir ejercicios de propiocepción y fortalecimiento de tobillo.",
    },
    {
      "name": "Tendinitis rotuliana",
      "excludedTags": ["Saltos", "Aceleraciones"],
      "recommendTags": ["Fuerza excéntrica", "Estiramiento", "Core"],
      "duration": 4,
      "notes": "Enfocarse en el control del movimiento y progresión gradual de la carga.",
    },
    {
      "name": "Lesión de hombro (manguito rotador)",
      "excludedTags": ["Press sobre cabeza", "Remate", "Bloqueo"],
      "recommendTags": ["Movilidad escapular", "Fortalecimiento del core", "Trabajo de banda elástica"],
      "duration": 6,
      "notes": "Priorizar ejercicios de estabilidad escapular y fortalecimiento controlado del hombro.",
    },
    {
      "name": "Lumbalgia leve",
      "excludedTags": ["Peso muerto", "Cargas pesadas"],
      "recommendTags": ["Movilidad", "Core", "Estiramiento"],
      "duration": 2,
      "notes": "Trabajar estabilidad central sin sobrecargar la zona lumbar.",
    },
    {
      "name": "Distensión isquiotibial",
      "excludedTags": ["Sprints", "Saltos explosivos"],
      "recommendTags": ["Movilidad", "Fuerza controlada", "Trabajo excéntrico"],
      "duration": 5,
      "notes": "Iniciar con rango corto y avanzar progresivamente hacia la carga total.",
    },
  ];

  for (final inj in injuries) {
    final existing = await injuriesRef
        .where("name", isEqualTo: inj["name"])
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await injuriesRef.add(inj);
      print("✅ Lesión agregada: ${inj['name']}");
    } else {
      print("⚠️ Lesión ya existente: ${inj['name']}");
    }
  }

  print("🩺 Catálogo de lesiones completado.");
}
