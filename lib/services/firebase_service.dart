import 'package:cloud_firestore/cloud_firestore.dart';

final _users = FirebaseFirestore.instance.collection('users');
final _contracts = FirebaseFirestore.instance.collection('contracts');

Future<bool> userExists(String name) async {
  final snapshot = await _users.where('name', isEqualTo: name).limit(1).get();
  return snapshot.docs.isNotEmpty;
}

Future<String?> getUserId(String name) async {
  final snapshot = await _users.where('name', isEqualTo: name).limit(1).get();
  return snapshot.docs.isEmpty ? null : snapshot.docs.first.id;
}

Future<String> createUser(String name) async {
  final doc = await _users.add({'name': name});
  return doc.id;
}

Future<String> createContract(String creatorId, String partnerId, int duration) async {
  final contract = await _contracts.add({
    'creatorId': creatorId,
    'partnerId': partnerId,
    'duration': duration,
    'createdAt': FieldValue.serverTimestamp(),
  });

  final contractRef = {'contractId': contract.id};
  await _users.doc(creatorId).collection('contracts').doc(contract.id).set(contractRef);
  await _users.doc(partnerId).collection('contracts').doc(contract.id).set(contractRef);

  return contract.id;
}

Stream<List<Map<String, dynamic>>> getUserContracts(String userId) {
  return _users.doc(userId).collection('contracts').snapshots().asyncMap((snapshot) async {
    final contracts = <Map<String, dynamic>>[];
    for (final doc in snapshot.docs) {
      final contractDoc = await _contracts.doc(doc.id).get();
      if (contractDoc.exists) {
        contracts.add({'id': doc.id, ...contractDoc.data()!});
      }
    }
    return contracts;
  });
}

Stream<List<Map<String, dynamic>>> getUsers(String? excludeUserId) {
  return _users.snapshots().map((snapshot) {
    return snapshot.docs
        .where((doc) => doc.id != excludeUserId)
        .map((doc) => {'id': doc.id, 'name': doc.data()['name'] as String})
        .toList();
  });
}
