import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/app_shell.dart';
import 'login_screen.dart';

String _dinhDang(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  String hai(int n) => n.toString().padLeft(2, '0');
  return '${hai(d.day)}/${hai(d.month)}/${d.year} ${hai(d.hour)}:${hai(d.minute)}:${hai(d.second)}';
}

num _so(dynamic v) => v is num ? v : (num.tryParse('$v') ?? 0);

const Color _navy = Color(0xFF111A33);

TextStyle _serif(double size, {Color color = _navy, FontWeight? w}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    color: color,
    fontWeight: w,
  );
}

/// Tiêu đề lớn có gạch cam bên dưới
Widget _tieuDeMuc(String t) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(t, style: _serif(26)),
      const SizedBox(height: 8),
      Container(width: 44, height: 3, color: AppTheme.cam),
      const SizedBox(height: 16),
    ],
  );
}

/// Thẻ trắng bo góc, đổ bóng nhẹ
BoxDecoration _kieuThe() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 10,
        offset: const Offset(0, 3),
      ),
    ],
  );
}

ButtonStyle _nutCam() => FilledButton.styleFrom(
      backgroundColor: AppTheme.cam,
      foregroundColor: _navy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        fontSize: 13,
      ),
    );

ButtonStyle _nutVien() => OutlinedButton.styleFrom(
      foregroundColor: _navy,
      side: const BorderSide(color: _navy),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        fontSize: 12,
      ),
    );

/// Đầu trang: tiêu đề có gạch cam + nút cam bên phải
Widget _dauTrang(
  String tieuDe, {
  required String nhanNut,
  required IconData icon,
  required VoidCallback onNut,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _tieuDeMuc(tieuDe)),
        const SizedBox(width: 12),
        FilledButton.icon(
          style: _nutCam(),
          onPressed: onNut,
          icon: Icon(icon, size: 18),
          label: Text(nhanNut),
        ),
      ],
    ),
  );
}

/// Một dòng danh sách: vòng tròn icon, tiêu đề, mô tả, phần bên phải
Widget _theDong({
  required IconData icon,
  required Color mau,
  required String tieuDe,
  required String moTa,
  Widget? hau,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: _kieuThe(),
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: mau.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: mau, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tieuDe, style: _serif(18, w: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                moTa,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        if (hau != null) ...[const SizedBox(width: 12), hau],
      ],
    ),
  );
}

/// Nhãn trạng thái nhỏ, viền màu
Widget _nhanTT(String t, Color mau) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: mau.withValues(alpha: 0.08),
      border: Border.all(color: mau),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      t.toUpperCase(),
      style: TextStyle(
        color: mau,
        fontSize: 11.5,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.8,
      ),
    ),
  );
}

class _Loi extends StatelessWidget {
  final VoidCallback onThuLai;
  const _Loi({required this.onThuLai});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Không tải được dữ liệu'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onThuLai, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _KhungLoi extends StatelessWidget {
  final String text;
  final bool thanhCong;
  const _KhungLoi(this.text, {this.thanhCong = false});

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    final nen = thanhCong
        ? Colors.green.withValues(alpha: 0.12)
        : mau.errorContainer;
    final chu = thanhCong ? Colors.green.shade800 : mau.onErrorContainer;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: nen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            thanhCong ? Icons.check_circle : Icons.error_outline,
            color: chu,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: chu))),
        ],
      ),
    );
  }
}

// =============================================================== Khung chính

class QuanTriScreen extends StatefulWidget {
  const QuanTriScreen({super.key});

  @override
  State<QuanTriScreen> createState() => _QuanTriScreenState();
}

class _QuanTriScreenState extends State<QuanTriScreen> {
  int _tab = 0;

  Future<void> _dangXuat() async {
    await ApiService.dangXuat();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final noiDung = [
      const _TabTongQuan(),
      const _TabNhanVien(),
      const _TabCuDan(),
      const _TabTu(),
      const _TabCanHo(),
      const _TabAudit(),
      const _TabCauHinh(),
      const _TabTaiKhoan(),
    ][_tab];
    return AppShell(
      muc: const [
        MucDieuHuong('Tổng quan', Icons.dashboard_outlined),
        MucDieuHuong('Nhân viên', Icons.badge_outlined),
        MucDieuHuong('Cư dân', Icons.people_outline),
        MucDieuHuong('Tủ locker', Icons.view_module_outlined),
        MucDieuHuong('Căn hộ', Icons.apartment_outlined),
        MucDieuHuong('Nhật ký', Icons.fact_check_outlined),
        MucDieuHuong('Cấu hình', Icons.settings_outlined),
        MucDieuHuong('Tài khoản', Icons.manage_accounts_outlined),
      ],
      chon: _tab,
      onChon: (i) => setState(() => _tab = i),
      onDangXuat: _dangXuat,
      phuDe: 'Quản trị viên',
      noiDung: noiDung,
    );
  }
}

// ------------------------------------------------------------- Tổng quan

class _TabTongQuan extends StatefulWidget {
  const _TabTongQuan();

  @override
  State<_TabTongQuan> createState() => _TabTongQuanState();
}

class _TabTongQuanState extends State<_TabTongQuan> {
  late Future<List<dynamic>> _future;

  Future<List<dynamic>> _tai() => Future.wait([
        ApiService.layDuLieu('/api/admin/dashboard/tong-quan'),
        ApiService.layDuLieu('/api/admin/dashboard/thong-ke-tu'),
      ]);

  @override
  void initState() {
    super.initState();
    _future = _tai();
  }

