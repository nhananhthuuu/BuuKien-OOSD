-- Migration 03: thêm email vào tai_khoan để hỗ trợ quên mật khẩu bằng OTP
-- An toàn: chỉ thêm cột mới, không xóa dữ liệu

BEGIN;

ALTER TABLE tai_khoan
    ADD COLUMN IF NOT EXISTS email VARCHAR(100);

-- Copy email đã có của cư dân sang tai_khoan
UPDATE tai_khoan tk
SET email = cd.email
FROM cu_dan cd
WHERE cd.tai_khoan_id = tk.id
  AND cd.email IS NOT NULL
  AND tk.email IS NULL;

-- Mỗi email chỉ thuộc về một tài khoản (không tính giá trị NULL, không phân biệt hoa/thường)
CREATE UNIQUE INDEX IF NOT EXISTS ux_tai_khoan_email
    ON tai_khoan (LOWER(email))
    WHERE email IS NOT NULL;

COMMIT;