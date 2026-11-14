package com.doan.buukien.common;

import com.doan.buukien.security.NguoiDungHienTai;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class AuditContext {

    private final JdbcTemplate jdbc;

    public AuditContext(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    // Phải gọi bên trong @Transactional để cùng 1 kết nối với lệnh nghiệp vụ phía sau
    public void gan(NguoiDungHienTai nd, String ip) {
        jdbc.queryForList(
                "SELECT set_config('app.tai_khoan_id', ?, true), set_config('app.ip', ?, true)",
                String.valueOf(nd.id()), ip
        );
    }
}