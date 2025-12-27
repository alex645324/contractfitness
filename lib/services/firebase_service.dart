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

Future<String> createContract(List<String> userIds, int duration) async {
  final doc = await _firestore.collection('contracts').add({
    'userIds': userIds,
    'duration': duration,
    'createdAt': FieldValue.serverTimestamp(),
  });

  for (final userId in userIds) {
    await _firestore.collection('users').doc(userId).update({
      'contractIds': FieldValue.arrayUnion([doc.id]),
    });
  }

  return doc.id;
}

Future<List<Map<String, dynamic>>> getContractsByUserId(String userId) async {
  final snapshot = await _firestore
      .collection('contracts')
      .where('userIds', arrayContains: userId)
      .get();
  return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
}

Future<List<Map<String, dynamic>>> getUsersByIds(List<String> userIds) async {
  if (userIds.isEmpty) return [];
  final snapshot = await _firestore
      .collection('users')
      .where(FieldPath.documentId, whereIn: userIds)
      .get();
  return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
}

Future<void> saveDailyActions(String documentId, Map<String, bool> actions) async {
  await _firestore.collection('dailyActions').doc(documentId).set(actions);
}

Future<Map<String, bool>?> getDailyActions(String documentId) async {
  final doc = await _firestore.collection('dailyActions').doc(documentId).get();
  if (!doc.exists) return null;
  final data = doc.data()!;
  return {
    'train': data['train'] as bool? ?? false,
    'nutrition': data['nutrition'] as bool? ?? false,
    'sleep': data['sleep'] as bool? ?? false,
  };
}

Future<void> updateContractProgress(String contractId, int delta) async {
  await _firestore.collection('contracts').doc(contractId).update({
    'progress': FieldValue.increment(delta),
  });
}

Future<void> incrementContractPenalties(String contractId) async {
  await _firestore.collection('contracts').doc(contractId).update({
    'penalties': FieldValue.increment(1),
  });
}

Future<DateTime> getServerDate() async {
  final tempDoc = _firestore.collection('_temp').doc();
  await tempDoc.set({'t': FieldValue.serverTimestamp()});
  final snap = await tempDoc.get();
  await tempDoc.delete();
  final timestamp = snap.data()!['t'] as Timestamp;
  final dt = timestamp.toDate();
  return DateTime(dt.year, dt.month, dt.day);
}

Future<DateTime?> getUserLastActiveDate(String userId) async {
  final doc = await _firestore.collection('users').doc(userId).get();
  final data = doc.data();
  if (data == null || data['lastActiveDate'] == null) return null;
  final timestamp = data['lastActiveDate'] as Timestamp;
  final dt = timestamp.toDate();
  return DateTime(dt.year, dt.month, dt.day);
}

Future<void> setUserLastActiveDate(String userId, DateTime date) async {
  await _firestore.collection('users').doc(userId).update({
    'lastActiveDate': Timestamp.fromDate(date),
  });
}
