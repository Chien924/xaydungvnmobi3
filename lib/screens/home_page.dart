import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../models/app_notification.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
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

class ManageItem {
  final String title;
  final String subtitle;
  final String path;
  final IconData icon;
  final Color color;

  const ManageItem({
    required this.title,
    required this.subtitle,
    required this.path,
    required this.icon,
    required this.color,
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
  bool loadingNotifications = false;
  String? notificationError;
  AppNotificationData notificationData = AppNotificationData.empty();
  int unreadCount = 0;

  @override
  void initState() {
    super.initState();
    refreshUser();
    refreshNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      WebPage.preloadAll();
    });
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

  Future<void> refreshNotifications() async {
    if (mounted) {
      setState(() {
        loadingNotifications = true;
        notificationError = null;
      });
    }

    try {
      final data = await NotificationService.fetch();
      if (mounted) {
        setState(() {
          notificationData = data;
          unreadCount = data.totalUnread;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          notificationError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => loadingNotifications = false);
    }
  }

  Future<void> refreshHome() async {
    await refreshUser();
    await refreshNotifications();
  }

  void openWeb(String title, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WebPage(title: title, path: path)),
    ).then((_) {
      refreshUser();
      refreshNotifications();
    });
  }

  Future<void> openLogin() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (ok == true) {
      WebPage.resetCachedControllers();
      await refreshUser();
      await refreshNotifications();
      WebPage.preloadAll();
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    WebPage.resetCachedControllers();
    if (mounted) {
      setState(() {
        notificationData = AppNotificationData.empty();
        unreadCount = 0;
      });
    }
    await refreshUser();
    WebPage.preloadAll();
  }

  void goTab(int index) {
    setState(() => selectedIndex = index);
    if (index == 3) refreshNotifications();
    if (index == 4) refreshUser();
  }

  static const searchItems = <AppItem>[
    AppItem(title: 'Cơ giới', icon: 'co-gioi', path: '/tim-xe'),
    AppItem(title: 'Cửa hàng vật tư', icon: 'vat-tu', path: '/tim-vat-tu'),
    AppItem(title: 'Tổ đội', icon: 'to-doi', path: '/tim-to-doi'),
    AppItem(title: 'Gói thầu', icon: 'goi-thau', path: '/tim-goi-thau.php'),
    AppItem(title: 'Bản đồ xây dựng VN', icon: 'ban-do', path: '/ban-do-osm-vietnam.php'),
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

  static const manageContentItems = <ManageItem>[
    ManageItem(
      title: 'Quản lí xe',
      subtitle: 'Xe đã đăng, sửa tin, trạng thái',
      path: '/xe-cua-toi?tab=quanly',
      icon: Icons.local_shipping_rounded,
      color: Color(0xff2563eb),
    ),
    ManageItem(
      title: 'Xác minh xe',
      subtitle: 'Gửi yêu cầu xác minh xe cơ giới',
      path: '/xac-minh-xe.php',
      icon: Icons.verified_rounded,
      color: Color(0xff0284c7),
    ),
    ManageItem(
      title: 'Quản lí vật tư',
      subtitle: 'Cửa hàng, vật tư, báo giá',
      path: '/vat-tu-cua-toi?tab=quanly',
      icon: Icons.warehouse_rounded,
      color: Color(0xff16a34a),
    ),
    ManageItem(
      title: 'Quản lí tổ đội',
      subtitle: 'Tổ đội thi công đã đăng',
      path: '/to-doi-cua-toi?tab=quanly',
      icon: Icons.groups_rounded,
      color: Color(0xffea580c),
    ),
    ManageItem(
      title: 'Quản lí nhu cầu',
      subtitle: 'Đơn hàng vật tư của tôi',
      path: '/nhu-cau-cua-toi?tab=list',
      icon: Icons.inventory_2_rounded,
      color: Color(0xff0f766e),
    ),
    ManageItem(
      title: 'Quản lí việc làm',
      subtitle: 'Tin tuyển dụng đã đăng',
      path: '/viec-lam-cua-toi.php?tab=quanly',
      icon: Icons.work_rounded,
      color: Color(0xffdb2777),
    ),
  ];

  static const manageTenderItems = <ManageItem>[
    ManageItem(
      title: 'Gói thầu đã đăng',
      subtitle: 'Theo dõi gói mời thầu, báo giá, hồ sơ tham gia',
      path: '/theo-doi-goi-thau?tab=goidang',
      icon: Icons.assignment_rounded,
      color: Color(0xff7c3aed),
    ),
    ManageItem(
      title: 'Gói thầu tham gia',
      subtitle: 'Các gói đã tham gia và báo giá đã gửi',
      path: '/theo-doi-goi-thau?tab=goithamgia',
      icon: Icons.handshake_rounded,
      color: Color(0xff0891b2),
    ),
  ];

  static const managePartnerItems = <ManageItem>[
    ManageItem(
      title: 'Đối tác xe',
      subtitle: 'Danh sách đối tác cơ giới',
      path: '/doi-tac-cua-toi?tab=list_xe',
      icon: Icons.precision_manufacturing_rounded,
      color: Color(0xff1d4ed8),
    ),
    ManageItem(
      title: 'Đối tác vật tư',
      subtitle: 'Nhà cung cấp, đại lý vật tư',
      path: '/doi-tac-cua-toi?tab=list_vattu',
      icon: Icons.storefront_rounded,
      color: Color(0xff15803d),
    ),
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
      backgroundColor: const Color(0xfff6f8fb),
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: NavigationBar(
        height: 66,
        elevation: 8,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xffdcfce7),
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
      onRefresh: refreshHome,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
        children: [
          _accountCard(compact: false),
          const SizedBox(height: 14),
          _menuSection(
            title: 'Tìm kiếm dịch vụ xây dựng',
            subtitle: '',
            icon: Icons.search_rounded,
            color: const Color(0xff1689e8),
            bgColor: const Color(0xffeef8ff),
            borderColor: const Color(0xffbde2ff),
            items: searchItems,
          ),
          const SizedBox(height: 14),
          _menuSection(
            title: 'Đăng tin nhanh',
            subtitle: '',
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
    return RefreshIndicator(
      onRefresh: refreshHome,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          _pageHeader(
            title: 'Quản lí',
            subtitle: '',
            icon: Icons.folder_rounded,
            color: const Color(0xff7c3aed),
          ),
          const SizedBox(height: 14),
          _manageSection(
            title: 'Tin đang quản lí',
            subtitle: '',
            icon: Icons.dashboard_customize_rounded,
            color: const Color(0xff2563eb),
            bgColor: const Color(0xffeff6ff),
            borderColor: const Color(0xffbfdbfe),
            items: manageContentItems,
          ),
          const SizedBox(height: 14),
          _manageSection(
            title: 'Theo dõi gói thầu',
            subtitle: '',
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xff7c3aed),
            bgColor: const Color(0xfff5f3ff),
            borderColor: const Color(0xffddd6fe),
            items: manageTenderItems,
            fullWidth: true,
          ),
          const SizedBox(height: 14),
          _manageSection(
            title: 'Đối tác',
            subtitle: '',
            icon: Icons.diversity_3_rounded,
            color: const Color(0xff0f766e),
            bgColor: const Color(0xffecfdf5),
            borderColor: const Color(0xffbbf7d0),
            items: managePartnerItems,
          ),
        ],
      ),
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
    if (ok == true) {
      WebPage.resetCachedControllers();
      await refreshUser();
      await refreshNotifications();
    }
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
              subtitle: '',
              icon: Icons.notifications_active_rounded,
              color: const Color(0xffef4444),
            ),
          ),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xfffff1f2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xffffcdd2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '$unreadCount thông báo chưa đọc',
                      style: const TextStyle(color: Color(0xffbe123c), fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _markAllNotifications,
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    label: const Text('Đọc tất cả'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xffbe123c),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
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
      onRefresh: refreshHome,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        children: [
          _pageHeader(
            title: 'Tài khoản',
            subtitle: '',
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
                        loadingUser ? 'Đang tải...' : 'Tài khoản: $username',
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: const [BoxShadow(color: Color(0x0f0f172a), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 42, height: 42, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: Colors.white, size: 24)),
              const SizedBox(width: 10),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 18, height: 1.1, color: Color(0xff06122a), fontWeight: FontWeight.w900))),
            ],
          ),
          const SizedBox(height: 10),
          GridView.builder(
            itemCount: items.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 84,
              crossAxisSpacing: 7,
              mainAxisSpacing: 7,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _iconButton(item: item, onTap: () => openWeb(item.title, item.path));
            },
          ),
          const SizedBox(height: 13),
          if (subtitle.trim().isNotEmpty) Text(subtitle, style: const TextStyle(color: Color(0xff36506b), fontSize: 13, height: 1.45, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _iconButton({required AppItem item, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: const Color(0x160f172a),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffeaf0f6)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
          child: Column(
            children: [
              Expanded(
                child: Image.asset(
                  'assets/icons/${item.icon}.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(Icons.apps_rounded, size: 42, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 3),
              Text(item.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff06122a), fontSize: 9.8, height: 1.08, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _manageSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required List<ManageItem> items,
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: const [BoxShadow(color: Color(0x0d0f172a), blurRadius: 16, offset: Offset(0, 7))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: Colors.white, size: 27),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 19, height: 1.15, color: Color(0xff06122a), fontWeight: FontWeight.w900)),
                    if (subtitle.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(color: Color(0xff475569), fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          if (fullWidth)
            ...items.map((item) => _manageWideCard(item)).toList()
          else
            GridView.builder(
              itemCount: items.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 112,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) => _manageGridCard(items[index]),
            ),
        ],
      ),
    );
  }

  Widget _manageGridCard(ManageItem item) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openWeb(item.title, item.path),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xffe5e7eb)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: item.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(item.icon, color: item.color, size: 21),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xff94a3b8), size: 21),
                ],
              ),
              const SizedBox(height: 8),
              Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, height: 1.15, fontWeight: FontWeight.w900, color: Color(0xff0f172a))),
              const SizedBox(height: 4),
              Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.2, height: 1.25, fontWeight: FontWeight.w700, color: Color(0xff64748b))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _manageWideCard(ManageItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openWeb(item.title, item.path),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xffe5e7eb)),
              boxShadow: const [BoxShadow(color: Color(0x070f172a), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: item.color.withOpacity(0.12), borderRadius: BorderRadius.circular(15)),
                  child: Icon(item.icon, color: item.color, size: 25),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, height: 1.2, fontWeight: FontWeight.w900, color: Color(0xff0f172a))),
                      const SizedBox(height: 4),
                      Text(item.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.3, fontWeight: FontWeight.w700, color: Color(0xff64748b))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(color: item.color.withOpacity(0.10), borderRadius: BorderRadius.circular(999)),
                  child: Icon(Icons.open_in_new_rounded, color: item.color, size: 17),
                ),
              ],
            ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffe5e7eb)),
        boxShadow: const [BoxShadow(color: Color(0x0a0f172a), blurRadius: 14, offset: Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(width: 54, height: 54, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: color, size: 30)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xff06122a))),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 12.5, height: 1.35, color: Color(0xff64748b), fontWeight: FontWeight.w700)),
                ],
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

  Future<void> _openNotification(AppNotificationItem item) async {
    if (item.system) {
      if (item.link.isNotEmpty) openWeb(item.title.isEmpty ? 'Thông báo hệ thống' : item.title, item.link);
      return;
    }

    try {
      final link = await NotificationService.markOne(item.id);
      await refreshNotifications();

      final target = link.isNotEmpty ? link : item.link;
      if (target.isNotEmpty) {
        openWeb(item.title.isEmpty ? 'Thông báo' : item.title, target);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _markAllNotifications() async {
    try {
      await NotificationService.markAll();
      await refreshNotifications();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đọc tất cả')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _notificationList({required bool userMode}) {
    final items = userMode ? notificationData.mine : notificationData.system;
    final emptyTitle = userMode ? 'Chưa có thông báo cá nhân mới' : 'Chưa có thông báo hệ thống mới';

    return RefreshIndicator(
      onRefresh: refreshNotifications,
      child: ListView(
        padding: const EdgeInsets.all(14),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (loadingNotifications && items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (notificationError != null && items.isEmpty)
            _noticeBox(
              icon: Icons.wifi_off_rounded,
              title: 'Chưa lấy được thông báo',
              desc: '',
              actionText: 'Tải lại',
              onAction: refreshNotifications,
            )
          else if (items.isEmpty)
            _noticeBox(
              icon: userMode ? Icons.notifications_none_rounded : Icons.campaign_rounded,
              title: emptyTitle,
              desc: '',
            )
          else
            ...items.map(_notificationCard),
        ],
      ),
    );
  }

  Widget _noticeBox({
    required IconData icon,
    required String title,
    String desc = '',
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xffe5e7eb))),
      child: Column(
        children: [
          Icon(icon, size: 54, color: const Color(0xff94a3b8)),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w700, height: 1.4)),
          ],
          if (actionText != null && onAction != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionText)),
          ],
        ],
      ),
    );
  }

  Widget _notificationCard(AppNotificationItem item) {
    final color = item.isUrgent ? const Color(0xffdc2626) : const Color(0xff2563eb);
    final title = item.title.isEmpty ? 'Thông báo' : item.title;
    final moduleText = item.system ? 'Hệ thống' : (item.moduleLabel.isNotEmpty ? item.moduleLabel : 'Thông báo');
    final timeText = item.timeText.isNotEmpty ? item.timeText : item.time;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe5e7eb)),
        boxShadow: const [BoxShadow(color: Color(0x080f172a), blurRadius: 12, offset: Offset(0, 5))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openNotification(item),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(14)),
                child: Icon(item.system ? Icons.campaign_rounded : Icons.notifications_active_rounded, color: color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xff0f172a), height: 1.25))),
                        if (!item.system && item.count > 1)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xffffe4e6), borderRadius: BorderRadius.circular(999)),
                            child: Text('+${item.count}', style: const TextStyle(color: Color(0xffbe123c), fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                      ],
                    ),
                    if (item.message.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(item.message, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xff475569), fontSize: 12.5, height: 1.42, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xfff1f5f9), borderRadius: BorderRadius.circular(8)),
                          child: Text(moduleText, style: const TextStyle(color: Color(0xff475569), fontSize: 11, fontWeight: FontWeight.w900)),
                        ),
                        const Spacer(),
                        if (timeText.isNotEmpty)
                          Text(timeText, style: const TextStyle(color: Color(0xff64748b), fontSize: 11, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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
              child: Text(unreadCount > 99 ? '99+' : '$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
            ),
          ),
      ],
    );
  }
}
