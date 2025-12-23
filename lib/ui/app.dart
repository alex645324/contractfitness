import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
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
  final _pageController = PageController();
  int _currentPage = 0;
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final savedUserId = await loadSavedUserId();
    debugPrint('[HomePage] Loaded savedUserId: $savedUserId');
    if (!mounted) return;
    if (savedUserId != null) {
      setState(() => _userId = savedUserId);
      await checkYesterdayPenalty(savedUserId);
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
              if (_userId != null && _contract == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.ease);
                        },
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == 0
                                ? const Color(0xFF3E3E3E)
                                : const Color(0xFFB7B7B9),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(1,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.ease);
                        },
                        child: Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == 1
                                ? const Color(0xFF3E3E3E)
                                : const Color(0xFFB7B7B9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Center(
                child: GestureDetector(
                  onTap: () => setState(() => _isHidden = !_isHidden),
                  child: Container(
                    width: 170,
                    height: 8,
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB7B7B9).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (!_isHidden)
                SizedBox(
                  height: 210,
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      dragDevices: {
                        PointerDeviceKind.touch,
                        PointerDeviceKind.mouse,
                      },
                    ),
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (page) => setState(() => _currentPage = page),
                      children: [
                        SetupSection(
                          savedUserId: _userId,
                          onCompleted: (result) async {
                            setState(() {
                              _userId = result.userId;
                              _lastSetup = result;
                            });
                            await persistUserId(result.userId);
                            await _loadContract();
                          },
                        ),
                        if (_userId != null)
                          DailyActionsSection(
                            userId: _userId!,
                            onProgressUpdated: _loadContract,
                          ),
                      ],
                    ),
                  ),
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
  final String? savedUserId;
  const SetupSection({super.key, required this.onCompleted, this.savedUserId});

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
  bool _accountLocked = false;
  bool _confirmPressed = false;

  @override
  void initState() {
    super.initState();
    _initialStartDate = _startDate;
    _displayedMonth = DateTime(_startDate.year, _startDate.month);
    _loadUsers();
    _restoreLockedState();
  }

  Future<void> _restoreLockedState() async {
    debugPrint('[SetupSection] Restoring state, savedUserId: ${widget.savedUserId}');
    if (widget.savedUserId == null) return;
    final name = await getUserNameById(widget.savedUserId!);
    debugPrint('[SetupSection] Fetched userName: $name');
    if (!mounted || name == null) return;
    setState(() {
      _nameController.text = name;
      _accountLocked = true;
    });
    debugPrint('[SetupSection] State restored - accountLocked: $_accountLocked');
  }

  Future<void> _loadUsers() async {
    final users = await getUsers();
    setState(() => _users = users);
  }

  @override
  void didUpdateWidget(SetupSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.savedUserId == null && widget.savedUserId != null) {
      _restoreLockedState();
    }
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleConfirm() async {
    setState(() => _confirmPressed = true);
    await _submit();
    if (mounted) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() => _confirmPressed = false);
    }
  }

  Future<void> _submit() async {
    final trimmedName = _nameController.text.trim();
    debugPrint('[SetupSection] _submit called - accountLocked: $_accountLocked, name: $trimmedName');

    // Case 1: Account not locked - create account only
    if (!_accountLocked) {
      if (trimmedName.isEmpty) {
        debugPrint('[SetupSection] Empty name, returning');
        return;
      }
      setState(() => _loading = true);
      debugPrint('[SetupSection] Creating account...');
      final result = await submitSetup(
        name: trimmedName,
        partnerId: null,
        duration: _duration,
        startDate: _startDate,
      );
      if (!mounted) return;
      if (result is SetupSuccess) {
        debugPrint('[SetupSection] Account created - userId: ${result.userId}');
        await persistUserId(result.userId);
        setState(() {
          _accountLocked = true;
          _loading = false;
        });
        await _loadUsers();
      } else if (result is SetupFailure) {
        debugPrint('[SetupSection] Account creation failed: ${result.message}');
        setState(() => _loading = false);
      }
      return;
    }

    // Case 2: Account locked - create contract
    final durationChanged = _duration != 30;
    final startDateChanged = _startDate.year != _initialStartDate.year ||
        _startDate.month != _initialStartDate.month ||
        _startDate.day != _initialStartDate.day;
    final partnerSelected = _selectedPartnerId != null;

    debugPrint('[SetupSection] Contract check - duration: $durationChanged, date: $startDateChanged, partner: $partnerSelected');

    if (!durationChanged || !startDateChanged || !partnerSelected) {
      debugPrint('[SetupSection] Incomplete fields, returning');
      return;
    }

    setState(() => _loading = true);
    debugPrint('[SetupSection] Creating contract...');
    final result = await submitSetup(
      name: trimmedName,
      partnerId: _selectedPartnerId,
      duration: _duration,
      startDate: _startDate,
    );
    if (!mounted) return;

    if (result is SetupSuccess) {
      debugPrint('[SetupSection] Contract created - contractId: ${result.contractId}');
      widget.onCompleted(result);
      // Reset for next contract
      setState(() {
        _selectedPartnerId = null;
        _duration = 30;
        _startDate = DateTime.now();
        _initialStartDate = _startDate;
        _displayedMonth = DateTime(_startDate.year, _startDate.month);
        _loading = false;
      });
    } else if (result is SetupFailure) {
      debugPrint('[SetupSection] Contract creation failed: ${result.message}');
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
                        enabled: !_accountLocked,
                        style: const TextStyle(
                          fontFamily: 'SF Pro Display',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: Color(0xFF3E3E3E),
                        ),
                        decoration: InputDecoration(
                          hintText: 'username?',
                          border: InputBorder.none,
                          hintStyle: const TextStyle(
                            fontFamily: 'SF Pro Display',
                            fontWeight: FontWeight.w400,
                            fontSize: 15,
                            color: Color(0xFF8E8E93),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          suffixIcon: _accountLocked
                              ? const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.lock,
                                    size: 18,
                                    color: Color(0xFF3E3E3E),
                                  ),
                                )
                              : null,
                          suffixIconConstraints: const BoxConstraints(
                            minWidth: 0,
                            minHeight: 0,
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
                    selected: _confirmPressed,
                    onTap: _handleConfirm,
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

class DailyActionsSection extends StatefulWidget {
  final String userId;
  final VoidCallback onProgressUpdated;
  const DailyActionsSection({
    super.key,
    required this.userId,
    required this.onProgressUpdated,
  });

  @override
  State<DailyActionsSection> createState() => _DailyActionsSectionState();
}

class _DailyActionsSectionState extends State<DailyActionsSection> {
  bool _train = false;
  bool _nutrition = false;
  bool _sleep = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _loadTodayActions();
  }

  Future<void> _loadTodayActions() async {
    final docId = todayDocId(widget.userId);
    final actions = await getDailyActions(docId);
    if (!mounted) return;
    if (actions != null) {
      setState(() {
        _train = actions['train'] ?? false;
        _nutrition = actions['nutrition'] ?? false;
        _sleep = actions['sleep'] ?? false;
        _completed = _train && _nutrition && _sleep;
      });
    }
  }

  Future<void> _toggle(String key, bool value) async {
    if (_completed) return;
    setState(() {
      if (key == 'train') _train = value;
      if (key == 'nutrition') _nutrition = value;
      if (key == 'sleep') _sleep = value;
    });

    await saveDailyActions(todayDocId(widget.userId), {
      'train': _train,
      'nutrition': _nutrition,
      'sleep': _sleep,
    });

    if (_train && _nutrition && _sleep) {
      setState(() => _completed = true);
      await completeDailyActions(widget.userId);
      widget.onProgressUpdated();
    }
  }

  int get _count => (_train ? 1 : 0) + (_nutrition ? 1 : 0) + (_sleep ? 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAction('Train hard', _train, (v) => _toggle('train', v)),
            _buildAction('Nutrition', _nutrition, (v) => _toggle('nutrition', v)),
            _buildAction('Sleep', _sleep, (v) => _toggle('sleep', v)),
          ],
        ),
        const Spacer(),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF3E3E3E), width: 3),
          ),
          child: Center(
            child: Text(
              '$_count/3',
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF3E3E3E),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAction(String label, bool checked, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF8E8E93), width: 1.5),
                color: checked ? const Color(0xFF3E3E3E) : Colors.transparent,
              ),
              child: checked
                  ? const Icon(Icons.check, size: 18, color: Color(0xFFD5D5D8))
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'SF Pro Display',
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Color(0xFF3E3E3E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
