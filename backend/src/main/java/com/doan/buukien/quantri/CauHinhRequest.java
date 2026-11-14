package com.doan.buukien.quantri;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public record CauHinhRequest(
        @NotNull @Min(value = 0, message = "số ngày miễn phí phải >= 0") Integer soNgayMienPhi,
        @NotNull @Min(value = 0, message = "phí quá hạn phải >= 0") Long phiQuaHanMoiNgay,
        @NotNull @Min(value = 1, message = "số giờ hiệu lực mã phải >= 1") Integer soGioHieuLucMa
) {}