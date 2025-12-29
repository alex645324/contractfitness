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

  Widget _buildTaskIndicator(String label) {
    return SizedBox(
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
            style: const TextStyle(
              fontSize: 14,
              color: _lightDot,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
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
        const Text(
          '55%.',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD1D1D1),
          ),
        ),
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
                        child: _buildHeaderRow(),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(7, (_) => _buildDot(true)),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: List.generate(7, (_) => _buildDot(true)),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ...List.generate(3, (_) => _buildDot(true)),
                                  ...List.generate(4, (_) => _buildDot(false)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: List.generate(7, (_) => _buildDot(false)),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: List.generate(2, (_) => _buildDot(false)),
                              ),
                            ],
                          ),
                          const Expanded(child: SizedBox()),
                          Transform.translate(
                            offset: const Offset(53, -4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTaskIndicator('Eating'),
                                const SizedBox(height: 2),
                                _buildTaskIndicator('Lifting hard'),
                                const SizedBox(height: 2),
                                _buildTaskIndicator('Sleeping smart'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Transform.translate(
                        offset: const Offset(0, 8),
                        child: Text(
                          'PARTNER. ${['ALIEEL', 'MARCO', 'SARAH', 'JAKE'][index % 4]}',
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
                  child: _buildHeaderRow(),
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
