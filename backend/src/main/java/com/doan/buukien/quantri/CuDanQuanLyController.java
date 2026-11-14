package com.doan.buukien.quantri;

import com.doan.buukien.security.NguoiDungHienTai;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
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
@RequestMapping("/api/admin")
public class CuDanQuanLyController {

    public record CuDanMoi(
            @NotBlank @Size(min = 3, max = 50) String tenDangNhap,
            @NotBlank @Size(min = 6, max = 72) String matKhau,
            @NotBlank @Size(max = 100) String hoTen,
            @Size(max = 15) String sdt,
            @Size(max = 100) String email,
            @Pattern(regexp = "APP|SMS|EMAIL") String kenhThongBao,
            @NotBlank @Size(max = 10) String soCanHo) {
    }

    public record GanCanHoRequest(@NotBlank @Size(max = 10) String soCanHo) {
    }

    public record CanHoMoi(
            @NotBlank @Size(max = 10) String soCanHo,
            @Min(1) int tang,
            @NotBlank @Size(max = 10) String toaNha) {
    }

    private final CuDanQuanLyService service;

    public CuDanQuanLyController(CuDanQuanLyService service) {
        this.service = service;
    }

    @GetMapping("/cu-dan")
    public List<Map<String, Object>> dsCuDan() {
        return service.dsCuDan();
    }

    @PostMapping("/cu-dan")
    public Map<String, Object> themCuDan(@AuthenticationPrincipal NguoiDungHienTai nd,
                                         HttpServletRequest req,
                                         @Valid @RequestBody CuDanMoi rq) {
        return service.themCuDan(nd, req.getRemoteAddr(), rq);
    }

    @PostMapping("/cu-dan/{id}/gan-can-ho")
    public Map<String, Object> ganCanHo(@AuthenticationPrincipal NguoiDungHienTai nd,
                                        HttpServletRequest req,
                                        @PathVariable Long id,
                                        @Valid @RequestBody GanCanHoRequest rq) {
        return service.ganCanHo(nd, req.getRemoteAddr(), id, rq.soCanHo());
    }

    @PostMapping("/cu-dan/{id}/chuyen-di")
    public Map<String, Object> chuyenDi(@AuthenticationPrincipal NguoiDungHienTai nd,
                                        HttpServletRequest req,
                                        @PathVariable Long id) {
        return service.chuyenDi(nd, req.getRemoteAddr(), id);
    }

    @GetMapping("/can-ho")
    public List<Map<String, Object>> dsCanHo() {
        return service.dsCanHo();
    }

    @PostMapping("/can-ho")
    public Map<String, Object> themCanHo(@AuthenticationPrincipal NguoiDungHienTai nd,
                                         HttpServletRequest req,
                                         @Valid @RequestBody CanHoMoi rq) {
        return service.themCanHo(nd, req.getRemoteAddr(), rq);
    }
}