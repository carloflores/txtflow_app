import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _urlController;
  late TextEditingController _whitelistController;
  late TextEditingController _intervalController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _urlController = TextEditingController(text: provider.storage.apiUrl);
    _whitelistController = TextEditingController(text: provider.storage.whitelist.join(', '));
    _intervalController = TextEditingController(text: provider.storage.pollingInterval.toString());
  }

  @override
  void dispose() {
    _urlController.dispose();
    _whitelistController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'API URL',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppConstants.primaryColor)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a URL';
                  if (!value.startsWith('http')) return 'URL must start with http/https';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _whitelistController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Whitelist (comma separated numbers)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppConstants.primaryColor)),
                  helperText: 'Leave empty to allow all (Not recommended)',
                  helperStyle: TextStyle(color: Colors.grey),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _intervalController,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Polling Interval (minutes)',
                  labelStyle: TextStyle(color: Colors.grey),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppConstants.primaryColor)),
                  helperText: 'Minimum 5 minutes (Android limitation)',
                  helperStyle: TextStyle(color: Colors.grey),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an interval';
                  final interval = int.tryParse(value);
                  if (interval == null || interval < 5) return 'Minimum interval is 5 minutes';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final whitelist = _whitelistController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();
                    final interval = int.parse(_intervalController.text);
                    
                    context.read<AppProvider>().updateSettings(
                      _urlController.text,
                      whitelist,
                      interval,
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved')),
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppConstants.accentColor),
                ),
                onPressed: () async {
                  try {
                    const platform = MethodChannel('com.carlodflores.txtflow/settings');
                    await platform.invokeMethod('openDefaultSmsSettings');
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Could not open settings: $e')),
                      );
                    }
                  }
                },
                child: const Text('Set as Default SMS App', style: TextStyle(color: AppConstants.accentColor, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
