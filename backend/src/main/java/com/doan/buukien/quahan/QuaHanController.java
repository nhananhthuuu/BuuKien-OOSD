package com.doan.buukien.quahan;

import com.doan.buukien.security.NguoiDungHienTai;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/nhan-vien/qua-han")
public class QuaHanController {

    private final QuaHanService service;

    public QuaHanController(QuaHanService service) {
        this.service = service;
    }

    @GetMapping
    public List<Map<String, Object>> danhSach() {
        return service.danhSach();
    }

    // Quét ngay (để thử, không phải chờ job)
    @PostMapping("/quet-ngay")
    public Map<String, Object> quetNgay() {
        return Map.of("soBuuKienChuyenQuaHan", service.quet());
    }

    @PostMapping("/{id}/xu-ly")
    public Map<String, Object> xuLy(@AuthenticationPrincipal NguoiDungHienTai nd,
                                    HttpServletRequest req,
                                    @PathVariable Long id,
                                    @Valid @RequestBody XuLyQuaHanRequest rq) {
        BigDecimal phi = service.xuLy(nd, req.getRemoteAddr(), id, rq);
        return Map.of("buuKienId", id, "hinhThuc", rq.hinhThuc(), "phiLuuKho", phi);
    }
}