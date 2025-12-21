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
  SetupSuccess? _lastSetup;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final savedUserId = await loadSavedUserId();
    if (!mounted) return;
    if (savedUserId != null) {
      setState(() => _userId = savedUserId);
      await _loadContract();
      return;
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
      body: SafeArea(
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
                child: _contract != null
                    ? GridView.builder(
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
                      )
                    : const _EmptyContracts(),
              ),
              const SizedBox(height: 12),
              SetupSection(
                onCompleted: (result) async {
                  setState(() {
                    _userId = result.userId;
                    _lastSetup = result;
                  });
                  await persistUserId(result.userId);
                  await _loadContract();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyContracts extends StatelessWidget {
  const _EmptyContracts();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No contracts yet',
        style: TextStyle(
          fontFamily: 'SF Pro Display',
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}

class SetupSection extends StatefulWidget {
  final ValueChanged<SetupSuccess> onCompleted;
  const SetupSection({super.key, required this.onCompleted});

  @override
  State<SetupSection> createState() => _SetupSectionState();
}

class _SetupSectionState extends State<SetupSection> {
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
      widget.onCompleted(result);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFB7B7B9).withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _Block(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontFamily: 'SF Pro Display',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Color(0xFF3E3E3E),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'username?',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w400,
                      fontSize: 15,
                      color: Color(0xFF8E8E93),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _DurationPill(
              label: '60',
              selected: _duration == 60,
              onTap: () => setState(() => _duration = 60),
            ),
            const SizedBox(width: 8),
            _DurationPill(
              label: '90',
              selected: _duration == 90,
              onTap: () => setState(() => _duration = 90),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Block(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'partner?',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._users
                          .where((u) => u['name'] != _nameController.text)
                          .map(
                            (u) => _PartnerOption(
                              label: u['name'] as String,
                              selected: _selectedPartnerId == u['id'],
                              onTap: () => setState(() => _selectedPartnerId = u['id'] as String),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Block(
                onTap: _pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'start date?',
                        style: TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFFB7B7B9).withOpacity(0.7),
                              width: 1,
                            ),
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                          style: const TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                            color: Color(0xFF3E3E3E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3E3E3E),
              foregroundColor: const Color(0xFFCDCDD0),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCDCDD0)),
                    ),
                  )
                : const Text(
                    'continue',
                    style: TextStyle(
                      fontFamily: 'SF Pro Display',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Block({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD5D5D8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            offset: Offset(0, 0),
            blurRadius: 18,
            spreadRadius: 0,
            color: Color.fromRGBO(99, 99, 99, 0.15),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }
}

class _DurationPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DurationPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3E3E3E) : const Color(0xFFD5D5D8),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              offset: Offset(0, 0),
              blurRadius: 18,
              spreadRadius: 0,
              color: Color.fromRGBO(99, 99, 99, 0.15),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: selected ? const Color(0xFFCDCDD0) : const Color(0xFF3E3E3E),
          ),
        ),
      ),
    );
  }
}

class _PartnerOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PartnerOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: const Color(0xFF8E8E93),
                  width: 1,
                ),
                color: selected ? const Color(0xFF3E3E3E) : Colors.transparent,
              ),
              child: selected
                  ? const Icon(Icons.check, size: 14, color: Color(0xFFD5D5D8))
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF3E3E3E),
              ),
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
