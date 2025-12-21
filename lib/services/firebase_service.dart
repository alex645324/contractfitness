import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;

Future<String> createUser(String name) async {
  final doc = await _firestore.collection('users').add({
    'name': name,
    'createdAt': FieldValue.serverTimestamp(),
  });
  return doc.id;
}

Future<List<Map<String, dynamic>>> getUsers() async {
  final snapshot = await _firestore.collection('users').get();
  return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
}

Future<String> createContract(List<String> userIds, int duration, DateTime startDate) async {
  final doc = await _firestore.collection('contracts').add({
    'duration': duration,
    'startDate': Timestamp.fromDate(startDate),
    'createdAt': FieldValue.serverTimestamp(),
  });

  for (final userId in userIds) {
    await _firestore.collection('users').doc(userId).update({
      'contractIds': FieldValue.arrayUnion([doc.id]),
    });
  }

  return doc.id;
}
