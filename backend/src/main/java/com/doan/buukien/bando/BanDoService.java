package com.doan.buukien.bando;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;
import java.util.Map;

@Service
public class BanDoService {

    private final JdbcTemplate jdbc;

    public BanDoService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> tatCaTu() {
        return jdbc.queryForList("SELECT * FROM v_tu_locker_ban_do");
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> tuGanNhat(double kinhDo, double viDo, String kichCo) {
        // kinhDo, viDo đã được kiểm tra là số hợp lệ nên ghép thẳng vào câu lệnh là an toàn
        String sql = String.format(Locale.ROOT,
                "SELECT * FROM tim_tu_gan_nhat(%.6f, %.6f, CAST(? AS TEXT))", kinhDo, viDo);
        return jdbc.queryForList(sql, kichCo);
    }
}