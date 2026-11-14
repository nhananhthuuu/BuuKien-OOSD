package com.doan.buukien.quantri;

import com.doan.buukien.security.NguoiDungHienTai;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/tai-khoan")
public class TaiKhoanEmailController {

    // email để trống hoặc null nghĩa là xóa email của tài khoản
    public record SuaEmailRequest(@Size(max = 100) @Email String email) {
    }

    private final TaiKhoanEmailService service;

    public TaiKhoanEmailController(TaiKhoanEmailService service) {
        this.service = service;
    }

    @GetMapping
    public List<Map<String, Object>> dsTaiKhoan() {
        return service.dsTaiKhoan();
    }

    @PutMapping("/{id}/email")
    public Map<String, Object> suaEmail(@AuthenticationPrincipal NguoiDungHienTai nd,
                                        HttpServletRequest req,
                                        @PathVariable Long id,
                                        @Valid @RequestBody SuaEmailRequest rq) {
        return service.suaEmail(nd, req.getRemoteAddr(), id, rq.email());
    }
}