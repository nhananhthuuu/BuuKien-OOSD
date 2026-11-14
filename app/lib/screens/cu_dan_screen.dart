import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/vi_tri_tu.dart';
import 'login_screen.dart';

/// Ảnh banner trang chủ và ảnh nền thẻ mã nhận. Muốn đổi tấm khác thì đổi số ở đây.
const String kAnhBanner = 'assets/images/toanha5.jpg';
const String kAnhMaNhan = 'assets/images/toanha4.jpg';

const Color _navy = Color(0xFF111A33);
const Color _nen = Color(0xFFF4F5F9);
const Color _beNhat = Color(0xFFFBF3E4);

TextStyle _serif(double size, {Color color = _navy, FontWeight? w}) {
  return TextStyle(
    fontFamily: 'Georgia',
    fontFamilyFallback: const ['Times New Roman', 'serif'],
    fontSize: size,
    color: color,
    fontWeight: w,
  );
}

String _dinhDang(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  String hai(int n) => n.toString().padLeft(2, '0');
  return '${hai(d.day)}/${hai(d.month)}/${d.year} ${hai(d.hour)}:${hai(d.minute)}';
}

String _hms(Duration d) {
  String hai(int n) => n.toString().padLeft(2, '0');
  return '${hai(d.inHours)}:${hai(d.inMinutes % 60)}:${hai(d.inSeconds % 60)}';
}

Widget _anhNen(String duongDan, {Alignment canh = Alignment.center}) {
  return Image.asset(
    duongDan,
    fit: BoxFit.cover,
    alignment: canh,
    filterQuality: FilterQuality.high,
    isAntiAlias: true,
    gaplessPlayback: true,
    errorBuilder: (_, __, ___) => Container(color: AppTheme.chinh),
  );
}

(String, Color, IconData) _trangThai(String? tt) {
  switch (tt) {
    case 'CHO_NHAN':
      return ('Chờ nhận', Colors.blue, Icons.schedule);
    case 'QUA_HAN':
      return ('Quá hạn', Colors.deepOrange, Icons.warning_amber_rounded);
    case 'DA_NHAN':
      return ('Đã nhận', Colors.green, Icons.check_circle_outline);
    case 'DA_XU_LY':
      return ('Đã xử lý', Colors.grey, Icons.undo);
    default:
      return (tt ?? '', Colors.grey, Icons.help_outline);
  }
}

bool _canNhan(Map bk) =>
    bk['trang_thai'] == 'CHO_NHAN' || bk['trang_thai'] == 'QUA_HAN';

bool _sapQuaHan(Map bk) {
  if (bk['trang_thai'] != 'CHO_NHAN') return false;
  final h = DateTime.tryParse('${bk['ngay_het_han_luu']}')?.toLocal();
  if (h == null) return false;
  final con = h.difference(DateTime.now());
  return !con.isNegative && con.inHours < 24;
}

ButtonStyle _nutCam() => FilledButton.styleFrom(
      backgroundColor: AppTheme.cam,
      foregroundColor: _navy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      textStyle: const TextStyle(
          fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13),
    );

ButtonStyle _nutVien() => OutlinedButton.styleFrom(
      foregroundColor: _navy,
      side: const BorderSide(color: _navy),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      textStyle: const TextStyle(
          fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13),
    );

// ============================================================ Màn hình chính

class CuDanScreen extends StatefulWidget {
  const CuDanScreen({super.key});

  @override
  State<CuDanScreen> createState() => _CuDanScreenState();
}

class _CuDanScreenState extends State<CuDanScreen> {
  static const List<(String, IconData, IconData)> _muc = [
    ('Trang chủ', Icons.home_outlined, Icons.home),
    ('Bưu kiện', Icons.inventory_2_outlined, Icons.inventory_2),
    ('Thông báo', Icons.notifications_outlined, Icons.notifications),
    ('Bản đồ', Icons.map_outlined, Icons.map),
  ];

  int _tab = 0;
  final _timCtrl = TextEditingController();
  bool _dangTai = true;
  bool _loi = false;
  List<Map<String, dynamic>> _ds = [];

  @override
  void initState() {
    super.initState();
    _taiDuLieu();
  }

  @override
  void dispose() {
    _timCtrl.dispose();
    super.dispose();
  }

