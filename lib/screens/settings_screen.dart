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
  late Map<String, String> _customHeaders;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _urlController = TextEditingController(text: provider.storage.apiUrl);
    _whitelistController = TextEditingController(text: provider.storage.whitelist.join(', '));
    _intervalController = TextEditingController(text: provider.storage.pollingInterval.toString());
    _customHeaders = Map<String, String>.from(provider.storage.customHeaders);
  }

  @override
  void dispose() {
    _urlController.dispose();
    _whitelistController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  void _addHeader() {
    showDialog(
      context: context,
      builder: (context) => _HeaderDialog(
        onSave: (key, value) {
          setState(() {
            _customHeaders[key] = value;
          });
        },
      ),
    );
  }

  void _editHeader(String key, String value) {
    showDialog(
      context: context,
      builder: (context) => _HeaderDialog(
        initialKey: key,
        initialValue: value,
        onSave: (newKey, newValue) {
          setState(() {
            if (newKey != key) {
              _customHeaders.remove(key);
            }
            _customHeaders[newKey] = newValue;
          });
        },
      ),
    );
  }

  void _deleteHeader(String key) {
    setState(() {
      _customHeaders.remove(key);
    });
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
      body: SingleChildScrollView(
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
              
              // Service Settings Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildToggleRow(
                      title: 'Auto-start service',
                      subtitle: 'Start gateway service when app opens',
                      value: context.watch<AppProvider>().storage.autoStartService,
                      onChanged: (value) {
                        context.read<AppProvider>().setAutoStart(value);
                      },
                    ),
                    const Divider(color: Colors.grey, height: 24),
                    _buildToggleRow(
                      title: 'Enable notifications',
                      subtitle: 'Show notifications for incoming SMS',
                      value: context.watch<AppProvider>().storage.notificationsEnabled,
                      onChanged: (value) {
                        context.read<AppProvider>().setNotificationsEnabled(value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // SIM Card Selection Section
              Builder(
                builder: (context) {
                  final provider = context.watch<AppProvider>();
                  final simCards = provider.simCards;
                  
                  if (simCards.isEmpty) {
                    return const SizedBox.shrink(); // Hide if no SIM cards
                  }
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade800),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sim_card, color: AppConstants.accentColor, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'SIM Card for Sending',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select which SIM to use for outgoing SMS',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...simCards.map((sim) => RadioListTile<int>(
                          title: Text(
                            '${sim.slotLabel}: ${sim.label}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: sim.phoneNumber.isNotEmpty
                              ? Text(
                                  sim.phoneNumber,
                                  style: TextStyle(color: Colors.grey.shade500),
                                )
                              : null,
                          value: sim.subscriptionId,
                          groupValue: provider.selectedSimId == -1
                              ? simCards.first.subscriptionId
                              : provider.selectedSimId,
                          activeColor: AppConstants.accentColor,
                          onChanged: (value) {
                            if (value != null) {
                              provider.setSelectedSim(value);
                            }
                          },
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        )),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Custom Headers Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Custom Headers',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: _addHeader,
                          icon: const Icon(Icons.add_circle, color: AppConstants.accentColor),
                          tooltip: 'Add Header',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add custom headers like Authorization, API-Key, etc.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (_customHeaders.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: const Center(
                          child: Text(
                            'No custom headers configured',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _customHeaders.length,
                        separatorBuilder: (_, __) => const Divider(color: Colors.grey, height: 1),
                        itemBuilder: (context, index) {
                          final key = _customHeaders.keys.elementAt(index);
                          final value = _customHeaders[key]!;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              key,
                              style: const TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              _maskValue(value),
                              style: const TextStyle(color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => _editHeader(key, value),
                                  icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                                  tooltip: 'Edit',
                                ),
                                IconButton(
                                  onPressed: () => _deleteHeader(key),
                                  icon: const Icon(Icons.delete, color: AppConstants.errorColor, size: 20),
                                  tooltip: 'Delete',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
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
                      customHeaders: _customHeaders,
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

  String _maskValue(String value) {
    if (value.length <= 8) {
      return '••••••••';
    }
    return '${value.substring(0, 4)}••••${value.substring(value.length - 4)}';
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppConstants.accentColor,
        ),
      ],
    );
  }
}

class _HeaderDialog extends StatefulWidget {
  final String? initialKey;
  final String? initialValue;
  final Function(String key, String value) onSave;

  const _HeaderDialog({
    this.initialKey,
    this.initialValue,
    required this.onSave,
  });

  @override
  State<_HeaderDialog> createState() => _HeaderDialogState();
}

class _HeaderDialogState extends State<_HeaderDialog> {
  late TextEditingController _keyController;
  late TextEditingController _valueController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _keyController = TextEditingController(text: widget.initialKey ?? '');
    _valueController = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialKey != null;
    
    return AlertDialog(
      backgroundColor: AppConstants.surfaceColor,
      title: Text(
        isEditing ? 'Edit Header' : 'Add Header',
        style: const TextStyle(color: Colors.white),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _keyController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Header Name',
                hintText: 'e.g., Authorization',
                labelStyle: TextStyle(color: Colors.grey),
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppConstants.primaryColor)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a header name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valueController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Header Value',
                hintText: 'e.g., Bearer your-token',
                labelStyle: TextStyle(color: Colors.grey),
                hintStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppConstants.primaryColor)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a header value';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave(
                _keyController.text.trim(),
                _valueController.text.trim(),
              );
              Navigator.pop(context);
            }
          },
          child: Text(isEditing ? 'Update' : 'Add', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
