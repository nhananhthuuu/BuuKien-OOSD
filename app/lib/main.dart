import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'config/app_theme.dart';
void main() {
  runApp(const BuuKienApp());
}

class BuuKienApp extends StatelessWidget {
  const BuuKienApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bưu kiện thông minh',
      debugShowCheckedModeBanner: false,
            theme: AppTheme.theme(),
      home: const KhoiDong(),
    );
  }
}

/// Màn hình chờ: kiểm tra còn phiên đăng nhập cũ không.
class KhoiDong extends StatelessWidget {
  const KhoiDong({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ApiService.khoiPhucPhien(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snap.data == true ? const HomeScreen() : const LoginScreen();
      },
    );
  }
}