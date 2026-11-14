import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import 'ban_do_tu.dart';

const Color _navy = Color(0xFF111A33);
const Color _chamDam = Color(0xFF2E2A7A);

/// Tab "Bản đồ" của cư dân: chuyển qua lại giữa sơ đồ tòa nhà và bản đồ thật.
class ManViTriTu extends StatefulWidget {
  const ManViTriTu({super.key});

  @override
  State<ManViTriTu> createState() => _ManViTriTuState();
}

class _ManViTriTuState extends State<ManViTriTu> {
  int _che = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: 0,
                    label: Text('Sơ đồ tòa nhà'),
                    icon: Icon(Icons.apartment)),
                ButtonSegment(
                    value: 1,
                    label: Text('Bản đồ'),
                    icon: Icon(Icons.map_outlined)),
              ],
              selected: {_che},
              onSelectionChanged: (s) => setState(() => _che = s.first),
            ),
          ),
        ),
        Expanded(
          child: _che == 0 ? const _SoDoToaNha() : const BanDoTu(),
        ),
      ],
    );
  }
}

class _DuLieuTu {
  final List<String> dsTu;
  final Map<String, List<String>> tuSang;
  _DuLieuTu(this.dsTu, this.tuSang);
}

class _SoDoToaNha extends StatefulWidget {
  const _SoDoToaNha();

  @override
  State<_SoDoToaNha> createState() => _SoDoToaNhaState();
}

