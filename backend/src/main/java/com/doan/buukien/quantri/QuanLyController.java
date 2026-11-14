package com.doan.buukien.quantri;

import com.doan.buukien.security.NguoiDungHienTai;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
public class QuanLyController {

    public record NhanVienMoi(
            @NotBlank @Size(min = 3, max = 50) String tenDangNhap,
            @NotBlank @Size(min = 6, max = 72) String matKhau,
            @NotBlank @Size(max = 100) String hoTen,
            @Size(max = 15) String sdt,
            @Pattern(regexp = "BAO_VE|LE_TAN") String chucVu,
            @Pattern(regexp = "SANG|CHIEU|TOI") String caTruc) {
    }

    public record KhoaRequest(boolean khoa) {
    }

    public record TuMoi(
            @NotBlank @Pattern(regexp = "[A-Za-z0-9-]{3,10}") String maTu,
            @NotBlank @Size(max = 100) String viTri,
            Double kinhDo,
            Double viDo,
            @Min(0) @Max(20) int soNganS,
            @Min(0) @Max(20) int soNganM,
            @Min(0) @Max(20) int soNganL) {
    }

    private final QuanLyService service;

    public QuanLyController(QuanLyService service) {
        this.service = service;
    }

    @GetMapping("/nhan-vien")
    public List<Map<String, Object>> dsNhanVien() {
        return service.dsNhanVien();
    }

    @PostMapping("/nhan-vien")
    public Map<String, Object> themNhanVien(@AuthenticationPrincipal NguoiDungHienTai nd,
                                            HttpServletRequest req,
                                            @Valid @RequestBody NhanVienMoi rq) {
        return service.themNhanVien(nd, req.getRemoteAddr(), rq);
    }

    @PutMapping("/nhan-vien/{id}/khoa")
    public Map<String, Object> khoa(@AuthenticationPrincipal NguoiDungHienTai nd,
                                    HttpServletRequest req,
                                    @PathVariable Long id,
                                    @RequestBody KhoaRequest rq) {
        service.khoaNhanVien(nd, req.getRemoteAddr(), id, rq.khoa());
        return Map.of("thanhCong", true);
    }

    @GetMapping("/tu")
    public List<Map<String, Object>> dsTu() {
        return service.dsTu();
    }

    @PostMapping("/tu")
    public Map<String, Object> themTu(@AuthenticationPrincipal NguoiDungHienTai nd,
                                      HttpServletRequest req,
                                      @Valid @RequestBody TuMoi rq) {
        return service.themTu(nd, req.getRemoteAddr(), rq);
    }
}