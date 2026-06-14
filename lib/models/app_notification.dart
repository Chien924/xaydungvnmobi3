class AppNotificationItem {
  final int id;
  final int count;
  final String type;
  final String title;
  final String message;
  final String module;
  final String moduleLabel;
  final String priority;
  final String time;
  final String timeText;
  final String link;
  final bool system;

  const AppNotificationItem({
    required this.id,
    required this.count,
    required this.type,
    required this.title,
    required this.message,
    required this.module,
    required this.moduleLabel,
    required this.priority,
    required this.time,
    required this.timeText,
    required this.link,
    required this.system,
  });

  factory AppNotificationItem.fromJson(Map<String, dynamic> json, {bool system = false}) {
    int asInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? fallback;
    }

    String asText(dynamic value) => value == null ? '' : '$value';

    return AppNotificationItem(
      id: asInt(json['id']),
      count: asInt(json['so_tin'] ?? json['count'], 1),
      type: asText(json['type']),
      title: asText(json['title'] ?? json['tieu_de']).trim(),
      message: asText(json['message'] ?? json['noi_dung']).trim(),
      module: asText(json['module']).trim(),
      moduleLabel: asText(json['module_label'] ?? json['module']).trim(),
      priority: asText(json['priority']).trim().isEmpty ? 'important' : asText(json['priority']).trim(),
      time: asText(json['time'] ?? json['updated_at'] ?? json['created_at']).trim(),
      timeText: asText(json['time_text']).trim(),
      link: asText(json['link'] ?? json['url']).trim(),
      system: system,
    );
  }

  bool get isUrgent => priority == 'urgent';
}

class AppNotificationData {
  final int totalUnread;
  final List<AppNotificationItem> mine;
  final List<AppNotificationItem> system;

  const AppNotificationData({
    required this.totalUnread,
    required this.mine,
    required this.system,
  });

  factory AppNotificationData.empty() {
    return const AppNotificationData(totalUnread: 0, mine: [], system: []);
  }

  factory AppNotificationData.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    List<AppNotificationItem> parseList(dynamic raw, {required bool system}) {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((item) => AppNotificationItem.fromJson(Map<String, dynamic>.from(item), system: system))
          .toList();
    }

    final mineRaw = json['notifications'] ?? json['mine'] ?? json['personal'] ?? json['data'];
    final systemRaw = json['system'] ?? json['system_notifications'] ?? json['he_thong'];

    return AppNotificationData(
      totalUnread: asInt(json['total_unread'] ?? json['unread_count'] ?? json['count']),
      mine: parseList(mineRaw, system: false),
      system: parseList(systemRaw, system: true),
    );
  }
}
