package com.doan.buukien.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Service
public class JwtService {

    private final SecretKey key;
    private final long hetHanMs;

    public JwtService(@Value("${app.jwt.secret}") String secret,
                      @Value("${app.jwt.het-han-phut}") long hetHanPhut) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.hetHanMs = hetHanPhut * 60_000;
    }

    public String taoToken(Long taiKhoanId, String tenDangNhap, String vaiTro) {
        Date now = new Date();
        return Jwts.builder()
                .subject(tenDangNhap)
                .claim("uid", taiKhoanId)
                .claim("role", vaiTro)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + hetHanMs))
                .signWith(key)
                .compact();
    }

    // Token sai chữ ký hoặc hết hạn sẽ ném exception
    public Claims docToken(String token) {
        return Jwts.parser().verifyWith(key).build()
                .parseSignedClaims(token).getPayload();
    }
}