import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:telephony/telephony.dart';
import 'package:flutter/services.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:async';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestDefaultSms();
    // Refresh UI every second for the countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
      
      // Refresh logs/storage every 5 seconds to catch background updates
      if (timer.tick % 5 == 0 && mounted) {
        context.read<AppProvider>().loadLogs();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<AppProvider>();
    if (state == AppLifecycleState.resumed) {
      provider.setForegroundState(true);
      provider.loadLogs(); // Refresh logs on resume
    } else if (state == AppLifecycleState.paused) {
      provider.setForegroundState(false);
    }
  }

  Future<void> _requestDefaultSms() async {
    final Telephony telephony = Telephony.instance;
    const platform = MethodChannel('com.carlodflores.txtflow/settings');
    
    try {
      // Check if default using our platform channel
      final bool isDefault = await platform.invokeMethod('isDefaultSmsApp');
      debugPrint('Dashboard: isDefaultSmsApp = $isDefault');

      if (!isDefault) {
        debugPrint('Dashboard: Requesting permissions...');
        // Request permissions first
        await telephony.requestSmsPermissions;
        await telephony.requestPhonePermissions;

        debugPrint('Dashboard: Requesting to be default SMS app...');
        // Open settings to set as default
        await platform.invokeMethod('openDefaultSmsSettings');
      } else {
        debugPrint('Dashboard: Already default SMS app');
      }
    } catch (e) {
      debugPrint('Failed to request default SMS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/images/logo.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
            const SizedBox(width: 12),
            const Text('TxtFlow Gateway'),
          ],
        ),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: 'Test SMS',
            onPressed: () => _showTestSmsDialog(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusCard(provider),
          _buildStatsRow(provider),
          _buildDetailsCard(provider),
          Expanded(child: _buildLogsList(provider)),
        ],
      ),
    );
  }

  Widget _buildStatusCard(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Service Status', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        provider.isServiceRunning ? Icons.check_circle : Icons.pause_circle,
                        color: provider.isServiceRunning ? AppConstants.accentColor : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.isServiceRunning ? 'Active' : 'Paused',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Server Connection', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        provider.isOnline ? Icons.cloud_done : Icons.cloud_off,
                        color: provider.isOnline ? AppConstants.accentColor : AppConstants.errorColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        provider.isOnline ? 'Online' : 'Offline',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => provider.toggleService(),
                icon: Icon(provider.isServiceRunning ? Icons.stop : Icons.play_arrow),
                label: Text(provider.isServiceRunning ? 'Stop Service' : 'Start Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: provider.isServiceRunning ? AppConstants.errorColor : AppConstants.accentColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  await Workmanager().registerOneOffTask(
                    'manual_poll_${DateTime.now().millisecondsSinceEpoch}',
                    'sms_gateway_polling',
                    inputData: {'manual': true},
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Background task triggered manually')),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Run Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildStatsRow(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Sent', provider.messagesSentCount.toString(), Icons.send, Colors.blue)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('Received', provider.messagesReceivedCount.toString(), Icons.call_received, Colors.green)),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY();
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Device Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem('System Number', provider.systemPhoneNumber),
              _buildDetailItem('Last Sent To', provider.lastRecipient),
              _buildDetailItem('Next Poll', _formatNextPoll(provider.nextPollTime)),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY();
  }

  String _formatNextPoll(DateTime? nextPoll) {
    if (nextPoll == null) return 'Waiting...';
    final now = DateTime.now();
    if (nextPoll.isBefore(now)) return 'Soon';
    
    final diff = nextPoll.difference(now);
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return '~${minutes}m ${seconds}s';
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildLogsList(AppProvider provider) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Activity Log', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1, color: Colors.grey),
          Expanded(
            child: ListView.builder(
              itemCount: provider.logs.length,
              itemBuilder: (context, index) {
                final log = provider.logs[index];
                // Simple parsing for icons
                IconData icon = Icons.info_outline;
                Color color = Colors.grey;
                
                if (log.contains('Sent SMS')) {
                  icon = Icons.send;
                  color = Colors.blue;
                } else if (log.contains('Received SMS')) {
                  icon = Icons.call_received;
                  color = Colors.green;
                } else if (log.contains('failed') || log.contains('error') || log.contains('Offline')) {
                  icon = Icons.error_outline;
                  color = Colors.red;
                } else if (log.contains('Background')) {
                  icon = Icons.refresh;
                  color = Colors.orange;
                }

                // Remove timestamp for display if it's too long, or keep it
                // Format: "YYYY-MM-DD HH:MM:SS - Log message"
                final parts = log.split(' - ');
                final time = parts.isNotEmpty ? parts[0].split(' ')[1] : ''; // Just get HH:MM:SS
                final message = parts.length > 1 ? parts.sublist(1).join(' - ') : log;

                return ListTile(
                  leading: Icon(icon, color: color, size: 20),
                  title: Text(
                    message,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                );
              },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY();
  }

  Future<void> _showTestSmsDialog(BuildContext context, AppProvider provider) async {
    final phoneController = TextEditingController();
    final messageController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text('Send Test SMS', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppConstants.accentColor)),
              ),
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppConstants.accentColor)),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            onPressed: () async {
              final address = phoneController.text.trim();
              final body = messageController.text.trim();
              
              if (address.isNotEmpty && body.isNotEmpty) {
                Navigator.pop(context);
                try {
                  final telephony = Telephony.instance;
                  await telephony.sendSms(to: address, message: body);
                  
                  // Update logs and last recipient
                  await provider.storage.setLastRecipient(address);
                  await provider.storage.incrementSentCount();
                  await provider.addLog('Manual: Sent SMS to $address');
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message sent!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to send: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