class _SoDoToaNhaState extends State<_SoDoToaNha>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nhip = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);
  late Future<_DuLieuTu> _future;

  @override
  void initState() {
    super.initState();
    _future = _tai();
  }

  @override
  void dispose() {
    _nhip.dispose();
    super.dispose();
  }

  Future<_DuLieuTu> _tai() async {
    final bkRaw = await ApiService.layDuLieu('/api/cu-dan/buu-kien');
    dynamic tuRaw;
    try {
      tuRaw = await ApiService.layDuLieu('/api/ban-do/tu');
    } catch (_) {
      tuRaw = null;
    }
    final tuSang = <String, List<String>>{};
    for (final b in ((bkRaw as List?) ?? []).whereType<Map>()) {
      final tt = b['trang_thai'];
      if (tt != 'CHO_NHAN' && tt != 'QUA_HAN') continue;
      if (b['ma_tu'] == null) continue;
      (tuSang['${b['ma_tu']}'] ??= []).add('${b['ma_ngan'] ?? '-'}');
    }
    final dsTu = <String>[];
    for (final t in ((tuRaw as List?) ?? []).whereType<Map>()) {
      if (t['ma_tu'] != null) dsTu.add('${t['ma_tu']}');
    }
    for (final k in tuSang.keys) {
      if (!dsTu.contains(k)) dsTu.add(k);
    }
    dsTu.sort();
    return _DuLieuTu(dsTu, tuSang);
  }

  Widget _chuThich(Color mau, String chu) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
                color: mau, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(chu, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DuLieuTu>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || snap.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
                const SizedBox(height: 12),
                const Text('Không tải được sơ đồ'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => setState(() => _future = _tai()),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
        }
        final d = snap.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Text('Vị trí tủ locker',
                style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 24,
                    color: _navy)),
            const SizedBox(height: 6),
            Container(width: 44, height: 3, color: AppTheme.cam),
            const SizedBox(height: 12),
            if (d.tuSang.isEmpty)
              Text(
                  'Hiện bạn chưa có bưu kiện nào cần nhận, nên các tủ trong sảnh đều màu xám.',
                  style: TextStyle(color: Colors.grey.shade700))
            else ...[
              Text('Bưu kiện của bạn đang ở sảnh tầng trệt:',
                  style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in d.tuSang.entries)
                    for (final ngan in e.value)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppTheme.cam.withValues(alpha: 0.15),
                          border: Border.all(color: AppTheme.cam),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('Tủ ${e.key} · ngăn $ngan',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, color: _navy)),
                      ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Container(
              height: 380,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF3E0), Color(0xFFF1F2F8)],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _ToaNhaPainter(d.dsTu, d.tuSang.keys.toSet(), _nhip),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                _chuThich(AppTheme.cam, 'Tủ có bưu kiện của bạn'),
                _chuThich(const Color(0xFF8A90B8), 'Tủ khác'),
                                _chuThich(const Color(0xFFFFE7B8), 'Sảnh tầng trệt'),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Mặt bằng tầng trệt',
                style: TextStyle(
                    fontFamily: 'Georgia', fontSize: 22, color: _navy)),
            const SizedBox(height: 6),
            Container(width: 44, height: 3, color: AppTheme.cam),
            const SizedBox(height: 12),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _MatBangPainter(d.dsTu, d.tuSang),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ToaNhaPainter extends CustomPainter {
  final List<String> dsTu;
  final Set<String> tuSang;
  final Animation<double> anim;

  _ToaNhaPainter(this.dsTu, this.tuSang, this.anim) : super(repaint: anim);

  static const double _w = 6; // chiều rộng (trục x)
  static const double _d = 4; // chiều sâu (trục y)
  static const double _h = 7; // số tầng
  static const double _m = 1.6; // lề quanh tòa nhà

  double _s = 1, _ox = 0, _oy = 0;

  Offset _p(double x, double y, double z) => Offset(
      _ox + (x - y) * 0.866 * _s, _oy + (x + y) * 0.5 * _s - z * _s);

  void _da(Canvas c, List<Offset> pts, Color fill, [Color? vien]) {
    final path = Path()..addPolygon(pts, true);
    c.drawPath(path, Paint()..color = fill);
    if (vien != null) {
      c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = vien
            ..strokeWidth = 1);
    }
  }

  void _hop(Canvas c, double x0, double y0, double x1, double y1, double h,
      Color top, Color trai, Color phai) {
    _da(c, [_p(x0, y0, h), _p(x1, y0, h), _p(x1, y1, h), _p(x0, y1, h)], top);
    _da(c, [_p(x0, y1, 0), _p(x1, y1, 0), _p(x1, y1, h), _p(x0, y1, h)], trai);
    _da(c, [_p(x1, y0, 0), _p(x1, y1, 0), _p(x1, y1, h), _p(x1, y0, h)], phai);
  }

  void _nhan(Canvas c, String t, Offset tam, bool sang) {
    final tp = TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(
              color: sang ? Colors.white : _navy,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: tam, width: tp.width + 14, height: tp.height + 8),
        const Radius.circular(6));
    c.drawRRect(
        r, Paint()..color = sang ? _navy : Colors.white.withValues(alpha: 0.92));
    tp.paint(c, tam - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final wU = (_w + _d + 4 * _m) * 0.866;
    final hU = (_w + _d + 4 * _m) * 0.5 + _h;
    _s = math.min(size.width * 0.94 / wU, size.height * 0.94 / hU);
    _ox = size.width / 2 - ((_w - _d) / 2) * 0.866 * _s;
    _oy = (size.height - hU * _s) / 2 + (_m + _h) * _s;

    // Nền đất
    _da(
        canvas,
        [
          _p(-_m, -_m, 0),
          _p(_w + _m, -_m, 0),
          _p(_w + _m, _d + _m, 0),
          _p(-_m, _d + _m, 0),
        ],
        const Color(0xFFE6E8F2),
        const Color(0xFFD0D3E4));

    // Thân tòa nhà: mặt phải, mặt trái, mái
    _da(canvas, [_p(_w, 0, 0), _p(_w, _d, 0), _p(_w, _d, _h), _p(_w, 0, _h)],
        const Color(0xFF1B1F5A));
    _da(canvas, [_p(0, _d, 0), _p(_w, _d, 0), _p(_w, _d, _h), _p(0, _d, _h)],
        _chamDam);
    _da(canvas, [_p(0, 0, _h), _p(_w, 0, _h), _p(_w, _d, _h), _p(0, _d, _h)],
        const Color(0xFF5650B8));
    // Khối kỹ thuật trên mái
    _hop(canvas, 2.4, 1.2, 3.6, 2.6, 0.7, const Color(0xFF7A74D0),
        const Color(0xFF3A3590), const Color(0xFF2A2670));

    // Cửa sổ
    for (var f = 1; f < _h.toInt(); f++) {
      for (var i = 0; i < _w.toInt(); i++) {
        final sang = (i * 7 + f * 13) % 5 == 0;
        _da(
            canvas,
            [
              _p(i + 0.2, _d, f + 0.25),
              _p(i + 0.8, _d, f + 0.25),
              _p(i + 0.8, _d, f + 0.75),
              _p(i + 0.2, _d, f + 0.75),
            ],
            sang ? const Color(0xFFFFD27A) : const Color(0x558F93D6));
      }
      for (var j = 0; j < _d.toInt(); j++) {
        final sang = (j * 11 + f * 5) % 4 == 0;
        _da(
            canvas,
            [
              _p(_w, j + 0.2, f + 0.25),
              _p(_w, j + 0.8, f + 0.25),
              _p(_w, j + 0.8, f + 0.75),
              _p(_w, j + 0.2, f + 0.75),
            ],
            sang ? const Color(0xFFFFD27A) : const Color(0x448F93D6));
      }
    }

    // Sảnh tầng trệt (kính sáng) và cửa chính
    _da(
        canvas,
        [
          _p(0.25, _d, 0.05),
          _p(_w - 0.25, _d, 0.05),
          _p(_w - 0.25, _d, 0.9),
          _p(0.25, _d, 0.9),
        ],
        const Color(0xFFFFE7B8));
    _da(
        canvas,
        [
          _p(_w / 2 - 0.4, _d, 0.05),
          _p(_w / 2 + 0.4, _d, 0.05),
          _p(_w / 2 + 0.4, _d, 0.75),
          _p(_w / 2 - 0.4, _d, 0.75),
        ],
        const Color(0xFF5B4630));

    // Các tủ locker nằm ở sảnh
    final n = dsTu.length;
    if (n == 0) return;
    final pitch = (_w - 0.8) / n;
    final rong = math.min(0.9, pitch * 0.7);
    const y0 = _d + 0.45;
    const y1 = _d + 1.05;
    const cao = 0.75;
    final t = anim.value;

    final nhans = <(String, Offset, bool)>[];
    for (var i = 0; i < n; i++) {
      final ma = dsTu[i];
      final sang = tuSang.contains(ma);
      final x0 = 0.4 + pitch * i + (pitch - rong) / 2;
      final x1 = x0 + rong;
      final cx = (x0 + x1) / 2;
      final cy = (y0 + y1) / 2;

      if (sang) {
        final rx = (0.95 + 0.4 * t) * _s;
        final r = Rect.fromCenter(center: _p(cx, cy, 0), width: rx * 2, height: rx);
        canvas.drawOval(r, Paint()..color = AppTheme.cam.withValues(alpha: 0.20));
        canvas.drawOval(
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = AppTheme.cam.withValues(alpha: 0.9 - 0.6 * t));
      }

      if (sang) {
        _hop(canvas, x0, y0, x1, y1, cao, Color.lerp(AppTheme.cam, Colors.white, 0.25)!,
            AppTheme.cam, Color.lerp(AppTheme.cam, Colors.black, 0.25)!);
      } else {
        _hop(canvas, x0, y0, x1, y1, cao, const Color(0xFFB9BDD9),
            const Color(0xFF8A90B8), const Color(0xFF6C739C));
      }
      // Vạch chia ngăn trên mặt trước
      for (final k in [cao / 3, cao * 2 / 3]) {
        canvas.drawLine(
            _p(x0, y1, k),
            _p(x1, y1, k),
            Paint()
              ..color = Colors.white.withValues(alpha: 0.5)
              ..strokeWidth = 1);
      }
      nhans.add((ma, _p(cx, cy, cao + 0.2) + Offset(0, i % 2 == 0 ? -16 : -36), sang));
    }
    // Vẽ nhãn sau cùng để không bị tủ che
    for (final e in nhans) {
      _nhan(canvas, e.$1, e.$2, e.$3);
    }
  }

  @override
  bool shouldRepaint(covariant _ToaNhaPainter old) =>
      old.dsTu != dsTu || old.tuSang != tuSang;
}
class _MatBangPainter extends CustomPainter {
  final List<String> dsTu;
  final Map<String, List<String>> tuSang;
  _MatBangPainter(this.dsTu, this.tuSang);

