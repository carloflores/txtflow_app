import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/app_provider.dart';
import '../services/contact_service.dart';
import '../utils/constants.dart';
import '../models/sms_message.dart';
import 'thread_screen.dart';
import 'dashboard_screen.dart';
import 'settings_screen.dart';
import 'groups_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _getUnreadCount(AppProvider provider) {
    return provider.storage.getConversations()
        .fold(0, (sum, conv) => sum + conv.unreadCount);
  }

  List<Conversation> _getFilteredConversations(AppProvider provider) {
    final conversations = provider.storage.getConversations();
    if (_searchQuery.isEmpty) return conversations;
    
    return conversations.where((conv) {
      final query = _searchQuery.toLowerCase();
      return conv.displayName.toLowerCase().contains(query) ||
             conv.address.toLowerCase().contains(query) ||
             conv.snippet.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final conversations = _getFilteredConversations(provider);
    final unreadCount = _getUnreadCount(provider);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // App bar with search
            _buildAppBar(provider, unreadCount),
            
            // Search bar
            _buildSearchBar(),
            
            // Conversations list
            Expanded(
              child: conversations.isEmpty
                  ? _buildEmptyState()
                  : _buildConversationsList(conversations, provider),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewMessageDialog(context, provider),
        backgroundColor: AppConstants.primaryColor,
        icon: const Icon(Icons.message, color: Colors.white),
        label: const Text('Start chat', style: TextStyle(color: Colors.white)),
      ).animate().scale(delay: 300.ms, curve: Curves.easeOutBack),
    );
  }

  Widget _buildAppBar(AppProvider provider, int unreadCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Logo and title
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/images/logo.svg',
                  width: 28,
                  height: 28,
                  colorFilter: const ColorFilter.mode(
                    AppConstants.primaryColor,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'TxtFlow',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const Spacer(),
          
          // Gateway status indicator
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: provider.isServiceRunning
                    ? AppConstants.accentColor.withOpacity(0.15)
                    : Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: provider.isServiceRunning
                      ? AppConstants.accentColor.withOpacity(0.4)
                      : Colors.orange.withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    provider.isServiceRunning
                        ? Icons.cloud_done
                        : Icons.cloud_off,
                    size: 14,
                    color: provider.isServiceRunning
                        ? AppConstants.accentColor
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    provider.isServiceRunning ? 'Gateway On' : 'Gateway Off',
                    style: TextStyle(
                      fontSize: 12,
                      color: provider.isServiceRunning
                          ? AppConstants.accentColor
                          : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 4),
          
          // Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: AppConstants.surfaceColor,
            onSelected: (value) {
              switch (value) {
                case 'groups':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GroupsScreen()),
                  );
                  break;
                case 'gateway':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                  break;
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'groups',
                child: Row(
                  children: [
                    Icon(Icons.group, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text('Groups', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'gateway',
                child: Row(
                  children: [
                    Icon(
                      Icons.router,
                      color: provider.isServiceRunning
                          ? AppConstants.accentColor
                          : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Gateway Dashboard',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Colors.grey, size: 20),
                    SizedBox(width: 12),
                    Text('Settings', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search conversations',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 14,
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
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
              _searchQuery.isEmpty ? Icons.chat_bubble_outline : Icons.search_off,
              size: 64,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isEmpty ? 'No messages yet' : 'No results found',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Start a conversation by tapping the button below'
                : 'Try a different search term',
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

  Widget _buildConversationsList(
    List<Conversation> conversations,
    AppProvider provider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Space for FAB
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _buildConversationTile(conversation, provider)
            .animate()
            .fadeIn(delay: Duration(milliseconds: 30 * index))
            .slideX(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildConversationTile(Conversation conversation, AppProvider provider) {
    final hasUnread = conversation.unreadCount > 0;
    final initial = conversation.displayName.isNotEmpty
        ? conversation.displayName[0].toUpperCase()
        : '#';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ThreadScreen(address: conversation.address),
          ),
        ).then((_) => setState(() {}));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnread
              ? AppConstants.primaryColor.withOpacity(0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: hasUnread
                    ? const LinearGradient(
                        colors: [AppConstants.primaryColor, Color(0xFF1976D2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: hasUnread ? null : Colors.grey.shade800,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: hasUnread ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 14),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.displayName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: hasUnread
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        conversation.timeAgo,
                        style: TextStyle(
                          color: hasUnread
                              ? AppConstants.primaryColor
                              : Colors.grey.shade500,
                          fontSize: 12,
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.snippet,
                          style: TextStyle(
                            color: hasUnread
                                ? Colors.grey.shade300
                                : Colors.grey.shade500,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showNewMessageDialog(
    BuildContext context,
    AppProvider provider,
  ) async {
    final phoneController = TextEditingController();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.message, color: AppConstants.primaryColor),
            SizedBox(width: 12),
            Text('New Message', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: phoneController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Enter phone number',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                      filled: true,
                      fillColor: AppConstants.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppConstants.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.contacts, color: AppConstants.primaryColor),
                    tooltip: 'Pick from contacts',
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      _showContactPicker(context, provider);
                    },
                  ),
                ),
              ],
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              final phone = phoneController.text.trim();
              if (phone.isNotEmpty) {
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ThreadScreen(address: phone),
                  ),
                ).then((_) => setState(() {}));
              }
            },
            child: const Text('Start', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showContactPicker(BuildContext context, AppProvider provider) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConstants.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => _ContactPickerSheet(
          scrollController: scrollController,
          onContactSelected: (phone) {
            Navigator.pop(sheetContext);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ThreadScreen(address: phone),
              ),
            ).then((_) => setState(() {}));
          },
        ),
      ),
    );
  }
}

class _ContactPickerSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(String) onContactSelected;

  const _ContactPickerSheet({
    required this.scrollController,
    required this.onContactSelected,
  });

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _contacts = [];
  List<dynamic> _filteredContacts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredContacts = _contacts;
      } else {
        _filteredContacts = _contacts.where((contact) {
          final name = contact.displayName.toLowerCase();
          final phones = contact.phones
              .map((p) => p.number.toLowerCase())
              .join(' ');
          return name.contains(query.toLowerCase()) ||
              phones.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle bar
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade700,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        // Header
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.contacts, color: AppConstants.primaryColor),
              SizedBox(width: 12),
              Text(
                'Select Contact',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Search bar
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
        
        // Contact list
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppConstants.primaryColor,
                  ),
                )
              : _filteredContacts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty
                                ? Icons.contacts_outlined
                                : Icons.search_off,
                            size: 48,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No contacts found'
                                : 'No matches',
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: widget.scrollController,
                      itemCount: _filteredContacts.length,
                      itemBuilder: (context, index) {
                        final contact = _filteredContacts[index];
                        final phones = contact.phones;
                        final initial = contact.displayName.isNotEmpty
                            ? contact.displayName[0].toUpperCase()
                            : '#';

                        if (phones.isEmpty) return const SizedBox.shrink();

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppConstants.primaryColor,
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            contact.displayName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            phones.first.number,
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                          trailing: phones.length > 1
                              ? PopupMenuButton<String>(
                                  icon: const Icon(
                                    Icons.more_vert,
                                    color: Colors.grey,
                                  ),
                                  color: AppConstants.surfaceColor,
                                  onSelected: widget.onContactSelected,
                                  itemBuilder: (context) => phones
                                      .map<PopupMenuItem<String>>((phone) =>
                                          PopupMenuItem(
                                            value: phone.number,
                                            child: Text(
                                              phone.number,
                                              style: const TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ))
                                      .toList(),
                                )
                              : null,
                          onTap: () =>
                              widget.onContactSelected(phones.first.number),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

