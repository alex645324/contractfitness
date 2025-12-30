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
  final _task1Controller = TextEditingController();
  final _task2Controller = TextEditingController();
  final _task3Controller = TextEditingController();
  final _partnerController = TextEditingController();
  bool _hasError = false;
  bool _partnerError = false;
  bool _isSuccess = false;
  bool _contractError = false;
  bool _contractSuccess = false;
  bool _isCreating = false;

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
    _task1Controller.dispose();
    _task2Controller.dispose();
    _task3Controller.dispose();
    _partnerController.dispose();
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

  Future<void> _onPartnerFind() async {
    final name = _partnerController.text.trim();
    if (name.isEmpty) return;
    final exists = await logic.userExists(name);
    setState(() {
      _partnerError = !exists;
      _selectedPartner = exists ? name : null;
    });
  }

  Future<void> _onContractConfirm() async {
    if (_isCreating) return;

    final tasks = [
      _task1Controller.text.trim(),
      _task2Controller.text.trim(),
      _task3Controller.text.trim(),
    ];
    final allTasksFilled = tasks.every((t) => t.isNotEmpty);

    if (!_isAuthenticated || _selectedPartner == null || !allTasksFilled) {
      setState(() {
        _contractError = true;
        _contractSuccess = false;
      });
      return;
    }

    _isCreating = true;
    final result = await logic.createContract(_selectedDuration, _selectedPartner!, tasks);
    _isCreating = false;
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

          // Tasks section
          const Text(
            'Tasks.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextField(
              controller: _task1Controller,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 16, color: _darkColor),
              decoration: const InputDecoration(
                hintText: 'TASK 1',
                hintStyle: TextStyle(fontSize: 16, color: _lightGray),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextField(
              controller: _task2Controller,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 16, color: _darkColor),
              decoration: const InputDecoration(
                hintText: 'TASK 2',
                hintStyle: TextStyle(fontSize: 16, color: _lightGray),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextField(
              controller: _task3Controller,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 16, color: _darkColor),
              decoration: const InputDecoration(
                hintText: 'TASK 3',
                hintStyle: TextStyle(fontSize: 16, color: _lightGray),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextField(
              controller: _partnerController,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {
                _partnerError = false;
                _selectedPartner = null;
                _contractError = false;
                _contractSuccess = false;
              }),
              style: TextStyle(
                fontSize: 16,
                color: _partnerError ? Colors.red : (_selectedPartner != null ? Colors.green : _darkColor),
              ),
              decoration: InputDecoration(
                hintText: 'FIND',
                hintStyle: TextStyle(
                  fontSize: 16,
                  color: _partnerError ? Colors.red : _lightGray,
                ),
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _onPartnerFind,
                    child: Text(
                      'THIS FUCKER',
                      style: TextStyle(
                        fontSize: 16,
                        color: _partnerError ? Colors.red : (_selectedPartner != null ? Colors.green : _lightGray),
                      ),
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
