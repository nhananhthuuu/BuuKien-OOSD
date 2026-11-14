package com.doan.buukien.nhanvien;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record TiepNhanRequest(
        @NotBlank String maVanDon,
        @NotBlank String soCanHo,
        @NotBlank @Pattern(regexp = "S|M|L", message = "kichCo chỉ nhận S, M hoặc L") String kichCo,
        Long shipperId   // có thể bỏ trống
) {}