  Future<void> _taiDuLieu() async {
    try {
      final d = await ApiService.layDuLieu('/api/cu-dan/buu-kien');
      if (!mounted) return;
      setState(() {
        _ds = ((d as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _dangTai = false;
        _loi = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dangTai = false;
        _loi = true;
      });
    }
  }

  Future<void> _dangXuat() async {
    await ApiService.dangXuat();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _xemMa(Map<String, dynamic> bk) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManHinhMaNhan(buuKien: bk)),
    );
    _taiDuLieu();
  }

  Future<void> _nhapMa(Map<String, dynamic> bk) async {
    final ketQua = await showDialog<bool>(
      context: context,
      builder: (_) => _HopThoaiNhapMa(
        buuKienId: bk['buu_kien_id'] as int,
        maVanDon: bk['ma_van_don'].toString(),
      ),
    );
    if (ketQua == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nhận bưu kiện thành công! Ngăn tủ đã được mở.')),
      );
      _taiDuLieu();
    }
  }

  List<Map<String, dynamic>> get _dsLoc {
    final q = _timCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _ds;
    return _ds
        .where((b) => b['ma_van_don'].toString().toLowerCase().contains(q))
        .toList();
  }

  // ---------- Thanh tìm kiếm ----------
  Widget _oTim() {
    return TextField(
      controller: _timCtrl,
      onChanged: (v) => setState(() {
        if (v.isNotEmpty && _tab != 1) _tab = 1;
      }),
      decoration: InputDecoration(
        hintText: 'Tìm bưu kiện theo mã vận đơn',
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppTheme.chinh, width: 1.5)),
      ),
    );
  }

  // ---------- Thanh bên (màn rộng) ----------
  Widget _thanhBen() {
    final ten = ApiService.tenDangNhap ?? '';
    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LAVITHOR',
                    style: _serif(22, w: FontWeight.w600)
                        .copyWith(letterSpacing: 4)),
                const SizedBox(height: 6),
                Text('RESIDENCE',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 3.5,
                        color: Colors.grey.shade500)),
              ],
            ),
          ),
          for (var i = 0; i < _muc.length; i++) _mucBen(i),
          const Spacer(),
          Container(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: AppTheme.cam,
                  child: Text(
                      ten.isEmpty ? '?' : ten.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                          color: _navy, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xin chào,',
                          style: TextStyle(
                              fontSize: 10.5, color: Colors.grey.shade600)),
                      Text(ten,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _navy)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Đăng xuất',
                  icon: Icon(Icons.logout, color: Colors.grey.shade600),
                  onPressed: _dangXuat,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mucBen(int i) {
    final chon = _tab == i;
    return InkWell(
      onTap: () => setState(() => _tab = i),
      child: Container(
        color: chon ? _beNhat : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(chon ? _muc[i].$3 : _muc[i].$2,
                size: 19,
                color: chon ? AppTheme.cam : const Color(0xFF4A4F63)),
            const SizedBox(width: 14),
            Text(_muc[i].$1,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: chon ? FontWeight.w700 : FontWeight.w500,
                    color: chon ? AppTheme.cam : _navy)),
          ],
        ),
      ),
    );
  }

  // ---------- Nội dung các tab ----------
  Widget _noiDung() {
    Widget tab;
    switch (_tab) {
      case 0:
        tab = _tuyChonTai(_trangChu());
        break;
      case 1:
        tab = _tuyChonTai(_danhSach());
        break;
      case 2:
        tab = const _TabThongBao();
        break;
      default:
        tab = const ManViTriTu();
    }
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: tab,
      ),
    );
  }

  Widget _tuyChonTai(Widget con) {
    if (_dangTai) return const Center(child: CircularProgressIndicator());
    if (_loi) return _Loi(onThuLai: _taiDuLieu);
    return RefreshIndicator(onRefresh: _taiDuLieu, child: con);
  }

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

  // ---------- Trang chủ ----------
  Widget _trangChu() {
    final ten = ApiService.tenDangNhap ?? '';
    final cho = _ds.where((b) => b['trang_thai'] == 'CHO_NHAN').length;
    final sap = _ds.where(_sapQuaHan).length;
    final da = _ds.where((b) => b['trang_thai'] == 'DA_NHAN').length;
    final dangLuu = _dsLoc.where(_canNhan).toList();

    const bong = [Shadow(color: Colors.black87, blurRadius: 10)];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        // Banner: ảnh nằm sau chữ, KHÔNG phủ lớp mờ
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Muốn lấy khúc khác của ảnh thì đổi số y (-1 là đỉnh ảnh, 1 là đáy ảnh)
                _anhNen(kAnhBanner, canh: const Alignment(0, -0.35)),
                // Dải đen rất nhẹ ở đáy cho chữ dễ đọc. Không thích thì xóa cả Container này.
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.30),
                      ],
                      stops: const [0.0, 0.65, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Xin chào,',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              shadows: bong)),
                      Text(ten,
                          style: _serif(36, color: Colors.white)
                              .copyWith(shadows: bong)),
                      const SizedBox(height: 14),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _navy,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
                            side: BorderSide(color: AppTheme.cam, width: 1),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                              fontSize: 11.5),
                        ),
                        onPressed: () => setState(() => _tab = 1),
                        child: const Text('BƯU KIỆN CỦA TÔI'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, c) {
            final cot = c.maxWidth >= 560 ? 3 : 2;
            final w = (c.maxWidth - 12 * (cot - 1)) / cot;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                    width: w,
                    child: _oSo(
                        'Đang chờ nhận', cho, Icons.schedule, Colors.blue)),
                SizedBox(
                    width: w,
                    child: _oSo('Sắp quá hạn', sap, Icons.hourglass_bottom,
                        Colors.deepOrange)),
                SizedBox(
                    width: w,
                    child: _oSo('Đã nhận', da, Icons.check_circle_outline,
                        Colors.green)),
              ],
            );
          },
        ),
        const SizedBox(height: 28),
        _tieuDeMuc('Bưu kiện đang lưu'),
        if (dangLuu.isEmpty)
          _trong('Hiện không có bưu kiện nào đang chờ bạn nhận.')
        else
          for (final bk in dangLuu) _hangDangLuu(bk),
      ],
    );
  }

  Widget _oSo(String nhan, int so, IconData icon, Color mau) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Spacer(),
              Icon(icon, color: mau, size: 20),
            ],
          ),
          Text('$so', style: _serif(36)),
          const SizedBox(height: 4),
          Text(nhan,
              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _trong(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 44, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text(t,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  Widget _hangDangLuu(Map<String, dynamic> bk) {
    final (_, mau, _) = _trangThai(bk['trang_thai']);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        spacing: 16,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_rounded, color: mau),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bk['ma_van_don'].toString(),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _navy)),
                  Text(
                      'Tủ ${bk['ma_tu'] ?? '-'}, ngăn ${bk['ma_ngan'] ?? '-'}  ·  Hạn lưu ${_dinhDang(bk['ngay_het_han_luu'])}',
                      style: TextStyle(
                          fontSize: 12.5, color: Colors.grey.shade700)),
                ],
              ),
            ],
          ),
          FilledButton(
            style: _nutCam(),
            onPressed: () => _xemMa(bk),
            child: const Text('XEM MÃ NHẬN'),
          ),
        ],
      ),
    );
  }

  // ---------- Danh sách bưu kiện ----------
  Widget _danhSach() {
    final ds = _dsLoc;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        _tieuDeMuc('Bưu kiện của tôi'),
        if (ds.isEmpty)
          _trong(_timCtrl.text.isEmpty
              ? 'Chưa có bưu kiện nào.'
              : 'Không tìm thấy bưu kiện khớp mã vận đơn này.')
        else
          for (final bk in ds) _theBuuKien(bk),
      ],
    );
  }

  Widget _theBuuKien(Map<String, dynamic> bk) {
    final (nhan, mau, icon) = _trangThai(bk['trang_thai']);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(bk['ma_van_don'].toString(),
                    style: _serif(20, w: FontWeight.bold)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: mau.withValues(alpha: 0.08),
                  border: Border.all(color: mau),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 15, color: mau),
                    const SizedBox(width: 5),
                    Text(nhan.toUpperCase(),
                        style: TextStyle(
                            color: mau,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Dong(Icons.place_outlined,
              'Tủ ${bk['ma_tu'] ?? '-'}, ngăn ${bk['ma_ngan'] ?? '-'}'),
          _Dong(Icons.login, 'Đến: ${_dinhDang(bk['ngay_tiep_nhan'])}'),
          _Dong(Icons.event_busy_outlined,
              'Hạn lưu: ${_dinhDang(bk['ngay_het_han_luu'])}'),
          if (bk['ngay_nhan'] != null)
            _Dong(Icons.done_all, 'Đã nhận: ${_dinhDang(bk['ngay_nhan'])}'),
          if (_canNhan(bk)) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton(
                  style: _nutCam(),
                  onPressed: () => _xemMa(bk),
                  child: const Text('XEM MÃ NHẬN'),
                ),
                OutlinedButton(
                  style: _nutVien(),
                  onPressed: () => _nhapMa(bk),
                  child: const Text('NHẬP MÃ'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------- Khung chính ----------
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final rong = c.maxWidth >= 900;
        if (rong) {
          return Scaffold(
            backgroundColor: _nen,
            body: Row(
              children: [
                _thanhBen(),
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                        child: Row(
                          children: [
                            Expanded(child: _oTim()),
                            const SizedBox(width: 12),
                            IconButton(
                              tooltip: 'Tải lại',
                              icon: const Icon(Icons.refresh, color: _navy),
                              onPressed: _taiDuLieu,
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _noiDung()),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        return Scaffold(
          backgroundColor: _nen,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: _navy,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text('LAVITHOR',
                style: _serif(20, w: FontWeight.w600)
                    .copyWith(letterSpacing: 4)),
            actions: [
              IconButton(
                tooltip: 'Đăng xuất',
                icon: const Icon(Icons.logout),
                onPressed: _dangXuat,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _oTim(),
              ),
              Expanded(child: _noiDung()),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            backgroundColor: Colors.white,
            indicatorColor: AppTheme.cam.withValues(alpha: 0.30),
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: [
              for (final m in _muc)
                NavigationDestination(
                    icon: Icon(m.$2), selectedIcon: Icon(m.$3), label: m.$1),
            ],
          ),
        );
      },
    );
  }
}

class _Dong extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Dong(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text, style: TextStyle(color: Colors.grey.shade800))),
        ],
      ),
    );
  }
}

// ============================================================ Màn mã nhận hàng

class ManHinhMaNhan extends StatefulWidget {
  final Map<String, dynamic> buuKien;
  const ManHinhMaNhan({super.key, required this.buuKien});

  @override
  State<ManHinhMaNhan> createState() => _ManHinhMaNhanState();
}

class _ManHinhMaNhanState extends State<ManHinhMaNhan> {
  String? _ma;
  DateTime? _hanDen;
  Duration _conLai = Duration.zero;
  bool _hien = false;
  bool _dang = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _hanDen == null) return;
      final con = _hanDen!.difference(DateTime.now());
      setState(() {
        if (con.isNegative) {
          _ma = null;
          _hanDen = null;
          _hien = false;
          _conLai = Duration.zero;
        } else {
          _conLai = con;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _baoLoi(String t) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));
  }

  Future<bool> _taoMa() async {
    setState(() => _dang = true);
    final kq = await ApiService.guiJson(
        '/api/cu-dan/buu-kien/${widget.buuKien['buu_kien_id']}/lay-ma');
    if (!mounted) return false;
    if (!kq.ok || kq.data is! Map) {
      setState(() => _dang = false);
      _baoLoi(kq.loi ?? 'Không tạo được mã');
      return false;
    }
    final d = kq.data as Map;
    final han = DateTime.tryParse('${d['hanDen']}')?.toLocal();
    setState(() {
      _ma = d['ma'].toString();
      _hanDen = han;
      _conLai = han == null ? Duration.zero : han.difference(DateTime.now());
      _dang = false;
    });
    return true;
  }

  Future<void> _bamHienMa() async {
    if (_ma == null) {
      final ok = await _taoMa();
      if (ok && mounted) setState(() => _hien = true);
    } else {
      setState(() => _hien = !_hien);
    }
  }

  Future<void> _bamTaoMoi() async {
    if (_ma != null) {
      final dongY = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: Text('Tạo mã mới?', style: _serif(22)),
          content: const Text(
              'Mã hiện tại sẽ bị vô hiệu hóa ngay lập tức và không dùng lại được.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hủy')),
            FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: _navy,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero)),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Tạo mã mới')),
          ],
        ),
      );
      if (dongY != true) return;
    }
    final ok = await _taoMa();
    if (ok && mounted) setState(() => _hien = false);
  }

  Future<void> _nhapMa() async {
    final ketQua = await showDialog<bool>(
      context: context,
      builder: (_) => _HopThoaiNhapMa(
        buuKienId: widget.buuKien['buu_kien_id'] as int,
        maVanDon: widget.buuKien['ma_van_don'].toString(),
      ),
    );
    if (ketQua == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nhận bưu kiện thành công! Ngăn tủ đã được mở.')),
      );
      Navigator.of(context).pop();
    }
  }

  String get _maHienThi {
    if (_ma == null || !_hien) return '●●● ●●●';
    final m = _ma!;
    return m.length == 6 ? '${m.substring(0, 3)} ${m.substring(3)}' : m;
  }

  Widget _theMa() {
    final coMa = _ma != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 400,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _anhNen(kAnhMaNhan),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
              colors: [
                    AppTheme.chinh.withValues(alpha: 0.45),
                    _navy.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('MÃ NHẬN CỦA BẠN',
                      style: TextStyle(
                          color: Colors.white70,
                          letterSpacing: 4,
                          fontSize: 12.5)),
                  const SizedBox(height: 16),
                  FittedBox(
                    child: Text(_maHienThi,
                        style: _serif(60, color: Colors.white)
                            .copyWith(letterSpacing: 8)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 18,
                          color: coMa ? AppTheme.cam : Colors.white54),
                      const SizedBox(width: 8),
                      Text(
                        coMa
                            ? 'Hết hạn sau ${_hms(_conLai)}'
                            : 'Chưa có mã đang hiệu lực',
                        style: TextStyle(
                            color: coMa ? Colors.white : Colors.white60,
                            fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton(
                        style: _nutCam(),
                        onPressed: _dang ? null : _bamHienMa,
                        child: _dang
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _navy))
                            : Text(_hien ? 'ẨN MÃ' : 'HIỆN MÃ'),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                              fontSize: 13),
                        ),
                        onPressed: _dang ? null : _bamTaoMoi,
                        child: const Text('TẠO MÃ MỚI'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Tạo mã mới sẽ vô hiệu hóa mã cũ ngay lập tức.\nMã chỉ dùng một lần và không xem lại được sau khi rời trang.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white60, fontSize: 12.5, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _capThongTin(String nhan, String giaTri) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(nhan.toUpperCase(),
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.grey.shade600)),
          ),
          Expanded(
              child: Text(giaTri,
                  style: const TextStyle(
                      color: _navy, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buoc(int so, String tieuDe, String moTa) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppTheme.cam),
            child: Text('$so',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: _navy)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tieuDe,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: _navy)),
                const SizedBox(height: 2),
                Text(moTa,
                    style:
                        TextStyle(color: Colors.grey.shade700, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _theThongTin() {
    final bk = widget.buuKien;
    final (nhan, _, _) = _trangThai(bk['trang_thai']);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Thông tin bưu kiện', style: _serif(22)),
          const SizedBox(height: 4),
          Container(width: 40, height: 3, color: AppTheme.cam),
          const SizedBox(height: 12),
          _capThongTin('Mã vận đơn', bk['ma_van_don'].toString()),
          _capThongTin(
              'Vị trí', 'Tủ ${bk['ma_tu'] ?? '-'}, ngăn ${bk['ma_ngan'] ?? '-'}'),
          _capThongTin('Ngày đến', _dinhDang(bk['ngay_tiep_nhan'])),
          _capThongTin('Hạn lưu', _dinhDang(bk['ngay_het_han_luu'])),
          _capThongTin('Trạng thái', nhan),
          const SizedBox(height: 14),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 10),
          Text('Cách nhận hàng', style: _serif(20)),
          const SizedBox(height: 6),
          _buoc(1, 'Đến tủ locker',
              'Đến tủ ${bk['ma_tu'] ?? ''}, ngăn ${bk['ma_ngan'] ?? ''} theo thông tin ở trên.'),
          _buoc(2, 'Lấy mã và nhập mã',
              'Bấm "Hiện mã", sau đó bấm "Nhập mã để mở ngăn" và nhập mã 6 số.'),
          _buoc(3, 'Lấy hàng',
              'Ngăn tủ tự mở. Lấy bưu kiện rồi đóng cửa ngăn lại.'),
          if (_canNhan(bk)) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: _nutVien(),
                onPressed: _nhapMa,
                child: const Text('NHẬP MÃ ĐỂ MỞ NGĂN'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _nen,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Mã nhận hàng', style: _serif(22)),
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final rong = c.maxWidth >= 820;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: rong
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 5, child: _theThongTin()),
                          const SizedBox(width: 20),
                          Expanded(flex: 5, child: _theMa()),
                        ],
                      )
                    : Column(
                        children: [
                          _theMa(),
                          const SizedBox(height: 20),
                          _theThongTin(),
                        ],
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================ Hộp thoại nhập mã

class _HopThoaiNhapMa extends StatefulWidget {
  final int buuKienId;
  final String maVanDon;
  const _HopThoaiNhapMa({required this.buuKienId, required this.maVanDon});

  @override
  State<_HopThoaiNhapMa> createState() => _HopThoaiNhapMaState();
}

class _HopThoaiNhapMaState extends State<_HopThoaiNhapMa> {
  final _ctrl = TextEditingController();
  bool _dangGui = false;
  String? _loi;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _gui() async {
    final ma = _ctrl.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(ma)) {
      setState(() => _loi = 'Mã gồm đúng 6 chữ số');
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
    });
    final loi = await ApiService.nhapMaNhan(widget.buuKienId, ma);
    if (!mounted) return;
    if (loi == null) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _dangGui = false;
        _loi = loi;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      title: Text('Nhập mã nhận hàng', style: _serif(22)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bưu kiện ${widget.maVanDon}'),
          const SizedBox(height: 14),
          TextField(
            controller: _ctrl,
            autofocus: true,
            maxLength: 6,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: _serif(30).copyWith(letterSpacing: 8),
            onSubmitted: (_) => _gui(),
            decoration: InputDecoration(
              counterText: '',
              hintText: '------',
              errorText: _loi,
              errorMaxLines: 3,
              border: const UnderlineInputBorder(),
              focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.chinh, width: 2)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _dangGui ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: _navy,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero)),
          onPressed: _dangGui ? null : _gui,
          child: _dangGui
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Xác nhận'),
        ),
      ],
    );
  }
}

