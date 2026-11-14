package com.doan.buukien.security;

import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;

@Component
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    public JwtAuthFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            try {
                Claims c = jwtService.docToken(header.substring(7));
                String vaiTro = c.get("role", String.class);
                Long uid = ((Number) c.get("uid")).longValue();

                var nguoiDung = new NguoiDungHienTai(uid, c.getSubject(), vaiTro);
                var auth = new UsernamePasswordAuthenticationToken(
                        nguoiDung, null, List.of(new SimpleGrantedAuthority("ROLE_" + vaiTro)));
                SecurityContextHolder.getContext().setAuthentication(auth);
            } catch (Exception e) {
                SecurityContextHolder.clearContext();   // token hỏng: coi như chưa đăng nhập
            }
        }
        chain.doFilter(request, response);
    }
}