CREATE EXTENSION IF NOT EXISTS postgis;

ALTER TABLE tu_locker ADD COLUMN IF NOT EXISTS toa_do geometry(Point, 4326);
CREATE INDEX IF NOT EXISTS idx_tu_locker_toa_do ON tu_locker USING gist (toa_do);

UPDATE tu_locker SET toa_do = ST_SetSRID(ST_MakePoint(106.7009, 10.7769), 4326) WHERE ma_tu = 'TU-A';
UPDATE tu_locker SET toa_do = ST_SetSRID(ST_MakePoint(106.7015, 10.7772), 4326) WHERE ma_tu = 'TU-B';

-- Tìm tủ gần nhất (theo kinh độ, vĩ độ) còn ngăn trống đủ cỡ
CREATE OR REPLACE FUNCTION tim_tu_gan_nhat(
    p_kinh_do DOUBLE PRECISION, p_vi_do DOUBLE PRECISION, p_kich_co TEXT DEFAULT 'S')
RETURNS TABLE (ma_tu VARCHAR, vi_tri VARCHAR, khoang_cach_m NUMERIC, so_ngan_trong BIGINT)
LANGUAGE sql STABLE AS $$
    SELECT t.ma_tu, t.vi_tri,
           round(ST_Distance(t.toa_do::geography,
                 ST_SetSRID(ST_MakePoint(p_kinh_do, p_vi_do), 4326)::geography)::numeric, 1),
           count(n.id)
    FROM tu_locker t
    JOIN ngan_tu n ON n.tu_id = t.id AND n.trang_thai = 'TRONG'
                  AND fn_rank_kich_co(n.kich_co) >= fn_rank_kich_co(p_kich_co)
    WHERE t.trang_thai = 'HOAT_DONG' AND t.toa_do IS NOT NULL
    GROUP BY t.id, t.ma_tu, t.vi_tri, t.toa_do
    ORDER BY 3
    LIMIT 1;
$$;

-- View cho Flutter vẽ vị trí tủ
CREATE OR REPLACE VIEW v_tu_locker_ban_do AS
SELECT s.tu_id, s.ma_tu, s.vi_tri, s.con_trong,
       ST_X(t.toa_do) AS kinh_do, ST_Y(t.toa_do) AS vi_do
FROM v_thong_ke_tu s JOIN tu_locker t ON t.id = s.tu_id
WHERE t.toa_do IS NOT NULL;

SELECT * FROM tim_tu_gan_nhat(106.7010, 10.7770, 'M');
SELECT * FROM v_tu_locker_ban_do;