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

Future<String?> getUserName(String userId) async {
  final doc = await _users.doc(userId).get();
  if (!doc.exists) return null;
  return doc.data()?['name'] as String?;
}

Future<String> createUser(String name) async {
  final doc = await _users.add({'name': name});
  return doc.id;
}

Future<String?> createContract(String creatorId, String partnerId, int duration, List<String> tasks, String pairKey) async {
  final db = FirebaseFirestore.instance;
  final contractRef = _contracts.doc(pairKey);

  final result = await db.runTransaction<String?>((transaction) async {
    final doc = await transaction.get(contractRef);
    if (doc.exists) return null;

    transaction.set(contractRef, {
      'creatorId': creatorId,
      'partnerId': partnerId,
      'duration': duration,
      'tasks': tasks,
      'createdAt': FieldValue.serverTimestamp(),
      'daysCompleted': 0,
      'daysMissed': 0,
      'completed': false,
      'taskCompletions': {},
    });

    return pairKey;
  });

  if (result == null) return null;

  final userContractRef = {'contractId': pairKey};
  await _users.doc(creatorId).collection('contracts').doc(pairKey).set(userContractRef);
  await _users.doc(partnerId).collection('contracts').doc(pairKey).set(userContractRef);

  return pairKey;
}

Stream<List<Map<String, dynamic>>> getUserContracts(String userId) {
  return _users.doc(userId).collection('contracts').snapshots().asyncExpand((snapshot) {
    if (snapshot.docs.isEmpty) {
      return Stream.value(<Map<String, dynamic>>[]);
    }
    final contractIds = snapshot.docs.map((doc) => doc.id).toList();
    return _contracts
        .where(FieldPath.documentId, whereIn: contractIds)
        .snapshots()
        .map((contractSnapshot) {
          return contractSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();
        });
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

Future<void> setTaskCompletions(String contractId, String date, String userId, List<int> indices) async {
  await _contracts.doc(contractId).update({
    'taskCompletions.$date.$userId': indices,
  });
}

Future<void> updateContractProgress(String contractId, {int? daysCompleted, bool? completed}) async {
  final updates = <String, dynamic>{};
  if (daysCompleted != null) updates['daysCompleted'] = daysCompleted;
  if (completed != null) updates['completed'] = completed;
  if (updates.isNotEmpty) {
    await _contracts.doc(contractId).update(updates);
  }
}

Future<Map<String, dynamic>?> getContract(String contractId) async {
  final doc = await _contracts.doc(contractId).get();
  if (!doc.exists) return null;
  return {'id': doc.id, ...doc.data()!};
}