// ============================================================ Tab thông báo

class _TabThongBao extends StatefulWidget {
  const _TabThongBao();

  @override
  State<_TabThongBao> createState() => _TabThongBaoState();
}

class _TabThongBaoState extends State<_TabThongBao> {
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.layDuLieu('/api/cu-dan/thong-bao');
  }

  Future<void> _taiLai() async {
    setState(() => _future = ApiService.layDuLieu('/api/cu-dan/thong-bao'));
    try {
      await _future;
    } catch (_) {}
  }

  IconData _iconKenh(String? k) {
    switch (k) {
      case 'SMS':
        return Icons.sms_outlined;
      case 'EMAIL':
        return Icons.email_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) return _Loi(onThuLai: _taiLai);
        final ds = (snap.data as List?) ?? [];
        return RefreshIndicator(
          onRefresh: _taiLai,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Text('Thông báo', style: _serif(26)),
              const SizedBox(height: 8),
              Container(width: 44, height: 3, color: AppTheme.cam),
              const SizedBox(height: 16),
              if (ds.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off_outlined,
                          size: 44, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text('Chưa có thông báo',
                          style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                )
              else
                for (final e in ds) _theThongBao(e as Map),
            ],
          ),
        );
      },
    );
  }

  Widget _theThongBao(Map tb) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.cam.withValues(alpha: 0.18)),
            child: Icon(_iconKenh(tb['kenh_gui']?.toString()),
                color: _navy, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tb['noi_dung'].toString(),
                    style: const TextStyle(color: _navy, height: 1.4)),
                const SizedBox(height: 4),
                Text(_dinhDang(tb['ngay_gui']?.toString()),
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
          OutlinedButton(
              style: _nutVien(),
              onPressed: onThuLai,
              child: const Text('THỬ LẠI')),
        ],
      ),
    );
  }
}