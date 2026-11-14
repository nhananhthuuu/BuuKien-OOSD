package com.doan.buukien.quantri;

import com.doan.buukien.common.AuditContext;
import com.doan.buukien.security.NguoiDungHienTai;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class TaiKhoanEmailService {

    private final JdbcTemplate jdbc;
    private final AuditContext audit;

    public TaiKhoanEmailService(JdbcTemplate jdbc, AuditContext audit) {
        this.jdbc = jdbc;
        this.audit = audit;
    }

    private void ghi(String hanhDong, String doiTuong, Long doiTuongId, String chiTiet) {
        jdbc.queryForList(
                "SELECT 1 FROM (SELECT fn_ghi_audit(?::text, ?::text, ?::bigint, ?::text)) x",
                hanhDong, doiTuong, doiTuongId, chiTiet);
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> dsTaiKhoan() {
        return jdbc.queryForList("""
                SELECT tk.id, tk.ten_dang_nhap, tk.vai_tro, tk.trang_thai, tk.email,
                       COALESCE(cd.ho_ten, nv.ho_ten, sp.ho_ten) AS ho_ten
                FROM tai_khoan tk
                LEFT JOIN cu_dan cd ON cd.tai_khoan_id = tk.id
                LEFT JOIN nhan_vien nv ON nv.tai_khoan_id = tk.id
                LEFT JOIN shipper sp ON sp.tai_khoan_id = tk.id
                ORDER BY tk.id
                """);
    }

    @Transactional
    public Map<String, Object> suaEmail(NguoiDungHienTai nd, String ip, Long id, String emailMoi) {
        audit.gan(nd, ip);

        List<String> vaiTro = jdbc.queryForList(
                "SELECT vai_tro FROM tai_khoan WHERE id = ?", String.class, id);
        if (vaiTro.isEmpty()) {
            throw new IllegalArgumentException("Không tìm thấy tài khoản " + id);
        }

        // Để trống thì lưu NULL; có email thì không được trùng tài khoản khác
        String email = (emailMoi == null || emailMoi.isBlank()) ? null : emailMoi.trim();
        if (email != null) {
            Integer trung = jdbc.queryForObject(
                    "SELECT count(*) FROM tai_khoan WHERE LOWER(email) = LOWER(?) AND id <> ?",
                    Integer.class, email, id);
            if (trung != null && trung > 0) {
                throw new IllegalArgumentException("Email " + email + " đã được dùng cho tài khoản khác");
            }
        }

        jdbc.update("UPDATE tai_khoan SET email = ? WHERE id = ?", email, id);
        // Cư dân còn lưu email ở bảng cu_dan: giữ hai nơi khớp nhau
        if ("CU_DAN".equals(vaiTro.get(0))) {
            jdbc.update("UPDATE cu_dan SET email = ? WHERE tai_khoan_id = ?", email, id);
        }

        ghi("SUA_EMAIL_TAI_KHOAN", "tai_khoan", id, email == null ? "xóa email" : "email=" + email);
        return Map.of("thanhCong", true);
    }
}