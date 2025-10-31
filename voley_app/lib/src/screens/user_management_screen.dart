import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voley_app/src/models/user.dart';
import 'package:voley_app/src/services/user_service.dart';

class UserManagementScreen extends ConsumerWidget {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNameController = TextEditingController();
    final userEmailController = TextEditingController();
    final testScoreController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: userNameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: userEmailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: testScoreController,
              decoration: const InputDecoration(labelText: 'Test Score'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final user = User(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  email: userEmailController.text,
                  name: userNameController.text,
                  role: UserRole.player,
                  createdAt: DateTime.now(),
                  testScores: [int.tryParse(testScoreController.text) ?? 0],
                );
                await _userService.createUser(user);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User created successfully!')),
                );
              },
              child: const Text('Create User'),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<User>>(
              future: _userService.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No users found.');
                } else {
                  return DropdownButton<User>(
                    hint: const Text('Select User'),
                    items: snapshot.data!.map((user) {
                      return DropdownMenuItem<User>(
                        value: user,
                        child: Text(user.name),
                      );
                    }).toList(),
                    onChanged: (User? selectedUser) {
                      // Handle user selection
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}