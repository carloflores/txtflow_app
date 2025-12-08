import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../services/contact_service.dart';
import '../utils/constants.dart';
import '../models/group.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final groups = provider.storage.getGroups();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Message Groups'),
        backgroundColor: AppConstants.surfaceColor,
        foregroundColor: Colors.white,
      ),
      body: groups.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = MessageGroup.fromJson(groups[index]);
                return _buildGroupTile(group, provider)
                    .animate()
                    .fadeIn(delay: Duration(milliseconds: 50 * index))
                    .slideX(begin: 0.1, end: 0);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context, provider),
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.group_add, color: Colors.white),
        label: const Text('New Group', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.group_outlined,
              size: 64,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No groups yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a group to send messages to multiple contacts',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildGroupTile(MessageGroup group, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.group, color: AppConstants.primaryColor),
        ),
        title: Text(
          group.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${group.memberCount} members',
          style: TextStyle(color: Colors.grey.shade500),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.grey),
          color: AppConstants.surfaceColor,
          onSelected: (value) => _handleGroupAction(value, group, provider),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'send',
              child: Row(
                children: [
                  Icon(Icons.send, color: AppConstants.primaryColor, size: 20),
                  SizedBox(width: 12),
                  Text('Send to group', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.grey, size: 20),
                  SizedBox(width: 12),
                  Text('Edit group', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppConstants.errorColor, size: 20),
                  SizedBox(width: 12),
                  Text('Delete group', style: TextStyle(color: AppConstants.errorColor)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _showSendToGroupDialog(context, group, provider),
      ),
    );
  }

  void _handleGroupAction(String action, MessageGroup group, AppProvider provider) {
    switch (action) {
      case 'send':
        _showSendToGroupDialog(context, group, provider);
        break;
      case 'edit':
        _showEditGroupDialog(context, group, provider);
        break;
      case 'delete':
        _showDeleteGroupDialog(context, group, provider);
        break;
    }
  }

  void _showCreateGroupDialog(BuildContext context, AppProvider provider) {
    final nameController = TextEditingController();
    List<String> selectedMembers = [];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.group_add, color: AppConstants.primaryColor),
              SizedBox(width: 12),
              Text('Create Group', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Group name',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.label, color: Colors.grey),
                    filled: true,
                    fillColor: AppConstants.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members (${selectedMembers.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await _showMemberPicker(context, selectedMembers);
                        if (result != null) {
                          setDialogState(() => selectedMembers = result);
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                if (selectedMembers.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedMembers.map((phone) {
                      final name = ContactService.getDisplayName(phone);
                      return Chip(
                        label: Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: AppConstants.backgroundColor,
                        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onDeleted: () {
                          setDialogState(() => selectedMembers.remove(phone));
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty && selectedMembers.isNotEmpty) {
                  final group = MessageGroup(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    members: selectedMembers,
                    createdAt: DateTime.now(),
                  );
                  await provider.storage.saveGroup(group.toJson());
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Group created')),
                    );
                  }
                }
              },
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>?> _showMemberPicker(BuildContext context, List<String> current) async {
    final selected = List<String>.from(current);
    
    return showModalBottomSheet<List<String>>(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => _MemberPickerContent(
            scrollController: scrollController,
            selected: selected,
            onSelectionChanged: (phone, isSelected) {
              setSheetState(() {
                if (isSelected) {
                  if (!selected.contains(phone)) selected.add(phone);
                } else {
                  selected.remove(phone);
                }
              });
            },
            onDone: () => Navigator.pop(sheetContext, selected),
          ),
        ),
      ),
    );
  }

  void _showSendToGroupDialog(BuildContext context, MessageGroup group, AppProvider provider) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.send, color: AppConstants.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Send to ${group.name}',
                style: const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${group.memberCount} recipients',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(color: Colors.grey.shade500),
                filled: true,
                fillColor: AppConstants.backgroundColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final message = messageController.text.trim();
              if (message.isNotEmpty) {
                Navigator.pop(dialogContext);
                await _sendToGroup(group, message, provider);
              }
            },
            child: const Text('Send', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _sendToGroup(MessageGroup group, String message, AppProvider provider) async {
    int sent = 0;
    int failed = 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sending to ${group.memberCount} recipients...'),
        duration: const Duration(seconds: 2),
      ),
    );

    for (final phone in group.members) {
      try {
        await provider.sendSmsWithSelectedSim(to: phone, message: message);
        sent++;
      } catch (e) {
        failed++;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent: $sent, Failed: $failed'),
          backgroundColor: failed == 0 ? AppConstants.accentColor : AppConstants.errorColor,
        ),
      );
    }
  }

  void _showEditGroupDialog(BuildContext context, MessageGroup group, AppProvider provider) {
    final nameController = TextEditingController(text: group.name);
    List<String> selectedMembers = List.from(group.members);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppConstants.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.edit, color: AppConstants.primaryColor),
              SizedBox(width: 12),
              Text('Edit Group', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Group name',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.label, color: Colors.grey),
                    filled: true,
                    fillColor: AppConstants.backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Members (${selectedMembers.length})',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await _showMemberPicker(context, selectedMembers);
                        if (result != null) {
                          setDialogState(() => selectedMembers = result);
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                if (selectedMembers.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedMembers.map((phone) {
                      final name = ContactService.getDisplayName(phone);
                      return Chip(
                        label: Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        backgroundColor: AppConstants.backgroundColor,
                        deleteIcon: const Icon(Icons.close, size: 16, color: Colors.grey),
                        onDeleted: () {
                          setDialogState(() => selectedMembers.remove(phone));
                        },
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty && selectedMembers.isNotEmpty) {
                  final updated = group.copyWith(name: name, members: selectedMembers);
                  await provider.storage.saveGroup(updated.toJson());
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Group updated')),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteGroupDialog(BuildContext context, MessageGroup group, AppProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete, color: AppConstants.errorColor),
            SizedBox(width: 12),
            Text('Delete Group', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${group.name}"?',
          style: const TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await provider.storage.deleteGroup(group.id);
              if (mounted) {
                Navigator.pop(dialogContext);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MemberPickerContent extends StatefulWidget {
  final ScrollController scrollController;
  final List<String> selected;
  final Function(String, bool) onSelectionChanged;
  final VoidCallback onDone;

  const _MemberPickerContent({
    required this.scrollController,
    required this.selected,
    required this.onSelectionChanged,
    required this.onDone,
  });

  @override
  State<_MemberPickerContent> createState() => _MemberPickerContentState();
}

class _MemberPickerContentState extends State<_MemberPickerContent> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _contacts = [];
  List<dynamic> _filteredContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await ContactService.getAllContacts();
    setState(() {
      _contacts = contacts;
      _filteredContacts = contacts;
      _isLoading = false;
    });
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          final name = contact.displayName.toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade700,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Members (${widget.selected.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton(
                onPressed: widget.onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                ),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: _filterContacts,
            decoration: InputDecoration(
              hintText: 'Search contacts',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: AppConstants.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _filteredContacts[index];
                    final phones = contact.phones;
                    if (phones.isEmpty) return const SizedBox.shrink();
                    
                    final phone = phones.first.number;
                    final isSelected = widget.selected.contains(phone);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (value) => widget.onSelectionChanged(phone, value ?? false),
                      activeColor: AppConstants.primaryColor,
                      title: Text(
                        contact.displayName,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        phone,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                      secondary: CircleAvatar(
                        backgroundColor: isSelected
                            ? AppConstants.primaryColor
                            : AppConstants.backgroundColor,
                        child: Text(
                          contact.displayName.isNotEmpty
                              ? contact.displayName[0].toUpperCase()
                              : '#',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
