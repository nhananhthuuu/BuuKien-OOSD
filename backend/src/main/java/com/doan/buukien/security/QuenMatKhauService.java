package com.doan.buukien.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.security.SecureRandom;
import java.util.List;
import java.util.Map;

@Service
public class QuenMatKhauService {

    private static final Logger log = LoggerFactory.getLogger(QuenMatKhauService.class);

    static final int PHUT_HET_HAN = 10;          // OTP hết hạn sau 10 phút
    static final int SO_LAN_SAI_TOI_DA = 5;      // nhập sai tối đa 5 lần
    static final int SO_YEU_CAU_TOI_DA = 3;      // tối đa 3 lần yêu cầu OTP...
    static final int PHUT_GIOI_HAN_YEU_CAU = 15; // ...trong 15 phút

    private final JdbcTemplate jdbc;
    private final PasswordEncoder encoder;
    private final GuiEmailService guiEmail;
    private final TransactionTemplate tx;
    private final SecureRandom random = new SecureRandom();

    public QuenMatKhauService(JdbcTemplate jdbc, PasswordEncoder encoder,
                              GuiEmailService guiEmail, PlatformTransactionManager tm) {
        this.jdbc = jdbc;
        this.encoder = encoder;
        this.guiEmail = guiEmail;
        this.tx = new TransactionTemplate(tm);
    }

    /**
     * Yêu cầu gửi OTP. Không trả về gì: controller luôn trả cùng một thông báo,
     * để người ngoài không dò được tài khoản nào tồn tại.
     */
    public void yeuCau(String dinhDanh, String ip) {
        Map<String, Object> tk = timTaiKhoan(dinhDanh);
        if (tk == null) {
            ghiAudit(null, "QUEN_MK_YEU_CAU_THAT_BAI",
                    "Không tìm thấy tài khoản hoạt động: " + rutGon(dinhDanh), ip);
            return;
        }

        Long id = ((Number) tk.get("id")).longValue();
        String email = (String) tk.get("email");
        if (email == null || email.isBlank()) {
            ghiAudit(id, "QUEN_MK_YEU_CAU_THAT_BAI", "Tài khoản chưa có email", ip);
            return;
        }

        Integer soYeuCau = jdbc.queryForObject("""
                SELECT COUNT(*) FROM otp_quen_mat_khau
                WHERE tai_khoan_id = ? AND ngay_tao > NOW() - (? * INTERVAL '1 minute')
                """, Integer.class, id, PHUT_GIOI_HAN_YEU_CAU);
        if (soYeuCau != null && soYeuCau >= SO_YEU_CAU_TOI_DA) {
            ghiAudit(id, "QUEN_MK_YEU_CAU_THAT_BAI", "Yêu cầu OTP quá nhiều lần", ip);
            return;
        }

        // Vô hiệu các mã cũ chưa dùng
        jdbc.update("UPDATE otp_quen_mat_khau SET da_su_dung = TRUE WHERE tai_khoan_id = ? AND da_su_dung = FALSE", id);

        String otp = String.format("%06d", random.nextInt(1_000_000));
        Long otpId = jdbc.queryForObject("""
                INSERT INTO otp_quen_mat_khau (tai_khoan_id, otp_hash, het_han_luc)
                VALUES (?, ?, NOW() + (? * INTERVAL '1 minute'))
                RETURNING id
                """, Long.class, id, encoder.encode(otp), PHUT_HET_HAN);

        boolean daGui = guiEmail.guiOtp(email, otp, PHUT_HET_HAN);
        if (!daGui) {
            jdbc.update("UPDATE otp_quen_mat_khau SET da_su_dung = TRUE WHERE id = ?", otpId);
            ghiAudit(id, "QUEN_MK_YEU_CAU_THAT_BAI", "Gửi email OTP thất bại", ip);
            return;
        }
        ghiAudit(id, "QUEN_MK_YEU_CAU", "Đã gửi OTP quên mật khẩu", ip);
    }

    /** Kiểm tra OTP đúng và còn hạn hay không (chưa dùng hết mã). */
    public boolean xacMinh(String dinhDanh, String otp, String ip) {
        Map<String, Object> tk = timTaiKhoan(dinhDanh);
        if (tk == null) {
            return false;
        }
        Long id = ((Number) tk.get("id")).longValue();
        boolean ok = kiemTraOtp(id, otp) != null;
        if (!ok) {
            ghiAudit(id, "QUEN_MK_OTP_SAI", "OTP sai, hết hạn hoặc đã bị khóa", ip);
        }
        return ok;
    }

