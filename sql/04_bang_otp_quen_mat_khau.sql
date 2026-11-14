-- Migration 04: bảng lưu OTP quên mật khẩu
-- An toàn: chỉ tạo bảng mới, không đụng dữ liệu cũ

BEGIN;

CREATE TABLE IF NOT EXISTS otp_quen_mat_khau (
    id             BIGSERIAL PRIMARY KEY,
    tai_khoan_id   BIGINT       NOT NULL REFERENCES tai_khoan(id) ON DELETE CASCADE,
    otp_hash       TEXT         NOT NULL,
    het_han_luc    TIMESTAMPTZ  NOT NULL,
    so_lan_sai     INT          NOT NULL DEFAULT 0,
    da_su_dung     BOOLEAN      NOT NULL DEFAULT FALSE,
    ngay_tao       TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS ix_otp_tai_khoan_ngay_tao
    ON otp_quen_mat_khau (tai_khoan_id, ngay_tao DESC);

COMMIT;