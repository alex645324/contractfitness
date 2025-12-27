import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_service.dart';

sealed class SetupResult {}

sealed class ContractResult {}

class ContractSuccess extends ContractResult {
  final String id;
  final String title;
  final List<String> partnerNames;
  final int progress;
  final int duration;
  final int penalties;
  ContractSuccess(this.id, this.title, this.partnerNames, this.progress, this.duration, this.penalties);
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
}) async {
  if (name.isEmpty) {
    return SetupFailure('Name is required');
  }

  final userId = await _ensureUser(name);

  String? contractId;
  if (partnerId != null) {
    contractId = await createContract([userId, partnerId], duration);
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

  final progress = (contract['progress'] as int?) ?? 0;
  final penalties = (contract['penalties'] as int?) ?? 0;

  return ContractSuccess(
    contract['id'] as String,
    'Body #${contract['id'].toString().substring(0, 2).toUpperCase()}',
    partnerNames,
    progress,
    contract['duration'] as int,
    penalties,
  );
}

Future<String> _ensureUser(String name) async {
  final existingId = await findUserIdByName(name);
  if (existingId != null) return existingId;
  return createUser(name);
}

Future<String?> findUserIdByName(String name) async {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  final users = await getUsers();
  for (final user in users) {
    final rawName = (user['name'] as String?) ?? '';
    if (rawName.trim().toLowerCase() == lower) {
      return user['id'] as String;
    }
  }
  return null;
}

Future<void> persistUserId(String userId) async {
  debugPrint('[persistUserId] Saving userId: $userId');
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('userId', userId);
  debugPrint('[persistUserId] Saved successfully');
}

Future<String?> loadSavedUserId() async {
  debugPrint('[loadSavedUserId] Loading...');
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  debugPrint('[loadSavedUserId] Got userId: $userId');
  return userId;
}

Future<String?> getUserNameById(String userId) async {
  final users = await getUsersByIds([userId]);
  if (users.isEmpty) return null;
  return users.first['name'] as String?;
}

String _formatDate(DateTime date) {
  final y = date.year.toString();
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String docIdForDate(String userId, DateTime date) {
  return '${userId}_${_formatDate(date)}';
}

Future<DateTime> checkDayTransition(String userId) async {
  final serverDate = await getServerDate();
  final lastActive = await getUserLastActiveDate(userId);

  if (lastActive != null && lastActive.isBefore(serverDate)) {
    // Process each missed day
    var checkDate = lastActive;
    while (checkDate.isBefore(serverDate)) {
      final docId = docIdForDate(userId, checkDate);
      final actions = await getDailyActions(docId);

      final complete = actions != null &&
          actions['train'] == true &&
          actions['nutrition'] == true &&
          actions['sleep'] == true;

      if (!complete) {
        final contracts = await getContractsByUserId(userId);
        for (final contract in contracts) {
          final contractId = contract['id'] as String;
          await updateContractProgress(contractId, -1);
          await incrementContractPenalties(contractId);
        }
      }

      checkDate = checkDate.add(const Duration(days: 1));
    }
  }

  await setUserLastActiveDate(userId, serverDate);
  return serverDate;
}

Future<void> completeDailyActions(String userId) async {
  final contracts = await getContractsByUserId(userId);
  for (final contract in contracts) {
    final contractId = contract['id'] as String;
    await updateContractProgress(contractId, 1);
  }
}
