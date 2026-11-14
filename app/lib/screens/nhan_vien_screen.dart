import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/app_shell.dart';
import 'login_screen.dart';

String _dinhDang(String? iso) {
  if (iso == null) return '';
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  String hai(int n) => n.toString().padLeft(2, '0');
  return '${hai(d.day)}/${hai(d.month)}/${d.year} ${hai(d.hour)}:${hai(d.minute)}';
}

String _tien(dynamic v) {
  final n = (v is num) ? v.round() : 0;
  final s = n.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
  return '$s đ';
}

class NhanVienScreen extends StatefulWidget {
  const NhanVienScreen({super.key});

  @override
  State<NhanVienScreen> createState() => _NhanVienScreenState();
}

class _NhanVienScreenState extends State<NhanVienScreen> {
  int _tab = 0;
  static const _tieuDe = ['Bưu kiện đang lưu', 'Tiếp nhận bưu kiện', 'Bưu kiện quá hạn'];

  static const _muc = [
    MucDieuHuong('Đang lưu', Icons.inventory_2_outlined),
    MucDieuHuong('Tiếp nhận', Icons.add_box_outlined),
    MucDieuHuong('Quá hạn', Icons.warning_amber_rounded),
  ];

  static const _moTa = [
    'Theo dõi bưu kiện đang được lưu tại tủ locker.',
    'Nhập thông tin và bố trí ngăn lưu trữ cho bưu kiện.',
    'Theo dõi và xử lý các bưu kiện đã quá thời gian lưu.',
  ];

