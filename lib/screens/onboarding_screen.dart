import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  bool _isInstaller = false;
  String _languageCode = 'mix';
  int _step = 0;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _finishSetup() async {
    await context.read<SolarAppState>().saveUserSetup(
      name: _nameController.text,
      isInstaller: _isInstaller,
      languageCode: _languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F3),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: Color(0xFFE9E1CC)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _step == 0 ? _buildNameStep() : _buildLanguageStep(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNameStep() {
    return Column(
      key: const ValueKey('name-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.solar_power, size: 54, color: Color(0xFF1D9E75)),
        const SizedBox(height: 10),
        const Text(
          'Welcome to SolarCalcPK',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your name and tell us if you are an installer.',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.blueGrey),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _isInstaller,
          activeColor: const Color(0xFF1D9E75),
          title: const Text(
            'I am an installer',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          onChanged: (value) => setState(() => _isInstaller = value ?? false),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter your name first.')),
              );
              return;
            }
            setState(() => _step = 1);
          },
          child: const Text('Next: Select Language'),
        ),
      ],
    );
  }

  Widget _buildLanguageStep() {
    return Column(
      key: const ValueKey('language-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(Icons.language, size: 54, color: Color(0xFF1D9E75)),
        const SizedBox(height: 10),
        const Text(
          'Choose Language',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 18),
        _languageTile(
          'mix',
          'Roman Urdu Mix',
          'Solar calculator aur invoice generator',
        ),
        _languageTile('en', 'English', 'Solar sizing and invoice generator'),
        _languageTile('ur', 'اردو', 'سولر کیلکولیٹر اور انوائس جنریٹر'),
        const SizedBox(height: 14),
        ElevatedButton(onPressed: _finishSetup, child: const Text('Enter App')),
        TextButton(
          onPressed: () => setState(() => _step = 0),
          child: const Text('Back'),
        ),
      ],
    );
  }

  Widget _languageTile(String code, String title, String subtitle) {
    final selected = _languageCode == code;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _languageCode = code),
      child: Card(
        elevation: 0,
        color: selected
            ? const Color(0xFF1D9E75).withValues(alpha: 0.10)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? const Color(0xFF1D9E75) : const Color(0xFFE9E1CC),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          leading: Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? const Color(0xFF1D9E75) : Colors.blueGrey,
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}
