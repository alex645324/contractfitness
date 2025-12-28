import 'package:flutter/material.dart';
import '../logic/setup_logic.dart' as logic;

class BottomSheetContent extends StatefulWidget {
  const BottomSheetContent({super.key});

  @override
  State<BottomSheetContent> createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<BottomSheetContent> {
  static const _darkColor = Color(0xFF545454);
  static const _barColor = Color(0xFFF2F2F2);
  static const _lightGray = Color(0xFFD1D1D1);

  int _selectedDuration = 60;
  String? _selectedPartner;
  String? _selectedAccount;
  final _nameController = TextEditingController();
  bool _hasError = false;
  bool _isSuccess = false;
  bool _contractError = false;
  bool _contractSuccess = false;

  final List<int> _durations = [60, 90];
  final List<String> _accountOptions = ['SIGN UP', 'LOG IN'];

  bool get _isAuthenticated => logic.currentUserId != null;

  @override
  void initState() {
    super.initState();
    if (_isAuthenticated) {
      _nameController.text = logic.currentUserName ?? '';
      _isSuccess = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (_selectedAccount == null) return;
    final isSignUp = _selectedAccount == 'SIGN UP';
    final result = await logic.authenticate(_nameController.text, isSignUp);
    setState(() {
      _hasError = !result.success;
      _isSuccess = result.success;
    });
  }

  Future<void> _onContractConfirm() async {
    if (!_isAuthenticated || _selectedPartner == null) return;
    final result = await logic.createContract(_selectedDuration, _selectedPartner!);
    setState(() {
      _contractError = !result.success;
      _contractSuccess = result.success;
    });
  }

  TextStyle _optionStyle({required bool isSelected, double fontSize = 16}) {
    return TextStyle(
      fontSize: fontSize,
      color: _lightGray,
      decoration:
          isSelected ? TextDecoration.lineThrough : TextDecoration.none,
      decorationColor: _darkColor,
      decorationThickness: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 17, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 130,
              height: 10,
              decoration: BoxDecoration(
                color: _barColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Duration section
          const Text(
            'Duration.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 8),
          ...(_durations.map((d) => GestureDetector(
            onTap: () => setState(() => _selectedDuration = d),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                d.toString(),
                style:
                    _optionStyle(isSelected: _selectedDuration == d, fontSize: 18),
              ),
            ),
          ))),
          const SizedBox(height: 20),

          // Partner section
          const Text(
            'Partner.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: logic.getUsers(),
            builder: (context, snapshot) {
              final users = snapshot.data ?? [];
              final displayUsers = users.take(3).toList();
              if (displayUsers.isEmpty) {
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...displayUsers.take(2).map((u) => GestureDetector(
                    onTap: () => setState(() {
                      _selectedPartner = u['name'] as String;
                      _contractError = false;
                      _contractSuccess = false;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        (u['name'] as String).toUpperCase(),
                        style: _optionStyle(isSelected: _selectedPartner == u['name']),
                      ),
                    ),
                  )),
                  if (displayUsers.length >= 3)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _selectedPartner = displayUsers[2]['name'] as String;
                                _contractError = false;
                                _contractSuccess = false;
                              }),
                              child: Text(
                                (displayUsers[2]['name'] as String).toUpperCase(),
                                style: _optionStyle(isSelected: _selectedPartner == displayUsers[2]['name']),
                              ),
                            ),
                          ),
                          if (_isAuthenticated)
                            GestureDetector(
                              onTap: _onContractConfirm,
                              child: Text(
                                'CONFIRM',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: _contractError ? Colors.red : (_contractSuccess ? Colors.green : _lightGray),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Account section
          const Text(
            'Account.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 8),
          if (!_isAuthenticated)
            ...(_accountOptions.map((a) => GestureDetector(
              onTap: () => setState(() => _selectedAccount = a),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  a,
                  style: _optionStyle(isSelected: _selectedAccount == a),
                ),
              ),
            ))),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.characters,
                    enabled: !_isAuthenticated,
                    onChanged: (_) => setState(() {
                      _hasError = false;
                      _isSuccess = false;
                    }),
                    style: TextStyle(
                      fontSize: 16,
                      color: _hasError ? Colors.red : (_isSuccess ? Colors.green : _darkColor),
                    ),
                    decoration: InputDecoration(
                      hintText: 'NAME',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: _hasError ? Colors.red : _lightGray,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _isAuthenticated ? null : _onConfirm,
                  child: Text(
                    'CONFIRM',
                    style: TextStyle(
                      fontSize: 16,
                      color: _hasError ? Colors.red : (_isSuccess ? Colors.green : _lightGray),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}
