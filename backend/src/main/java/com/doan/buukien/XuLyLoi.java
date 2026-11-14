package com.doan.buukien.common;

import org.springframework.dao.DataAccessException;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice
public class XuLyLoi {

    @ExceptionHandler(DataAccessException.class)
    public ResponseEntity<Map<String, String>> loiCsdl(DataAccessException ex) {
        String m = ex.getMostSpecificCause().getMessage();
        String dong1 = m.lines().findFirst().orElse(m).replaceFirst("^ERROR:\\s*", "");
        return ResponseEntity.badRequest().body(Map.of("loi", dong1));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> loiDauVao(IllegalArgumentException ex) {
        return ResponseEntity.badRequest().body(Map.of("loi", ex.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> loiHopLe(MethodArgumentNotValidException ex) {
        String msg = ex.getBindingResult().getFieldErrors().stream()
                .findFirst()
                .map(f -> f.getField() + ": " + f.getDefaultMessage())
                .orElse("Dữ liệu không hợp lệ");
        return ResponseEntity.badRequest().body(Map.of("loi", msg));
    }
}