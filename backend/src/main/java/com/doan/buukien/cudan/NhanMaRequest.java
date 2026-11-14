package com.doan.buukien.cudan;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record NhanMaRequest(
        @NotBlank @Pattern(regexp = "\\d{6}", message = "mã nhận gồm đúng 6 chữ số") String ma
) {}