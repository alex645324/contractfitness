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

  Widget _buildContractWidget(Map<String, dynamic> contract) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 22),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withValues(alpha: 0.25),
            offset: Offset.zero,
            blurRadius: 60,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Transform.scale(
        scale: 0.8,
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Transform.translate(
              offset: const Offset(0, -8),
              child: Row(
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
              ),
            ),
            const SizedBox(height: 4),
            // Dot board and task indicators
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dot board - 30 days, 7 per row
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: 7 dark
                    Row(
                      children: List.generate(7, (_) => _buildDot(true)),
                    ),
                    const SizedBox(height: 10),
                    // Row 2: 7 dark
                    Row(
                      children: List.generate(7, (_) => _buildDot(true)),
                    ),
                    const SizedBox(height: 10),
                    // Row 3: 3 dark, 4 light
                    Row(
                      children: [
                        ...List.generate(3, (_) => _buildDot(true)),
                        ...List.generate(4, (_) => _buildDot(false)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Row 4: 7 light
                    Row(
                      children: List.generate(7, (_) => _buildDot(false)),
                    ),
                    const SizedBox(height: 10),
                    // Row 5: 2 light
                    Row(
                      children: List.generate(2, (_) => _buildDot(false)),
                    ),
                  ],
                ),
                const Expanded(child: SizedBox()),
                // Task indicators
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
            const Text(
              'PARTNER. ALIEEL',
              style: TextStyle(
                fontSize: 16,
                color: _lightDot,
              ),
            ),
          ],
        ),
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
                return ListView(
                  padding: const EdgeInsets.only(top: 100),
                  children: snapshot.data!.map(_buildContractWidget).toList(),
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
