package com.doan.buukien.security;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
@RequestMapping("/api/auth/quen-mat-khau")
public class QuenMatKhauController {

    // dinhDanh = tên đăng nhập hoặc email
    public record YeuCauRequest(@NotBlank @Size(max = 100) String dinhDanh) {
    }

    public record XacMinhRequest(@NotBlank @Size(max = 100) String dinhDanh,
                                 @NotBlank @Size(min = 6, max = 6) String otp) {
    }

    public record DatLaiRequest(@NotBlank @Size(max = 100) String dinhDanh,
                                @NotBlank @Size(min = 6, max = 6) String otp,
                                @NotBlank @Size(min = 6, max = 72) String matKhauMoi) {
    }

    private final QuenMatKhauService service;

    public QuenMatKhauController(QuenMatKhauService service) {
        this.service = service;
    }

    // Luôn trả cùng một thông báo, dù tài khoản có tồn tại hay không
    @PostMapping("/yeu-cau")
    public ResponseEntity<?> yeuCau(@Valid @RequestBody YeuCauRequest req, HttpServletRequest http) {
        service.yeuCau(req.dinhDanh(), http.getRemoteAddr());
        return ResponseEntity.ok(Map.of("thongBao",
                "Nếu thông tin hợp lệ, mã OTP đã được gửi đến email đã đăng ký của tài khoản."));
    }

    @PostMapping("/xac-minh")
    public ResponseEntity<?> xacMinh(@Valid @RequestBody XacMinhRequest req, HttpServletRequest http) {
        if (!service.xacMinh(req.dinhDanh(), req.otp(), http.getRemoteAddr())) {
            return loiOtp();
        }
        return ResponseEntity.ok(Map.of("hopLe", true));
    }

    @PostMapping("/dat-lai")
    public ResponseEntity<?> datLai(@Valid @RequestBody DatLaiRequest req, HttpServletRequest http) {
        if (!service.datLai(req.dinhDanh(), req.otp(), req.matKhauMoi(), http.getRemoteAddr())) {
            return loiOtp();
        }
        return ResponseEntity.ok(Map.of("thongBao", "Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại."));
    }

    private ResponseEntity<?> loiOtp() {
        return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(Map.of("loi", "Mã OTP không đúng hoặc đã hết hạn"));
    }
}