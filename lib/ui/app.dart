import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../logic/setup_logic.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contract Fitness',
      debugShowCheckedModeBanner: false,
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
  String? _userId;
  ContractSuccess? _contract;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSetupDialog());
  }

  Future<void> _showSetupDialog() async {
    final result = await showDialog<SetupSuccess>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SetupDialog(),
    );
    if (result != null) {
      setState(() => _userId = result.userId);
      _loadContract();
    }
  }

  Future<void> _loadContract() async {
    if (_userId == null) return;
    final result = await getActiveContract(_userId!);
    if (result is ContractSuccess && mounted) {
      setState(() => _contract = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFC8C8C8),
      body: _contract != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    const Text(
                      'Contracts',
                      style: TextStyle(
                        fontFamily: 'SF Pro Display',
                        fontWeight: FontWeight.w600,
                        fontSize: 30,
                        color: Color(0xFF3E3E3E),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.3,
                        ),
                        itemCount: 1,
                        itemBuilder: (context, index) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: 0.9,
                              child: ContractCard(contract: _contract!),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
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
    setState(() => _loading = true);

    final result = await submitSetup(
      name: _nameController.text,
      partnerId: _selectedPartnerId,
      duration: _duration,
      startDate: _startDate,
    );

    if (!mounted) return;

    if (result is SetupSuccess) {
      Navigator.of(context).pop(result);
    } else if (result is SetupFailure) {
      setState(() => _loading = false);
    }
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

class ContractCard extends StatelessWidget {
  final ContractSuccess contract;
  const ContractCard({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFCDCDD0),
        borderRadius: BorderRadius.circular(21),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 0),
            blurRadius: 18,
            spreadRadius: 0,
            color: Color.fromRGBO(99, 99, 99, 0.25),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            contract.title,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontWeight: FontWeight.w500,
              fontSize: 16,
              color: Color(0xFF3E3E3E),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFB7B7B9).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          _buildBullet('With ${contract.partnerNames.join(' and ')}'),
          const SizedBox(height: 4),
          _buildBullet('${contract.daysPassed}/${contract.duration}'),
          const SizedBox(height: 4),
          _buildBullet('Contract penalties: 0'),
        ],
      ),
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      children: [
        const Text(
          '•  ',
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: Color(0xFF767678),
          ),
        ),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'SF Pro Display',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xFF767678),
            ),
          ),
        ),
      ],
    );
  }
}
