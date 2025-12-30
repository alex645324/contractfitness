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

Future<String> createContract(String creatorId, String partnerId, int duration, List<String> tasks) async {
  final contract = await _contracts.add({
    'creatorId': creatorId,
    'partnerId': partnerId,
    'duration': duration,
    'tasks': tasks,
    'createdAt': FieldValue.serverTimestamp(),
    'daysCompleted': 0,
    'lastEvaluatedDate': null,
    'completed': false,
    'taskCompletions': {},
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

Future<List<int>> getTaskCompletions(String contractId, String date, String userId) async {
  final doc = await _contracts.doc(contractId).get();
  if (!doc.exists) return [];
  final completions = doc.data()?['taskCompletions'] as Map<String, dynamic>? ?? {};
  final dayData = completions[date] as Map<String, dynamic>? ?? {};
  final userTasks = dayData[userId] as List<dynamic>? ?? [];
  return userTasks.cast<int>();
}

Future<void> setTaskCompletions(String contractId, String date, String userId, List<int> indices) async {
  await _contracts.doc(contractId).update({
    'taskCompletions.$date.$userId': indices,
  });
}

Future<void> updateContractProgress(String contractId, {int? daysCompleted, String? lastEvaluatedDate, bool? completed}) async {
  final updates = <String, dynamic>{};
  if (daysCompleted != null) updates['daysCompleted'] = daysCompleted;
  if (lastEvaluatedDate != null) updates['lastEvaluatedDate'] = lastEvaluatedDate;
  if (completed != null) updates['completed'] = completed;
  if (updates.isNotEmpty) {
    await _contracts.doc(contractId).update(updates);
  }
}
