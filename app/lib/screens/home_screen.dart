import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'cu_dan_screen.dart';
import 'nhan_vien_screen.dart';
import 'quan_tri_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _tenVaiTro(String? v) {
    switch (v) {
      case 'CU_DAN':
        return 'Cư dân';
      case 'NHAN_VIEN':
        return 'Nhân viên';
      case 'SHIPPER':
        return 'Shipper';
      case 'QUAN_TRI_VIEN':
        return 'Quản trị viên';
      default:
        return v ?? '';
    }
  }

  Future<void> _dangXuat(BuildContext context) async {
    await ApiService.dangXuat();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

    @override
  Widget build(BuildContext context) {
    if (ApiService.vaiTro == 'CU_DAN') return const CuDanScreen();
    if (ApiService.vaiTro == 'CU_DAN') return const CuDanScreen();
    if (ApiService.vaiTro == 'NHAN_VIEN') return const NhanVienScreen();
    if (ApiService.vaiTro == 'QUAN_TRI_VIEN') return const QuanTriScreen();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bưu kiện thông minh'),
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => _dangXuat(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 72, color: Colors.green),
            const SizedBox(height: 16),
            Text('Xin chào, ${ApiService.tenDangNhap ?? ''}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Vai trò: ${_tenVaiTro(ApiService.vaiTro)}'),
          ],
        ),
      ),
    );
  }
}