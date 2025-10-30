import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> seedTests() async {
  final testsRef = FirebaseFirestore.instance.collection('tests');

  final tests = [
    {
      "name": "Test de salto vertical (CMJ)",
      "description": "Evalúa la potencia de piernas y la capacidad explosiva mediante un salto vertical sin impulso de brazos.",
      "measure": "cm",
      "objective": "Potencia de piernas / rendimiento en salto.",
      "recommendedTags": ["Potencia", "Fuerza", "Piernas"],
    },
    {
      "name": "Test de agilidad T-Test",
      "description": "Evalúa la agilidad y la capacidad de cambio de dirección, importantes para defensa y cobertura.",
      "measure": "s",
      "objective": "Agilidad lateral y coordinación.",
      "recommendedTags": ["Agilidad", "Defensa", "Cambio de dirección"],
    },
    {
      "name": "Test de resistencia Yo-Yo Intermitente Nivel 1",
      "description": "Evalúa la capacidad aeróbica y recuperación entre esfuerzos repetidos.",
      "measure": "metros",
      "objective": "Resistencia aeróbica y capacidad de recuperación.",
      "recommendedTags": ["Resistencia", "Cardio", "Recuperación"],
    },
    {
      "name": "Test de plancha abdominal",
      "description": "Evalúa la estabilidad y resistencia del core manteniendo la posición de plancha el mayor tiempo posible.",
      "measure": "s",
      "objective": "Estabilidad del core y control postural.",
      "recommendedTags": ["Core", "Estabilidad", "Postura"],
    },
    {
      "name": "Test de flexibilidad de sit and reach",
      "description": "Evalúa la flexibilidad de la cadena posterior (isquiotibiales y zona lumbar).",
      "measure": "cm",
      "objective": "Flexibilidad general y movilidad.",
      "recommendedTags": ["Movilidad", "Flexibilidad"],
    },
    {
      "name": "Test de sprint 10 metros",
      "description": "Evalúa la velocidad de reacción y aceleración corta, importante en desplazamientos defensivos.",
      "measure": "s",
      "objective": "Velocidad y aceleración.",
      "recommendedTags": ["Velocidad", "Reacción", "Explosividad"],
    },
    {
      "name": "Test de salto con contramovimiento (CMJ con brazos)",
      "description": "Evalúa la potencia de salto integrando el movimiento de brazos, más real al contexto del remate.",
      "measure": "cm",
      "objective": "Potencia de salto aplicada al ataque y bloqueo.",
      "recommendedTags": ["Potencia", "Ataque", "Salto"],
    },
    {
      "name": "Test de lanzamiento de balón medicinal",
      "description": "Evalúa la potencia del tren superior, relacionada con el golpeo y remate.",
      "measure": "m",
      "objective": "Potencia de brazos y tronco.",
      "recommendedTags": ["Hombros", "Potencia", "Tronco"],
    },
    {
      "name": "Test de equilibrio unipodal",
      "description": "Evalúa la estabilidad y control corporal en una sola pierna.",
      "measure": "s",
      "objective": "Estabilidad y propiocepción.",
      "recommendedTags": ["Equilibrio", "Estabilidad", "Prevención"],
    },
    {
      "name": "Test de salto triple horizontal",
      "description": "Evalúa la fuerza y coordinación de tren inferior con movimientos consecutivos.",
      "measure": "m",
      "objective": "Potencia, coordinación y estabilidad al aterrizar.",
      "recommendedTags": ["Piernas", "Potencia", "Coordinación"],
    },
  ];

  for (final test in tests) {
    final existing = await testsRef
        .where("name", isEqualTo: test["name"])
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await testsRef.add(test);
      print("✅ Test agregado: ${test['name']}");
    } else {
      print("⚠️ Test ya existente: ${test['name']}");
    }
  }

  print("📊 Catálogo de tests cargado correctamente.");
}
