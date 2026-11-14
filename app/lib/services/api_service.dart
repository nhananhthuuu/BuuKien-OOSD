import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static String? token;
  static String? tenDangNhap;
  static String? vaiTro;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static dynamic _giaiMa(http.Response r) {
    if (r.bodyBytes.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(r.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  /// Trả về null nếu đăng nhập thành công, ngược lại trả về câu báo lỗi.
    static Future<String?> dangNhap(String user, String pass,
      {bool ghiNho = false}) async {
    try {
      final r = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'tenDangNhap': user, 'matKhau': pass}),
          )
          .timeout(const Duration(seconds: 10));

      final data = _giaiMa(r);
      if (r.statusCode == 200 && data is Map) {
        token = data['token'];
        tenDangNhap = data['tenDangNhap'];
        vaiTro = data['vaiTro'];
        final prefs = await SharedPreferences.getInstance();
        if (ghiNho) {
          await prefs.setString('token', token!);
        } else {
          await prefs.remove('token');
        }
        return null;
      }
      if (data is Map && data['loi'] != null) return data['loi'].toString();
      return 'Sai tên đăng nhập hoặc mật khẩu';
    } catch (_) {
      return 'Không kết nối được máy chủ. Kiểm tra Docker và backend đã chạy chưa.';
    }
  }
  /// Mở lại app: nếu còn token hợp lệ thì vào thẳng, không cần đăng nhập lại.
  static Future<bool> khoiPhucPhien() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('token');
      if (saved == null) return false;
      token = saved;
      final r = await http
          .get(Uri.parse('${ApiConfig.baseUrl}/api/auth/me'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      final data = _giaiMa(r);
      if (r.statusCode == 200 && data is Map) {
        tenDangNhap = data['tenDangNhap'];
        vaiTro = data['vaiTro'];
        return true;
      }
    } catch (_) {}
    await dangXuat();
    return false;
  }

  static Future<void> dangXuat() async {
    token = null;
    tenDangNhap = null;
    vaiTro = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
    /// Lấy dữ liệu GET (danh sách hoặc object). Ném lỗi nếu thất bại.
  static Future<dynamic> layDuLieu(String duongDan) async {
    final r = await http
        .get(Uri.parse('${ApiConfig.baseUrl}$duongDan'), headers: _headers)
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw Exception('Lỗi ${r.statusCode}');
    }
    return _giaiMa(r);
  }

  /// Cư dân nhập mã nhận. Trả về null nếu thành công, ngược lại trả câu báo lỗi.
  static Future<String?> nhapMaNhan(int buuKienId, String ma) async {
    try {
      final r = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/cu-dan/buu-kien/$buuKienId/nhan'),
            headers: _headers,
            body: jsonEncode({'ma': ma}),
          )
          .timeout(const Duration(seconds: 10));
      final data = _giaiMa(r);
      if (r.statusCode == 200 && data is Map && data['thanhCong'] == true) {
        return null;
      }
      if (data is Map && data['loi'] != null) return data['loi'].toString();
      return 'Mã không đúng, đã hết hạn hoặc đã được dùng';
    } catch (_) {
      return 'Không kết nối được máy chủ';
    }
  }
    /// Gửi POST JSON. ok = true khi HTTP 200; ngược lại 'loi' chứa câu báo lỗi.
  static Future<({bool ok, dynamic data, String? loi})> guiJson(
      String duongDan,
      [Map<String, dynamic>? body]) async {
    try {
      final r = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}$duongDan'),
            headers: _headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(const Duration(seconds: 15));
      final data = _giaiMa(r);
      if (r.statusCode == 200) return (ok: true, data: data, loi: null);
      if (r.statusCode == 403) {
        return (ok: false, data: null, loi: 'Bạn không có quyền thực hiện thao tác này');
      }
      final loi = (data is Map && data['loi'] != null)
          ? data['loi'].toString()
          : 'Lỗi ${r.statusCode}';
      return (ok: false, data: null, loi: loi);
    } catch (_) {
      return (ok: false, data: null, loi: 'Không kết nối được máy chủ');
    }
  }
    /// Gửi PUT JSON, cùng kiểu trả về với guiJson.
  static Future<({bool ok, dynamic data, String? loi})> suaJson(
      String duongDan, Map<String, dynamic> body) async {
    try {
      final r = await http
          .put(
            Uri.parse('${ApiConfig.baseUrl}$duongDan'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
      final data = _giaiMa(r);
      if (r.statusCode == 200) return (ok: true, data: data, loi: null);
      if (r.statusCode == 403) {
        return (ok: false, data: null, loi: 'Bạn không có quyền thực hiện thao tác này');
      }
      final loi = (data is Map && data['loi'] != null)
          ? data['loi'].toString()
          : 'Lỗi ${r.statusCode}';
      return (ok: false, data: null, loi: loi);
    } catch (_) {
      return (ok: false, data: null, loi: 'Không kết nối được máy chủ');
    }
  }
}