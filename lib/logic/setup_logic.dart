import '../services/firebase_service.dart' as svc;

Future<({bool success, String? error})> authenticate(String name, bool isSignUp) async {
  if (name.trim().isEmpty) {
    return (success: false, error: 'empty');
  }

  final exists = await svc.userExists(name);

  if (isSignUp) {
    if (exists) {
      return (success: false, error: 'taken');
    }
    await svc.createUser(name);
    return (success: true, error: null);
  } else {
    if (!exists) {
      return (success: false, error: 'not_found');
    }
    return (success: true, error: null);
  }
}
