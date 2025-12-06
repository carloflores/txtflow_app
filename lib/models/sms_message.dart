import '../services/contact_service.dart';

class LocalSmsMessage {
  final String id;
  final String address;
  final String body;
  final int date;
  final bool isIncoming;
  final bool isRead;
  final String? status; // 'sent', 'delivered', 'failed', 'pending'

  LocalSmsMessage({
    required this.id,
    required this.address,
    required this.body,
    required this.date,
    required this.isIncoming,
    this.isRead = false,
    this.status,
  });

  factory LocalSmsMessage.fromJson(Map<String, dynamic> json) {
    return LocalSmsMessage(
      id: json['id'] as String,
      address: json['address'] as String,
      body: json['body'] as String,
      date: json['date'] as int,
      isIncoming: json['isIncoming'] as bool? ?? true,
      isRead: json['isRead'] as bool? ?? false,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'body': body,
      'date': date,
      'isIncoming': isIncoming,
      'isRead': isRead,
      'status': status,
    };
  }

  LocalSmsMessage copyWith({
    String? id,
    String? address,
    String? body,
    int? date,
    bool? isIncoming,
    bool? isRead,
    String? status,
  }) {
    return LocalSmsMessage(
      id: id ?? this.id,
      address: address ?? this.address,
      body: body ?? this.body,
      date: date ?? this.date,
      isIncoming: isIncoming ?? this.isIncoming,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(date);

  @override
  String toString() => 'LocalSmsMessage(id: $id, address: $address, body: $body)';
}

class Conversation {
  final String address;
  final LocalSmsMessage lastMessage;
  final int unreadCount;
  final int messageCount;

  Conversation({
    required this.address,
    required this.lastMessage,
    this.unreadCount = 0,
    this.messageCount = 0,
  });

  String get displayName => ContactService.getDisplayName(address);

  String get snippet {
    final prefix = lastMessage.isIncoming ? '' : 'You: ';
    final body = lastMessage.body;
    return '$prefix${body.length > 50 ? '${body.substring(0, 50)}...' : body}';
  }

  String get timeAgo {
    final now = DateTime.now();
    final messageTime = lastMessage.dateTime;
    final diff = now.difference(messageTime);

    if (diff.inDays > 7) {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

