package com.doan.buukien.nhanvien;

import com.doan.buukien.security.NguoiDungHienTai;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/nhan-vien")
public class NhanVienController {

    private final NhanVienService service;

    public NhanVienController(NhanVienService service) {
        this.service = service;
    }

    @GetMapping("/buu-kien-dang-luu")
    public List<Map<String, Object>> dangLuu(@AuthenticationPrincipal NguoiDungHienTai nd,
                                             HttpServletRequest req) {
        return service.danhSachDangLuu(nd, req.getRemoteAddr());
    }

    @GetMapping("/can-ho/{soCanHo}/ton-tai")
    public Map<String, Object> tonTai(@AuthenticationPrincipal NguoiDungHienTai nd,
                                      HttpServletRequest req,
                                      @PathVariable String soCanHo) {
        boolean co = service.tonTaiCanHo(nd, req.getRemoteAddr(), soCanHo);
        return Map.of("soCanHo", soCanHo, "tonTai", co);
    }

    @PostMapping("/buu-kien")
    public Map<String, Object> tiepNhan(@AuthenticationPrincipal NguoiDungHienTai nd,
                                        HttpServletRequest req,
                                        @Valid @RequestBody TiepNhanRequest rq) {
        return service.tiepNhan(nd, req.getRemoteAddr(), rq);
    }
}