  void _chu(Canvas c, String t, Offset tam,
      {double size = 11, Color color = _navy, bool dam = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(
              color: color,
              fontSize: size,
              fontWeight: dam ? FontWeight.w700 : FontWeight.w500)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, tam - Offset(tp.width / 2, tp.height / 2));
  }

  void _netDut(Canvas c, Path p, Paint paint) {
    for (final m in p.computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        c.drawPath(m.extractPath(d, math.min(d + 8, m.length)), paint);
        d += 14;
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final khung = Rect.fromLTWH(16, 16, size.width - 32, size.height - 32);

    // Sàn sảnh và tường
    canvas.drawRect(khung, Paint()..color = const Color(0xFFFFF3DC));
    canvas.drawRect(
        khung,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = _navy);

    // Cửa chính (khoét một đoạn ở tường dưới)
    final cuaX = khung.center.dx;
    canvas.drawRect(
        Rect.fromCenter(
            center: Offset(cuaX, khung.bottom), width: 90, height: 8),
        Paint()..color = const Color(0xFFFFF3DC));
    _chu(canvas, 'CỬA CHÍNH', Offset(cuaX, khung.bottom - 12),
        size: 10.5, dam: true);

    // Thang bộ (trái) và thang máy (phải)
    void khoi(Rect r, String ten) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()..color = const Color(0xFF8A90B8));
      _chu(canvas, ten, r.center,
          size: 10.5, color: Colors.white, dam: true);
    }

