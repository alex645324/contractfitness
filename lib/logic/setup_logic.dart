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
