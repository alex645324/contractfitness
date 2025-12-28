import 'package:flutter/material.dart';
import 'bottom_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _lightGray = Color(0xFFF2F2F2);
  bool _isSheetOpen = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const SizedBox.expand(),
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
