package com.doan.buukien.quantri;

import com.doan.buukien.common.AuditContext;
import com.doan.buukien.security.NguoiDungHienTai;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;

@Service
public class QuanLyService {

    private final JdbcTemplate jdbc;
    private final AuditContext audit;

    public QuanLyService(JdbcTemplate jdbc, AuditContext audit) {
        this.jdbc = jdbc;
        this.audit = audit;
    }

    private void ghi(String hanhDong, String doiTuong, Long doiTuongId, String chiTiet) {
        jdbc.queryForList(
                "SELECT 1 FROM (SELECT fn_ghi_audit(?::text, ?::text, ?::bigint, ?::text)) x",
                hanhDong, doiTuong, doiTuongId, chiTiet);
    }

    // ------------------------------------------------------------ Nhân viên

    public List<Map<String, Object>> dsNhanVien() {
        return jdbc.queryForList(
                "SELECT nv.id, nv.ma_nhan_vien, nv.ho_ten, nv.sdt, nv.chuc_vu, nv.ca_truc, "
                        + "tk.ten_dang_nhap, tk.trang_thai "
                        + "FROM nhan_vien nv JOIN tai_khoan tk ON tk.id = nv.tai_khoan_id ORDER BY nv.id");
    }

    @Transactional
    public Map<String, Object> themNhanVien(NguoiDungHienTai nd, String ip,
                                            QuanLyController.NhanVienMoi rq) {
        audit.gan(nd, ip);
        Integer trung = jdbc.queryForObject(
                "SELECT count(*) FROM tai_khoan WHERE ten_dang_nhap = ?", Integer.class, rq.tenDangNhap());
        if (trung != null && trung > 0) {
            throw new IllegalArgumentException("Tên đăng nhập " + rq.tenDangNhap() + " đã tồn tại");
        }
        Long tkId = jdbc.queryForObject(
                "INSERT INTO tai_khoan (ten_dang_nhap, mat_khau_hash, vai_tro) "
                        + "VALUES (?, crypt(?, gen_salt('bf')), 'NHAN_VIEN') RETURNING id",
                Long.class, rq.tenDangNhap(), rq.matKhau());
        String ma = jdbc.queryForObject(
                "SELECT 'NV' || lpad((COALESCE(max(substring(ma_nhan_vien from 3)::int), 0) + 1)::text, 3, '0') "
                        + "FROM nhan_vien WHERE ma_nhan_vien ~ '^NV[0-9]+$'", String.class);
        String chucVu = rq.chucVu() == null ? "BAO_VE" : rq.chucVu();
        String caTruc = rq.caTruc() == null ? "SANG" : rq.caTruc();
        Long id = jdbc.queryForObject(
                "INSERT INTO nhan_vien (tai_khoan_id, ma_nhan_vien, ho_ten, sdt, chuc_vu, ca_truc) "
                        + "VALUES (?, ?, ?, ?, ?, ?) RETURNING id",
                Long.class, tkId, ma, rq.hoTen(), rq.sdt(), chucVu, caTruc);
        ghi("TAO_NHAN_VIEN", "nhan_vien", id, "ma=" + ma + ", tai_khoan=" + rq.tenDangNhap());
        return Map.of("id", id, "maNhanVien", ma);
    }

    @Transactional
    public void khoaNhanVien(NguoiDungHienTai nd, String ip, Long nhanVienId, boolean khoa) {
        audit.gan(nd, ip);
        int dong = jdbc.update(
                "UPDATE tai_khoan SET trang_thai = ? "
                        + "WHERE id = (SELECT tai_khoan_id FROM nhan_vien WHERE id = ?)",
                khoa ? "KHOA" : "HOAT_DONG", nhanVienId);
        if (dong == 0) {
            throw new IllegalArgumentException("Không tìm thấy nhân viên " + nhanVienId);
        }
        ghi(khoa ? "KHOA_TAI_KHOAN" : "MO_KHOA_TAI_KHOAN", "nhan_vien", nhanVienId, null);
    }

    // ------------------------------------------------------------ Tủ locker

    public List<Map<String, Object>> dsTu() {
        return jdbc.queryForList(
                "SELECT t.id, t.ma_tu, t.vi_tri, t.trang_thai, t.tong_so_ngan, "
                        + "ST_X(t.toa_do) AS kinh_do, ST_Y(t.toa_do) AS vi_do "
                        + "FROM tu_locker t ORDER BY t.id");
    }

    @Transactional
    public Map<String, Object> themTu(NguoiDungHienTai nd, String ip, QuanLyController.TuMoi rq) {
        audit.gan(nd, ip);
        String maTu = rq.maTu().trim().toUpperCase();
        int tong = rq.soNganS() + rq.soNganM() + rq.soNganL();
        if (tong < 1) {
            throw new IllegalArgumentException("Tủ phải có ít nhất 1 ngăn");
        }
        Integer trung = jdbc.queryForObject(
                "SELECT count(*) FROM tu_locker WHERE ma_tu = ?", Integer.class, maTu);
        if (trung != null && trung > 0) {
            throw new IllegalArgumentException("Mã tủ " + maTu + " đã tồn tại");
        }
        List<Long> qt = jdbc.queryForList(
                "SELECT id FROM quan_tri_vien WHERE tai_khoan_id = ?", Long.class, nd.id());
        Long qtId = qt.isEmpty() ? null : qt.get(0);

        Long tuId;
        if (rq.kinhDo() != null && rq.viDo() != null) {
            tuId = jdbc.queryForObject(
                    "INSERT INTO tu_locker (quan_tri_vien_id, ma_tu, vi_tri, toa_do) "
                            + "VALUES (?, ?, ?, ST_SetSRID(ST_MakePoint(?, ?), 4326)) RETURNING id",
                    Long.class, qtId, maTu, rq.viTri(), rq.kinhDo(), rq.viDo());
        } else {
            tuId = jdbc.queryForObject(
                    "INSERT INTO tu_locker (quan_tri_vien_id, ma_tu, vi_tri) VALUES (?, ?, ?) RETURNING id",
                    Long.class, qtId, maTu, rq.viTri());
        }

        String tienTo = maTu.replaceFirst("^TU-", "");
        int stt = 1;
        String[] cỡ = {"S", "M", "L"};
        int[] soLuong = {rq.soNganS(), rq.soNganM(), rq.soNganL()};
        for (int k = 0; k < 3; k++) {
            for (int j = 0; j < soLuong[k]; j++, stt++) {
                String maNgan = tienTo + "-" + (stt < 10 ? "0" + stt : String.valueOf(stt));
                jdbc.update("INSERT INTO ngan_tu (tu_id, ma_ngan, kich_co) VALUES (?, ?, ?)",
                        tuId, maNgan, cỡ[k]);
            }
        }
        ghi("TAO_TU_LOCKER", "tu_locker", tuId, "ma_tu=" + maTu + ", so_ngan=" + tong);
        return Map.of("id", tuId, "maTu", maTu, "soNgan", tong);
    }
}