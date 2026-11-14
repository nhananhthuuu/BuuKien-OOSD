import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'quen_mat_khau_screen.dart';

/// Ảnh bìa bên trái trang đăng nhập. Muốn đổi tấm khác thì đổi số ở đây.
const String kAnhBia = 'assets/images/toanha2.jpg';

const String kTenChungCu = 'Chung cư Lavithor';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _anMatKhau = true;
  bool _dangTai = false;
  bool _ghiNho = false;
  String? _loi;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _dangNhap() async {
    final u = _userCtrl.text.trim();
    final p = _passCtrl.text;
    if (u.isEmpty || p.isEmpty) {
      setState(() => _loi = 'Vui lòng nhập đủ tên đăng nhập và mật khẩu');
      return;
    }
    setState(() {
      _dangTai = true;
      _loi = null;
    });
    final loi = await ApiService.dangNhap(u, p, ghiNho: _ghiNho);
    if (!mounted) return;
    if (loi == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() {
        _dangTai = false;
        _loi = loi;
      });
    }
  }

    Widget _bia() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          kAnhBia,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => Container(color: AppTheme.chinh),
        ),
        // Phần trên giữ ảnh rõ nét, chỉ tối dần ở đáy để chữ trắng dễ đọc
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppTheme.toi.withValues(alpha: 0.30),
                AppTheme.toi.withValues(alpha: 0.88),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(56),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                    color: AppTheme.cam, shape: BoxShape.circle),
                child: const Icon(Icons.inventory_2_rounded,
                    color: Colors.white, size: 34),
              ),
              const SizedBox(height: 22),
              const Text('Quản lý bưu kiện\ntòa nhà thông minh',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1.2)),
              const SizedBox(height: 12),
              const Text('Nhận hàng an toàn, minh bạch, không cần chờ đợi.',
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

    /// Tên chung cư ở đầu cột đăng nhập
  Widget _thuongHieu() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('LAVITHOR',
            style: TextStyle(
                fontFamily: 'Georgia',
                fontFamilyFallback: ['Times New Roman', 'serif'],
                fontSize: 34,
                letterSpacing: 8,
                color: Color(0xFF4A4F63))),
        const SizedBox(height: 10),
        Container(width: 90, height: 1, color: const Color(0xFF9A9DAB)),
        const SizedBox(height: 10),
        const Text('RESIDENCE',
            style: TextStyle(
                fontSize: 12, letterSpacing: 5, color: Color(0xFF7A7E8F))),
      ],
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

  Widget _form() {
    final mau = Theme.of(context).colorScheme;
    return Container(
      color: Colors.white,
      child: Stack(
        children: [
          Positioned(
            top: 32,
            left: 0,
            right: 0,
            child: Center(child: _thuongHieu()),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Đăng nhập',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Georgia',
                            fontFamilyFallback: ['Times New Roman', 'serif'],
                            fontSize: 40,
                            color: Color(0xFF111A33))),
                    const SizedBox(height: 8),
                    Text('Chào mừng bạn quay lại cổng quản lý bưu kiện.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14)),
                    const SizedBox(height: 36),
                    _nhan('TÊN ĐĂNG NHẬP'),
                    TextField(
                      controller: _userCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: _kieuO(
                          'Nhập tên đăng nhập của bạn', Icons.person_outline),
                    ),
                    const SizedBox(height: 22),
                    _nhan('MẬT KHẨU'),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _anMatKhau,
                      onSubmitted: (_) => _dangNhap(),
                      decoration: _kieuO(
                        'Nhập mật khẩu',
                        Icons.lock_outline,
                        suffix: IconButton(
                          icon: Icon(
                              _anMatKhau
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey.shade500,
                              size: 20),
                          onPressed: () =>
                              setState(() => _anMatKhau = !_anMatKhau),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _ghiNho,
                            activeColor: AppTheme.chinh,
                            onChanged: (v) =>
                                setState(() => _ghiNho = v ?? false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('Ghi nhớ đăng nhập',
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 13.5)),
                        const Spacer(),
                        InkWell(
                          onTap: () async {
                            final ok = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                  builder: (_) => const QuenMatKhauScreen()),
                            );
                            if (!mounted) return;
                            if (ok == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại.')),
                              );
                            }
                          },
                          child: const Text('Quên mật khẩu?',
                              style: TextStyle(
                                  color: Color(0xFF3A3F52),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    if (_loi != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mau.errorContainer,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline,
                              color: mau.onErrorContainer, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_loi!,
                                  style: TextStyle(
                                      color: mau.onErrorContainer))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 30),
                    SizedBox(
                      height: 54,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF111A33),
                          shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero),
                        ),
                        onPressed: _dangTai ? null : _dangNhap,
                        child: _dangTai
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : const Text('ĐĂNG NHẬP',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ---------- Chân trang ----------

  Widget _tieuDeCot(String t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Container(width: 36, height: 3, color: AppTheme.cam),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _cotChan(String tieuDe, List<String> muc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeCot(tieuDe),
        for (final m in muc)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Text(m,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ),
      ],
    );
  }

  Widget _cotLienHe() {
    const kieu = TextStyle(color: Colors.white70, fontSize: 14, height: 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _tieuDeCot('Liên hệ'),
        const Text('CÔNG TY CP PHÁT TRIỂN\nBẤT ĐỘNG SẢN LAVITHOR',
            style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                height: 1.3)),
        const SizedBox(height: 12),
        const Text(
            'Chủ đầu tư và vận hành tổ hợp căn hộ Lavithor Residence, thành lập năm 2012 tại TP. Hồ Chí Minh.',
            style: kieu),
        const SizedBox(height: 12),
        const Text.rich(TextSpan(style: kieu, children: [
          TextSpan(
              text: 'Văn phòng Ban quản lý: ',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          TextSpan(
              text:
                  'Tầng trệt Tòa A, 128 Nguyễn Hữu Cảnh, Phường 22, Quận Bình Thạnh, TP. Hồ Chí Minh'),
        ])),
        const SizedBox(height: 8),
        const Text.rich(TextSpan(style: kieu, children: [
          TextSpan(
              text: 'Hotline: ',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          TextSpan(text: '1900 6868 (24/7)'),
        ])),
        const Text.rich(TextSpan(style: kieu, children: [
          TextSpan(
              text: 'Email: ',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          TextSpan(text: 'banquanly@lavithor.vn'),
        ])),
      ],
    );
  }

  Widget _chanTrang(bool rong) {
    final cotLienKet = _cotChan('Liên kết', const [
      'Tủ locker',
      'Hướng dẫn nhận hàng',
      'Quy định lưu kho',
      'Phí lưu kho quá hạn',
      'Liên hệ Ban quản lý',
    ]);
    final cotVeChungToi = _cotChan('Về chúng tôi', const [
      'Tầm nhìn',
      'Ban quản lý tòa nhà',
      'Tuyển dụng',
      'Chính sách quyền riêng tư',
      'Điều khoản sử dụng',
    ]);
    final cotHoTro = _cotChan('Hỗ trợ', const [
      'Câu hỏi thường gặp',
      'Báo sự cố tủ locker',
      'Quên mã nhận hàng',
      'Hướng dẫn sử dụng',
    ]);

    return Container(
      width: double.infinity,
      color: AppTheme.toi,
      padding: EdgeInsets.symmetric(
          horizontal: rong ? 56 : 24, vertical: rong ? 44 : 32),
      child: Column(
        children: [
          if (rong)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: _cotLienHe()),
                const SizedBox(width: 40),
                Expanded(flex: 2, child: cotLienKet),
                Expanded(flex: 2, child: cotVeChungToi),
                Expanded(flex: 2, child: cotHoTro),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cotLienHe(),
                const SizedBox(height: 28),
                cotLienKet,
                const SizedBox(height: 20),
                cotVeChungToi,
                const SizedBox(height: 20),
                cotHoTro,
              ],
            ),
          const SizedBox(height: 28),
          Divider(color: Colors.white.withValues(alpha: 0.18)),
          const SizedBox(height: 12),
          const Text(
              '© 2026 Chung cư Lavithor. Hệ thống quản lý bưu kiện tòa nhà thông minh.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 12.5)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, c) {
          final rong = c.maxWidth >= 900;
          final cao = c.maxHeight < 640 ? 640.0 : c.maxHeight;
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: cao,
                  child: rong
                      ? Row(
                          children: [
                            Expanded(flex: 5, child: _bia()),
                            Expanded(flex: 4, child: _form()),
                          ],
                        )
                      : _form(),
                ),
                _chanTrang(rong),
              ],
            ),
          );
        },
      ),
    );
  }
}