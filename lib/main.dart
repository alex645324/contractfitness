import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contract Fitness',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSetupDialog());
  }

  void _showSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SetupDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFC8C8C8),
    );
  }
}

class SetupDialog extends StatefulWidget {
  const SetupDialog({super.key});

  @override
  State<SetupDialog> createState() => _SetupDialogState();
}

class _SetupDialogState extends State<SetupDialog> {
  final _nameController = TextEditingController();
  int _duration = 30;
  DateTime _startDate = DateTime.now();
  bool _loading = false;
  List<Map<String, dynamic>> _users = [];
  String? _selectedPartnerId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await getUsers();
    setState(() => _users = users);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _loading = true);

    final userId = await createUser(_nameController.text);

    if (_selectedPartnerId != null) {
      await createContract([userId, _selectedPartnerId!], _duration, _startDate);
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create Contract',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Partner',
                border: OutlineInputBorder(),
              ),
              items: _users
                  .where((u) => u['name'] != _nameController.text)
                  .map((u) => DropdownMenuItem(
                        value: u['id'] as String,
                        child: Text(u['name'] as String),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPartnerId = v),
            ),
            const SizedBox(height: 16),
            const Text('Contract Duration', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 30, label: Text('30')),
                ButtonSegment(value: 60, label: Text('60')),
                ButtonSegment(value: 90, label: Text('90')),
              ],
              selected: {_duration},
              onSelectionChanged: (s) => setState(() => _duration = s.first),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _pickDate,
              child: Text(
                'Start: ${_startDate.month}/${_startDate.day}/${_startDate.year}',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
