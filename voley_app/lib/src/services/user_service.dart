import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voley_app/src/models/user.dart';

class UserService {
  final CollectionReference _usersCollection =
      FirebaseFirestore.instance.collection('users');

  Future<void> createUser(User user) async {
    try {
      await _usersCollection.doc(user.id).set(user.toJson());
    } catch (e) {
      print('Error creating user: $e');
    }
  }

  Future<List<User>> getUsers() async {
    try {
      final querySnapshot = await _usersCollection.get();
      return querySnapshot.docs
          .map((doc) => User.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error retrieving users: $e');
      return [];
    }
  }
}
