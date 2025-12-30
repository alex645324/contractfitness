import 'package:flutter/material.dart';
import 'bottom_sheet.dart';
import '../logic/setup_logic.dart' as logic;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _lightGray = Color(0xFFF2F2F2);
  static const _shadowColor = Color(0xFFC7C7C7);
  static const _darkDot = Color(0xFF545454);
  static const _lightDot = Color(0xFFD1D1D1);
  bool _isSheetOpen = false;
  int _expandedIndex = -1;
  final Map<String, List<int>> _completedTasks = {};
  final Map<String, String> _partnerNames = {};
  final Set<String> _evaluatedContracts = {};

  @override
  void initState() {
    super.initState();
    logic.runDailyEvaluation();
  }

  Widget _buildDot(bool isDark) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.only(right: 13),
      decoration: BoxDecoration(
        color: isDark ? _darkDot : _lightDot,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTaskIndicator(String label, {required bool isCrossed, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 18,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: _lightDot,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 13),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: _lightDot,
                decoration: isCrossed ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: _darkDot,
                decorationThickness: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(int daysCompleted, int duration) {
    return Row(
      children: [
        const Text(
          'DAY.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF545454),
          ),
        ),
        const SizedBox(width: 80),
        Text(
          '$daysCompleted/$duration.',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD1D1D1),
          ),
        ),
      ],
    );
  }

  void _resolvePartnerName(String partnerId) async {
    if (_partnerNames.containsKey(partnerId)) return;
    final name = await logic.getUserName(partnerId);
    if (name != null && mounted) {
      setState(() => _partnerNames[partnerId] = name);
    }
  }

  void _loadTaskCompletions(String contractId) async {
    if (_completedTasks.containsKey(contractId)) return;
    final tasks = await logic.getCompletedTasks(contractId);
    if (mounted) {
      setState(() => _completedTasks[contractId] = tasks);
    }
  }

  void _evaluateContract(Map<String, dynamic> contract) async {
    final contractId = contract['id'] as String;
    if (_evaluatedContracts.contains(contractId)) return;
    _evaluatedContracts.add(contractId);
    await logic.evaluatePendingDays(contract);
  }

  void _toggleTask(String contractId, int taskIndex) async {
    await logic.toggleTask(contractId, taskIndex);
    final tasks = await logic.getCompletedTasks(contractId);
    if (mounted) {
      setState(() => _completedTasks[contractId] = tasks);
    }
  }

  Widget _buildDotBoard(int daysCompleted) {
    final page = daysCompleted ~/ 30;
    final filledOnPage = daysCompleted - (page * 30);

    List<Widget> buildRow(int startIdx, int count) {
      return List.generate(count, (i) {
        final dotIdx = startIdx + i;
        return _buildDot(dotIdx < filledOnPage);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: buildRow(0, 7)),
        const SizedBox(height: 10),
        Row(children: buildRow(7, 7)),
        const SizedBox(height: 10),
        Row(children: buildRow(14, 7)),
        const SizedBox(height: 10),
        Row(children: buildRow(21, 7)),
        const SizedBox(height: 10),
        Row(children: buildRow(28, 2)),
      ],
    );
  }

  void _showBottomSheet() {
    setState(() => _isSheetOpen = true);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.fromLTRB(30, 0, 30, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: const BottomSheetContent(),
      ),
    ).whenComplete(() => setState(() => _isSheetOpen = false));
  }

  Widget _buildContractWidget(Map<String, dynamic> contract, int index, bool isExpanded, int expandedIdx, bool isLast) {
    final contractId = contract['id'] as String;
    final duration = contract['duration'] as int? ?? 90;
    final daysCompleted = contract['daysCompleted'] as int? ?? 0;
    final isCompleted = contract['completed'] as bool? ?? false;
    final tasks = (contract['tasks'] as List<dynamic>?)?.cast<String>() ?? ['Task 1', 'Task 2', 'Task 3'];
    final partnerId = contract['partnerId'] as String? ?? '';
    _resolvePartnerName(partnerId);
    _evaluateContract(contract);
    _loadTaskCompletions(contractId);
    final partnerName = _partnerNames[partnerId]?.toUpperCase() ?? '';
    final completedTasks = _completedTasks[contractId] ?? [];

    final card = Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: EdgeInsets.fromLTRB(24, 16, 24, isExpanded ? 0 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isExpanded
              ? BorderRadius.circular(16)
              : (isLast
                  ? BorderRadius.circular(16)
                  : const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    )),
          boxShadow: [
            BoxShadow(
              color: _shadowColor.withValues(alpha: 0.25),
              offset: Offset.zero,
              blurRadius: 60,
              spreadRadius: 1,
            ),
          ],
        ),
        child: isExpanded
            ? Transform.scale(
                scale: 0.8,
                alignment: Alignment.topLeft,
                child: Transform.translate(
                  offset: const Offset(0, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -12),
                        child: _buildHeaderRow(daysCompleted, duration),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDotBoard(daysCompleted),
                          const Spacer(),
                          Transform.translate(
                            offset: const Offset(0, -4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTaskIndicator(tasks[0], isCrossed: completedTasks.contains(0), onTap: isCompleted ? () {} : () => _toggleTask(contractId, 0)),
                                const SizedBox(height: 2),
                                _buildTaskIndicator(tasks.length > 1 ? tasks[1] : '', isCrossed: completedTasks.contains(1), onTap: isCompleted ? () {} : () => _toggleTask(contractId, 1)),
                                const SizedBox(height: 2),
                                _buildTaskIndicator(tasks.length > 2 ? tasks[2] : '', isCrossed: completedTasks.contains(2), onTap: isCompleted ? () {} : () => _toggleTask(contractId, 2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Transform.translate(
                        offset: const Offset(0, 8),
                        child: Text(
                          'PARTNER. $partnerName',
                          style: const TextStyle(
                            fontSize: 16,
                            color: _lightDot,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Transform.translate(
                offset: const Offset(0, -6),
                child: Transform.scale(
                  scale: 0.8,
                  alignment: Alignment.centerLeft,
                  child: _buildHeaderRow(daysCompleted, duration),
                ),
              ),
    );
    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
      child: isExpanded
          ? card
          : Transform.translate(
              offset: Offset(0, 12.0 * (expandedIdx - index)),
              child: card,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: logic.currentUserId == null
          ? const SizedBox.expand()
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: logic.getUserContracts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.expand();
                }
                final contracts = snapshot.data!.reversed.toList();
                final expandedIdx = _expandedIndex < 0
                    ? contracts.length - 1
                    : (_expandedIndex >= contracts.length ? contracts.length - 1 : _expandedIndex);
                return ListView(
                  padding: const EdgeInsets.only(top: 40),
                  children: [
                    for (int i = 0; i < contracts.length; i++)
                      _buildContractWidget(contracts[i], i, i == expandedIdx, expandedIdx, i == contracts.length - 1),
                  ],
                );
              },
            ),
      bottomNavigationBar: _isSheetOpen
          ? null
          : GestureDetector(
              onTap: _showBottomSheet,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 17),
                child: Container(
                  height: 40,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: Container(
                    width: 135,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _lightGray,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
