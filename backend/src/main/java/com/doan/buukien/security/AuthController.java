package com.doan.buukien.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    public record LoginRequest(@NotBlank String tenDangNhap, @NotBlank String matKhau) {
    }

    private final JdbcTemplate jdbc;
    private final PasswordEncoder encoder;
    private final JwtService jwtService;

    public AuthController(JdbcTemplate jdbc, PasswordEncoder encoder, JwtService jwtService) {
        this.jdbc = jdbc;
        this.encoder = encoder;
        this.jwtService = jwtService;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest req, HttpServletRequest http) {
        String ip = http.getRemoteAddr();

        List<Map<String, Object>> ds = jdbc.queryForList(
                "SELECT id, mat_khau_hash, vai_tro, trang_thai FROM tai_khoan WHERE ten_dang_nhap = ?",
                req.tenDangNhap());

        // Sai tên hoặc sai mật khẩu: trả cùng một thông báo, không để lộ tên nào tồn tại
        if (ds.isEmpty()) {
            ghiAudit(null, "DANG_NHAP_THAT_BAI", null, "Tên đăng nhập không tồn tại: " + req.tenDangNhap(), ip);
            return loiDangNhap();
        }

        Map<String, Object> tk = ds.get(0);
        Long id = ((Number) tk.get("id")).longValue();

        if (!"HOAT_DONG".equals(tk.get("trang_thai"))) {
            ghiAudit(id, "DANG_NHAP_THAT_BAI", id, "Tài khoản đang bị khóa", ip);
            return loiDangNhap();
        }
        if (!encoder.matches(req.matKhau(), (String) tk.get("mat_khau_hash"))) {
            ghiAudit(id, "DANG_NHAP_THAT_BAI", id, "Sai mật khẩu", ip);
            return loiDangNhap();
        }

        String vaiTro = (String) tk.get("vai_tro");
        ghiAudit(id, "DANG_NHAP", id, "Đăng nhập thành công", ip);
        String token = jwtService.taoToken(id, req.tenDangNhap(), vaiTro);
        return ResponseEntity.ok(Map.of(
                "token", token,
                "tenDangNhap", req.tenDangNhap(),
                "vaiTro", vaiTro));
    }

    // Kiểm tra token đang là ai
    @GetMapping("/me")
    public NguoiDungHienTai toiLaAi(@AuthenticationPrincipal NguoiDungHienTai nguoiDung) {
        return nguoiDung;
    }

    private ResponseEntity<?> loiDangNhap() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("loi", "Tên đăng nhập hoặc mật khẩu không đúng"));
    }

    private void ghiAudit(Long taiKhoanId, String hanhDong, Long doiTuongId, String chiTiet, String ip) {
        jdbc.update("""
                INSERT INTO nhat_ky_audit (tai_khoan_id, hanh_dong, doi_tuong, doi_tuong_id, chi_tiet, dia_chi_ip)
                VALUES (?, ?, 'tai_khoan', ?, ?, ?::inet)
                """, taiKhoanId, hanhDong, doiTuongId, chiTiet, ip);
    }
}