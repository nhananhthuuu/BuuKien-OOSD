import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

class MucDieuHuong {
  final String nhan;
  final IconData icon;
  const MucDieuHuong(this.nhan, this.icon);
}

class AppShell extends StatelessWidget {
  final List<MucDieuHuong> muc;
  final int chon;
  final ValueChanged<int> onChon;
  final VoidCallback onDangXuat;
  final Widget noiDung;
  final String phuDe;
  final ValueChanged<String>? onTim;
  final String goiYTim;

  const AppShell({
    super.key,
    required this.muc,
    required this.chon,
    required this.onChon,
    required this.onDangXuat,
    required this.noiDung,
    required this.phuDe,
    this.onTim,
    this.goiYTim = 'Tìm kiếm',
  });

  static const double _rong = 900;

  Widget _oTim() {
    return TextField(
      onChanged: onTim,
      decoration: InputDecoration(
        hintText: goiYTim,
        prefixIcon: const Icon(Icons.search),
        isDense: true,
        filled: true,
        fillColor: AppTheme.nen,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _tieuDe() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: onTim == null
                ? const SizedBox()
                : Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _oTim(),
                    ),
                  ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Xin chào, ${ApiService.tenDangNhap ?? ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(phuDe,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thanhBen() {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Quản lý bưu kiện\ntòa nhà thông minh',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.chinh,
                      fontSize: 15)),
            ),
          ),
          const Divider(height: 1),
          for (int i = 0; i < muc.length; i++) _mucBen(i),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Đăng xuất'),
            onTap: onDangXuat,
          ),
        ],
      ),
    );
  }

  Widget _mucBen(int i) {
    final act = i == chon;
    return InkWell(
      onTap: () => onChon(i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: act ? AppTheme.nen : null,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: act ? AppTheme.cam : null,
                border: Border.all(
                    color: act ? AppTheme.cam : Colors.grey.shade300, width: 2),
              ),
              child: Icon(muc[i].icon,
                  size: 16, color: act ? Colors.white : Colors.grey),
            ),
            const SizedBox(width: 14),
            Text(muc[i].nhan,
                style: TextStyle(
                    fontWeight: act ? FontWeight.w700 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rong = MediaQuery.of(context).size.width >= _rong;
    final phanNoi = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: noiDung,
      ),
    );

    if (rong) {
      return Scaffold(
        body: Row(
          children: [
            _thanhBen(),
            Expanded(
              child: Column(
                children: [
                  _tieuDe(),
                  Expanded(child: phanNoi),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(muc[chon].nhan),
        actions: [
          IconButton(
              tooltip: 'Đăng xuất',
              icon: const Icon(Icons.logout),
              onPressed: onDangXuat),
        ],
      ),
      body: Column(
        children: [
          if (onTim != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: _oTim(),
            ),
          Expanded(child: phanNoi),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: chon,
        onDestinationSelected: onChon,
        destinations: [
          for (final m in muc)
            NavigationDestination(icon: Icon(m.icon), label: m.nhan),
        ],
      ),
    );
  }
}