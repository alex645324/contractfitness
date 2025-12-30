import '../services/firebase_service.dart' as svc;

String? currentUserId;
String? currentUserName;
String? currentContractId;

Future<({bool success, String? error})> authenticate(String name, bool isSignUp) async {
  if (name.trim().isEmpty) {
    return (success: false, error: 'empty');
  }

  final exists = await svc.userExists(name);

  if (isSignUp) {
    if (exists) {
      return (success: false, error: 'taken');
    }
    final userId = await svc.createUser(name);
    currentUserId = userId;
    currentUserName = name;
    return (success: true, error: null);
  } else {
    if (!exists) {
      return (success: false, error: 'not_found');
    }
    final userId = await svc.getUserId(name);
    currentUserId = userId;
    currentUserName = name;
    return (success: true, error: null);
  }
}

Future<({bool success, String? error})> createContract(int duration, String partnerName, List<String> tasks) async {
  if (currentUserId == null) {
    return (success: false, error: 'not_authenticated');
  }

  final partnerId = await svc.getUserId(partnerName);
  if (partnerId == null) {
    return (success: false, error: 'partner_not_found');
  }

  final contractId = await svc.createContract(currentUserId!, partnerId, duration, tasks);
  currentContractId = contractId;
  return (success: true, error: null);
}

Future<bool> userExists(String name) async {
  return await svc.userExists(name);
}

Future<String?> getUserName(String userId) async {
  return await svc.getUserName(userId);
}

Stream<List<Map<String, dynamic>>> getUserContracts() {
  if (currentUserId == null) return const Stream.empty();
  return svc.getUserContracts(currentUserId!);
}

Stream<List<Map<String, dynamic>>> getUsers() {
  return svc.getUsers(currentUserId);
}

String getTodayDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _getYesterdayDate() {
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  return '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
}

Future<List<int>> getCompletedTasks(String contractId) async {
  if (currentUserId == null) return [];
  return await svc.getTaskCompletions(contractId, getTodayDate(), currentUserId!);
}

Future<void> toggleTask(String contractId, int taskIndex) async {
  if (currentUserId == null) return;
  final today = getTodayDate();
  final current = await svc.getTaskCompletions(contractId, today, currentUserId!);
  if (current.contains(taskIndex)) {
    current.remove(taskIndex);
  } else {
    current.add(taskIndex);
  }
  await svc.setTaskCompletions(contractId, today, currentUserId!, current);
}

Future<void> evaluatePendingDays(Map<String, dynamic> contract) async {
  final contractId = contract['id'] as String;
  final createdAt = contract['createdAt'];
  if (createdAt == null) return;

  final startDate = (createdAt as dynamic).toDate() as DateTime;
  final duration = contract['duration'] as int? ?? 90;
  final taskCount = (contract['tasks'] as List<dynamic>?)?.length ?? 3;
  final creatorId = contract['creatorId'] as String;
  final partnerId = contract['partnerId'] as String;
  var daysCompleted = contract['daysCompleted'] as int? ?? 0;
  final lastEvaluatedDate = contract['lastEvaluatedDate'] as String?;
  final taskCompletions = contract['taskCompletions'] as Map<String, dynamic>? ?? {};

  final yesterday = _getYesterdayDate();
  final today = DateTime.now();
  final daysSinceStart = today.difference(startDate).inDays;

  // Contract ended?
  if (daysSinceStart >= duration) {
    if (contract['completed'] != true) {
      await svc.updateContractProgress(contractId, completed: true);
    }
  }

  // Nothing to evaluate yet (still day 0)
  if (daysSinceStart < 1) return;

  // Already evaluated up to yesterday
  if (lastEvaluatedDate == yesterday) return;

  // Find start date for evaluation
  DateTime evalStart;
  if (lastEvaluatedDate != null) {
    final parts = lastEvaluatedDate.split('-');
    evalStart = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])).add(const Duration(days: 1));
  } else {
    evalStart = startDate.add(const Duration(days: 1));
  }

  // Evaluate each day up to yesterday
  final yesterdayDate = DateTime.now().subtract(const Duration(days: 1));
  var current = evalStart;
  while (!current.isAfter(yesterdayDate) && current.difference(startDate).inDays <= duration) {
    final dateStr = '${current.year}-${current.month.toString().padLeft(2, '0')}-${current.day.toString().padLeft(2, '0')}';
    final dayData = taskCompletions[dateStr] as Map<String, dynamic>? ?? {};
    final creatorTasks = (dayData[creatorId] as List<dynamic>?)?.cast<int>() ?? [];
    final partnerTasks = (dayData[partnerId] as List<dynamic>?)?.cast<int>() ?? [];

    final creatorDone = creatorTasks.length == taskCount;
    final partnerDone = partnerTasks.length == taskCount;

    if (creatorDone && partnerDone) {
      daysCompleted++;
    }
    current = current.add(const Duration(days: 1));
  }

  await svc.updateContractProgress(contractId, daysCompleted: daysCompleted, lastEvaluatedDate: yesterday);
}
