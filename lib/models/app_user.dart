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
    return AppUser(
      id: int.tryParse('${json['id'] ?? 0}') ?? 0,
      username: '${json['username'] ?? ''}',
      displayName: '${json['display_name'] ?? json['username'] ?? ''}',
      balance: int.tryParse('${json['balance'] ?? 0}') ?? 0,
      phone: '${json['phone'] ?? ''}',
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
