class AppUser {
  final int id;
  final String username;
  final String displayName;
  final int balance;
  final String phone;

  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.balance,
    required this.phone,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      final text = '$value'.replaceAll(RegExp(r'[^0-9-]'), '');
      return int.tryParse(text) ?? 0;
    }

    final username = '${json['username'] ?? json['usersname'] ?? json['tai_khoan'] ?? ''}'.trim();
    final displayName = '${json['display_name'] ?? json['name'] ?? json['ho_ten'] ?? username}'.trim();

    return AppUser(
      id: parseInt(json['id'] ?? json['user_id'] ?? json['account_id']),
      username: username,
      displayName: displayName.isEmpty ? username : displayName,
      balance: parseInt(json['balance'] ?? json['sodu'] ?? json['so_du'] ?? json['vnd'] ?? 0),
      phone: '${json['phone'] ?? json['sdt'] ?? json['so_dien_thoai'] ?? ''}'.trim(),
    );
  }

  String get balanceText {
    final raw = balance.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < raw.length; i++) {
      final fromEnd = raw.length - i;
      buffer.write(raw[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write('.');
    }
    return '${buffer.toString()} VNĐ';
  }
}
