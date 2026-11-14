package com.doan.buukien.nhanvien;

import com.doan.buukien.common.AuditContext;
import com.doan.buukien.security.NguoiDungHienTai;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class NhanVienService {

    private static final Logger log = LoggerFactory.getLogger(NhanVienService.class);

    private final JdbcTemplate jdbc;
    private final AuditContext audit;

    public NhanVienService(JdbcTemplate jdbc, AuditContext audit) {
        this.jdbc = jdbc;
        this.audit = audit;
    }

    @Transactional
    public List<Map<String, Object>> danhSachDangLuu(NguoiDungHienTai nd, String ip) {
        audit.gan(nd, ip);
        return jdbc.queryForList("SELECT * FROM v_buu_kien_dang_luu");
    }

    @Transactional
    public boolean tonTaiCanHo(NguoiDungHienTai nd, String ip, String soCanHo) {
        audit.gan(nd, ip);
        Boolean kq = jdbc.queryForObject("SELECT ton_tai_can_ho(?)", Boolean.class, soCanHo);
        return Boolean.TRUE.equals(kq);
    }

    @Transactional
    public Map<String, Object> tiepNhan(NguoiDungHienTai nd, String ip, TiepNhanRequest rq) {
        audit.gan(nd, ip);

        // 1. Tra id nhân viên từ tài khoản đang đăng nhập
        List<Long> ds = jdbc.queryForList(
                "SELECT id FROM nhan_vien WHERE tai_khoan_id = ?", Long.class, nd.id());
        if (ds.isEmpty()) {
            throw new IllegalArgumentException("Tài khoản này không phải nhân viên");
        }
        Long nhanVienId = ds.get(0);

        // 2. Tiếp nhận: DB tự chọn ngăn, tính hạn lưu, tạo thông báo, ghi audit
        Map<String, Object> kq = jdbc.queryForMap(
                "SELECT o_buu_kien_id, o_ma_ngan FROM tiep_nhan_buu_kien(?, ?, ?, ?, CAST(? AS BIGINT))",
                rq.maVanDon(), rq.soCanHo(), rq.kichCo(), nhanVienId, rq.shipperId());
        Long buuKienId = ((Number) kq.get("o_buu_kien_id")).longValue();
        String maNgan = (String) kq.get("o_ma_ngan");

        // 3. Sinh mã nhận 6 số (CSDL chỉ lưu bản băm). KHÔNG trả cho nhân viên.
        String maNhan = jdbc.queryForObject(
                "SELECT sinh_ma_nhan(?, NULL::bigint)", String.class, buuKienId);

        // 4. Giả lập gửi cho cư dân (sau này đổi thành SMS/Email/RabbitMQ)
        log.info("[GIA LAP GUI CU DAN] Buu kien {} (can ho {}) - ma nhan: {}",
                rq.maVanDon(), rq.soCanHo(), maNhan);

        Map<String, Object> out = new LinkedHashMap<>();
        out.put("buuKienId", buuKienId);
        out.put("maNgan", maNgan);
        out.put("thongBao", "Đã tiếp nhận. Hãy bỏ bưu kiện vào ngăn " + maNgan
                + ". Mã nhận đã được gửi cho cư dân.");
        return out;
    }
}