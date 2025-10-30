// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  // Ya no es un String, es una referencia
  final CollectionReference collectionRef;

  // El constructor ahora recibe la referencia
  FirestoreService(this.collectionRef);

  // El resto de la lógica es la misma
  Future<DocumentReference> addItem(Map<String, dynamic> data) async {
    return await collectionRef.add(data);
  }

  Future<void> updateItem(String id, Map<String, dynamic> data) async {
    await collectionRef.doc(id).update(data);
  }
  
  // A veces es útil establecer un doc con un ID específico (como el UID del atleta)
  Future<void> setItem(String id, Map<String, dynamic> data) async {
    await collectionRef.doc(id).set(data);
  }

  Future<void> deleteItem(String id) async {
    await collectionRef.doc(id).delete();
  }

  Stream<QuerySnapshot> getItems() {
    return collectionRef.snapshots();
  }

  // Útil para los dropdowns
  Future<QuerySnapshot> getItemsOnce() {
    return collectionRef.get();
  }
}