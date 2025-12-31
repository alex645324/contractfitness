import '../services/firebase_service.dart' as svc;

String? currentUserId;
String? currentUserName;
String? currentContractId;

Future<({bool success, String? error})> authenticate(String name, bool isSignUp) async {
  if (name.trim().isEmpty) return (success: false, error: 'empty');

  final exists = await svc.userExists(name);

  if (isSignUp && exists) return (success: false, error: 'taken');
  if (!isSignUp && !exists) return (success: false, error: 'not_found');

  currentUserId = isSignUp ? await svc.createUser(name) : await svc.getUserId(name);
  currentUserName = name;
  return (success: true, error: null);
}

Future<({bool success, String? error})> createContract(int duration, String partnerName, List<String> tasks) async {
  if (currentUserId == null) {
    return (success: false, error: 'not_authenticated');
  }

  final partnerId = await svc.getUserId(partnerName);
  if (partnerId == null) {
    return (success: false, error: 'partner_not_found');
  }

  final ids = [currentUserId!, partnerId]..sort();
  final pairKey = ids.join('_');

  final contractId = await svc.createContract(currentUserId!, partnerId, duration, tasks, pairKey);
  if (contractId == null) {
    return (success: false, error: 'duplicate');
  }
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
  final d = DateTime.now();
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

Future<void> toggleTask(String contractId, int taskIndex) async {
  if (currentUserId == null) return;
  final today = getTodayDate();

  // Fetch contract to check completion status
  final contract = await svc.getContract(contractId);
  if (contract == null) return;

  final creatorId = contract['creatorId'] as String;
  final partnerId = contract['partnerId'] as String;
  final taskCount = (contract['tasks'] as List<dynamic>?)?.length ?? 3;
  final daysCompleted = contract['daysCompleted'] as int? ?? 0;
  final taskCompletions = contract['taskCompletions'] as Map<String, dynamic>? ?? {};
  final dayData = taskCompletions[today] as Map<String, dynamic>? ?? {};

  // Get both users' completions for today
  var creatorTasks = (dayData[creatorId] as List<dynamic>?)?.cast<int>().toList() ?? [];
  var partnerTasks = (dayData[partnerId] as List<dynamic>?)?.cast<int>().toList() ?? [];

  // Check if day was complete before
  final wasComplete = creatorTasks.length == taskCount && partnerTasks.length == taskCount;

  // Toggle current user's task
  final myTasks = currentUserId == creatorId ? creatorTasks : partnerTasks;
  if (myTasks.contains(taskIndex)) {
    myTasks.remove(taskIndex);
  } else {
    myTasks.add(taskIndex);
  }
  await svc.setTaskCompletions(contractId, today, currentUserId!, myTasks);

  // Update references after toggle
  if (currentUserId == creatorId) {
    creatorTasks = myTasks;
  } else {
    partnerTasks = myTasks;
  }

  // Check if day is complete now
  final isComplete = creatorTasks.length == taskCount && partnerTasks.length == taskCount;

  // Update daysCompleted if status changed
  if (isComplete && !wasComplete) {
    await svc.updateContractProgress(contractId, daysCompleted: daysCompleted + 1);
  } else if (!isComplete && wasComplete) {
    await svc.updateContractProgress(contractId, daysCompleted: daysCompleted - 1);
  }
}
