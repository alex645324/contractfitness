import '../services/firebase_service.dart';

sealed class SetupResult {}

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
