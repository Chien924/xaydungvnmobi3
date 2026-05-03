import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'support_page.dart';
import 'web_page.dart';

class AppItem {
  final String title;
  final String icon;
  final String path;
  final String desc;

  const AppItem({
    required this.title,
    required this.icon,
    required this.path,
    this.desc = 'Mở trong app',
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;
  AppUser? user;
  bool loadingUser = true;
  int unreadCount = 10;

  @override
  void initState() {
    super.initState();
    refreshUser();
  }

  Future<void> refreshUser() async {
    if (mounted) setState(() => loadingUser = true);
    try {
      user = await AuthService.currentUser();
    } catch (_) {
      user = null;
    }
    if (mounted) setState(() => loadingUser = false);
  }

  void openWeb(String title, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WebPage(title: title, path: path)),
    ).then((_) => refreshUser());
  }

  Future<void> openLogin() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (ok == true) await refreshUser();
  }

  Future<void> logout() async {
    await AuthService.logout();
    await refreshUser();
  }

  void goTab(int index) {
    setState(() => selectedIndex = index);
    if (index == 4) refreshUser();
  }

  static const searchItems = <AppItem>[
    AppItem(title: 'Cơ giới', icon: 'co-gioi', path: '/tim-xe'),
    AppItem(title: 'Cửa hàng vật tư', icon: 'vat-tu', path: '/tim-vat-tu'),
    AppItem(title: 'Tổ đội', icon: 'to-doi', path: '/tim-to-doi'),
    AppItem(title: 'Gói thầu', icon: 'goi-thau', path: '/tim-goi-thau.php'),
    AppItem(title: 'Đơn hàng vật tư', icon: 'nhu-cau', path: '/tim-kiem-nhu-cau.php'),
    AppItem(title: 'Việc làm', icon: 'viec-lam', path: '/viec-lam.php'),
    AppItem(title: 'Tạo CV', icon: 'tao-cv', path: '/tao-cv.php'),
  ];

  static const postItems = <AppItem>[
    AppItem(title: 'Đăng xe', icon: 'dang-xe1', path: '/xe-cua-toi?tab=dang'),
    AppItem(title: 'Đăng vật tư', icon: 'dang-vat-tu1', path: '/vat-tu-cua-toi?tab=form'),
    AppItem(title: 'Đăng tổ đội', icon: 'dang-to-doi', path: '/to-doi-cua-toi?tab=form'),
    AppItem(title: 'Đăng gói thầu', icon: 'dang-goi-thau', path: '/goi-thau-cua-toi?tab=form'),
    AppItem(title: 'Đăng đơn hàng', icon: 'dang-nhu-cau1', path: '/nhu-cau-cua-toi?tab=form'),
    AppItem(title: 'Đăng đối tác', icon: 'dang-doi-tac', path: '/doi-tac-cua-toi?tab=form'),
    AppItem(title: 'Đăng việc làm', icon: 'dang-viec-lam1', path: '/viec-lam-cua-toi.php?tab=dang'),
  ];

  static const manageItems = <AppItem>[
    AppItem(title: 'Quản lí xe', icon: 'dang-xe1', path: '/xe-cua-toi?tab=quanly'),
    AppItem(title: 'Quản lí vật tư', icon: 'dang-vat-tu1', path: '/vat-tu-cua-toi?tab=quanly'),
    AppItem(title: 'Quản lí tổ đội', icon: 'dang-to-doi', path: '/to-doi-cua-toi?tab=quanly'),
    AppItem(title: 'Quản lí gói thầu', icon: 'dang-goi-thau', path: '/goi-thau-cua-toi?tab=quanly'),
    AppItem(title: 'Quản lí nhu cầu', icon: 'dang-nhu-cau1', path: '/nhu-cau-cua-toi?tab=list'),
    AppItem(title: 'Đối tác xe', icon: 'dang-doi-tac', path: '/doi-tac-cua-toi?tab=list_xe'),
    AppItem(title: 'Đối tác vật tư', icon: 'vat-tu', path: '/doi-tac-cua-toi?tab=list_vattu'),
    AppItem(title: 'Quản lí việc làm', icon: 'dang-viec-lam1', path: '/viec-lam-cua-toi.php?tab=quanly'),
  ];

  static const infoItems = <AppItem>[
    AppItem(title: 'Hướng dẫn sử dụng', icon: 'tao-cv', path: '/huong-dan-su-dung.php'),
    AppItem(title: 'Chính sách / quy định', icon: 'goi-thau', path: '/chinh-sach-quy-dinh.php'),
    AppItem(title: 'Liên hệ hỗ trợ', icon: 'dang-doi-tac', path: '/lien-he-ho-tro.php'),
    AppItem(title: 'Thông báo hệ thống', icon: 'nhu-cau', path: '/thong-bao-he-thong.php'),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _homeTab(),
      _manageTab(),
      _supportTab(),
      _notificationTab(),
      _accountTab(),
    ];

    return Scaffold(
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: goTab,
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Trang chủ'),
          const NavigationDestination(icon: Icon(Icons.folder_rounded), label: 'Quản lí'),
          const NavigationDestination(icon: Icon(Icons.support_agent_rounded), label: 'Hỗ trợ'),
          NavigationDestination(
            icon: _badgeIcon(Icons.notifications_rounded),
            selectedIcon: _badgeIcon(Icons.notifications_active_rounded),
            label: 'Thông báo',
          ),
          const NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Tài khoản'),
        ],
      ),
    );
  }

  Widget _homeTab() {
    return RefreshIndicator(
      onRefresh: refreshUser,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          _accountCard(compact: false),
          const SizedBox(height: 14),
          _menuSection(
            title: 'Tìm kiếm dịch vụ xây dựng',
            subtitle: 'Tìm nhanh cơ giới, vật tư, tổ đội, gói thầu, nhu cầu, việc làm và tạo CV.',
            icon: Icons.search_rounded,
            color: const Color(0xff1689e8),
            bgColor: const Color(0xffeef8ff),
            borderColor: const Color(0xffbde2ff),
            items: searchItems,
          ),
          const SizedBox(height: 14),
          _menuSection(
            title: 'Đăng tin nhanh',
            subtitle: 'Đăng xe, vật tư, tổ đội, gói thầu, nhu cầu, đối tác và việc làm.',
            icon: Icons.add_rounded,
            color: const Color(0xffff8a00),
            bgColor: const Color(0xfffff8ed),
            borderColor: const Color(0xffffd19c),
            items: postItems,
          ),
          const SizedBox(height: 14),
          _infoSection(),
        ],
      ),
    );
  }

  Widget _manageTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      children: [
        _pageHeader(
          title: 'Quản lí',
          subtitle: 'Chọn mục cần quản lí, app sẽ mở đúng trang web trong app.',
          icon: Icons.folder_rounded,
          color: const Color(0xff7c3aed),
        ),
        const SizedBox(height: 14),
        _menuSection(
          title: 'Quản lí tin của tôi',
          subtitle: 'Riêng mục đối tác tách 2 nút: đối tác xe và đối tác vật tư.',
          icon: Icons.grid_view_rounded,
          color: const Color(0xff7c3aed),
          bgColor: const Color(0xfff5f3ff),
          borderColor: const Color(0xffddd6fe),
          items: manageItems,
        ),
      ],
    );
  }

  Widget _supportTab() {
    return const SupportPage();
  }

  Future<void> openRegister() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
    if (ok == true) await refreshUser();
  }

  Widget _notificationTab() {
    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: _pageHeader(
              title: 'Thông báo',
              subtitle: 'Thiết kế sẵn. Sau này chỉ cần nối API thông báo.',
              icon: Icons.notifications_active_rounded,
              color: const Color(0xffef4444),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffe5e7eb)),
            ),
            child: const TabBar(
              labelColor: Color(0xff0f172a),
              unselectedLabelColor: Color(0xff64748b),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(text: 'Của tôi'),
                Tab(text: 'Hệ thống'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _notificationList(userMode: true),
                _notificationList(userMode: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountTab() {
    final u = user;
    return RefreshIndicator(
      onRefresh: refreshUser,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          _pageHeader(
            title: 'Tài khoản',
            subtitle: 'Đăng nhập 1 lần, app sẽ tự lưu cho lần sau.',
            icon: Icons.person_rounded,
            color: const Color(0xff0f766e),
          ),
          const SizedBox(height: 14),
          if (u == null) _loginPrompt() else _loggedAccount(u),
          const SizedBox(height: 14),
          _accountAction('Nạp tiền', Icons.account_balance_wallet_rounded, '/nap-tien.php'),
          _accountAction('Lịch sử của tôi', Icons.history_rounded, '/lich-su-cua-toi.php'),
          _accountAction('Thông tin cá nhân', Icons.badge_rounded, '/thong-tin-ca-nhan.php'),
        ],
      ),
    );
  }

  Widget _accountCard({required bool compact}) {
    final u = user;
    final username = u == null ? 'Chưa đăng nhập' : (u.username.isNotEmpty ? u.username : 'Tài khoản');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xff0f766e), Color(0xff16a34a)]),
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [BoxShadow(color: Color(0x220f766e), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Center(
                  child: Text('XD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xây Dựng VN', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                    SizedBox(height: 3),
                    Text('Cơ giới · Vật tư · Tổ đội · Đấu thầu', style: TextStyle(color: Color(0xffdcfce7), fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => goTab(3),
                icon: _badgeIcon(Icons.notifications_rounded, light: true),
                style: IconButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.16)),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loadingUser ? 'Đang kiểm tra tài khoản...' : 'Tài khoản: $username',
                        style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        u == null ? 'Số dư: -- VNĐ' : 'Số dư: ${u.balanceText}',
                        style: const TextStyle(color: Color(0xffdcfce7), fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xff15803d),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                  onPressed: u == null ? openLogin : logout,
                  child: Text(u == null ? 'Đăng nhập' : 'Thoát', style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required List<AppItem> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 52, height: 52, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: Colors.white, size: 28)),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 22, height: 1.1, color: Color(0xff06122a), fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 14),
          GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisExtent: 104, crossAxisSpacing: 11, mainAxisSpacing: 11),
            itemBuilder: (context, index) {
              final item = items[index];
              return _iconButton(item: item, onTap: () => openWeb(item.title, item.path));
            },
          ),
          const SizedBox(height: 13),
          Text(subtitle, style: const TextStyle(color: Color(0xff36506b), fontSize: 13, height: 1.45, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _iconButton({required AppItem item, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  'assets/icons/${item.icon}.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.apps_rounded, size: 42, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 5),
              Text(item.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff06122a), fontSize: 11.5, height: 1.15, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xffe5e7eb))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thông tin khác', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xff06122a))),
          const SizedBox(height: 12),
          ...infoItems.map((item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Image.asset('assets/icons/${item.icon}.png', width: 42, height: 42, errorBuilder: (_, __, ___) => const Icon(Icons.info_rounded)),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: const Text('Đường dẫn để sẵn, sửa trang web sau'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => openWeb(item.title, item.path),
              )),
        ],
      ),
    );
  }

  Widget _pageHeader({required String title, required String subtitle, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xffe5e7eb))),
      child: Row(
        children: [
          Container(width: 54, height: 54, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: color, size: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xff06122a))),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12.5, height: 1.35, color: Color(0xff64748b), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _loginPrompt() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xffe5e7eb))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bạn chưa đăng nhập', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          const Text('Đăng nhập để xem số dư, quản lí tin, nạp tiền và lịch sử.', style: TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: FilledButton(onPressed: openLogin, child: const Text('Đăng nhập'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton(onPressed: openRegister, child: const Text('Tạo tài khoản'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loggedAccount(AppUser u) {
    final username = u.username.isNotEmpty ? u.username : 'Tài khoản';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xffe5e7eb))),
      child: Row(
        children: [
          const CircleAvatar(radius: 26, backgroundColor: Color(0xffdcfce7), child: Icon(Icons.person_rounded, color: Color(0xff15803d), size: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Số dư: ${u.balanceText}', style: const TextStyle(color: Color(0xff15803d), fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          TextButton(onPressed: logout, child: const Text('Đăng xuất')),
        ],
      ),
    );
  }

  Widget _accountAction(String title, IconData icon, String path) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xffe5e7eb))),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xff0f766e)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => openWeb(title, path),
      ),
    );
  }

  Widget _notificationList({required bool userMode}) {
    final title = userMode ? 'Chưa có thông báo cá nhân mới' : 'Chưa có thông báo hệ thống mới';
    final desc = userMode
        ? 'Sau này API sẽ đổ thông báo báo giá, duyệt tin, số dư, gói thầu vào đây.'
        : 'Sau này bạn có thể đăng thông báo bảo trì, cập nhật chức năng, chính sách tại đây.';
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xffe5e7eb))),
          child: Column(
            children: [
              Icon(userMode ? Icons.notifications_none_rounded : Icons.campaign_rounded, size: 54, color: const Color(0xff94a3b8)),
              const SizedBox(height: 10),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _badgeIcon(IconData icon, {bool light = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: light ? Colors.white : null),
        if (unreadCount > 0)
          Positioned(
            right: -8,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(999)),
              child: Text('+$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ),
      ],
    );
  }
}
