# BuuKien-OOSD: Hệ thống quản lý bưu kiện tòa nhà thông minh

Đồ án môn Phương pháp phát triển phần mềm hướng đối tượng (OOSD).

- Sinh viên: Nhan Anh Thư (MSSV 1250080190)
- Lớp: 12_ĐH_CNPM2, khóa 2023 - 2027
- Trường: Đại học Tài nguyên và Môi trường TP.HCM
- Mã nguồn: https://github.com/nhananhthuuu/BuuKien-OOSD

## Công nghệ sử dụng

- Backend: Java, Spring Boot (Maven), cổng 8080
- Cơ sở dữ liệu: PostgreSQL
- Hàng đợi tin nhắn: RabbitMQ
- Gửi OTP quên mật khẩu: Gmail SMTP
- Ứng dụng: Flutter (Android, iOS, ...)

## Cấu trúc thư mục

| Thư mục | Nội dung |
|---|---|
| `backend/` | Mã nguồn server Spring Boot |
| `app/` | Mã nguồn ứng dụng Flutter |
| `sql/` | Script tạo cơ sở dữ liệu |
| `draw.oi ppttk/` | Các sơ đồ thiết kế (file draw.io) |
| `png_so_do/` | Các sơ đồ dạng ảnh PNG |

## Yêu cầu cài đặt

- JDK 17 trở lên (hoặc đúng phiên bản trong `backend/pom.xml`)
- PostgreSQL (project dùng cổng 5433, database `parcel_db`)
- RabbitMQ (cổng 5672)
- Flutter SDK

## Hướng dẫn chạy

### 1. Tạo cơ sở dữ liệu

1. Tạo database tên `parcel_db` trong PostgreSQL.
2. Chạy các file script trong thư mục `sql/` để tạo bảng và dữ liệu mẫu.

### 2. Cấu hình mật khẩu (quan trọng)

Mật khẩu và khóa bí mật **không** được đưa lên GitHub. Trong `backend/src/main/resources/`:

1. Tạo file `application-local.properties` (file này đã bị `.gitignore` chặn).
2. Điền giá trị thật của máy bạn, theo mẫu:

```
spring.datasource.password=mat_khau_database_cua_ban
spring.rabbitmq.password=mat_khau_rabbitmq_cua_ban
app.jwt.secret=chuoi_bi_mat_jwt_dai_it_nhat_32_ky_tu
```

3. Muốn gửi OTP qua Gmail thì đặt thêm biến môi trường `MAIL_USERNAME` và `MAIL_PASSWORD` (mật khẩu ứng dụng của Gmail).

### 3. Chạy backend

```
cd backend
./mvnw spring-boot:run
```

(Trên Windows dùng `mvnw.cmd spring-boot:run`.) Server chạy tại http://localhost:8080.

### 4. Chạy ứng dụng Flutter

```
cd app
flutter pub get
flutter run
```

## Tài liệu thiết kế

Các sơ đồ phân tích và thiết kế nằm trong `draw.oi ppttk/` (file gốc draw.io) và `png_so_do/` (ảnh PNG).