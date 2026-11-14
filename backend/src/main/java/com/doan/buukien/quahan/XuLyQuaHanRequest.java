package com.doan.buukien.quahan;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record XuLyQuaHanRequest(
        @NotBlank @Pattern(regexp = "HOAN_TRA|CHUYEN_KHO", message = "hinhThuc chỉ nhận HOAN_TRA hoặc CHUYEN_KHO") String hinhThuc,
        String ghiChu   // có thể bỏ trống
) {}