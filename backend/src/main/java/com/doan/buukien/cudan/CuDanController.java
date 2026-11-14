package com.doan.buukien.cudan;

import com.doan.buukien.security.NguoiDungHienTai;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
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
@RequestMapping("/api/cu-dan")
public class CuDanController {

    private final CuDanService service;

    public CuDanController(CuDanService service) {
        this.service = service;
    }

    @GetMapping("/buu-kien")
    public List<Map<String, Object>> buuKien(@AuthenticationPrincipal NguoiDungHienTai nd,
                                             HttpServletRequest req) {
        return service.buuKienCuaToi(nd, req.getRemoteAddr());
    }

    @GetMapping("/thong-bao")
    public List<Map<String, Object>> thongBao(@AuthenticationPrincipal NguoiDungHienTai nd,
                                              HttpServletRequest req) {
        return service.thongBaoCuaToi(nd, req.getRemoteAddr());
    }

    @PostMapping("/buu-kien/{id}/nhan")
    public ResponseEntity<Map<String, Object>> nhan(@AuthenticationPrincipal NguoiDungHienTai nd,
                                                    HttpServletRequest req,
                                                    @PathVariable Long id,
                                                    @Valid @RequestBody NhanMaRequest rq) {
        boolean ok = service.nhanBangMa(nd, req.getRemoteAddr(), id, rq.ma());
        if (ok) {
            return ResponseEntity.ok(Map.of("thanhCong", true, "thongBao", "Mở ngăn thành công, mời bạn lấy bưu kiện"));
        }
        return ResponseEntity.badRequest().body(Map.of("thanhCong", false, "loi", "Mã sai, đã hết hạn hoặc đã dùng"));
    }
    @PostMapping("/buu-kien/{id}/lay-ma")
    public Map<String, Object> layMa(@AuthenticationPrincipal NguoiDungHienTai nd,
                                     HttpServletRequest req,
                                     @PathVariable Long id) {
        return service.layMaNhan(nd, req.getRemoteAddr(), id);
    }
}