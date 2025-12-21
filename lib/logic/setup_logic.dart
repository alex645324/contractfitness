import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

sealed class SetupResult {}

sealed class ContractResult {}

class ContractSuccess extends ContractResult {
  final String id;
  final String title;
  final List<String> partnerNames;
  final int daysPassed;
  final int duration;
  ContractSuccess(this.id, this.title, this.partnerNames, this.daysPassed, this.duration);
}

class ContractNotFound extends ContractResult {}

class SetupSuccess extends SetupResult {
  final String userId;
  final String? contractId;
  SetupSuccess(this.userId, this.contractId);
}

class SetupFailure extends SetupResult {
  final String message;
  SetupFailure(this.message);
}

Future<SetupResult> submitSetup({
  required String name,
  String? partnerId,
  required int duration,
  required DateTime startDate,
}) async {
  if (name.isEmpty) {
    return SetupFailure('Name is required');
  }

  final userId = await createUser(name);

  String? contractId;
  if (partnerId != null) {
    contractId = await createContract([userId, partnerId], duration, startDate);
  }

  return SetupSuccess(userId, contractId);
}

Future<ContractResult> getActiveContract(String userId) async {
  final contracts = await getContractsByUserId(userId);
  if (contracts.isEmpty) return ContractNotFound();

  final contract = contracts.first;
  final userIds = List<String>.from(contract['userIds'] ?? []);
  final partnerIds = userIds.where((id) => id != userId).toList();
  final partners = await getUsersByIds(partnerIds);
  final partnerNames = partners.map((p) => p['name'] as String).toList();

  final startDate = (contract['startDate'] as Timestamp).toDate();
  final daysPassed = DateTime.now().difference(startDate).inDays;

  return ContractSuccess(
    contract['id'] as String,
    'Body #${contract['id'].toString().substring(0, 2).toUpperCase()}',
    partnerNames,
    daysPassed < 0 ? 0 : daysPassed,
    contract['duration'] as int,
  );
}