  Future<void> _dangXuat() async {
    await ApiService.dangXuat();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tab = [
      const _TabDangLuu(),
      const _TabTiepNhan(),
      const _TabQuaHan(),
    ][_tab];

    return AppShell(
      muc: _muc,
      chon: _tab,
      onChon: (i) => setState(() => _tab = i),
      onDangXuat: _dangXuat,
      phuDe: 'Nhân viên',
      noiDung: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BannerNhanVien(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _tieuDe[_tab],
                    style: const TextStyle(
                      color: Color(0xFF2E2A7A),
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _moTa[_tab],
                    style: const TextStyle(
                      color: Color(0xFF77788A),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: tab),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- Dùng chung

class _Dong extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Dong(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
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

// ------------------------------------------------------------- Tab đang lưu

class _TabDangLuu extends StatefulWidget {
  const _TabDangLuu();

  @override
  State<_TabDangLuu> createState() => _TabDangLuuState();
}

class _TabDangLuuState extends State<_TabDangLuu> {
  static const _duongDan = '/api/nhan-vien/buu-kien-dang-luu';
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
          child: ds.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 120),
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Center(child: Text('Không có bưu kiện nào đang lưu')),
                ])
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: ds.length,
                  itemBuilder: (context, i) {
                    final bk = ds[i] as Map;
                    final quaHan = bk['trang_thai'] == 'QUA_HAN';
                    final mau = quaHan ? Colors.orange : Colors.blue;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.inventory_2_rounded, color: mau),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(bk['ma_van_don'].toString(),
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold)),
                                ),
                                Chip(
                                  label: Text(quaHan ? 'Quá hạn' : 'Chờ nhận',
                                      style: TextStyle(color: mau)),
                                  side: BorderSide(color: mau),
                                  backgroundColor: mau.withValues(alpha: 0.08),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _Dong(Icons.apartment,
                                'Căn hộ ${bk['so_can_ho']} (tòa ${bk['toa_nha']})'),
                            _Dong(Icons.place_outlined,
                                'Tủ ${bk['ma_tu'] ?? '-'}, ngăn ${bk['ma_ngan'] ?? '-'}, cỡ ${bk['kich_co']}'),
                            _Dong(Icons.event_busy_outlined,
                                'Hạn lưu: ${_dinhDang(bk['ngay_het_han_luu'])}'),
                            if (quaHan)
                              _Dong(Icons.timer_outlined,
                                  'Quá hạn ${bk['so_ngay_qua_han']} ngày'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}

// ------------------------------------------------------------- Tab tiếp nhận

class _TabTiepNhan extends StatefulWidget {
  const _TabTiepNhan();

  @override
  State<_TabTiepNhan> createState() => _TabTiepNhanState();
}

class _TabTiepNhanState extends State<_TabTiepNhan> {
  final _vanDon = TextEditingController();
  final _canHo = TextEditingController();
  String _kichCo = 'M';
  bool _dangGui = false;
  String? _loi;
  String? _ketQua;

  @override
  void dispose() {
    _vanDon.dispose();
    _canHo.dispose();
    super.dispose();
  }

  Future<void> _kiemTraCanHo() async {
    final so = _canHo.text.trim();
    if (so.isEmpty) return;
    String noi;
    try {
      final d = await ApiService.layDuLieu(
          '/api/nhan-vien/can-ho/${Uri.encodeComponent(so)}/ton-tai');
      noi = (d is Map && d['tonTai'] == true)
          ? 'Căn hộ $so có tồn tại'
          : 'Không có căn hộ $so';
    } catch (_) {
      noi = 'Không kiểm tra được căn hộ';
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(noi)));
  }

  Future<void> _tiepNhan() async {
    final vd = _vanDon.text.trim();
    final ch = _canHo.text.trim();
    if (vd.isEmpty || ch.isEmpty) {
      setState(() {
        _loi = 'Vui lòng nhập mã vận đơn và số căn hộ';
        _ketQua = null;
      });
      return;
    }
    setState(() {
      _dangGui = true;
      _loi = null;
      _ketQua = null;
    });
    final kq = await ApiService.guiJson('/api/nhan-vien/buu-kien',
        {'maVanDon': vd, 'soCanHo': ch, 'kichCo': _kichCo});
    if (!mounted) return;
    if (kq.ok && kq.data is Map) {
      final d = kq.data as Map;
      setState(() {
        _dangGui = false;
        _ketQua =
            'Đã tiếp nhận $vd.\nHãy bỏ bưu kiện vào ngăn ${d['maNgan']}.\nMã nhận đã gửi riêng cho cư dân, nhân viên không xem được.';
        _vanDon.clear();
        _canHo.clear();
      });
    } else {
      setState(() {
        _dangGui = false;
        _loi = kq.loi;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _vanDon,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Mã vận đơn',
                  prefixIcon: const Icon(Icons.qr_code_2),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _canHo,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Số căn hộ (vd: A-1205)',
                  prefixIcon: const Icon(Icons.apartment),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _kiemTraCanHo,
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Kiểm tra căn hộ'),
                ),
              ),
              const SizedBox(height: 4),
              const Text('Kích cỡ bưu kiện'),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'S', label: Text('S (nhỏ)')),
                  ButtonSegment(value: 'M', label: Text('M (vừa)')),
                  ButtonSegment(value: 'L', label: Text('L (lớn)')),
                ],
                selected: {_kichCo},
                onSelectionChanged: (s) => setState(() => _kichCo = s.first),
              ),
              if (_loi != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: mau.errorContainer,
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(Icons.error_outline, color: mau.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_loi!,
                            style: TextStyle(color: mau.onErrorContainer))),
                  ]),
                ),
              ],
              if (_ketQua != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_ketQua!)),
                  ]),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _dangGui ? null : _tiepNhan,
                  icon: _dangGui
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Icon(Icons.add_box),
                  label: const Text('Tiếp nhận bưu kiện',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- Tab quá hạn

class _TabQuaHan extends StatefulWidget {
  const _TabQuaHan();

  @override
  State<_TabQuaHan> createState() => _TabQuaHanState();
}

class _TabQuaHanState extends State<_TabQuaHan> {
  static const _duongDan = '/api/nhan-vien/qua-han';
  late Future<dynamic> _future;
  bool _dangQuet = false;

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

  Future<void> _quetNgay() async {
    setState(() => _dangQuet = true);
    final kq = await ApiService.guiJson('$_duongDan/quet-ngay');
    if (!mounted) return;
    setState(() => _dangQuet = false);
    _thongBao(kq.ok ? 'Đã quét xong bưu kiện quá hạn' : (kq.loi ?? 'Lỗi'));
    _taiLai();
  }

  Future<void> _xuLy(Map bk, String hinhThuc) async {
    final ghiChu = TextEditingController();
    final tenHT = hinhThuc == 'HOAN_TRA' ? 'Hoàn trả' : 'Chuyển kho';
    final dongY = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$tenHT bưu kiện'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${bk['ma_van_don']} (căn hộ ${bk['so_can_ho']})'),
            const SizedBox(height: 6),
            Text('Phí lưu kho dự kiến: ${_tien(bk['phi_luu_kho_du_kien'])}'),
            const SizedBox(height: 12),
            TextField(
              controller: ghiChu,
              decoration: InputDecoration(
                labelText: 'Ghi chú (không bắt buộc)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Xác nhận')),
        ],
      ),
    );
    final ghiChuText = ghiChu.text.trim();
    ghiChu.dispose();
    if (dongY != true) return;

    final kq = await ApiService.guiJson(
        '$_duongDan/${bk['buu_kien_id']}/xu-ly', {
      'hinhThuc': hinhThuc,
      if (ghiChuText.isNotEmpty) 'ghiChu': ghiChuText,
    });
    if (kq.ok && kq.data is Map) {
      _thongBao('$tenHT xong. Phí lưu kho: ${_tien((kq.data as Map)['phiLuuKho'])}');
    } else {
      _thongBao(kq.loi ?? 'Lỗi');
    }
    _taiLai();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              const Expanded(
                  child: Text('Hệ thống tự quét mỗi 60 giây.',
                      style: TextStyle(color: Colors.grey))),
              OutlinedButton.icon(
                onPressed: _dangQuet ? null : _quetNgay,
                icon: const Icon(Icons.radar),
                label: const Text('Quét ngay'),
              ),
            ],
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
                    ? ListView(children: const [
                        SizedBox(height: 100),
                        Icon(Icons.verified_outlined,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Center(child: Text('Không có bưu kiện quá hạn')),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: ds.length,
                        itemBuilder: (context, i) {
                          final bk = ds[i] as Map;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: Colors.orange),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(bk['ma_van_don'].toString(),
                                          style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ]),
                                  const SizedBox(height: 8),
                                  _Dong(Icons.apartment,
                                      'Căn hộ ${bk['so_can_ho']}'),
                                  _Dong(Icons.place_outlined,
                                      'Tủ ${bk['ma_tu'] ?? '-'}, ngăn ${bk['ma_ngan'] ?? '-'}'),
                                  _Dong(Icons.timer_outlined,
                                      'Quá hạn ${bk['so_ngay_qua_han']} ngày'),
                                  _Dong(Icons.payments_outlined,
                                      'Phí dự kiến: ${_tien(bk['phi_luu_kho_du_kien'])}'),
                                  const SizedBox(height: 12),
                                  Row(children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _xuLy(bk, 'HOAN_TRA'),
                                        icon: const Icon(Icons.undo),
                                        label: const Text('Hoàn trả'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => _xuLy(bk, 'CHUYEN_KHO'),
                                        icon: const Icon(Icons.warehouse_outlined),
                                        label: const Text('Chuyển kho'),
                                      ),
                                    ),
                                  ]),
                                ],
                              ),
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

// ------------------------------------------------------------- Banner giao diện nhân viên

class _BannerNhanVien extends StatelessWidget {
  const _BannerNhanVien();

  static const Color _timThan = Color(0xFF2E2A7A);
  static const Color _cam = Color(0xFFFFA000);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rong = constraints.maxWidth;
        final hienThiBaAnh = rong >= 520;
        final chieuCao = rong < 520 ? 170.0 : 220.0;

        return SizedBox(
          height: chieuCao,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/toanha5.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              _timThan.withOpacity(0.96),
                              _timThan.withOpacity(0.74),
                              _timThan.withOpacity(0.12),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(rong < 520 ? 16 : 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'LAVITHOR RESIDENCE',
                              style: TextStyle(
                                color: _cam,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quản lý bưu kiện',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: rong < 520 ? 20 : 27,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              'Tiếp nhận, lưu trữ và theo dõi bưu kiện tại tòa nhà.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: rong < 520 ? 11 : 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hienThiBaAnh) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/toanha3.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/toanha4.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

