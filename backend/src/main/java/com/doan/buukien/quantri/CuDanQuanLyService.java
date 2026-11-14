package com.doan.buukien.quantri;

import com.doan.buukien.common.AuditContext;
import com.doan.buukien.security.NguoiDungHienTai;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class CuDanQuanLyService {

    // Điều kiện "đang cư trú" (giống view v_buu_kien_cua_cu_dan)
    private static final String DANG_O =
            "ct.ngay_bat_dau <= CURRENT_DATE AND (ct.ngay_ket_thuc IS NULL OR ct.ngay_ket_thuc >= CURRENT_DATE)";

    private final JdbcTemplate jdbc;
    private final AuditContext audit;

    public CuDanQuanLyService(JdbcTemplate jdbc, AuditContext audit) {
        this.jdbc = jdbc;
        this.audit = audit;
    }

    private void ghi(String hanhDong, String doiTuong, Long doiTuongId, String chiTiet) {
        jdbc.queryForList(
                "SELECT 1 FROM (SELECT fn_ghi_audit(?::text, ?::text, ?::bigint, ?::text)) x",
                hanhDong, doiTuong, doiTuongId, chiTiet);
    }

    private Long idCanHo(String soCanHo) {
        List<Long> ds = jdbc.queryForList(
                "SELECT id FROM can_ho WHERE so_can_ho = upper(trim(?))", Long.class, soCanHo);
        if (ds.isEmpty()) {
            throw new IllegalArgumentException("Không tìm thấy căn hộ " + soCanHo);
        }
        return ds.get(0);
    }

    // ------------------------------------------------------------ Cư dân

    public List<Map<String, Object>> dsCuDan() {
        return jdbc.queryForList(
                "SELECT cd.id, cd.ho_ten, cd.sdt, cd.email, cd.kenh_thong_bao_uu_tien, "
                        + "tk.ten_dang_nhap, tk.trang_thai, "
                        + "(SELECT string_agg(ch.so_can_ho, ', ' ORDER BY ch.so_can_ho) "
                        + " FROM cu_tru ct JOIN can_ho ch ON ch.id = ct.can_ho_id "
                        + " WHERE ct.cu_dan_id = cd.id AND " + DANG_O + ") AS can_ho_dang_o "
                        + "FROM cu_dan cd JOIN tai_khoan tk ON tk.id = cd.tai_khoan_id ORDER BY cd.id");
    }

    @Transactional
    public Map<String, Object> themCuDan(NguoiDungHienTai nd, String ip, CuDanQuanLyController.CuDanMoi rq) {
        audit.gan(nd, ip);
        Integer trung = jdbc.queryForObject(
                "SELECT count(*) FROM tai_khoan WHERE ten_dang_nhap = ?", Integer.class, rq.tenDangNhap());
        if (trung != null && trung > 0) {
            throw new IllegalArgumentException("Tên đăng nhập " + rq.tenDangNhap() + " đã tồn tại");
        }
        // Email để trống thì lưu NULL; có email thì không được trùng tài khoản khác
        String email = (rq.email() == null || rq.email().isBlank()) ? null : rq.email().trim();
        if (email != null) {
            Integer trungEmail = jdbc.queryForObject(
                    "SELECT count(*) FROM tai_khoan WHERE LOWER(email) = LOWER(?)", Integer.class, email);
            if (trungEmail != null && trungEmail > 0) {
                throw new IllegalArgumentException("Email " + email + " đã được dùng cho tài khoản khác");
            }
        }
        Long canHo = idCanHo(rq.soCanHo());
        Long tkId = jdbc.queryForObject(
                "INSERT INTO tai_khoan (ten_dang_nhap, mat_khau_hash, vai_tro, email) "
                        + "VALUES (?, crypt(?, gen_salt('bf')), 'CU_DAN', ?) RETURNING id",
                Long.class, rq.tenDangNhap(), rq.matKhau(), email);
        String kenh = rq.kenhThongBao() == null ? "APP" : rq.kenhThongBao();
        Long id = jdbc.queryForObject(
                "INSERT INTO cu_dan (tai_khoan_id, ho_ten, sdt, email, kenh_thong_bao_uu_tien) "
                        + "VALUES (?, ?, ?, ?, ?) RETURNING id",
                Long.class, tkId, rq.hoTen(), rq.sdt(), email, kenh);
        jdbc.update("INSERT INTO cu_tru (cu_dan_id, can_ho_id) VALUES (?, ?)", id, canHo);
        ghi("TAO_CU_DAN", "cu_dan", id,
                "tai_khoan=" + rq.tenDangNhap() + ", can_ho=" + rq.soCanHo().trim().toUpperCase());
        return Map.of("id", id);
    }

    @Transactional
    public Map<String, Object> ganCanHo(NguoiDungHienTai nd, String ip, Long cuDanId, String soCanHo) {
        audit.gan(nd, ip);
        Integer co = jdbc.queryForObject(
                "SELECT count(*) FROM cu_dan WHERE id = ?", Integer.class, cuDanId);
        if (co == null || co == 0) {
            throw new IllegalArgumentException("Không tìm thấy cư dân " + cuDanId);
        }
        Long canHo = idCanHo(soCanHo);
        Integer daO = jdbc.queryForObject(
                "SELECT count(*) FROM cu_tru ct WHERE ct.cu_dan_id = ? AND ct.can_ho_id = ? AND " + DANG_O,
                Integer.class, cuDanId, canHo);
        if (daO != null && daO > 0) {
            throw new IllegalArgumentException("Cư dân này đang ở căn hộ " + soCanHo.trim().toUpperCase());
        }
        jdbc.update("INSERT INTO cu_tru (cu_dan_id, can_ho_id) VALUES (?, ?) "
                + "ON CONFLICT DO NOTHING", cuDanId, canHo);
        // Cư dân từng bị khóa do chuyển đi thì mở lại khi quay về ở
        jdbc.update("UPDATE tai_khoan SET trang_thai = 'HOAT_DONG' "
                + "WHERE id = (SELECT tai_khoan_id FROM cu_dan WHERE id = ?)", cuDanId);
        ghi("GAN_CAN_HO", "cu_dan", cuDanId, "can_ho=" + soCanHo.trim().toUpperCase());
        return Map.of("thanhCong", true);
    }

    // Chuyển đi: kết thúc mọi cư trú đang có, khóa tài khoản. Không xóa dữ liệu (giữ lịch sử, audit).
    @Transactional
    public Map<String, Object> chuyenDi(NguoiDungHienTai nd, String ip, Long cuDanId) {
        audit.gan(nd, ip);
        Integer co = jdbc.queryForObject(
                "SELECT count(*) FROM cu_dan WHERE id = ?", Integer.class, cuDanId);
        if (co == null || co == 0) {
            throw new IllegalArgumentException("Không tìm thấy cư dân " + cuDanId);
        }
        // Bưu kiện chưa nhận ở căn hộ mà người này là người ở cuối cùng
        Integer coBuuKien = jdbc.queryForObject(
                "SELECT count(*) FROM buu_kien b WHERE b.trang_thai IN ('CHO_NHAN','QUA_HAN') "
                        + "AND b.can_ho_id IN (SELECT ct.can_ho_id FROM cu_tru ct WHERE ct.cu_dan_id = ? AND " + DANG_O + ") "
                        + "AND NOT EXISTS (SELECT 1 FROM cu_tru ct WHERE ct.can_ho_id = b.can_ho_id "
                        + "AND ct.cu_dan_id <> ? AND " + DANG_O + ")",
                Integer.class, cuDanId, cuDanId);

        // Dòng cư trú mới bắt đầu hôm nay mà đã có dòng "hôm qua" cùng căn hộ: bỏ dòng thừa để khỏi trùng khóa
        jdbc.update("DELETE FROM cu_tru ct WHERE ct.cu_dan_id = ? AND " + DANG_O + " "
                        + "AND ct.ngay_bat_dau >= CURRENT_DATE "
                        + "AND EXISTS (SELECT 1 FROM cu_tru x WHERE x.cu_dan_id = ct.cu_dan_id "
                        + "AND x.can_ho_id = ct.can_ho_id AND x.ngay_bat_dau = CURRENT_DATE - 1 AND x.id <> ct.id)",
                cuDanId);
        jdbc.update("UPDATE cu_tru ct SET ngay_ket_thuc = CURRENT_DATE - 1, "
                + "ngay_bat_dau = LEAST(ngay_bat_dau, CURRENT_DATE - 1) "
                + "WHERE ct.cu_dan_id = ? AND " + DANG_O, cuDanId);
        jdbc.update("UPDATE tai_khoan SET trang_thai = 'KHOA' "
                + "WHERE id = (SELECT tai_khoan_id FROM cu_dan WHERE id = ?)", cuDanId);
        ghi("CU_DAN_CHUYEN_DI", "cu_dan", cuDanId, "bưu kiện chưa nhận không còn người ở: " + coBuuKien);
        return Map.of("thanhCong", true, "buuKienKhongNguoiNhan", coBuuKien == null ? 0 : coBuuKien);
    }

    // ------------------------------------------------------------ Căn hộ

    public List<Map<String, Object>> dsCanHo() {
        return jdbc.queryForList(
                "SELECT ch.id, ch.so_can_ho, ch.tang, ch.toa_nha, ch.trang_thai, "
                        + "(SELECT count(*) FROM cu_tru ct WHERE ct.can_ho_id = ch.id AND " + DANG_O + ") AS so_cu_dan "
                        + "FROM can_ho ch ORDER BY ch.toa_nha, ch.tang, ch.so_can_ho");
    }

    @Transactional
    public Map<String, Object> themCanHo(NguoiDungHienTai nd, String ip, CuDanQuanLyController.CanHoMoi rq) {
        audit.gan(nd, ip);
        String so = rq.soCanHo().trim().toUpperCase();
        Integer trung = jdbc.queryForObject(
                "SELECT count(*) FROM can_ho WHERE so_can_ho = ?", Integer.class, so);
        if (trung != null && trung > 0) {
            throw new IllegalArgumentException("Căn hộ " + so + " đã tồn tại");
        }
        Long id = jdbc.queryForObject(
                "INSERT INTO can_ho (so_can_ho, tang, toa_nha) VALUES (?, ?, ?) RETURNING id",
                Long.class, so, rq.tang(), rq.toaNha().trim().toUpperCase());
        ghi("TAO_CAN_HO", "can_ho", id, "so_can_ho=" + so);
        return Map.of("id", id, "soCanHo", so);
    }
}