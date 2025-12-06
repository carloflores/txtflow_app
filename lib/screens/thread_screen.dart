import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../services/contact_service.dart';
import '../utils/constants.dart';
import '../models/sms_message.dart';

class ThreadScreen extends StatefulWidget {
  final String address;

  const ThreadScreen({super.key, required this.address});

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark conversation as read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().storage.markConversationAsRead(widget.address);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final messages = provider.storage.getMessagesForContact(widget.address);
    final contactName = ContactService.getContactName(widget.address);
    final displayName = contactName ?? widget.address;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              contactName != null ? widget.address : '${messages.length} messages',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Send a message to start the conversation',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true, // Newest at bottom
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final showDate = index == messages.length - 1 ||
                          !_isSameDay(
                            message.dateTime,
                            messages[index + 1].dateTime,
                          );
                      
                      return Column(
                        children: [
                          if (showDate) _buildDateDivider(message.dateTime),
                          _buildMessageBubble(message),
                        ],
                      );
                    },
                  ),
          ),
          
          // Compose bar
          _buildComposeBar(provider),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    String text;
    
    if (_isSameDay(date, now)) {
      text = 'Today';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      text = 'Yesterday';
    } else {
      text = DateFormat('MMM d, yyyy').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(LocalSmsMessage message) {
    final isIncoming = message.isIncoming;
    final time = DateFormat('HH:mm').format(message.dateTime);

    return Align(
      alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isIncoming
              ? AppConstants.surfaceColor
              : AppConstants.primaryColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isIncoming ? 4 : 16),
            bottomRight: Radius.circular(isIncoming ? 16 : 4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isIncoming ? Colors.grey : Colors.white70,
                    fontSize: 11,
                  ),
                ),
                if (!isIncoming) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == 'delivered'
                        ? Icons.done_all
                        : message.status == 'sent'
                            ? Icons.done
                            : message.status == 'failed'
                                ? Icons.error_outline
                                : Icons.access_time,
                    size: 14,
                    color: message.status == 'failed'
                        ? AppConstants.errorColor
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposeBar(AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppConstants.backgroundColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppConstants.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isSending ? null : () => _sendMessage(provider),
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(AppProvider provider) async {
    final body = _messageController.text.trim();
    if (body.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      debugPrint('ThreadScreen: Sending SMS to ${widget.address}');
      
      // Create message record
      final message = LocalSmsMessage(
        id: '${widget.address}_${DateTime.now().millisecondsSinceEpoch}_out',
        address: widget.address,
        body: body,
        date: DateTime.now().millisecondsSinceEpoch,
        isIncoming: false,
        status: 'sent',
      );

      // Save to storage first
      await provider.storage.saveMessage(message);
      debugPrint('ThreadScreen: Message saved to storage');
      
      // Send SMS using selected SIM
      await provider.sendSmsWithSelectedSim(
        to: widget.address,
        message: body,
      );
      debugPrint('ThreadScreen: SMS sent successfully');
      
      // Update status to sent
      await provider.storage.setLastRecipient(widget.address);
      await provider.storage.incrementSentCount();
      await provider.addLog('Sent SMS to ${widget.address}');

      // Refresh UI - force reload
      await provider.loadLogs();
      
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent'),
            backgroundColor: AppConstants.accentColor,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('ThreadScreen: Error sending SMS: $e');
      debugPrint('ThreadScreen: Stack trace: $stackTrace');
      await provider.addLog('Error sending SMS: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
