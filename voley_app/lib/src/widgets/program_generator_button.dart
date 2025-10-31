import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

// (Este podría ser tu StateNotifier, Cubit, o un simple StatefulWidget)
class ProgramGeneratorButton extends StatefulWidget {
  const ProgramGeneratorButton({super.key});

  @override
  _ProgramGeneratorButtonState createState() => _ProgramGeneratorButtonState();
}

class _ProgramGeneratorButtonState extends State<ProgramGeneratorButton> {
  bool _isLoading = false;

  Future<void> _triggerProgramGeneration() async {
    // 1. Poner la UI en modo de carga
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Obtener la instancia de la función "callable"
      // El nombre 'generateMyProgram' DEBE coincidir con el 'export' en index.ts
      final callable = FirebaseFunctions.instance.httpsCallable('generateMyProgram');
      
      // 3. Llamar a la función (no necesita parámetros, ya que toma el UID del contexto)
      final HttpsCallableResult result = await callable.call();

      // 4. ¡Éxito! La función se ejecutó y guardó el programa.
      print("Resultado de la función: ${result.data}"); // Ej: { success: true, programId: '...' }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Nuevo programa generado!')),
        );
      }

    } on FirebaseFunctionsException catch (e) {
      // Manejar errores de la función (ej. 'unauthenticated')
      print('Error de Cloud Function: ${e.code} - ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e) {
      // Manejar otros errores (ej. sin conexión)
      print('Error desconocido: $e');
    }

    // 5. Quitar el modo de carga
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _triggerProgramGeneration,
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text('Generar mi Programa'),
    );
  }
}