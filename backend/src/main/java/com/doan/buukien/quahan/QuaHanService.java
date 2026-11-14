package com.doan.buukien.quahan;

import com.doan.buukien.common.AuditContext;
import com.doan.buukien.security.NguoiDungHienTai;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Service
public class QuaHanService {

    private final JdbcTemplate jdbc;
    private final AuditContext audit;

    public QuaHanService(JdbcTemplate jdbc, AuditContext audit) {
        this.jdbc = jdbc;
        this.audit = audit;
    }

    // Việc của HỆ THỐNG: chuyển bưu kiện hết hạn sang QUA_HAN, tạo hồ sơ + thông báo
    @Transactional
    public int quet() {
        Integer n = jdbc.queryForObject("SELECT danh_dau_qua_han()", Integer.class);
        return n == null ? 0 : n;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> danhSach() {
        return jdbc.queryForList("SELECT * FROM v_buu_kien_qua_han ORDER BY so_ngay_qua_han DESC");
    }

    @Transactional
    public BigDecimal xuLy(NguoiDungHienTai nd, String ip, Long buuKienId, XuLyQuaHanRequest rq) {
        audit.gan(nd, ip);

        List<Long> ds = jdbc.queryForList(
                "SELECT id FROM nhan_vien WHERE tai_khoan_id = ?", Long.class, nd.id());
        if (ds.isEmpty()) {
            throw new IllegalArgumentException("Tài khoản này không phải nhân viên");
        }

        return jdbc.queryForObject(
                "SELECT xu_ly_buu_kien_qua_han(?, ?, ?, CAST(? AS TEXT))",
                BigDecimal.class, buuKienId, rq.hinhThuc(), ds.get(0), rq.ghiChu());
    }
}