    /** Kiểm tra OTP rồi đặt mật khẩu mới. Trả về true nếu đổi thành công. */
    public boolean datLai(String dinhDanh, String otp, String matKhauMoi, String ip) {
        Map<String, Object> tk = timTaiKhoan(dinhDanh);
        if (tk == null) {
            return false;
        }
        Long id = ((Number) tk.get("id")).longValue();

        if (kiemTraOtp(id, otp) == null) {
            ghiAudit(id, "QUEN_MK_OTP_SAI", "OTP sai, hết hạn hoặc đã bị khóa", ip);
            return false;
        }

        String hashMoi = encoder.encode(matKhauMoi);
        // Đổi mật khẩu và đánh dấu OTP đã dùng: làm cùng một giao dịch
        tx.executeWithoutResult(status -> {
            jdbc.update("UPDATE tai_khoan SET mat_khau_hash = ? WHERE id = ?", hashMoi, id);
            jdbc.update("UPDATE otp_quen_mat_khau SET da_su_dung = TRUE WHERE tai_khoan_id = ? AND da_su_dung = FALSE", id);
        });

        ghiAudit(id, "QUEN_MK_DAT_LAI", "Đặt lại mật khẩu thành công", ip);
        return true;
    }

    // ----- Hàm hỗ trợ -----

    /** Tìm tài khoản đang hoạt động theo tên đăng nhập hoặc email. Không đúng 1 tài khoản thì trả null. */
    private Map<String, Object> timTaiKhoan(String dinhDanh) {
        if (dinhDanh == null || dinhDanh.isBlank()) {
            return null;
        }
        String dd = dinhDanh.trim();
        List<Map<String, Object>> ds = jdbc.queryForList("""
                SELECT id, email FROM tai_khoan
                WHERE trang_thai = 'HOAT_DONG'
                  AND (ten_dang_nhap = ? OR LOWER(email) = LOWER(?))
                """, dd, dd);
        return ds.size() == 1 ? ds.get(0) : null;
    }

    /**
     * Kiểm tra OTP mới nhất còn hiệu lực của tài khoản.
     * Đúng: trả về id bản ghi OTP. Sai: tăng số lần sai và trả null.
     */
    private Long kiemTraOtp(Long taiKhoanId, String otp) {
        if (otp == null || otp.isBlank()) {
            return null;
        }
        List<Map<String, Object>> ds = jdbc.queryForList("""
                SELECT id, otp_hash, so_lan_sai FROM otp_quen_mat_khau
                WHERE tai_khoan_id = ? AND da_su_dung = FALSE AND het_han_luc > NOW()
                ORDER BY ngay_tao DESC
                LIMIT 1
                """, taiKhoanId);
        if (ds.isEmpty()) {
            return null;
        }

        Map<String, Object> b = ds.get(0);
        Long otpId = ((Number) b.get("id")).longValue();
        int soLanSai = ((Number) b.get("so_lan_sai")).intValue();
        if (soLanSai >= SO_LAN_SAI_TOI_DA) {
            return null; // mã này đã bị khóa
        }

        if (!encoder.matches(otp.trim(), (String) b.get("otp_hash"))) {
            jdbc.update("UPDATE otp_quen_mat_khau SET so_lan_sai = so_lan_sai + 1 WHERE id = ?", otpId);
            return null;
        }
        return otpId;
    }

    /** Ghi nhật ký, nếu lỗi thì chỉ cảnh báo, không làm hỏng luồng quên mật khẩu. */
    private void ghiAudit(Long taiKhoanId, String hanhDong, String chiTiet, String ip) {
        try {
            jdbc.update("""
                    INSERT INTO nhat_ky_audit (tai_khoan_id, hanh_dong, doi_tuong, doi_tuong_id, chi_tiet, dia_chi_ip)
                    VALUES (?, ?, 'tai_khoan', ?, ?, ?::inet)
                    """, taiKhoanId, hanhDong, taiKhoanId, chiTiet, ip);
        } catch (Exception e) {
            log.warn("Ghi audit that bai ({}): {}", hanhDong, e.getMessage());
        }
    }

    private String rutGon(String s) {
        if (s == null) {
            return "";
        }
        return s.length() > 50 ? s.substring(0, 50) : s;
    }
}