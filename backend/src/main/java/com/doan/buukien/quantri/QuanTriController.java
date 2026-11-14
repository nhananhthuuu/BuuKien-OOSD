package com.doan.buukien.quantri;

import com.doan.buukien.security.NguoiDungHienTai;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
public class QuanTriController {

    private final QuanTriService service;

    public QuanTriController(QuanTriService service) {
        this.service = service;
    }

    @GetMapping("/dashboard/tong-quan")
    public Map<String, Object> tongQuan() {
        return service.tongQuan();
    }

    @GetMapping("/dashboard/thong-ke-tu")
    public List<Map<String, Object>> thongKeTu() {
        return service.thongKeTu();
    }

    @GetMapping("/nhat-ky-audit")
    public List<Map<String, Object>> nhatKy(@RequestParam(name = "limit", defaultValue = "50") int limit,
                                            @RequestParam(name = "hanhDong", required = false) String hanhDong) {
        int gioiHan = Math.max(1, Math.min(limit, 200));
        return service.nhatKyAudit(gioiHan, hanhDong);
    }

    @GetMapping("/cau-hinh-kho")
    public Map<String, Object> cauHinh() {
        return service.cauHinh();
    }

    @PutMapping("/cau-hinh-kho")
    public Map<String, Object> suaCauHinh(@AuthenticationPrincipal NguoiDungHienTai nd,
                                          HttpServletRequest req,
                                          @Valid @RequestBody CauHinhRequest rq) {
        return service.suaCauHinh(nd, req.getRemoteAddr(), rq);
    }
}