  Future<void> _taiLai() async {
    setState(() => _future = _tai());
    try {
      await _future;
    } catch (_) {}
  }

  Widget _the(String nhan, dynamic giaTri, IconData icon, Color mau) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
      decoration: _kieuThe(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              Icon(icon, color: mau, size: 20),
            ],
          ),
          Text('${_so(giaTri)}', style: _serif(36)),
          const SizedBox(height: 4),
          Text(
            nhan,
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || snap.data == null) return _Loi(onThuLai: _taiLai);

        var tq = snap.data![0];
        if (tq is List && tq.isNotEmpty) tq = tq.first;
        final m = (tq is Map) ? tq : <dynamic, dynamic>{};
        final tu = (snap.data![1] as List?) ?? [];

        final cacThe = <(String, dynamic, IconData, Color)>[
          ('Chờ nhận', m['buu_kien_cho_nhan'], Icons.schedule, Colors.blue),
          (
            'Quá hạn',
            m['buu_kien_qua_han'],
            Icons.warning_amber_rounded,
            Colors.deepOrange
          ),
          (
            'Ngăn đang dùng',
            m['ngan_dang_dung'],
            Icons.lock_outline,
            AppTheme.chinh
          ),
          ('Ngăn trống', m['ngan_trong'], Icons.lock_open, Colors.green),
          ('Số tủ', m['so_tu'], Icons.view_module_outlined, Colors.teal),
          ('Cư dân', m['so_cu_dan'], Icons.people_outline, Colors.indigo),
          ('Nhân viên', m['so_nhan_vien'], Icons.badge_outlined, Colors.brown),
          (
            'Thao tác hôm nay',
            m['thao_tac_hom_nay'],
            Icons.history,
            Colors.pink
          ),
        ];

        return RefreshIndicator(
          onRefresh: _taiLai,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              // Cụm Banner + 2 ảnh dọc toanha3.jpg & toanha4.jpg
              SizedBox(
                height: 240,
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: const DecorationImage(
                            image: AssetImage('assets/images/toanha5.jpg'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                _navy.withValues(alpha: 0.92),
                                _navy.withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                'LAVITHOR RESIDENCE',
                                style: TextStyle(
                                  color: AppTheme.cam,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Hệ thống Quản trị Bưu kiện',
                                style: _serif(
                                  28,
                                  color: Colors.white,
                                  w: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Giám sát tủ locker, căn hộ và cư dân theo thời gian thực.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/toanha3.jpg',
                          height: 240,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/toanha4.jpg',
                          height: 240,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _tieuDeMuc('Tổng quan hệ thống'),
              LayoutBuilder(
                builder: (context, c) {
                  final cot = c.maxWidth >= 700 ? 4 : 2;
                  final w = (c.maxWidth - 12 * (cot - 1)) / cot;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final t in cacThe)
                        SizedBox(width: w, child: _the(t.$1, t.$2, t.$3, t.$4)),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),
              _tieuDeMuc('Tình trạng từng tủ'),
              ...tu.map((t) {
                final x = t as Map;
                final tong = _so(x['tong_ngan']);
                final dung = _so(x['dang_dung']);
                final tiLe = tong == 0 ? 0.0 : (dung / tong).toDouble();
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: _kieuThe(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${x['ma_tu']}',
                            style: _serif(20, w: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${x['vi_tri']}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          ),
                          Text(
                            '${(tiLe * 100).round()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _navy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: tiLe,
                          minHeight: 8,
                          color: AppTheme.cam,
                          backgroundColor: AppTheme.nen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Đang dùng $dung / $tong ngăn  ·  Trống ${_so(x['con_trong'])}  ·  Hỏng ${_so(x['hong'])}',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ------------------------------------------------------------- Nhân viên

class _TabNhanVien extends StatefulWidget {
  const _TabNhanVien();

  @override
  State<_TabNhanVien> createState() => _TabNhanVienState();
}

class _TabNhanVienState extends State<_TabNhanVien> {
  static const _duongDan = '/api/admin/nhan-vien';
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.layDuLieu(_duongDan);
  }

  Future<void> _taiLai() async {
    setState(() => _future = ApiService.layDuLieu(_duongDan));
    try {
      await _future;
    } catch (_) {}
  }

  void _thongBao(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _them() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _HopThoaiThemNhanVien(),
    );
    if (ok == true) {
      _thongBao('Đã thêm nhân viên mới');
      _taiLai();
    }
  }

  Future<void> _khoa(Map nv) async {
    final dangKhoa = nv['trang_thai'] == 'KHOA';
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dangKhoa ? 'Mở khóa tài khoản?' : 'Khóa tài khoản?'),
        content: Text(
          dangKhoa
              ? '${nv['ho_ten']} sẽ đăng nhập lại được.'
              : '${nv['ho_ten']} sẽ không đăng nhập được cho đến khi mở khóa.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (dongY != true) return;
    final kq = await ApiService.suaJson(
      '$_duongDan/${nv['id']}/khoa',
      {'khoa': !dangKhoa},
    );
    _thongBao(
      kq.ok
          ? (dangKhoa ? 'Đã mở khóa' : 'Đã khóa tài khoản')
          : (kq.loi ?? 'Lỗi'),
    );
    _taiLai();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _dauTrang(
          'Quản lý nhân viên',
          nhanNut: 'THÊM NHÂN VIÊN',
          icon: Icons.person_add_alt_1,
          onNut: _them,
        ),
        Expanded(
          child: FutureBuilder<dynamic>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return _Loi(onThuLai: _taiLai);
              final ds = (snap.data as List?) ?? [];
              return RefreshIndicator(
                onRefresh: _taiLai,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: ds.length,
                  itemBuilder: (context, i) {
                    final nv = ds[i] as Map;
                    final khoa = nv['trang_thai'] == 'KHOA';
                    return _theDong(
                      icon: khoa ? Icons.lock : Icons.badge,
                      mau: khoa ? Colors.red : AppTheme.cam,
                      tieuDe: '${nv['ho_ten']}  (${nv['ma_nhan_vien']})',
                      moTa: 'Tài khoản: ${nv['ten_dang_nhap']}\n'
                          '${nv['chuc_vu'] == 'LE_TAN' ? 'Lễ tân' : 'Bảo vệ'}'
                          ' · Ca ${_tenCa(nv['ca_truc'])}'
                          '${nv['sdt'] != null ? ' · ${nv['sdt']}' : ''}',
                      hau: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (khoa) ...[
                            _nhanTT('Đang bị khóa', Colors.red),
                            const SizedBox(height: 8),
                          ],
                          OutlinedButton(
                            style: _nutVien(),
                            onPressed: () => _khoa(nv),
                            child: Text(khoa ? 'MỞ KHÓA' : 'KHÓA'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _tenCa(dynamic c) {
    switch (c) {
      case 'CHIEU':
        return 'chiều';
      case 'TOI':
        return 'tối';
      default:
        return 'sáng';
    }
  }
}

class _HopThoaiThemNhanVien extends StatefulWidget {
  const _HopThoaiThemNhanVien();

  @override
  State<_HopThoaiThemNhanVien> createState() => _HopThoaiThemNhanVienState();
}

class _HopThoaiThemNhanVienState extends State<_HopThoaiThemNhanVien> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _ten = TextEditingController();
  final _sdt = TextEditingController();
  String _chucVu = 'BAO_VE';
  String _ca = 'SANG';
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _ten.dispose();
    _sdt.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    if (_user.text.trim().length < 3 ||
        _pass.text.length < 6 ||
        _ten.text.trim().isEmpty) {
      setState(() => _loi =
          'Tên đăng nhập tối thiểu 3 ký tự, mật khẩu tối thiểu 6 ký tự, và phải nhập họ tên');
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    final kq = await ApiService.guiJson('/api/admin/nhan-vien', {
      'tenDangNhap': _user.text.trim(),
      'matKhau': _pass.text,
      'hoTen': _ten.text.trim(),
      if (_sdt.text.trim().isNotEmpty) 'sdt': _sdt.text.trim(),
      'chucVu': _chucVu,
      'caTruc': _ca,
    });
    if (!mounted) return;
    if (kq.ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _dangGui = false;
        _loi = kq.loi;
      });
    }
  }

  InputDecoration _kieu(String nhan, IconData icon) => InputDecoration(
        labelText: nhan,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm nhân viên'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loi != null) _KhungLoi(_loi!),
              TextField(
                controller: _ten,
                decoration: _kieu('Họ tên', Icons.badge_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sdt,
                keyboardType: TextInputType.phone,
                decoration: _kieu('Số điện thoại', Icons.phone_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _user,
                decoration: _kieu('Tên đăng nhập', Icons.person_outline),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: _kieu('Mật khẩu (từ 6 ký tự)', Icons.lock_outline),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _chucVu,
                decoration: _kieu('Chức vụ', Icons.work_outline),
                items: const [
                  DropdownMenuItem(value: 'BAO_VE', child: Text('Bảo vệ')),
                  DropdownMenuItem(value: 'LE_TAN', child: Text('Lễ tân')),
                ],
                onChanged: (v) => setState(() => _chucVu = v ?? 'BAO_VE'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _ca,
                decoration: _kieu('Ca trực', Icons.schedule),
                items: const [
                  DropdownMenuItem(value: 'SANG', child: Text('Sáng')),
                  DropdownMenuItem(value: 'CHIEU', child: Text('Chiều')),
                  DropdownMenuItem(value: 'TOI', child: Text('Tối')),
                ],
                onChanged: (v) => setState(() => _ca = v ?? 'SANG'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _dangGui ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _dangGui ? null : _gui,
          child: _dangGui
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Thêm'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- Tủ locker

class _TabTu extends StatefulWidget {
  const _TabTu();

  @override
  State<_TabTu> createState() => _TabTuState();
}

class _TabTuState extends State<_TabTu> {
  static const _duongDan = '/api/admin/tu';
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.layDuLieu(_duongDan);
  }

  Future<void> _taiLai() async {
    setState(() => _future = ApiService.layDuLieu(_duongDan));
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _them() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _HopThoaiThemTu(),
    );
    if (ok == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm tủ mới')),
      );
      _taiLai();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _dauTrang(
          'Quản lý tủ locker',
          nhanNut: 'THÊM TỦ',
          icon: Icons.add_box,
          onNut: _them,
        ),
        Expanded(
          child: FutureBuilder<dynamic>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return _Loi(onThuLai: _taiLai);
              final ds = (snap.data as List?) ?? [];
              return RefreshIndicator(
                onRefresh: _taiLai,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: ds.length,
                  itemBuilder: (context, i) {
                    final t = ds[i] as Map;
                    final coToaDo = t['kinh_do'] != null && t['vi_do'] != null;
                    final baoTri = t['trang_thai'] == 'BAO_TRI';
                    return _theDong(
                      icon: Icons.view_module,
                      mau: AppTheme.cam,
                      tieuDe: '${t['ma_tu']}',
                      moTa: '${t['vi_tri']}\n'
                          '${_so(t['tong_so_ngan'])} ngăn'
                          '${coToaDo ? ' · Có tọa độ bản đồ' : ' · Chưa có tọa độ'}',
                      hau: _nhanTT(
                        baoTri ? 'Bảo trì' : 'Hoạt động',
                        baoTri ? Colors.orange : Colors.green,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HopThoaiThemTu extends StatefulWidget {
  const _HopThoaiThemTu();

  @override
  State<_HopThoaiThemTu> createState() => _HopThoaiThemTuState();
}

class _HopThoaiThemTuState extends State<_HopThoaiThemTu> {
  final _ma = TextEditingController();
  final _viTri = TextEditingController();
  final _kinh = TextEditingController(text: '106.7010');
  final _vi = TextEditingController(text: '10.7770');
  final _s = TextEditingController(text: '4');
  final _m = TextEditingController(text: '4');
  final _l = TextEditingController(text: '4');
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    for (final c in [_ma, _viTri, _kinh, _vi, _s, _m, _l]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _gui() async {
    final ma = _ma.text.trim();
    final s = int.tryParse(_s.text.trim());
    final m = int.tryParse(_m.text.trim());
    final l = int.tryParse(_l.text.trim());
    final kinh = double.tryParse(_kinh.text.trim());
    final vi = double.tryParse(_vi.text.trim());
    if (!RegExp(r'^[A-Za-z0-9-]{3,10}$').hasMatch(ma) ||
        _viTri.text.trim().isEmpty) {
      setState(() => _loi =
          'Mã tủ gồm 3-10 ký tự chữ, số hoặc dấu gạch (ví dụ TU-D) và phải nhập vị trí');
      return;
    }
    if (s == null || m == null || l == null || kinh == null || vi == null) {
      setState(() => _loi = 'Số ngăn và tọa độ phải là số hợp lệ');
      return;
    }
    if (s + m + l < 1) {
      setState(() => _loi = 'Tủ phải có ít nhất 1 ngăn');
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    final kq = await ApiService.guiJson('/api/admin/tu', {
      'maTu': ma,
      'viTri': _viTri.text.trim(),
      'kinhDo': kinh,
      'viDo': vi,
      'soNganS': s,
      'soNganM': m,
      'soNganL': l,
    });
    if (!mounted) return;
    if (kq.ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _dangGui = false;
        _loi = kq.loi;
      });
    }
  }

  InputDecoration _kieu(String nhan, [IconData? icon]) => InputDecoration(
        labelText: nhan,
        prefixIcon: icon == null ? null : Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  Widget _oSo(TextEditingController c, String nhan) => Expanded(
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: _kieu(nhan),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm tủ locker'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loi != null) _KhungLoi(_loi!),
              TextField(
                controller: _ma,
                textCapitalization: TextCapitalization.characters,
                decoration: _kieu('Mã tủ (ví dụ TU-D)', Icons.qr_code_2),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _viTri,
                decoration: _kieu('Vị trí', Icons.place_outlined),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _oSo(_kinh, 'Kinh độ'),
                  const SizedBox(width: 10),
                  _oSo(_vi, 'Vĩ độ'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _oSo(_s, 'Ngăn S'),
                  const SizedBox(width: 10),
                  _oSo(_m, 'Ngăn M'),
                  const SizedBox(width: 10),
                  _oSo(_l, 'Ngăn L'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Mã ngăn tự đặt theo tủ (ví dụ D-01, D-02...).',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _dangGui ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _dangGui ? null : _gui,
          child: _dangGui
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Thêm tủ'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- Nhật ký audit

class _TabAudit extends StatefulWidget {
  const _TabAudit();

  @override
  State<_TabAudit> createState() => _TabAuditState();
}

class _TabAuditState extends State<_TabAudit> {
  String? _loc;
  late Future<dynamic> _future;

  static const _hanhDong = <String?, String>{
    null: 'Tất cả',
    'DANG_NHAP': 'Đăng nhập',
    'DANG_NHAP_THAT_BAI': 'Đăng nhập thất bại',
    'TIEP_NHAN_BUU_KIEN': 'Tiếp nhận',
    'TAO_MA_NHAN': 'Tạo mã nhận',
    'NHAP_MA_NHAN_THAT_BAI': 'Nhập mã sai',
    'SU_DUNG_MA_NHAN': 'Dùng mã nhận',
    'DOI_TRANG_THAI': 'Đổi trạng thái',
    'TAO_NHAN_VIEN': 'Thêm nhân viên',
    'KHOA_TAI_KHOAN': 'Khóa tài khoản',
    'TAO_TU_LOCKER': 'Thêm tủ',
    'SUA_CAU_HINH_KHO': 'Sửa cấu hình',
    'MO_KHOA_TAI_KHOAN': 'Mở khóa tài khoản',
    'TAO_CU_DAN': 'Thêm cư dân',
    'GAN_CAN_HO': 'Gắn căn hộ',
    'CU_DAN_CHUYEN_DI': 'Cư dân chuyển đi',
    'TAO_CAN_HO': 'Thêm căn hộ',
  };

  String get _duongDan {
    final q = StringBuffer('/api/admin/nhat-ky-audit?limit=50');
    if (_loc != null) q.write('&hanhDong=${Uri.encodeQueryComponent(_loc!)}');
    return q.toString();
  }

  @override
  void initState() {
    super.initState();
    _future = ApiService.layDuLieu(_duongDan);
  }

  Future<void> _taiLai() async {
    setState(() => _future = ApiService.layDuLieu(_duongDan));
    try {
      await _future;
    } catch (_) {}
  }

  (Color, IconData) _kieu(String? h) {
    switch (h) {
      case 'DANG_NHAP_THAT_BAI':
      case 'NHAP_MA_NHAN_THAT_BAI':
        return (Colors.red, Icons.gpp_bad_outlined);
      case 'TIEP_NHAN_BUU_KIEN':
        return (Colors.blue, Icons.add_box_outlined);
      case 'SU_DUNG_MA_NHAN':
        return (Colors.green, Icons.lock_open);
      case 'SUA_CAU_HINH_KHO':
      case 'TAO_NHAN_VIEN':
      case 'KHOA_TAI_KHOAN':
      case 'TAO_TU_LOCKER':
      case 'MO_KHOA_TAI_KHOAN':
      case 'TAO_CU_DAN':
      case 'GAN_CAN_HO':
      case 'CU_DAN_CHUYEN_DI':
      case 'TAO_CAN_HO':
        return (AppTheme.chinh, Icons.admin_panel_settings_outlined);
      default:
        return (Colors.blueGrey, Icons.history);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: _hanhDong.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                label: Text(e.value),
                selected: _loc == e.key,
                onSelected: (_) {
                debugPrint('LOC: ${e.key}');
                setState(() => _loc = e.key);
                _taiLai();
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: FutureBuilder<dynamic>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return _Loi(onThuLai: _taiLai);
              final ds = (snap.data as List?) ?? [];
              return RefreshIndicator(
                onRefresh: _taiLai,
                child: ds.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 100),
                          Center(child: Text('Không có bản ghi nào')),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: ds.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final a = ds[i] as Map;
                          final (mau, icon) = _kieu(a['hanh_dong']?.toString());
                          final chiTiet = a['chi_tiet'];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: mau.withValues(alpha: 0.12),
                                child: Icon(icon, color: mau),
                              ),
                              title: Text(
                                '${a['hanh_dong']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                '${a['nguoi_thao_tac']} (${a['vai_tro']})'
                                '${chiTiet != null ? '\n$chiTiet' : ''}'
                                '\n${_dinhDang(a['thoi_gian']?.toString())}'
                                '${a['dia_chi_ip'] != null ? '  ·  IP ${a['dia_chi_ip']}' : ''}',
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- Cấu hình kho

class _TabCauHinh extends StatefulWidget {
  const _TabCauHinh();

  @override
  State<_TabCauHinh> createState() => _TabCauHinhState();
}

class _TabCauHinhState extends State<_TabCauHinh> {
  final _ngay = TextEditingController();
  final _phi = TextEditingController();
  final _gio = TextEditingController();
  bool _dangTai = true;
  bool _dangLuu = false;
  String? _loi;
  String? _ok;

  @override
  void initState() {
    super.initState();
    _tai();
  }

  @override
  void dispose() {
    _ngay.dispose();
    _phi.dispose();
    _gio.dispose();
    super.dispose();
  }

  dynamic _lay(Map m, List<String> khoa) {
    for (final k in khoa) {
      if (m[k] != null) return m[k];
    }
    return null;
  }

  Future<void> _tai() async {
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    try {
      var d = await ApiService.layDuLieu('/api/admin/cau-hinh-kho');
      if (d is List && d.isNotEmpty) d = d.first;
      if (d is! Map) throw Exception('Dữ liệu không hợp lệ');
      _ngay.text = '${_so(_lay(d, ['soNgayMienPhi', 'so_ngay_mien_phi']))}';
      _phi.text =
          '${_so(_lay(d, ['phiQuaHanMoiNgay', 'phi_qua_han_moi_ngay']))}';
      _gio.text = '${_so(_lay(d, ['soGioHieuLucMa', 'so_gio_hieu_luc_ma']))}';
      setState(() => _dangTai = false);
    } catch (_) {
      setState(() {
        _dangTai = false;
        _loi = 'Không tải được cấu hình';
      });
    }
  }

  Future<void> _luu() async {
    final ngay = int.tryParse(_ngay.text.trim());
    final phi = int.tryParse(_phi.text.trim());
    final gio = int.tryParse(_gio.text.trim());
    if (ngay == null ||
        phi == null ||
        gio == null ||
        ngay < 0 ||
        phi < 0 ||
        gio <= 0) {
      setState(() {
        _loi = 'Vui lòng nhập số nguyên hợp lệ (số giờ hiệu lực phải lớn hơn 0)';
        _ok = null;
      });
      return;
    }
    setState(() {
      _dangLuu = true;
      _loi = null;
      _ok = null;
    });
    final kq = await ApiService.suaJson('/api/admin/cau-hinh-kho', {
      'soNgayMienPhi': ngay,
      'phiQuaHanMoiNgay': phi,
      'soGioHieuLucMa': gio,
    });
    if (!mounted) return;
    setState(() {
      _dangLuu = false;
      if (kq.ok) {
        _ok = 'Đã lưu cấu hình. Thao tác này được ghi vào nhật ký.';
      } else {
        _loi = kq.loi;
      }
    });
  }

  Widget _o(TextEditingController c, String nhan, IconData icon, String hau) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: c,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: nhan,
          prefixIcon: Icon(icon),
          suffixText: hau,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _tieuDeMuc('Cấu hình kho bưu kiện'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cột trái: Form cấu hình
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _kieuThe(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _o(
                        _ngay,
                        'Số ngày lưu miễn phí',
                        Icons.calendar_today,
                        'ngày',
                      ),
                      _o(
                        _phi,
                        'Phí quá hạn mỗi ngày',
                        Icons.payments_outlined,
                        'đồng',
                      ),
                      _o(
                        _gio,
                        'Hiệu lực của mã nhận',
                        Icons.timer_outlined,
                        'giờ',
                      ),
                      if (_loi != null) _KhungLoi(_loi!),
                      if (_ok != null) _KhungLoi(_ok!, thanhCong: true),
                      SizedBox(
                        height: 50,
                        child: FilledButton.icon(
                          style: _nutCam(),
                          onPressed: _dangLuu ? null : _luu,
                          icon: _dangLuu
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black54,
                                  ),
                                )
                              : const Icon(Icons.save, size: 18),
                          label: const Text('LƯU CẤU HÌNH'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Cột phải: 2 thẻ ảnh dọc toanha3.jpg & toanha4.jpg
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/toanha3.jpg',
                          height: 340,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/toanha4.jpg',
                          height: 340,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- Căn hộ

class _TabCanHo extends StatefulWidget {
  const _TabCanHo();

  @override
  State<_TabCanHo> createState() => _TabCanHoState();
}

class _TabCanHoState extends State<_TabCanHo> {
  static const _duongDan = '/api/admin/can-ho';
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.layDuLieu(_duongDan);
  }

  Future<void> _taiLai() async {
    setState(() => _future = ApiService.layDuLieu(_duongDan));
    try {
      await _future;
    } catch (_) {}
  }

  Future<void> _them() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _HopThoaiThemCanHo(),
    );
    if (ok == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm căn hộ mới')),
      );
      _taiLai();
    }
  }

  dynamic _lay(Map m, List<String> khoa) {
    for (final k in khoa) {
      if (m[k] != null) return m[k];
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _dauTrang(
          'Quản lý căn hộ',
          nhanNut: 'THÊM CĂN HỘ',
          icon: Icons.add_home_outlined,
          onNut: _them,
        ),
        Expanded(
          child: FutureBuilder<dynamic>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return _Loi(onThuLai: _taiLai);
              final ds = (snap.data as List?) ?? [];
              return RefreshIndicator(
                onRefresh: _taiLai,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: ds.length,
                  itemBuilder: (context, i) {
                    final c = ds[i] as Map;
                    final coNguoi = _lay(c, ['trang_thai']) == 'CO_NGUOI_O';
                    final soCuDan = _so(_lay(c, ['so_cu_dan']));
                    return _theDong(
                      icon: Icons.apartment,
                      mau: coNguoi ? AppTheme.cam : Colors.grey,
                      tieuDe: '${_lay(c, ['so_can_ho']) ?? ''}',
                      moTa: 'Tòa ${_lay(c, ['toa_nha']) ?? '-'}'
                          ' · Tầng ${_lay(c, ['tang']) ?? '-'}'
                          '\n$soCuDan cư dân đang ở',
                      hau: _nhanTT(
                        coNguoi ? 'Có người ở' : 'Trống',
                        coNguoi ? Colors.green : Colors.grey,
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HopThoaiThemCanHo extends StatefulWidget {
  const _HopThoaiThemCanHo();

  @override
  State<_HopThoaiThemCanHo> createState() => _HopThoaiThemCanHoState();
}

class _HopThoaiThemCanHoState extends State<_HopThoaiThemCanHo> {
  final _so = TextEditingController();
  final _tang = TextEditingController();
  final _toa = TextEditingController();
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _so.dispose();
    _tang.dispose();
    _toa.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    final tang = int.tryParse(_tang.text.trim());
    if (_so.text.trim().isEmpty || _toa.text.trim().isEmpty || tang == null) {
      setState(() => _loi =
          'Phải nhập số căn hộ (ví dụ D-0101), tòa nhà và tầng (là số)');
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    final kq = await ApiService.guiJson('/api/admin/can-ho', {
      'soCanHo': _so.text.trim(),
      'tang': tang,
      'toaNha': _toa.text.trim(),
    });
    if (!mounted) return;
    if (kq.ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _dangGui = false;
        _loi = kq.loi;
      });
    }
  }

  InputDecoration _kieu(String nhan, IconData icon) => InputDecoration(
        labelText: nhan,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm căn hộ'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loi != null) _KhungLoi(_loi!),
              TextField(
                controller: _so,
                textCapitalization: TextCapitalization.characters,
                decoration: _kieu(
                  'Số căn hộ (ví dụ D-0101)',
                  Icons.meeting_room_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _toa,
                textCapitalization: TextCapitalization.characters,
                decoration: _kieu('Tòa nhà (ví dụ D)', Icons.apartment),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tang,
                keyboardType: TextInputType.number,
                decoration: _kieu('Tầng', Icons.stairs_outlined),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _dangGui ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _dangGui ? null : _gui,
          child: _dangGui
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Thêm'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- Cư dân

class _TabCuDan extends StatefulWidget {
  const _TabCuDan();

  @override
  State<_TabCuDan> createState() => _TabCuDanState();
}

class _TabCuDanState extends State<_TabCuDan> {
  static const _duongDan = '/api/admin/cu-dan';
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.layDuLieu(_duongDan);
  }

  Future<void> _taiLai() async {
    setState(() => _future = ApiService.layDuLieu(_duongDan));
    try {
      await _future;
    } catch (_) {}
  }

  void _thongBao(String s) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  Future<void> _them() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _HopThoaiThemCuDan(),
    );
    if (ok == true) {
      _thongBao('Đã thêm cư dân mới');
      _taiLai();
    }
  }

  Future<void> _ganCanHo(Map cd) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _HopThoaiGanCanHo(
        cuDanId: cd['id'],
        hoTen: '${cd['ho_ten']}',
      ),
    );
    if (ok == true) {
      _thongBao('Đã gắn căn hộ cho ${cd['ho_ten']}');
      _taiLai();
    }
  }

  Future<void> _chuyenDi(Map cd) async {
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận chuyển đi?'),
        content: Text(
          '${cd['ho_ten']} sẽ kết thúc cư trú tại ${cd['can_ho_dang_o'] ?? 'căn hộ hiện tại'} '
          'và tài khoản sẽ bị khóa. Dữ liệu và lịch sử vẫn được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Chuyển đi'),
          ),
        ],
      ),
    );
    if (dongY != true) return;
    final kq = await ApiService.guiJson('$_duongDan/${cd['id']}/chuyen-di');
    if (!mounted) return;
    if (!kq.ok) {
      _thongBao(kq.loi ?? 'Lỗi');
      return;
    }
    final d = kq.data;
    final soBuuKien = d is Map ? _so(d['buuKienKhongNguoiNhan']).toInt() : 0;
    if (soBuuKien > 0) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.cam,
            size: 40,
          ),
          title: const Text('Còn bưu kiện chưa nhận'),
          content: Text(
            'Căn hộ này không còn ai ở nhưng còn $soBuuKien bưu kiện chưa nhận. '
            'Nhân viên cần xử lý (hoàn trả) khi bưu kiện quá hạn.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu'),
            ),
          ],
        ),
      );
    } else {
      _thongBao('Đã cho ${cd['ho_ten']} chuyển đi');
    }
    _taiLai();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _dauTrang(
          'Quản lý cư dân',
          nhanNut: 'THÊM CƯ DÂN',
          icon: Icons.person_add_alt_1,
          onNut: _them,
        ),
        Expanded(
          child: FutureBuilder<dynamic>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return _Loi(onThuLai: _taiLai);
              final ds = (snap.data as List?) ?? [];
              return RefreshIndicator(
                onRefresh: _taiLai,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: ds.length,
                  itemBuilder: (context, i) {
                    final cd = ds[i] as Map;
                    final khoa = cd['trang_thai'] == 'KHOA';
                    final canHo = cd['can_ho_dang_o'];
                    return _theDong(
                      icon: khoa ? Icons.lock : Icons.person,
                      mau: khoa ? Colors.red : AppTheme.cam,
                      tieuDe: '${cd['ho_ten']}',
                      moTa: 'Tài khoản: ${cd['ten_dang_nhap']}\n'
                          '${canHo != null ? 'Căn hộ: $canHo' : 'Chưa ở căn hộ nào'}'
                          '${cd['sdt'] != null ? ' · ${cd['sdt']}' : ''}\n'
                          'Email: ${cd['email'] ?? 'chưa có'}',
                      hau: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (khoa) _nhanTT('Đã chuyển đi', Colors.red),
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'gan') _ganCanHo(cd);
                              if (v == 'di') _chuyenDi(cd);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'gan',
                                child: Text('Gắn căn hộ'),
                              ),
                              if (canHo != null)
                                const PopupMenuItem(
                                  value: 'di',
                                  child: Text('Chuyển đi'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HopThoaiGanCanHo extends StatefulWidget {
  final dynamic cuDanId;
  final String hoTen;
  const _HopThoaiGanCanHo({required this.cuDanId, required this.hoTen});

  @override
  State<_HopThoaiGanCanHo> createState() => _HopThoaiGanCanHoState();
}

class _HopThoaiGanCanHoState extends State<_HopThoaiGanCanHo> {
  final _canHo = TextEditingController();
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _canHo.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    if (_canHo.text.trim().isEmpty) {
      setState(() => _loi = 'Vui lòng nhập số căn hộ (ví dụ C-0101)');
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    final kq = await ApiService.guiJson(
      '/api/admin/cu-dan/${widget.cuDanId}/gan-can-ho',
      {'soCanHo': _canHo.text.trim()},
    );
    if (!mounted) return;
    if (kq.ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _dangGui = false;
        _loi = kq.loi;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Gắn căn hộ cho ${widget.hoTen}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loi != null) _KhungLoi(_loi!),
            TextField(
              controller: _canHo,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Số căn hộ (ví dụ C-0101)',
                prefixIcon: const Icon(Icons.meeting_room_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nếu tài khoản đang bị khóa do chuyển đi, hệ thống sẽ mở khóa lại.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _dangGui ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _dangGui ? null : _gui,
          child: _dangGui
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Gắn'),
        ),
      ],
    );
  }
}

class _HopThoaiThemCuDan extends StatefulWidget {
  const _HopThoaiThemCuDan();

  @override
  State<_HopThoaiThemCuDan> createState() => _HopThoaiThemCuDanState();
}

class _HopThoaiThemCuDanState extends State<_HopThoaiThemCuDan> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _ten = TextEditingController();
  final _sdtC = TextEditingController();
  final _mail = TextEditingController();
  final _canHo = TextEditingController();
  String _kenh = 'APP';
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    for (final c in [_user, _pass, _ten, _sdtC, _mail, _canHo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _gui() async {
    if (_user.text.trim().length < 3 ||
        _pass.text.length < 6 ||
        _ten.text.trim().isEmpty ||
        _canHo.text.trim().isEmpty) {
      setState(() => _loi =
          'Tên đăng nhập tối thiểu 3 ký tự, mật khẩu tối thiểu 6 ký tự, phải nhập họ tên và số căn hộ');
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    final kq = await ApiService.guiJson('/api/admin/cu-dan', {
      'tenDangNhap': _user.text.trim(),
      'matKhau': _pass.text,
      'hoTen': _ten.text.trim(),
      if (_sdtC.text.trim().isNotEmpty) 'sdt': _sdtC.text.trim(),
      if (_mail.text.trim().isNotEmpty) 'email': _mail.text.trim(),
      'kenhThongBao': _kenh,
      'soCanHo': _canHo.text.trim(),
    });
    if (!mounted) return;
    if (kq.ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _dangGui = false;
        _loi = kq.loi;
      });
    }
  }

  InputDecoration _kieu(String nhan, IconData icon) => InputDecoration(
        labelText: nhan,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm cư dân'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_loi != null) _KhungLoi(_loi!),
              TextField(
                controller: _ten,
                decoration: _kieu('Họ tên', Icons.person_outline),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sdtC,
                keyboardType: TextInputType.phone,
                decoration: _kieu('Số điện thoại', Icons.phone_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _mail,
                keyboardType: TextInputType.emailAddress,
                decoration: _kieu('Email', Icons.email_outlined),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _canHo,
                textCapitalization: TextCapitalization.characters,
                decoration: _kieu(
                  'Số căn hộ (ví dụ C-0101)',
                  Icons.meeting_room_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _user,
                decoration: _kieu(
                  'Tên đăng nhập',
                  Icons.account_circle_outlined,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pass,
                obscureText: true,
                decoration: _kieu('Mật khẩu (từ 6 ký tự)', Icons.lock_outline),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _kenh,
                decoration: _kieu(
                  'Kênh nhận thông báo',
                  Icons.notifications_none,
                ),
                items: const [
                  DropdownMenuItem(value: 'APP', child: Text('Trong ứng dụng')),
                  DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                  DropdownMenuItem(value: 'EMAIL', child: Text('Email')),
                ],
                onChanged: (v) => setState(() => _kenh = v ?? 'APP'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _dangGui ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _dangGui ? null : _gui,
          child: _dangGui
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Thêm'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------- Tài khoản (email)

class _TabTaiKhoan extends StatefulWidget {
  const _TabTaiKhoan();

  @override
  State<_TabTaiKhoan> createState() => _TabTaiKhoanState();
}

class _TabTaiKhoanState extends State<_TabTaiKhoan> {
  static const _duongDan = '/api/admin/tai-khoan';
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.layDuLieu(_duongDan);
  }

  Future<void> _taiLai() async {
    setState(() => _future = ApiService.layDuLieu(_duongDan));
    try {
      await _future;
    } catch (_) {}
  }

  String _tenVaiTro(dynamic v) {
    switch (v) {
      case 'QUAN_TRI_VIEN':
        return 'Quản trị viên';
      case 'NHAN_VIEN':
        return 'Nhân viên';
      case 'CU_DAN':
        return 'Cư dân';
      case 'SHIPPER':
        return 'Shipper';
      default:
        return '$v';
    }
  }

  Future<void> _suaEmail(Map tk) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _HopThoaiSuaEmail(
        id: tk['id'],
        tenDangNhap: '${tk['ten_dang_nhap']}',
        emailHienTai: tk['email']?.toString() ?? '',
      ),
    );
    if (ok == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật email')),
      );
      _taiLai();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: _tieuDeMuc('Tài khoản và email'),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            'Email dùng để gửi mã OTP khi quên mật khẩu. Tài khoản chưa có email sẽ không đặt lại được mật khẩu.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
        Expanded(
          child: FutureBuilder<dynamic>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) return _Loi(onThuLai: _taiLai);
              final ds = (snap.data as List?) ?? [];
              return RefreshIndicator(
                onRefresh: _taiLai,
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: ds.length,
                  itemBuilder: (context, i) {
                    final tk = ds[i] as Map;
                    final khoa = tk['trang_thai'] == 'KHOA';
                    final email = tk['email']?.toString();
                    final coEmail = email != null && email.isNotEmpty;
                    final hoTen = tk['ho_ten']?.toString();
                    return _theDong(
                      icon: khoa ? Icons.lock : Icons.account_circle_outlined,
                      mau: khoa ? Colors.red : AppTheme.cam,
                      tieuDe: '${tk['ten_dang_nhap']}',
                      moTa: '${_tenVaiTro(tk['vai_tro'])}'
                          '${hoTen != null ? ' · $hoTen' : ''}\n'
                          'Email: ${coEmail ? email : 'chưa có'}',
                      hau: OutlinedButton(
                        style: _nutVien(),
                        onPressed: () => _suaEmail(tk),
                        child: Text(coEmail ? 'SỬA EMAIL' : 'THÊM EMAIL'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HopThoaiSuaEmail extends StatefulWidget {
  final dynamic id;
  final String tenDangNhap;
  final String emailHienTai;
  const _HopThoaiSuaEmail({
    required this.id,
    required this.tenDangNhap,
    required this.emailHienTai,
  });

  @override
  State<_HopThoaiSuaEmail> createState() => _HopThoaiSuaEmailState();
}

class _HopThoaiSuaEmailState extends State<_HopThoaiSuaEmail> {
  late final TextEditingController _email;
  bool _dangGui = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.emailHienTai);
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    final e = _email.text.trim();
    if (e.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      setState(() => _loi = 'Email không đúng định dạng');
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    final kq = await ApiService.suaJson(
      '/api/admin/tai-khoan/${widget.id}/email',
      {'email': e},
    );
    if (!mounted) return;
    if (kq.ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _dangGui = false;
        _loi = kq.loi;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Email của ${widget.tenDangNhap}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loi != null) _KhungLoi(_loi!),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _gui(),
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Để trống rồi bấm Lưu nếu muốn xóa email của tài khoản này.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _dangGui ? null : () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _dangGui ? null : _gui,
          child: _dangGui
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}