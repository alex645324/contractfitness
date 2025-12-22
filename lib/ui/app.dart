import 'package:flutter/material.dart';
import '../services/firebase_service.dart';
import '../logic/setup_logic.dart';

const Color _backgroundColor = Color(0xFFD8D8D8);
const Color _surfaceColor = Color(0xFFE0E0E0);

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
      backgroundColor: _backgroundColor,
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
  final _nameFocus = FocusNode();
  int _duration = 30;
  DateTime _startDate = DateTime.now();
  late DateTime _initialStartDate;
  late DateTime _displayedMonth;
  bool _loading = false;
  List<Map<String, dynamic>> _users = [];
  String? _selectedPartnerId;
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    _initialStartDate = _startDate;
    _displayedMonth = DateTime(_startDate.year, _startDate.month);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await getUsers();
    setState(() => _users = users);
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final trimmedName = _nameController.text.trim();
    final durationChanged = _duration != 30;
    final startDateChanged = _startDate.year != _initialStartDate.year ||
        _startDate.month != _initialStartDate.month ||
        _startDate.day != _initialStartDate.day;
    final partnerSelected = _selectedPartnerId != null;
    final anyAdditional = durationChanged || startDateChanged || partnerSelected;
    final fullSetup =
        trimmedName.isNotEmpty && durationChanged && startDateChanged && partnerSelected;

    if (anyAdditional && !fullSetup) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    final result = await submitSetup(
      name: trimmedName,
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

  List<List<DateTime>> _calendarWeeks(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final start = first.subtract(Duration(days: first.weekday % 7));
    return List.generate(
      6,
      (week) => List.generate(7, (day) => start.add(Duration(days: week * 7 + day))),
    );
  }

  String _monthLabel(DateTime month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[month.month - 1]} ${month.year}';
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + delta);
    });
  }

  void _selectDate(DateTime date) {
    setState(() {
      _startDate = date;
      _displayedMonth = DateTime(date.year, date.month);
    });
  }

  void _toggleHidden() {
    setState(() => _isHidden = !_isHidden);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final partnerWidth = (constraints.maxWidth - 10) / 2;
        final currentName = _nameController.text.trim().toLowerCase();
        final partnerUsers = _users.where((u) {
          final rawName = (u['name'] as String?) ?? '';
          return rawName.trim().toLowerCase() != currentName;
        }).toList();
        final calendarWeeks = _calendarWeeks(_displayedMonth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _toggleHidden,
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 170,
                  height: 8,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB7B7B9).withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (!_isHidden) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: partnerWidth,
                    child: _Block(
                      child: TextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
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
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  _DurationPill(
                    label: '60',
                    selected: _duration == 60,
                    onTap: () => setState(() => _duration = 60),
                  ),
                  _DurationPill(
                    label: '90',
                    selected: _duration == 90,
                    onTap: () => setState(() => _duration = 90),
                  ),
                  _DurationPill(
                    label: 'Confirm',
                    selected: false,
                    onTap: _submit,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _Block(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                              SizedBox(
                                height: 90,
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  itemCount: partnerUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = partnerUsers[index];
                                    return _PartnerOption(
                                      label: user['name'] as String,
                                      selected: _selectedPartnerId == user['id'],
                                      onTap: () => setState(
                                        () => _selectedPartnerId = user['id'] as String,
                                      ),
                                    );
                                  },
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
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    alignment: Alignment.topCenter,
                                    icon: const Icon(
                                      Icons.chevron_left,
                                      size: 18,
                                      color: Color(0xFF3E3E3E),
                                    ),
                                    onPressed: () => _changeMonth(-1),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _monthLabel(_displayedMonth),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'SF Pro Display',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: Color(0xFF3E3E3E),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                    alignment: Alignment.topCenter,
                                    icon: const Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: Color(0xFF3E3E3E),
                                    ),
                                    onPressed: () => _changeMonth(1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              SizedBox(
                                height: 90,
                                child: Builder(
                                  builder: (context) {
                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      itemCount: calendarWeeks.length,
                                      itemBuilder: (context, weekIndex) {
                                        final week = calendarWeeks[weekIndex];
                                        return Row(
                                          children: week.map((day) {
                                            final inMonth =
                                                day.month == _displayedMonth.month;
                                            final isSelected =
                                                day.year == _startDate.year &&
                                                day.month == _startDate.month &&
                                                day.day == _startDate.day;
                                            return Expanded(
                                              child: GestureDetector(
                                                onTap: () => _selectDate(day),
                                                child: Container(
                                                  height: 22,
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: isSelected
                                                        ? const Color(0xFF3E3E3E)
                                                        : Colors.transparent,
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    '${day.day}',
                                                    style: TextStyle(
                                                      fontFamily: 'SF Pro Display',
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 12,
                                                      color: isSelected
                                                          ? const Color(0xFFCDCDD0)
                                                          : inMonth
                                                              ? const Color(0xFF3E3E3E)
                                                              : const Color(0xFFB7B7B9),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        );
      },
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
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(16),
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
          color: selected ? const Color(0xFF3E3E3E) : _surfaceColor,
          borderRadius: BorderRadius.circular(14),
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
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(21),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 0),
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
              height: 1.8,
              decoration: BoxDecoration(
                color: const Color(0xFFCACACC).withOpacity(0.7),
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
