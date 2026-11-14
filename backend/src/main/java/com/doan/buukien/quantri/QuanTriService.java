package com.doan.buukien.quantri;

import com.doan.buukien.common.AuditContext;
import com.doan.buukien.security.NguoiDungHienTai;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class QuanTriService {

    private static final String SQL_CAU_HINH =
            "SELECT so_ngay_mien_phi, phi_qua_han_moi_ngay, so_gio_hieu_luc_ma FROM cau_hinh_kho WHERE id = 1";

    private final JdbcTemplate jdbc;
    private final AuditContext audit;

    public QuanTriService(JdbcTemplate jdbc, AuditContext audit) {
        this.jdbc = jdbc;
        this.audit = audit;
    }

    @Transactional(readOnly = true)
    public Map<String, Object> tongQuan() {
        return jdbc.queryForMap("SELECT * FROM v_thong_ke_tong_quan");
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> thongKeTu() {
        return jdbc.queryForList("SELECT * FROM v_thong_ke_tu ORDER BY ma_tu");
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> nhatKyAudit(int limit, String hanhDong) {
        return jdbc.queryForList(
                "SELECT id, thoi_gian, nguoi_thao_tac, vai_tro, hanh_dong, doi_tuong, doi_tuong_id, chi_tiet, host(dia_chi_ip) AS dia_chi_ip "
                        + "FROM v_nhat_ky_audit_chi_tiet "
                        + "WHERE (CAST(? AS TEXT) IS NULL OR hanh_dong = CAST(? AS TEXT)) "
                        + "ORDER BY id DESC LIMIT ?",
                hanhDong, hanhDong, limit);
    }

    @Transactional(readOnly = true)
    public Map<String, Object> cauHinh() {
        return jdbc.queryForMap(SQL_CAU_HINH);
    }

    @Transactional
    public Map<String, Object> suaCauHinh(NguoiDungHienTai nd, String ip, CauHinhRequest rq) {
        audit.gan(nd, ip);
        jdbc.update("UPDATE cau_hinh_kho SET so_ngay_mien_phi = ?, phi_qua_han_moi_ngay = ?, so_gio_hieu_luc_ma = ? WHERE id = 1",
                rq.soNgayMienPhi(), rq.phiQuaHanMoiNgay(), rq.soGioHieuLucMa());

        String chiTiet = String.format("so_ngay_mien_phi=%d, phi_qua_han_moi_ngay=%d, so_gio_hieu_luc_ma=%d",
                rq.soNgayMienPhi(), rq.phiQuaHanMoiNgay(), rq.soGioHieuLucMa());
        jdbc.queryForObject("SELECT CAST(fn_ghi_audit('SUA_CAU_HINH_KHO', 'cau_hinh_kho', CAST(? AS BIGINT), ?) AS TEXT)",
                String.class, 1L, chiTiet);

        return jdbc.queryForMap(SQL_CAU_HINH);
    }
}