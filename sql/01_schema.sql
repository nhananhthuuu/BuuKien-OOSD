/* =====================================================================
   LOG-07: HỆ THỐNG QUẢN LÝ BƯU KIỆN TẠI TÒA NHÀ THÔNG MINH
   CSDL: PostgreSQL 14 trở lên (đã nhắm tới bản 17/18)

   CÁCH CHẠY (pgAdmin 4):
   Bước 1. Chuột phải Databases > Query Tool (đang ở database "postgres"),
           chạy RIÊNG câu này (phải là UTF8 để lưu được tiếng Việt):

           CREATE DATABASE buu_kien_db ENCODING 'UTF8' TEMPLATE template0;

   Bước 2. Chuột phải database buu_kien_db > Query Tool.
           Mở file này, bấm F5 chạy MỘT LẦN toàn bộ.
           (Chạy lại nhiều lần được: phần đầu sẽ xóa bảng cũ rồi tạo lại.)

   MỤC LỤC:
     PHẦN 1. Bảng (khớp ERD)
     PHẦN 2. Hàm hỗ trợ + nghiệp vụ
     PHẦN 3. Trigger
     PHẦN 4. View
     PHẦN 5. Phân quyền (không lộ danh sách cư dân)
     PHẦN 6. Dữ liệu mẫu
     PHẦN 7. Chạy thử (xóa phần này nếu không cần)

   QUY ƯỚC TRẠNG THÁI BƯU KIỆN:
     CHO_NHAN -> DA_NHAN
     CHO_NHAN -> QUA_HAN -> DA_NHAN  hoặc  DA_XU_LY
   ===================================================================== */

CREATE EXTENSION IF NOT EXISTS pgcrypto;   -- băm mật khẩu, băm mã nhận, sinh số ngẫu nhiên

/* =====================================================================
   PHẦN 1. BẢNG
   ===================================================================== */

DROP VIEW  IF EXISTS v_buu_kien_dang_luu, v_buu_kien_cua_cu_dan, v_buu_kien_qua_han,
                     v_thong_ke_tu, v_thong_ke_tong_quan, v_nhat_ky_audit_chi_tiet,
                     v_thong_bao_chua_gui CASCADE;
DROP TABLE IF EXISTS nhat_ky_audit, xu_ly_qua_han, thong_bao, ma_nhan, buu_kien, ngan_tu,
                     tu_locker, cu_tru, can_ho, cu_dan, shipper, nhan_vien, quan_tri_vien,
                     tai_khoan, cau_hinh_kho CASCADE;

-- Bảng cấu hình (ứng với use case "Cấu hình hạn lưu kho"). Chỉ có đúng 1 dòng.
CREATE TABLE cau_hinh_kho (
    id                   SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    so_ngay_mien_phi     INT           NOT NULL DEFAULT 3    CHECK (so_ngay_mien_phi >= 0),
    phi_qua_han_moi_ngay NUMERIC(12,0) NOT NULL DEFAULT 5000 CHECK (phi_qua_han_moi_ngay >= 0),
    so_gio_hieu_luc_ma   INT           NOT NULL DEFAULT 72   CHECK (so_gio_hieu_luc_ma > 0)
);
INSERT INTO cau_hinh_kho DEFAULT VALUES;

