package com.doan.buukien.cudan;

import com.doan.buukien.common.AuditContext;
import com.doan.buukien.security.NguoiDungHienTai;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class CuDanService {

    private final JdbcTemplate jdbc;
    private final AuditContext audit;

    public CuDanService(JdbcTemplate jdbc, AuditContext audit) {
        this.jdbc = jdbc;
        this.audit = audit;
    }

    private Long cuDanId(NguoiDungHienTai nd) {
        List<Long> ds = jdbc.queryForList(
                "SELECT id FROM cu_dan WHERE tai_khoan_id = ?", Long.class, nd.id());
        if (ds.isEmpty()) {
            throw new IllegalArgumentException("Tài khoản này không phải cư dân");
        }
        return ds.get(0);
    }

    @Transactional
    public List<Map<String, Object>> buuKienCuaToi(NguoiDungHienTai nd, String ip) {
        audit.gan(nd, ip);
        return jdbc.queryForList(
                "SELECT buu_kien_id, ma_van_don, ma_tu, ma_ngan, trang_thai, "
                        + "ngay_tiep_nhan, ngay_het_han_luu, ngay_nhan "
                        + "FROM v_buu_kien_cua_cu_dan WHERE cu_dan_id = ? ORDER BY ngay_tiep_nhan DESC",
                cuDanId(nd));
    }

    @Transactional
    public List<Map<String, Object>> thongBaoCuaToi(NguoiDungHienTai nd, String ip) {
        audit.gan(nd, ip);
        return jdbc.queryForList(
                "SELECT id, buu_kien_id, kenh_gui, noi_dung, ngay_gui "
                        + "FROM thong_bao WHERE cu_dan_id = ? ORDER BY ngay_gui DESC LIMIT 50",
                cuDanId(nd));
    }

    // Trả true/false, KHÔNG ném lỗi khi sai mã (để dòng audit thất bại được lưu)
    @Transactional
    public boolean nhanBangMa(NguoiDungHienTai nd, String ip, Long buuKienId, String ma) {
        audit.gan(nd, ip);
        Long cuDan = cuDanId(nd);

        // Bưu kiện phải thuộc căn hộ của cư dân đang đăng nhập
        Integer dem = jdbc.queryForObject(
                "SELECT count(*) FROM v_buu_kien_cua_cu_dan WHERE cu_dan_id = ? AND buu_kien_id = ?",
                Integer.class, cuDan, buuKienId);
        if (dem == null || dem == 0) {
            throw new IllegalArgumentException("Không tìm thấy bưu kiện của bạn");
        }

        Boolean ok = jdbc.queryForObject("SELECT xac_thuc_ma_nhan(?, ?)", Boolean.class, buuKienId, ma);
        return Boolean.TRUE.equals(ok);
    }
    // Cư dân tự lấy mã nhận của bưu kiện CỦA MÌNH. Mã gốc chỉ trả về đúng 1 lần cho người này.
    @Transactional
    public Map<String, Object> layMaNhan(NguoiDungHienTai nd, String ip, Long buuKienId) {
        audit.gan(nd, ip);
        Long cuDan = cuDanId(nd);

        List<String> tt = jdbc.queryForList(
                "SELECT trang_thai FROM v_buu_kien_cua_cu_dan WHERE cu_dan_id = ? AND buu_kien_id = ?",
                String.class, cuDan, buuKienId);
        if (tt.isEmpty()) {
            throw new IllegalArgumentException("Không tìm thấy bưu kiện của bạn");
        }
        if (!tt.get(0).equals("CHO_NHAN") && !tt.get(0).equals("QUA_HAN")) {
            throw new IllegalArgumentException("Bưu kiện này đã kết thúc, không thể lấy mã nhận");
        }

        String ma = jdbc.queryForObject("SELECT sinh_ma_nhan(?, ?)", String.class, buuKienId, cuDan);
        String hanDen = jdbc.queryForObject(
                "SELECT to_char(han_su_dung AT TIME ZONE 'UTC', 'YYYY-MM-DD\"T\"HH24:MI:SS\"Z\"') "
                        + "FROM ma_nhan WHERE buu_kien_id = ? ORDER BY id DESC LIMIT 1",
                String.class, buuKienId);
        return Map.of("ma", ma, "hanDen", hanDen);
    }
}