    khoi(Rect.fromLTWH(khung.left + 12, khung.top + 12, 78, 56), 'Thang bộ');
    khoi(Rect.fromLTWH(khung.right - 90, khung.top + 12, 78, 56), 'Thang máy');

    _chu(canvas, 'SẢNH', khung.center + const Offset(0, 8),
        size: 20, color: const Color(0x33111A33), dam: true);

    // Các tủ locker dọc tường trên
    final n = dsTu.length;
    if (n == 0) return;
    final bang = Rect.fromLTRB(khung.left + 104, 0, khung.right - 104, 0);
    final o = bang.width / n;
    final rong = math.min(72.0, o * 0.78);
    final tuTop = khung.top + 14;
    const tuCao = 50.0;

    final diemDen = <Offset>[];
    for (var i = 0; i < n; i++) {
      final ma = dsTu[i];
      final sang = tuSang.containsKey(ma);
      final cx = bang.left + o * i + o / 2;
      final r = Rect.fromCenter(
          center: Offset(cx, tuTop + tuCao / 2), width: rong, height: tuCao);

      if (sang) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(r.inflate(6), const Radius.circular(8)),
            Paint()..color = AppTheme.cam.withValues(alpha: 0.25));
      }
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)),
          Paint()..color = sang ? AppTheme.cam : const Color(0xFFB9BDD9));
      // Vạch ngăn
      for (var k = 1; k < 3; k++) {
        final y = r.top + tuCao * k / 3;
        canvas.drawLine(Offset(r.left, y), Offset(r.right, y),
            Paint()..color = Colors.white.withValues(alpha: 0.6));
      }
      _chu(canvas, ma, Offset(cx, r.bottom + 12),
          size: 11, dam: true, color: sang ? _navy : const Color(0xFF6C739C));
      if (sang) {
        _chu(canvas, 'Ngăn ${tuSang[ma]!.join(', ')}',
            Offset(cx, r.bottom + 27),
            size: 10.5, dam: true, color: const Color(0xFFB85C00));
        diemDen.add(Offset(cx, r.bottom + 42));
      }
    }

    // Đường đi: cửa chính -> sảnh -> tủ có bưu kiện
    final net = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.cam;
    final dau = Offset(cuaX, khung.bottom - 30);
    final giua = khung.bottom - (khung.height * 0.30);
    for (final den in diemDen) {
      final p = Path()
        ..moveTo(dau.dx, dau.dy)
        ..lineTo(dau.dx, giua)
        ..lineTo(den.dx, giua)
        ..lineTo(den.dx, den.dy);
      _netDut(canvas, p, net);
      final mui = Path()
        ..moveTo(den.dx, den.dy - 2)
        ..lineTo(den.dx - 6, den.dy + 9)
        ..lineTo(den.dx + 6, den.dy + 9)
        ..close();
      canvas.drawPath(mui, Paint()..color = AppTheme.cam);
    }
  }

  @override
  bool shouldRepaint(covariant _MatBangPainter old) =>
      old.dsTu != dsTu || old.tuSang != tuSang;
}