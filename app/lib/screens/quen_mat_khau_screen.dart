import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';

/// Màn hình quên mật khẩu bằng OTP gửi qua email (3 bước).
/// Đặt lại thành công thì đóng màn hình và trả về true cho màn hình đăng nhập.
class QuenMatKhauScreen extends StatefulWidget {
  const QuenMatKhauScreen({super.key});

  @override
  State<QuenMatKhauScreen> createState() => _QuenMatKhauScreenState();
}

class _QuenMatKhauScreenState extends State<QuenMatKhauScreen> {
  static const _goc = '/api/auth/quen-mat-khau';
  static const _mauNut = Color(0xFF111A33);

  final _dinhDanhCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _mkMoiCtrl = TextEditingController();
  final _xacNhanCtrl = TextEditingController();

  int _buoc = 1; // 1: nhập tài khoản, 2: nhập OTP, 3: mật khẩu mới
  bool _dangTai = false;
  bool _anMk = true;
  String? _loi;
  String? _thongBao;
  int _conLai = 0; // số giây còn lại trước khi được gửi lại OTP
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _dinhDanhCtrl.dispose();
    _otpCtrl.dispose();
    _mkMoiCtrl.dispose();
    _xacNhanCtrl.dispose();
    super.dispose();
  }

  void _batDauDemNguoc() {
    _timer?.cancel();
    setState(() => _conLai = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _conLai--;
        if (_conLai <= 0) t.cancel();
      });
    });
  }

  // ---------- Gọi API ----------

  Future<void> _guiOtp() async {
    final dd = _dinhDanhCtrl.text.trim();
    if (dd.isEmpty) {
      setState(() => _loi = 'Vui lòng nhập tên đăng nhập hoặc email');
      return;
    }
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    final kq = await ApiService.guiJson('$_goc/yeu-cau', {'dinhDanh': dd});
    if (!mounted) return;
    if (kq.ok) {
      final tb = kq.data is Map ? kq.data['thongBao']?.toString() : null;
      setState(() {
        _dangTai = false;
        _buoc = 2;
        _thongBao = tb;
        _otpCtrl.clear();
      });
      _batDauDemNguoc();
    } else {
      setState(() {
        _dangTai = false;
        _loi = kq.loi;
      });
    }
  }

  Future<void> _xacMinh() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      setState(() => _loi = 'Mã OTP gồm 6 chữ số');
      return;
    }
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    final kq = await ApiService.guiJson('$_goc/xac-minh', {
      'dinhDanh': _dinhDanhCtrl.text.trim(),
      'otp': otp,
    });
    if (!mounted) return;
    if (kq.ok) {
      setState(() {
        _dangTai = false;
        _buoc = 3;
      });
    } else {
      setState(() {
        _dangTai = false;
        _loi = kq.loi;
      });
    }
  }

  Future<void> _datLai() async {
    final mk = _mkMoiCtrl.text;
    if (mk.length < 6) {
      setState(() => _loi = 'Mật khẩu mới tối thiểu 6 ký tự');
      return;
    }
    if (mk.length > 72) {
      setState(() => _loi = 'Mật khẩu mới tối đa 72 ký tự');
      return;
    }
    if (mk != _xacNhanCtrl.text) {
      setState(() => _loi = 'Mật khẩu xác nhận không khớp');
      return;
    }
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    final kq = await ApiService.guiJson('$_goc/dat-lai', {
      'dinhDanh': _dinhDanhCtrl.text.trim(),
      'otp': _otpCtrl.text.trim(),
      'matKhauMoi': mk,
    });
    if (!mounted) return;
    if (kq.ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _dangTai = false;
        _loi = kq.loi;
      });
    }
  }

  // ---------- Giao diện ----------

  InputDecoration _kieuO(String goiY, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: goiY,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
      suffixIcon: suffix,
      filled: false,
      border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400)),
      enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400)),
      focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppTheme.chinh, width: 2)),
    );
  }

  Widget _nhan(String t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(t,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: Color(0xFF3A3F52))),
    );
  }

  Widget _nut(String chu, VoidCallback onPressed) {
    return SizedBox(
      height: 54,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _mauNut,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        onPressed: _dangTai ? null : onPressed,
        child: _dangTai
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
            : Text(chu,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2)),
      ),
    );
  }

  Widget _khungLoi(ColorScheme mau) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mau.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        Icon(Icons.error_outline, color: mau.onErrorContainer, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: Text(_loi!, style: TextStyle(color: mau.onErrorContainer))),
      ]),
    );
  }

  Widget _khungThongBao(ColorScheme mau) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mau.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(children: [
        Icon(Icons.mark_email_read_outlined,
            color: mau.onSecondaryContainer, size: 20),
        const SizedBox(width: 8),
        Expanded(
            child: Text(_thongBao!,
                style: TextStyle(color: mau.onSecondaryContainer))),
      ]),
    );
  }

  void _quayLai() {
    setState(() {
      _buoc--;
      _loi = null;
    });
  }

  List<Widget> _noiDungBuoc1() {
    return [
      _nhan('TÊN ĐĂNG NHẬP HOẶC EMAIL'),
      TextField(
        controller: _dinhDanhCtrl,
        keyboardType: TextInputType.emailAddress,
        onSubmitted: (_) => _guiOtp(),
        decoration: _kieuO('Nhập tên đăng nhập hoặc email', Icons.person_outline),
      ),
      const SizedBox(height: 30),
      _nut('GỬI MÃ OTP', _guiOtp),
    ];
  }

  List<Widget> _noiDungBuoc2() {
    return [
      _nhan('MÃ OTP (6 CHỮ SỐ)'),
      TextField(
        controller: _otpCtrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: const TextStyle(fontSize: 26, letterSpacing: 10),
        onSubmitted: (_) => _xacMinh(),
        decoration: _kieuO('------', Icons.pin_outlined),
      ),
      const SizedBox(height: 30),
      _nut('XÁC MINH', _xacMinh),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _dangTai ? null : _quayLai,
            child: const Text('Đổi tài khoản'),
          ),
          TextButton(
            onPressed: (_conLai > 0 || _dangTai) ? null : _guiOtp,
            child: Text(_conLai > 0 ? 'Gửi lại mã sau ${_conLai}s' : 'Gửi lại mã'),
          ),
        ],
      ),
    ];
  }

  List<Widget> _noiDungBuoc3() {
    return [
      _nhan('MẬT KHẨU MỚI'),
      TextField(
        controller: _mkMoiCtrl,
        obscureText: _anMk,
        textInputAction: TextInputAction.next,
        decoration: _kieuO(
          'Nhập mật khẩu mới (tối thiểu 6 ký tự)',
          Icons.lock_outline,
          suffix: IconButton(
            icon: Icon(
                _anMk
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey.shade500,
                size: 20),
            onPressed: () => setState(() => _anMk = !_anMk),
          ),
        ),
      ),
      const SizedBox(height: 22),
      _nhan('XÁC NHẬN MẬT KHẨU'),
      TextField(
        controller: _xacNhanCtrl,
        obscureText: _anMk,
        onSubmitted: (_) => _datLai(),
        decoration: _kieuO('Nhập lại mật khẩu mới', Icons.lock_outline),
      ),
      const SizedBox(height: 30),
      _nut('ĐẶT LẠI MẬT KHẨU', _datLai),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: _dangTai ? null : _quayLai,
          child: const Text('Quay lại bước nhập mã'),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final mau = Theme.of(context).colorScheme;

    const tieuDe = {
      1: 'Quên mật khẩu',
      2: 'Nhập mã OTP',
      3: 'Mật khẩu mới',
    };
    const moTa = {
      1: 'Nhập tên đăng nhập hoặc email đã đăng ký. Chúng tôi sẽ gửi mã OTP đến email của tài khoản.',
      2: 'Mã OTP gồm 6 chữ số, có hiệu lực trong 10 phút.',
      3: 'Tạo mật khẩu mới cho tài khoản của bạn.',
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _mauNut,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Quên mật khẩu'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('BƯỚC $_buoc / 3',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        letterSpacing: 2,
                        color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Text(tieuDe[_buoc]!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontFamilyFallback: ['Times New Roman', 'serif'],
                        fontSize: 34,
                        color: Color(0xFF111A33))),
                const SizedBox(height: 8),
                Text(moTa[_buoc]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                const SizedBox(height: 28),
                if (_buoc >= 2) ...[
                  Text('Tài khoản: ${_dinhDanhCtrl.text.trim()}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                ],
                if (_buoc == 2 && _thongBao != null) ...[
                  _khungThongBao(mau),
                  const SizedBox(height: 18),
                ],
                if (_buoc == 1) ..._noiDungBuoc1(),
                if (_buoc == 2) ..._noiDungBuoc2(),
                if (_buoc == 3) ..._noiDungBuoc3(),
                if (_loi != null) ...[
                  const SizedBox(height: 18),
                  _khungLoi(mau),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}