-- Lớp cha: tài khoản (4 vai trò bên dưới kế thừa)
CREATE TABLE tai_khoan (
    id             BIGSERIAL PRIMARY KEY,
    ten_dang_nhap  VARCHAR(50)  NOT NULL UNIQUE,
    mat_khau_hash  TEXT         NOT NULL,
    vai_tro        VARCHAR(15)  NOT NULL CHECK (vai_tro IN ('CU_DAN','NHAN_VIEN','SHIPPER','QUAN_TRI_VIEN')),
    trang_thai     VARCHAR(10)  NOT NULL DEFAULT 'HOAT_DONG' CHECK (trang_thai IN ('HOAT_DONG','KHOA')),
    ngay_tao       TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE quan_tri_vien (
    id            BIGSERIAL PRIMARY KEY,
    tai_khoan_id  BIGINT       NOT NULL UNIQUE REFERENCES tai_khoan(id) ON DELETE CASCADE,
    ho_ten        VARCHAR(100) NOT NULL,
    email         VARCHAR(100) UNIQUE,
    cap_do_quyen  VARCHAR(10)  NOT NULL DEFAULT 'THUONG' CHECK (cap_do_quyen IN ('THUONG','CAO'))
);

CREATE TABLE nhan_vien (
    id             BIGSERIAL PRIMARY KEY,
    tai_khoan_id   BIGINT       NOT NULL UNIQUE REFERENCES tai_khoan(id) ON DELETE CASCADE,
    ma_nhan_vien   VARCHAR(20)  NOT NULL UNIQUE,
    ho_ten         VARCHAR(100) NOT NULL,
    sdt            VARCHAR(15),
    chuc_vu        VARCHAR(10)  NOT NULL DEFAULT 'BAO_VE' CHECK (chuc_vu IN ('BAO_VE','LE_TAN')),
    ca_truc        VARCHAR(10)  NOT NULL DEFAULT 'SANG'   CHECK (ca_truc IN ('SANG','CHIEU','TOI'))
);

CREATE TABLE shipper (
    id                 BIGSERIAL PRIMARY KEY,
    tai_khoan_id       BIGINT       NOT NULL UNIQUE REFERENCES tai_khoan(id) ON DELETE CASCADE,
    ho_ten             VARCHAR(100) NOT NULL,
    sdt                VARCHAR(15),
    don_vi_van_chuyen  VARCHAR(50)  NOT NULL,
    bien_so_xe         VARCHAR(15)
);

CREATE TABLE cu_dan (
    id                      BIGSERIAL PRIMARY KEY,
    tai_khoan_id            BIGINT       NOT NULL UNIQUE REFERENCES tai_khoan(id) ON DELETE CASCADE,
    ho_ten                  VARCHAR(100) NOT NULL,
    sdt                     VARCHAR(15),
    email                   VARCHAR(100),
    kenh_thong_bao_uu_tien  VARCHAR(10)  NOT NULL DEFAULT 'APP' CHECK (kenh_thong_bao_uu_tien IN ('APP','SMS','EMAIL'))
);

CREATE TABLE can_ho (
    id          BIGSERIAL PRIMARY KEY,
    so_can_ho   VARCHAR(10) NOT NULL UNIQUE,
    tang        INT         NOT NULL CHECK (tang > 0),
    toa_nha     VARCHAR(10) NOT NULL,
    trang_thai  VARCHAR(12) NOT NULL DEFAULT 'TRONG' CHECK (trang_thai IN ('TRONG','CO_NGUOI_O'))
);

-- Bảng trung gian N-N giữa cư dân và căn hộ
CREATE TABLE cu_tru (
    id             BIGSERIAL PRIMARY KEY,
    cu_dan_id      BIGINT NOT NULL REFERENCES cu_dan(id)  ON DELETE CASCADE,
    can_ho_id      BIGINT NOT NULL REFERENCES can_ho(id)  ON DELETE CASCADE,
    ngay_bat_dau   DATE   NOT NULL DEFAULT CURRENT_DATE,
    ngay_ket_thuc  DATE,
    CHECK (ngay_ket_thuc IS NULL OR ngay_ket_thuc >= ngay_bat_dau),
    UNIQUE (cu_dan_id, can_ho_id, ngay_bat_dau)
);

CREATE TABLE tu_locker (
    id                BIGSERIAL PRIMARY KEY,
    quan_tri_vien_id  BIGINT REFERENCES quan_tri_vien(id) ON DELETE SET NULL,
    ma_tu             VARCHAR(10)  NOT NULL UNIQUE,
    vi_tri            VARCHAR(100) NOT NULL,
    tong_so_ngan      INT          NOT NULL DEFAULT 0,   -- tự cập nhật bằng trigger
    trang_thai        VARCHAR(10)  NOT NULL DEFAULT 'HOAT_DONG' CHECK (trang_thai IN ('HOAT_DONG','BAO_TRI'))
);

-- Hợp thành: xóa tủ thì ngăn mất theo
CREATE TABLE ngan_tu (
    id          BIGSERIAL PRIMARY KEY,
    tu_id       BIGINT      NOT NULL REFERENCES tu_locker(id) ON DELETE CASCADE,
    ma_ngan     VARCHAR(10) NOT NULL,
    kich_co     CHAR(1)     NOT NULL CHECK (kich_co IN ('S','M','L')),
    trang_thai  VARCHAR(10) NOT NULL DEFAULT 'TRONG' CHECK (trang_thai IN ('TRONG','DANG_DUNG','HONG')),
    UNIQUE (tu_id, ma_ngan)
);

CREATE TABLE buu_kien (
    id                      BIGSERIAL PRIMARY KEY,
    ma_van_don              VARCHAR(30) NOT NULL UNIQUE,
    can_ho_id               BIGINT      NOT NULL REFERENCES can_ho(id),
    ngan_tu_id              BIGINT      REFERENCES ngan_tu(id),
    shipper_id              BIGINT      REFERENCES shipper(id),
    nhan_vien_tiep_nhan_id  BIGINT      NOT NULL REFERENCES nhan_vien(id),
    kich_co                 CHAR(1)     NOT NULL CHECK (kich_co IN ('S','M','L')),
    trang_thai              VARCHAR(10) NOT NULL DEFAULT 'CHO_NHAN' CHECK (trang_thai IN ('CHO_NHAN','QUA_HAN','DA_NHAN','DA_XU_LY')),
    ngay_tiep_nhan          TIMESTAMPTZ NOT NULL DEFAULT now(),
    ngay_het_han_luu        TIMESTAMPTZ NOT NULL,        -- trigger tự tính nếu để trống
    ngay_nhan               TIMESTAMPTZ,
    CHECK (ngay_het_han_luu >= ngay_tiep_nhan),
    CHECK (trang_thai <> 'DA_NHAN' OR ngay_nhan IS NOT NULL)
);
-- Mỗi ngăn tại một thời điểm chỉ chứa tối đa 1 bưu kiện chưa lấy
CREATE UNIQUE INDEX uq_ngan_dang_chua_buu_kien ON buu_kien (ngan_tu_id) WHERE trang_thai IN ('CHO_NHAN','QUA_HAN');

-- Mã nhận một lần: chỉ lưu bản băm, không lưu mã gốc
CREATE TABLE ma_nhan (
    id            BIGSERIAL PRIMARY KEY,
    buu_kien_id   BIGINT      NOT NULL REFERENCES buu_kien(id) ON DELETE CASCADE,
    cu_dan_id     BIGINT      REFERENCES cu_dan(id),
    ma_hash       TEXT        NOT NULL,
    ngay_tao      TIMESTAMPTZ NOT NULL DEFAULT now(),
    han_su_dung   TIMESTAMPTZ NOT NULL,
    da_su_dung    BOOLEAN     NOT NULL DEFAULT FALSE,
    ngay_su_dung  TIMESTAMPTZ,
    CHECK (han_su_dung >= ngay_tao),
    CHECK (da_su_dung = (ngay_su_dung IS NOT NULL))
);

CREATE TABLE thong_bao (
    id              BIGSERIAL PRIMARY KEY,
    buu_kien_id     BIGINT      NOT NULL REFERENCES buu_kien(id) ON DELETE CASCADE,
    cu_dan_id       BIGINT      NOT NULL REFERENCES cu_dan(id),
    kenh_gui        VARCHAR(10) NOT NULL CHECK (kenh_gui IN ('APP','SMS','EMAIL')),
    noi_dung        TEXT        NOT NULL,
    trang_thai_gui  VARCHAR(10) NOT NULL DEFAULT 'CHO_GUI' CHECK (trang_thai_gui IN ('CHO_GUI','DA_GUI','LOI')),
    ngay_gui        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE xu_ly_qua_han (
    id                  BIGSERIAL PRIMARY KEY,
    buu_kien_id         BIGINT        NOT NULL REFERENCES buu_kien(id),
    nhan_vien_xu_ly_id  BIGINT        REFERENCES nhan_vien(id),
    ngay_qua_han        TIMESTAMPTZ   NOT NULL DEFAULT now(),
    hinh_thuc_xu_ly     VARCHAR(10)   NOT NULL DEFAULT 'NHAC_NHO' CHECK (hinh_thuc_xu_ly IN ('NHAC_NHO','HOAN_TRA','CHUYEN_KHO')),
    phi_luu_kho         NUMERIC(12,0) NOT NULL DEFAULT 0 CHECK (phi_luu_kho >= 0),
    ngay_xu_ly          TIMESTAMPTZ,
    ghi_chu             TEXT
);

-- Nhật ký audit: chỉ được thêm, không được sửa/xóa (có trigger chặn ở phần 3)
-- tai_khoan_id = NULL nghĩa là do HỆ THỐNG tự thực hiện
CREATE TABLE nhat_ky_audit (
    id             BIGSERIAL PRIMARY KEY,
    tai_khoan_id   BIGINT       REFERENCES tai_khoan(id),
    hanh_dong      VARCHAR(40)  NOT NULL,
    doi_tuong      VARCHAR(30)  NOT NULL,
    doi_tuong_id   BIGINT,
    chi_tiet       TEXT,
    dia_chi_ip     INET,
    thoi_gian      TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- Chỉ mục cho các truy vấn hay dùng
CREATE INDEX idx_buu_kien_can_ho     ON buu_kien (can_ho_id);
CREATE INDEX idx_buu_kien_trang_thai ON buu_kien (trang_thai, ngay_het_han_luu);
CREATE INDEX idx_ma_nhan_buu_kien    ON ma_nhan (buu_kien_id);
CREATE INDEX idx_thong_bao_cu_dan    ON thong_bao (cu_dan_id, trang_thai_gui);
CREATE INDEX idx_cu_tru_can_ho       ON cu_tru (can_ho_id);
CREATE INDEX idx_audit_tai_khoan     ON nhat_ky_audit (tai_khoan_id, thoi_gian DESC);
CREATE INDEX idx_audit_hanh_dong     ON nhat_ky_audit (hanh_dong, doi_tuong_id, thoi_gian DESC);

/* =====================================================================
   PHẦN 2. HÀM HỖ TRỢ VÀ NGHIỆP VỤ
   ===================================================================== */

-- Đổi kích cỡ thành số để so sánh: S < M < L
CREATE OR REPLACE FUNCTION fn_rank_kich_co(p_kich_co TEXT) RETURNS INT
LANGUAGE sql IMMUTABLE AS $$
    SELECT CASE p_kich_co WHEN 'S' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3 END;
$$;

-- Ghi nhật ký audit. Ai thao tác lấy từ biến phiên app.tai_khoan_id
-- (backend gọi:  SELECT set_config('app.tai_khoan_id', '<id>', true);  trước khi làm việc)
CREATE OR REPLACE FUNCTION fn_ghi_audit(p_hanh_dong TEXT, p_doi_tuong TEXT, p_doi_tuong_id BIGINT, p_chi_tiet TEXT DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_tk BIGINT;
    v_ip INET;
BEGIN
    BEGIN
        v_tk := NULLIF(current_setting('app.tai_khoan_id', true), '')::BIGINT;
    EXCEPTION WHEN OTHERS THEN
        v_tk := NULL;
    END;
    BEGIN
        v_ip := NULLIF(current_setting('app.ip', true), '')::INET;
    EXCEPTION WHEN OTHERS THEN
        v_ip := NULL;
    END;
    INSERT INTO nhat_ky_audit (tai_khoan_id, hanh_dong, doi_tuong, doi_tuong_id, chi_tiet, dia_chi_ip)
    VALUES (v_tk, p_hanh_dong, p_doi_tuong, p_doi_tuong_id, p_chi_tiet, v_ip);
END;
$$;

-- Tra cứu căn hộ: CHỈ trả về có / không, không lộ ai ở căn hộ đó
CREATE OR REPLACE FUNCTION ton_tai_can_ho(p_so_can_ho TEXT) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_co BOOLEAN;
BEGIN
    SELECT EXISTS (SELECT 1 FROM can_ho WHERE so_can_ho = upper(trim(p_so_can_ho))) INTO v_co;
    PERFORM fn_ghi_audit('TRA_CUU_CAN_HO', 'can_ho', NULL, CASE WHEN v_co THEN 'co' ELSE 'khong' END);
    RETURN v_co;
END;
$$;

-- Phí lưu kho = số ngày quá hạn x phí mỗi ngày
CREATE OR REPLACE FUNCTION tinh_phi_luu_kho(p_buu_kien_id BIGINT) RETURNS NUMERIC
LANGUAGE sql STABLE AS $$
    SELECT COALESCE(
        GREATEST(0, COALESCE(b.ngay_nhan, now())::date - b.ngay_het_han_luu::date) * c.phi_qua_han_moi_ngay,
        0)
    FROM buu_kien b CROSS JOIN cau_hinh_kho c
    WHERE b.id = p_buu_kien_id AND c.id = 1;
$$;

-- Chọn ngăn trống nhỏ nhất còn vừa kích cỡ. Trả về NULL nếu hết ngăn.
CREATE OR REPLACE FUNCTION chon_ngan_trong(p_kich_co TEXT) RETURNS BIGINT
LANGUAGE plpgsql AS $$
DECLARE
    v_id BIGINT;
BEGIN
    SELECT n.id INTO v_id
    FROM ngan_tu n JOIN tu_locker t ON t.id = n.tu_id
    WHERE n.trang_thai = 'TRONG'
      AND t.trang_thai = 'HOAT_DONG'
      AND fn_rank_kich_co(n.kich_co) >= fn_rank_kich_co(p_kich_co)
    ORDER BY fn_rank_kich_co(n.kich_co), n.id
    LIMIT 1
    FOR UPDATE OF n SKIP LOCKED;
    RETURN v_id;
END;
$$;

-- TIẾP NHẬN bưu kiện: kiểm tra căn hộ, mã vận đơn, ngăn trống rồi tạo bưu kiện.
-- Trigger sẽ tự: đánh dấu ngăn đang dùng, tạo thông báo cho cư dân, ghi audit.
-- KHÔNG sinh mã nhận ở đây (nhân viên không được thấy mã). Backend gọi sinh_ma_nhan() sau.
CREATE OR REPLACE FUNCTION tiep_nhan_buu_kien(
    p_ma_van_don TEXT, p_so_can_ho TEXT, p_kich_co TEXT, p_nhan_vien_id BIGINT, p_shipper_id BIGINT DEFAULT NULL,
    OUT o_buu_kien_id BIGINT, OUT o_ma_ngan TEXT)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_can_ho BIGINT;
    v_ngan   BIGINT;
    v_tk     BIGINT;
BEGIN
    SELECT tai_khoan_id INTO v_tk FROM nhan_vien WHERE id = p_nhan_vien_id;
    IF v_tk IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy nhân viên có id %', p_nhan_vien_id;
    END IF;
    PERFORM set_config('app.tai_khoan_id', v_tk::TEXT, true);   -- audit ghi đúng người thao tác

    SELECT id INTO v_can_ho FROM can_ho WHERE so_can_ho = upper(trim(p_so_can_ho));
    IF v_can_ho IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy căn hộ %', p_so_can_ho;
    END IF;
    IF EXISTS (SELECT 1 FROM buu_kien WHERE ma_van_don = p_ma_van_don) THEN
        RAISE EXCEPTION 'Mã vận đơn % đã tồn tại', p_ma_van_don;
    END IF;

    v_ngan := chon_ngan_trong(p_kich_co);
    IF v_ngan IS NULL THEN
        RAISE EXCEPTION 'Hết ngăn trống phù hợp kích cỡ %', p_kich_co;
    END IF;

    INSERT INTO buu_kien (ma_van_don, can_ho_id, ngan_tu_id, shipper_id, nhan_vien_tiep_nhan_id, kich_co)
    VALUES (p_ma_van_don, v_can_ho, v_ngan, p_shipper_id, p_nhan_vien_id, p_kich_co)
    RETURNING id INTO o_buu_kien_id;

    SELECT ma_ngan INTO o_ma_ngan FROM ngan_tu WHERE id = v_ngan;
END;
$$;

-- SINH MÃ NHẬN MỘT LẦN (6 chữ số). Trả mã gốc ĐÚNG MỘT LẦN để backend gửi cho cư dân.
-- Trong CSDL chỉ lưu bản băm SHA-256. Mã cũ chưa dùng của bưu kiện bị vô hiệu ngay.
CREATE OR REPLACE FUNCTION sinh_ma_nhan(p_buu_kien_id BIGINT, p_cu_dan_id BIGINT DEFAULT NULL) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_tt  TEXT;
    v_ma  TEXT;
    v_cfg cau_hinh_kho%ROWTYPE;
BEGIN
    SELECT trang_thai INTO v_tt FROM buu_kien WHERE id = p_buu_kien_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy bưu kiện %', p_buu_kien_id;
    END IF;
    IF v_tt NOT IN ('CHO_NHAN','QUA_HAN') THEN
        RAISE EXCEPTION 'Bưu kiện đã kết thúc (%), không thể tạo mã nhận', v_tt;
    END IF;
    SELECT * INTO v_cfg FROM cau_hinh_kho WHERE id = 1;

    UPDATE ma_nhan SET han_su_dung = LEAST(han_su_dung, now())
    WHERE buu_kien_id = p_buu_kien_id AND da_su_dung = FALSE;

    v_ma := lpad((((('x' || encode(gen_random_bytes(4), 'hex'))::bit(32))::BIGINT) % 1000000)::TEXT, 6, '0');

    INSERT INTO ma_nhan (buu_kien_id, cu_dan_id, ma_hash, han_su_dung)
    VALUES (p_buu_kien_id, p_cu_dan_id,
            encode(digest(v_ma || ':' || p_buu_kien_id::TEXT, 'sha256'), 'hex'),
            now() + make_interval(hours => v_cfg.so_gio_hieu_luc_ma));
    RETURN v_ma;
END;
$$;

-- XÁC THỰC MÃ NHẬN: đúng thì đánh dấu mã đã dùng + bưu kiện thành DA_NHAN (trigger lo phần còn lại)
-- Sai quá 5 lần trong 15 phút thì tạm khóa.
CREATE OR REPLACE FUNCTION xac_thuc_ma_nhan(p_buu_kien_id BIGINT, p_ma TEXT) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_hash TEXT;
    v_mn   BIGINT;
    v_sai  INT;
BEGIN
    SELECT count(*) INTO v_sai FROM nhat_ky_audit
    WHERE hanh_dong = 'NHAP_MA_NHAN_THAT_BAI' AND doi_tuong_id = p_buu_kien_id
      AND thoi_gian > now() - interval '15 minutes';
    IF v_sai >= 5 THEN
        RAISE EXCEPTION 'Nhập sai mã quá 5 lần. Vui lòng thử lại sau 15 phút';
    END IF;

    v_hash := encode(digest(p_ma || ':' || p_buu_kien_id::TEXT, 'sha256'), 'hex');
    SELECT id INTO v_mn FROM ma_nhan
    WHERE buu_kien_id = p_buu_kien_id AND ma_hash = v_hash
      AND da_su_dung = FALSE AND han_su_dung >= now()
    FOR UPDATE;

    IF NOT FOUND THEN
        PERFORM fn_ghi_audit('NHAP_MA_NHAN_THAT_BAI', 'buu_kien', p_buu_kien_id, 'Mã sai, đã hết hạn hoặc đã dùng');
        RETURN FALSE;
    END IF;

    UPDATE ma_nhan  SET da_su_dung = TRUE        WHERE id = v_mn;
    UPDATE buu_kien SET trang_thai = 'DA_NHAN'   WHERE id = p_buu_kien_id;
    RETURN TRUE;
END;
$$;

-- QUÉT QUÁ HẠN (cho job chạy định kỳ, vd Spring @Scheduled hoặc pg_cron).
-- Chuyển bưu kiện quá hạn lưu sang QUA_HAN, tạo hồ sơ xử lý, tạo thông báo nhắc cư dân.
-- Trả về số bưu kiện vừa bị chuyển.
CREATE OR REPLACE FUNCTION danh_dau_qua_han() RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_dem INT;
BEGIN
    PERFORM set_config('app.tai_khoan_id', '', true);   -- việc do HỆ THỐNG làm

    WITH qh AS (
        UPDATE buu_kien SET trang_thai = 'QUA_HAN'
        WHERE trang_thai = 'CHO_NHAN' AND ngay_het_han_luu < now()
        RETURNING id, ma_van_don, can_ho_id, ngay_het_han_luu
    ), xl AS (
        INSERT INTO xu_ly_qua_han (buu_kien_id, ngay_qua_han, hinh_thuc_xu_ly)
        SELECT id, ngay_het_han_luu, 'NHAC_NHO' FROM qh
        RETURNING id
    ), tb AS (
        INSERT INTO thong_bao (buu_kien_id, cu_dan_id, kenh_gui, noi_dung)
        SELECT qh.id, cd.id, cd.kenh_thong_bao_uu_tien,
               format('Bưu kiện %s đã quá hạn lưu kho. Vui lòng đến nhận sớm, phí lưu kho sẽ được tính.', qh.ma_van_don)
        FROM qh
        JOIN cu_tru ct ON ct.can_ho_id = qh.can_ho_id
                      AND ct.ngay_bat_dau <= CURRENT_DATE
                      AND (ct.ngay_ket_thuc IS NULL OR ct.ngay_ket_thuc >= CURRENT_DATE)
        JOIN cu_dan cd ON cd.id = ct.cu_dan_id
        RETURNING id
    )
    SELECT count(*) INTO v_dem FROM qh;

    RETURN v_dem;
END;
$$;

-- XỬ LÝ bưu kiện quá hạn (nhân viên): hoàn trả hoặc chuyển kho. Trả về phí lưu kho đã tính.
CREATE OR REPLACE FUNCTION xu_ly_buu_kien_qua_han(p_buu_kien_id BIGINT, p_hinh_thuc TEXT, p_nhan_vien_id BIGINT, p_ghi_chu TEXT DEFAULT NULL)
RETURNS NUMERIC
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
    v_tk  BIGINT;
    v_phi NUMERIC;
BEGIN
    IF p_hinh_thuc NOT IN ('HOAN_TRA','CHUYEN_KHO') THEN
        RAISE EXCEPTION 'Hình thức xử lý phải là HOAN_TRA hoặc CHUYEN_KHO';
    END IF;
    SELECT tai_khoan_id INTO v_tk FROM nhan_vien WHERE id = p_nhan_vien_id;
    IF v_tk IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy nhân viên có id %', p_nhan_vien_id;
    END IF;
    PERFORM set_config('app.tai_khoan_id', v_tk::TEXT, true);

    PERFORM 1 FROM buu_kien WHERE id = p_buu_kien_id AND trang_thai = 'QUA_HAN' FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Bưu kiện % không ở trạng thái quá hạn', p_buu_kien_id;
    END IF;

    v_phi := tinh_phi_luu_kho(p_buu_kien_id);

    UPDATE xu_ly_qua_han
    SET nhan_vien_xu_ly_id = p_nhan_vien_id, hinh_thuc_xu_ly = p_hinh_thuc,
        phi_luu_kho = v_phi, ngay_xu_ly = now(), ghi_chu = p_ghi_chu
    WHERE id = (SELECT id FROM xu_ly_qua_han WHERE buu_kien_id = p_buu_kien_id AND ngay_xu_ly IS NULL
                ORDER BY id DESC LIMIT 1);
    IF NOT FOUND THEN
        INSERT INTO xu_ly_qua_han (buu_kien_id, nhan_vien_xu_ly_id, hinh_thuc_xu_ly, phi_luu_kho, ngay_xu_ly, ghi_chu)
        VALUES (p_buu_kien_id, p_nhan_vien_id, p_hinh_thuc, v_phi, now(), p_ghi_chu);
    END IF;

    UPDATE buu_kien SET trang_thai = 'DA_XU_LY' WHERE id = p_buu_kien_id;
    RETURN v_phi;
END;
$$;

/* =====================================================================
   PHẦN 3. TRIGGER
   ===================================================================== */

-- T1. Tài khoản gắn vào bảng vai trò nào thì vai_tro phải khớp (kế thừa đúng)
CREATE OR REPLACE FUNCTION trg_fn_kiem_tra_vai_tro() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_vai_tro TEXT;
BEGIN
    SELECT vai_tro INTO v_vai_tro FROM tai_khoan WHERE id = NEW.tai_khoan_id;
    IF v_vai_tro IS DISTINCT FROM TG_ARGV[0] THEN
        RAISE EXCEPTION 'Tài khoản % có vai trò %, không thể gắn vào bảng % (cần vai trò %)',
            NEW.tai_khoan_id, v_vai_tro, TG_TABLE_NAME, TG_ARGV[0];
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_cu_dan_vai_tro        BEFORE INSERT OR UPDATE OF tai_khoan_id ON cu_dan        FOR EACH ROW EXECUTE FUNCTION trg_fn_kiem_tra_vai_tro('CU_DAN');
CREATE TRIGGER trg_nhan_vien_vai_tro     BEFORE INSERT OR UPDATE OF tai_khoan_id ON nhan_vien     FOR EACH ROW EXECUTE FUNCTION trg_fn_kiem_tra_vai_tro('NHAN_VIEN');
CREATE TRIGGER trg_shipper_vai_tro       BEFORE INSERT OR UPDATE OF tai_khoan_id ON shipper       FOR EACH ROW EXECUTE FUNCTION trg_fn_kiem_tra_vai_tro('SHIPPER');
CREATE TRIGGER trg_quan_tri_vien_vai_tro BEFORE INSERT OR UPDATE OF tai_khoan_id ON quan_tri_vien FOR EACH ROW EXECUTE FUNCTION trg_fn_kiem_tra_vai_tro('QUAN_TRI_VIEN');

-- T2. Cư trú thay đổi thì tự cập nhật trạng thái căn hộ (CO_NGUOI_O / TRONG)
CREATE OR REPLACE FUNCTION trg_fn_cu_tru_cap_nhat_can_ho() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE can_ho
    SET trang_thai = CASE WHEN EXISTS (
            SELECT 1 FROM cu_tru
            WHERE can_ho_id = NEW.can_ho_id AND ngay_bat_dau <= CURRENT_DATE
              AND (ngay_ket_thuc IS NULL OR ngay_ket_thuc >= CURRENT_DATE))
        THEN 'CO_NGUOI_O' ELSE 'TRONG' END
    WHERE id = NEW.can_ho_id;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_cu_tru_can_ho AFTER INSERT OR UPDATE ON cu_tru FOR EACH ROW EXECUTE FUNCTION trg_fn_cu_tru_cap_nhat_can_ho();

-- T3. Thêm / xóa ngăn thì tự cập nhật tổng số ngăn của tủ; không xóa ngăn đang chứa hàng
CREATE OR REPLACE FUNCTION trg_fn_ngan_tu_dem() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE tu_locker SET tong_so_ngan = (SELECT count(*) FROM ngan_tu WHERE tu_id = NEW.tu_id) WHERE id = NEW.tu_id;
        RETURN NEW;
    ELSE
        UPDATE tu_locker SET tong_so_ngan = (SELECT count(*) FROM ngan_tu WHERE tu_id = OLD.tu_id) WHERE id = OLD.tu_id;
        RETURN OLD;
    END IF;
END;
$$;
CREATE TRIGGER trg_ngan_tu_dem AFTER INSERT OR DELETE ON ngan_tu FOR EACH ROW EXECUTE FUNCTION trg_fn_ngan_tu_dem();

CREATE OR REPLACE FUNCTION trg_fn_ngan_tu_khong_xoa_khi_dung() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.trang_thai = 'DANG_DUNG' THEN
        RAISE EXCEPTION 'Ngăn % đang chứa bưu kiện, không thể xóa', OLD.ma_ngan;
    END IF;
    RETURN OLD;
END;
$$;
CREATE TRIGGER trg_ngan_tu_khong_xoa BEFORE DELETE ON ngan_tu FOR EACH ROW EXECUTE FUNCTION trg_fn_ngan_tu_khong_xoa_khi_dung();

-- T4. Trước khi thêm bưu kiện: kiểm tra ngăn, tự tính hạn lưu kho
CREATE OR REPLACE FUNCTION trg_fn_buu_kien_truoc_them() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
DECLARE
    v_ngan RECORD;
    v_cfg  cau_hinh_kho%ROWTYPE;
BEGIN
    IF NEW.ngan_tu_id IS NULL THEN
        RAISE EXCEPTION 'Bưu kiện phải được gán vào một ngăn tủ';
    END IF;

    SELECT n.trang_thai AS ngan_tt, n.kich_co AS ngan_kich_co, t.trang_thai AS tu_tt
    INTO v_ngan
    FROM ngan_tu n JOIN tu_locker t ON t.id = n.tu_id
    WHERE n.id = NEW.ngan_tu_id
    FOR UPDATE OF n;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy ngăn tủ %', NEW.ngan_tu_id;
    END IF;
    IF v_ngan.ngan_tt <> 'TRONG' THEN
        RAISE EXCEPTION 'Ngăn tủ % không còn trống (%)', NEW.ngan_tu_id, v_ngan.ngan_tt;
    END IF;
    IF v_ngan.tu_tt <> 'HOAT_DONG' THEN
        RAISE EXCEPTION 'Tủ chứa ngăn % đang bảo trì', NEW.ngan_tu_id;
    END IF;
    IF fn_rank_kich_co(v_ngan.ngan_kich_co) < fn_rank_kich_co(NEW.kich_co) THEN
        RAISE EXCEPTION 'Ngăn cỡ % quá nhỏ cho bưu kiện cỡ %', v_ngan.ngan_kich_co, NEW.kich_co;
    END IF;

    IF NEW.ngay_het_han_luu IS NULL THEN
        SELECT * INTO v_cfg FROM cau_hinh_kho WHERE id = 1;
        NEW.ngay_het_han_luu := COALESCE(NEW.ngay_tiep_nhan, now()) + make_interval(days => v_cfg.so_ngay_mien_phi);
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_buu_kien_truoc_them BEFORE INSERT ON buu_kien FOR EACH ROW EXECUTE FUNCTION trg_fn_buu_kien_truoc_them();

-- T5. Sau khi thêm bưu kiện: ngăn thành DANG_DUNG, tạo thông báo cho cư dân của căn hộ, ghi audit
CREATE OR REPLACE FUNCTION trg_fn_buu_kien_sau_them() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE ngan_tu SET trang_thai = 'DANG_DUNG' WHERE id = NEW.ngan_tu_id;

    INSERT INTO thong_bao (buu_kien_id, cu_dan_id, kenh_gui, noi_dung)
    SELECT NEW.id, cd.id, cd.kenh_thong_bao_uu_tien,
           format('Bưu kiện %s đã đến tòa nhà. Vui lòng nhận trước ngày %s.',
                  NEW.ma_van_don, to_char(NEW.ngay_het_han_luu, 'DD/MM/YYYY'))
    FROM cu_tru ct JOIN cu_dan cd ON cd.id = ct.cu_dan_id
    WHERE ct.can_ho_id = NEW.can_ho_id
      AND ct.ngay_bat_dau <= CURRENT_DATE
      AND (ct.ngay_ket_thuc IS NULL OR ct.ngay_ket_thuc >= CURRENT_DATE);

    PERFORM fn_ghi_audit('TIEP_NHAN_BUU_KIEN', 'buu_kien', NEW.id,
                         format('ma_van_don=%s, ngan_tu_id=%s', NEW.ma_van_don, NEW.ngan_tu_id));
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_buu_kien_sau_them AFTER INSERT ON buu_kien FOR EACH ROW EXECUTE FUNCTION trg_fn_buu_kien_sau_them();

-- T6. Trước khi sửa bưu kiện: chặn đổi trạng thái sai luồng, tự điền ngày nhận
CREATE OR REPLACE FUNCTION trg_fn_buu_kien_truoc_sua() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.ma_van_don <> OLD.ma_van_don OR NEW.can_ho_id <> OLD.can_ho_id THEN
        RAISE EXCEPTION 'Không được đổi mã vận đơn hoặc căn hộ của bưu kiện đã tiếp nhận';
    END IF;
    IF NEW.trang_thai <> OLD.trang_thai THEN
        IF OLD.trang_thai IN ('DA_NHAN','DA_XU_LY') THEN
            RAISE EXCEPTION 'Bưu kiện đã kết thúc (%), không thể đổi trạng thái', OLD.trang_thai;
        END IF;
        IF OLD.trang_thai = 'QUA_HAN' AND NEW.trang_thai = 'CHO_NHAN' THEN
            RAISE EXCEPTION 'Bưu kiện quá hạn không thể quay lại trạng thái chờ nhận';
        END IF;
        IF NEW.trang_thai = 'DA_XU_LY' AND OLD.trang_thai <> 'QUA_HAN' THEN
            RAISE EXCEPTION 'Chỉ bưu kiện quá hạn mới được xử lý (hoàn trả / chuyển kho)';
        END IF;
        IF NEW.trang_thai = 'DA_NHAN' THEN
            NEW.ngay_nhan := COALESCE(NEW.ngay_nhan, now());
        END IF;
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_buu_kien_truoc_sua BEFORE UPDATE ON buu_kien FOR EACH ROW EXECUTE FUNCTION trg_fn_buu_kien_truoc_sua();

-- T7. Sau khi đổi trạng thái: giải phóng ngăn, vô hiệu mã còn lại, ghi audit
CREATE OR REPLACE FUNCTION trg_fn_buu_kien_sau_doi_trang_thai() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.trang_thai IN ('DA_NHAN','DA_XU_LY') THEN
        UPDATE ngan_tu SET trang_thai = 'TRONG'
        WHERE id = NEW.ngan_tu_id AND trang_thai = 'DANG_DUNG';

        UPDATE ma_nhan SET han_su_dung = LEAST(han_su_dung, now())
        WHERE buu_kien_id = NEW.id AND da_su_dung = FALSE;
    END IF;
    PERFORM fn_ghi_audit('DOI_TRANG_THAI', 'buu_kien', NEW.id, OLD.trang_thai || ' -> ' || NEW.trang_thai);
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_buu_kien_sau_doi_trang_thai AFTER UPDATE OF trang_thai ON buu_kien
    FOR EACH ROW WHEN (OLD.trang_thai IS DISTINCT FROM NEW.trang_thai)
    EXECUTE FUNCTION trg_fn_buu_kien_sau_doi_trang_thai();

-- T8. MÃ NHẬN MỘT LẦN: đã dùng thì khóa chết, không dùng mã hết hạn, không đổi mã
CREATE OR REPLACE FUNCTION trg_fn_ma_nhan_mot_lan() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF OLD.da_su_dung THEN
        RAISE EXCEPTION 'Mã nhận đã được sử dụng, không thể sửa';
    END IF;
    IF NEW.ma_hash <> OLD.ma_hash OR NEW.buu_kien_id <> OLD.buu_kien_id THEN
        RAISE EXCEPTION 'Không được đổi mã hoặc bưu kiện của mã nhận';
    END IF;
    IF NEW.da_su_dung THEN
        IF now() > OLD.han_su_dung THEN
            RAISE EXCEPTION 'Mã nhận đã hết hạn';
        END IF;
        NEW.ngay_su_dung := COALESCE(NEW.ngay_su_dung, now());
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_ma_nhan_mot_lan BEFORE UPDATE ON ma_nhan FOR EACH ROW EXECUTE FUNCTION trg_fn_ma_nhan_mot_lan();

-- T9. Audit khi tạo mã và khi dùng mã (không bao giờ ghi mã gốc)
CREATE OR REPLACE FUNCTION trg_fn_ma_nhan_audit() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM fn_ghi_audit('TAO_MA_NHAN', 'ma_nhan', NEW.id, format('buu_kien_id=%s', NEW.buu_kien_id));
    ELSIF NEW.da_su_dung AND NOT OLD.da_su_dung THEN
        PERFORM fn_ghi_audit('SU_DUNG_MA_NHAN', 'ma_nhan', NEW.id, format('buu_kien_id=%s', NEW.buu_kien_id));
    END IF;
    RETURN NEW;
END;
$$;
CREATE TRIGGER trg_ma_nhan_audit AFTER INSERT OR UPDATE ON ma_nhan FOR EACH ROW EXECUTE FUNCTION trg_fn_ma_nhan_audit();

-- T10. NHẬT KÝ AUDIT BẤT BIẾN: cấm sửa, xóa, truncate
CREATE OR REPLACE FUNCTION trg_fn_audit_bat_bien() RETURNS TRIGGER
LANGUAGE plpgsql AS $$
BEGIN
    RAISE EXCEPTION 'Nhật ký audit chỉ được thêm, không được sửa hoặc xóa';
    RETURN NULL;
END;
$$;
CREATE TRIGGER trg_audit_khong_sua_xoa BEFORE UPDATE OR DELETE ON nhat_ky_audit FOR EACH ROW       EXECUTE FUNCTION trg_fn_audit_bat_bien();
CREATE TRIGGER trg_audit_khong_truncate BEFORE TRUNCATE        ON nhat_ky_audit FOR EACH STATEMENT EXECUTE FUNCTION trg_fn_audit_bat_bien();

/* =====================================================================
   PHẦN 4. VIEW
   ===================================================================== */

-- Cho NHÂN VIÊN: bưu kiện đang lưu. Chỉ có số căn hộ, KHÔNG có tên / sdt cư dân.
CREATE VIEW v_buu_kien_dang_luu AS
SELECT b.id AS buu_kien_id, b.ma_van_don, ch.so_can_ho, ch.toa_nha,
       t.ma_tu, n.ma_ngan, b.kich_co, b.trang_thai,
       b.ngay_tiep_nhan, b.ngay_het_han_luu,
       GREATEST(0, CURRENT_DATE - b.ngay_het_han_luu::date) AS so_ngay_qua_han
FROM buu_kien b
JOIN can_ho ch        ON ch.id = b.can_ho_id
LEFT JOIN ngan_tu n   ON n.id  = b.ngan_tu_id
LEFT JOIN tu_locker t ON t.id  = n.tu_id
WHERE b.trang_thai IN ('CHO_NHAN','QUA_HAN');

-- Cho CƯ DÂN: bưu kiện của căn hộ mình đang ở. Ứng dụng luôn lọc  WHERE cu_dan_id = <người đăng nhập>
CREATE VIEW v_buu_kien_cua_cu_dan AS
SELECT cd.id AS cu_dan_id, b.id AS buu_kien_id, b.ma_van_don,
       t.ma_tu, n.ma_ngan, b.trang_thai,
       b.ngay_tiep_nhan, b.ngay_het_han_luu, b.ngay_nhan
FROM cu_tru ct
JOIN cu_dan cd        ON cd.id = ct.cu_dan_id
JOIN buu_kien b       ON b.can_ho_id = ct.can_ho_id
LEFT JOIN ngan_tu n   ON n.id = b.ngan_tu_id
LEFT JOIN tu_locker t ON t.id = n.tu_id
WHERE ct.ngay_bat_dau <= CURRENT_DATE
  AND (ct.ngay_ket_thuc IS NULL OR ct.ngay_ket_thuc >= CURRENT_DATE);

-- Bưu kiện quá hạn kèm phí lưu kho dự kiến
CREATE VIEW v_buu_kien_qua_han AS
SELECT v.buu_kien_id, v.ma_van_don, v.so_can_ho, v.ma_tu, v.ma_ngan,
       v.ngay_het_han_luu, v.so_ngay_qua_han,
       tinh_phi_luu_kho(v.buu_kien_id) AS phi_luu_kho_du_kien
FROM v_buu_kien_dang_luu v
WHERE v.trang_thai = 'QUA_HAN';

-- Thống kê theo từng tủ (dashboard quản trị)
CREATE VIEW v_thong_ke_tu AS
SELECT t.id AS tu_id, t.ma_tu, t.vi_tri, t.trang_thai,
       count(n.id)                                      AS tong_ngan,
       count(n.id) FILTER (WHERE n.trang_thai = 'DANG_DUNG') AS dang_dung,
       count(n.id) FILTER (WHERE n.trang_thai = 'TRONG')     AS con_trong,
       count(n.id) FILTER (WHERE n.trang_thai = 'HONG')      AS hong
FROM tu_locker t LEFT JOIN ngan_tu n ON n.tu_id = t.id
GROUP BY t.id, t.ma_tu, t.vi_tri, t.trang_thai;

-- Tổng quan dashboard quản trị (1 dòng)
CREATE VIEW v_thong_ke_tong_quan AS
SELECT
    (SELECT count(*) FROM tu_locker)                                         AS so_tu,
    (SELECT count(*) FROM ngan_tu)                                           AS so_ngan,
    (SELECT count(*) FROM ngan_tu WHERE trang_thai = 'DANG_DUNG')            AS ngan_dang_dung,
    (SELECT count(*) FROM ngan_tu WHERE trang_thai = 'TRONG')                AS ngan_trong,
    (SELECT count(*) FROM buu_kien WHERE trang_thai = 'CHO_NHAN')            AS buu_kien_cho_nhan,
    (SELECT count(*) FROM buu_kien WHERE trang_thai = 'QUA_HAN')             AS buu_kien_qua_han,
    (SELECT count(*) FROM tai_khoan)                                         AS so_tai_khoan,
    (SELECT count(*) FROM tai_khoan WHERE vai_tro = 'CU_DAN')                AS so_cu_dan,
    (SELECT count(*) FROM tai_khoan WHERE vai_tro = 'NHAN_VIEN')             AS so_nhan_vien,
    (SELECT count(*) FROM tai_khoan WHERE vai_tro = 'SHIPPER')               AS so_shipper,
    (SELECT count(*) FROM can_ho)                                            AS so_can_ho,
    (SELECT count(*) FROM can_ho WHERE trang_thai = 'CO_NGUOI_O')            AS can_ho_co_nguoi_o,
    (SELECT count(*) FROM nhat_ky_audit WHERE thoi_gian::date = CURRENT_DATE) AS thao_tac_hom_nay;

-- Nhật ký audit dễ đọc: ai (tên đăng nhập + vai trò), làm gì, lúc nào
CREATE VIEW v_nhat_ky_audit_chi_tiet AS
SELECT a.id, a.thoi_gian,
       COALESCE(tk.ten_dang_nhap, 'HE_THONG') AS nguoi_thao_tac,
       COALESCE(tk.vai_tro, 'HE_THONG')       AS vai_tro,
       a.hanh_dong, a.doi_tuong, a.doi_tuong_id, a.chi_tiet, a.dia_chi_ip
FROM nhat_ky_audit a LEFT JOIN tai_khoan tk ON tk.id = a.tai_khoan_id;

-- Thông báo đang chờ gửi (cho dịch vụ gửi SMS / email / push, vd qua Kafka hoặc RabbitMQ)
CREATE VIEW v_thong_bao_chua_gui AS
SELECT tb.id, tb.buu_kien_id, tb.cu_dan_id, tb.kenh_gui, tb.noi_dung, cd.sdt, cd.email
FROM thong_bao tb JOIN cu_dan cd ON cd.id = tb.cu_dan_id
WHERE tb.trang_thai_gui = 'CHO_GUI';

/* =====================================================================
   PHẦN 5. PHÂN QUYỀN: KHÔNG LỘ DANH SÁCH CƯ DÂN
   Nhân viên / cư dân KHÔNG được đọc thẳng các bảng cu_dan, cu_tru, tai_khoan.
   Họ chỉ đi qua view và hàm ở trên.
   ===================================================================== */
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_cu_dan')    THEN CREATE ROLE role_cu_dan    NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_nhan_vien') THEN CREATE ROLE role_nhan_vien NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_quan_tri')  THEN CREATE ROLE role_quan_tri  NOLOGIN; END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'role_dich_vu')   THEN CREATE ROLE role_dich_vu   NOLOGIN; END IF;
END
$$;

REVOKE ALL ON ALL TABLES IN SCHEMA public FROM role_cu_dan, role_nhan_vien, role_quan_tri, role_dich_vu;

REVOKE EXECUTE ON FUNCTION ton_tai_can_ho(TEXT)                                         FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION tiep_nhan_buu_kien(TEXT, TEXT, TEXT, BIGINT, BIGINT)         FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION sinh_ma_nhan(BIGINT, BIGINT)                                 FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION xac_thuc_ma_nhan(BIGINT, TEXT)                               FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION danh_dau_qua_han()                                           FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION xu_ly_buu_kien_qua_han(BIGINT, TEXT, BIGINT, TEXT)           FROM PUBLIC;

-- Cư dân: chỉ xem bưu kiện của mình và nhập mã nhận
GRANT SELECT  ON v_buu_kien_cua_cu_dan TO role_cu_dan;
GRANT EXECUTE ON FUNCTION xac_thuc_ma_nhan(BIGINT, TEXT) TO role_cu_dan;

-- Nhân viên: xem bưu kiện (chỉ số căn hộ), tra cứu căn hộ có/không, tiếp nhận, xử lý quá hạn
GRANT SELECT  ON v_buu_kien_dang_luu, v_buu_kien_qua_han TO role_nhan_vien;
GRANT EXECUTE ON FUNCTION ton_tai_can_ho(TEXT)                                 TO role_nhan_vien;
GRANT EXECUTE ON FUNCTION tiep_nhan_buu_kien(TEXT, TEXT, TEXT, BIGINT, BIGINT) TO role_nhan_vien;
GRANT EXECUTE ON FUNCTION xu_ly_buu_kien_qua_han(BIGINT, TEXT, BIGINT, TEXT)   TO role_nhan_vien;

-- Quản trị: xem toàn bộ nhưng không thấy mật khẩu băm
GRANT SELECT ON ALL TABLES IN SCHEMA public TO role_quan_tri;
REVOKE SELECT ON tai_khoan FROM role_quan_tri;
GRANT  SELECT (id, ten_dang_nhap, vai_tro, trang_thai, ngay_tao) ON tai_khoan TO role_quan_tri;

-- Dịch vụ nền (backend): sinh mã nhận, quét quá hạn, đọc thông báo chờ gửi
GRANT EXECUTE ON FUNCTION sinh_ma_nhan(BIGINT, BIGINT) TO role_dich_vu;
GRANT EXECUTE ON FUNCTION danh_dau_qua_han()           TO role_dich_vu;
GRANT SELECT  ON v_thong_bao_chua_gui                  TO role_dich_vu;

/* =====================================================================
   PHẦN 6. DỮ LIỆU MẪU (mật khẩu của mọi tài khoản mẫu: 123456)
   ===================================================================== */

INSERT INTO tai_khoan (ten_dang_nhap, mat_khau_hash, vai_tro) VALUES
 ('admin01',     crypt('123456', gen_salt('bf')), 'QUAN_TRI_VIEN'),
 ('nv_an',       crypt('123456', gen_salt('bf')), 'NHAN_VIEN'),
 ('nv_binh',     crypt('123456', gen_salt('bf')), 'NHAN_VIEN'),
 ('shipper_spx', crypt('123456', gen_salt('bf')), 'SHIPPER'),
 ('cd_1205',     crypt('123456', gen_salt('bf')), 'CU_DAN'),
 ('cd_0803',     crypt('123456', gen_salt('bf')), 'CU_DAN'),
 ('cd_1501',     crypt('123456', gen_salt('bf')), 'CU_DAN');

INSERT INTO quan_tri_vien (tai_khoan_id, ho_ten, email, cap_do_quyen)
SELECT id, 'Quản Trị Viên Một', 'admin01@toanha.vn', 'CAO' FROM tai_khoan WHERE ten_dang_nhap = 'admin01';

INSERT INTO nhan_vien (tai_khoan_id, ma_nhan_vien, ho_ten, sdt, chuc_vu, ca_truc)
SELECT id, 'NV001', 'Nguyễn Văn An',  '0901000001', 'BAO_VE', 'SANG'  FROM tai_khoan WHERE ten_dang_nhap = 'nv_an'
UNION ALL
SELECT id, 'NV002', 'Trần Thị Bình',  '0901000002', 'LE_TAN', 'CHIEU' FROM tai_khoan WHERE ten_dang_nhap = 'nv_binh';

INSERT INTO shipper (tai_khoan_id, ho_ten, sdt, don_vi_van_chuyen, bien_so_xe)
SELECT id, 'Lê Văn Giao', '0902000001', 'Shopee Express', '59X1-12345' FROM tai_khoan WHERE ten_dang_nhap = 'shipper_spx';

INSERT INTO cu_dan (tai_khoan_id, ho_ten, sdt, email, kenh_thong_bao_uu_tien)
SELECT id, 'Phạm Minh Cư', '0903000001', 'cu1205@mail.vn', 'APP' FROM tai_khoan WHERE ten_dang_nhap = 'cd_1205'
UNION ALL
SELECT id, 'Hoàng Thị Dân', '0903000002', 'cu0803@mail.vn', 'SMS' FROM tai_khoan WHERE ten_dang_nhap = 'cd_0803'
UNION ALL
SELECT id, 'Võ Quốc Dân',   '0903000003', 'cu1501@mail.vn', 'EMAIL' FROM tai_khoan WHERE ten_dang_nhap = 'cd_1501';

INSERT INTO can_ho (so_can_ho, tang, toa_nha) VALUES
 ('A-1205', 12, 'A'), ('A-0803', 8, 'A'), ('B-1501', 15, 'B'), ('B-0302', 3, 'B');

INSERT INTO cu_tru (cu_dan_id, can_ho_id, ngay_bat_dau)
SELECT cd.id, ch.id, DATE '2025-01-01'
FROM (VALUES ('cd_1205','A-1205'), ('cd_0803','A-0803'), ('cd_1501','B-1501')) AS m(tk, ch_so)
JOIN tai_khoan tk ON tk.ten_dang_nhap = m.tk
JOIN cu_dan cd    ON cd.tai_khoan_id = tk.id
JOIN can_ho ch    ON ch.so_can_ho = m.ch_so;

INSERT INTO tu_locker (quan_tri_vien_id, ma_tu, vi_tri)
SELECT q.id, 'TU-A', 'Sảnh tòa A, tầng trệt' FROM quan_tri_vien q
UNION ALL
SELECT q.id, 'TU-B', 'Sảnh tòa B, tầng trệt' FROM quan_tri_vien q;

-- Mỗi tủ 12 ngăn: 4 ngăn S, 4 ngăn M, 4 ngăn L
INSERT INTO ngan_tu (tu_id, ma_ngan, kich_co)
SELECT t.id, right(t.ma_tu, 1) || '-' || lpad(g::TEXT, 2, '0'),
       CASE WHEN g <= 4 THEN 'S' WHEN g <= 8 THEN 'M' ELSE 'L' END
FROM tu_locker t CROSS JOIN generate_series(1, 12) AS g;

/* =====================================================================
   PHẦN 7. CHẠY THỬ (xem kết quả ở tab Data Output và Messages)
   Xóa phần này nếu bạn muốn CSDL sạch, chỉ có dữ liệu mẫu ở phần 6.
   ===================================================================== */

-- 7.1 Tra cứu căn hộ: chỉ ra true / false
SELECT ton_tai_can_ho('A-1205') AS co_a_1205, ton_tai_can_ho('Z-9999') AS co_z_9999;

-- 7.2 Luồng tiếp nhận -> sinh mã -> nhập sai -> nhập đúng -> nhập lại mã đã dùng
DO $$
DECLARE
    v_nv  BIGINT;
    v_sp  BIGINT;
    v_id  BIGINT;
    v_ma  TEXT;
BEGIN
    SELECT id INTO v_nv FROM nhan_vien WHERE ma_nhan_vien = 'NV001';
    SELECT id INTO v_sp FROM shipper LIMIT 1;

    SELECT o_buu_kien_id INTO v_id FROM tiep_nhan_buu_kien('SPX0123456', 'A-1205', 'M', v_nv, v_sp);
    v_ma := sinh_ma_nhan(v_id);
    RAISE NOTICE 'Mã nhận (chỉ hiện 1 lần, CSDL chỉ lưu bản băm): %', v_ma;

    PERFORM set_config('app.tai_khoan_id', (SELECT id::TEXT FROM tai_khoan WHERE ten_dang_nhap = 'cd_1205'), true);
    RAISE NOTICE 'Nhập sai mã   -> %', xac_thuc_ma_nhan(v_id, '000000');
    RAISE NOTICE 'Nhập đúng mã  -> %', xac_thuc_ma_nhan(v_id, v_ma);
    RAISE NOTICE 'Dùng lại mã   -> %', xac_thuc_ma_nhan(v_id, v_ma);
END
$$;

-- 7.3 Luồng quá hạn: tạo bưu kiện đã quá hạn lưu kho 2 ngày, quét, rồi xử lý
DO $$
DECLARE
    v_nv  BIGINT;
    v_id  BIGINT;
    v_phi NUMERIC;
BEGIN
    SELECT id INTO v_nv FROM nhan_vien WHERE ma_nhan_vien = 'NV002';
    PERFORM set_config('app.tai_khoan_id', (SELECT tai_khoan_id::TEXT FROM nhan_vien WHERE id = v_nv), true);

    INSERT INTO buu_kien (ma_van_don, can_ho_id, ngan_tu_id, nhan_vien_tiep_nhan_id, kich_co, ngay_tiep_nhan, ngay_het_han_luu)
    VALUES ('GHN8899001', (SELECT id FROM can_ho WHERE so_can_ho = 'A-0803'), chon_ngan_trong('S'), v_nv, 'S',
            now() - interval '5 days', now() - interval '2 days')
    RETURNING id INTO v_id;

    RAISE NOTICE 'Số bưu kiện vừa chuyển sang QUA_HAN: %', danh_dau_qua_han();
    v_phi := xu_ly_buu_kien_qua_han(v_id, 'HOAN_TRA', v_nv, 'Cư dân không đến nhận');
    RAISE NOTICE 'Phí lưu kho đã tính: % VNĐ', v_phi;
END
$$;

-- 7.4 Thử vi phạm: các lệnh dưới đây PHẢI báo lỗi (bỏ dấu -- ở đầu dòng để thử từng lệnh)
-- UPDATE nhat_ky_audit SET hanh_dong = 'XOA_DAU_VET' WHERE id = 1;     -- audit bất biến
-- DELETE FROM nhat_ky_audit;                                           -- audit bất biến
-- UPDATE ma_nhan SET da_su_dung = FALSE, ngay_su_dung = NULL;          -- mã đã dùng không mở lại được
-- INSERT INTO cu_dan (tai_khoan_id, ho_ten) SELECT id, 'Sai vai trò' FROM tai_khoan WHERE ten_dang_nhap = 'nv_an';

-- 7.5 Xem kết quả qua view
SELECT * FROM v_buu_kien_dang_luu;
SELECT * FROM v_buu_kien_cua_cu_dan WHERE cu_dan_id = (SELECT cd.id FROM cu_dan cd JOIN tai_khoan tk ON tk.id = cd.tai_khoan_id WHERE tk.ten_dang_nhap = 'cd_1205');
SELECT * FROM v_thong_ke_tu;
SELECT * FROM v_thong_ke_tong_quan;
SELECT * FROM v_thong_bao_chua_gui;
SELECT thoi_gian, nguoi_thao_tac, vai_tro, hanh_dong, doi_tuong, doi_tuong_id, chi_tiet
FROM v_nhat_ky_audit_chi_tiet ORDER BY id;

/* =====================================================================
   TÙY CHỌN: PostGIS (đề có nêu). Chỉ chạy khi đã cài PostGIS, bỏ dấu comment:
   CREATE EXTENSION IF NOT EXISTS postgis;
   ALTER TABLE tu_locker ADD COLUMN toa_do geometry(Point, 4326);
   CREATE INDEX idx_tu_locker_toa_do ON tu_locker USING gist (toa_do);
   ===================================================================== */
