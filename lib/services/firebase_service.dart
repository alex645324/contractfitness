import 'package:cloud_firestore/cloud_firestore.dart';

final _users = FirebaseFirestore.instance.collection('users');

Future<bool> userExists(String name) async {
  final snapshot = await _users.where('name', isEqualTo: name).limit(1).get();
  return snapshot.docs.isNotEmpty;
}

Future<void> createUser(String name) async {
  await _users.add({'name': name});
}
