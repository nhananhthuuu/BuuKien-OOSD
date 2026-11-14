package com.doan.buukien.thongbao;

import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
public class ThongBaoConsumer {

    private final JdbcTemplate jdbc;

    public ThongBaoConsumer(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @RabbitListener(queues = RabbitConfig.HANG_DOI)
    public void nhan(String tin) {
        String[] p = tin.split("\\|", 4);
        if (p.length < 4) {
            return;
        }
        long id = Long.parseLong(p[0]);
        // Chỉ đổi khi còn CHO_GUI: tin trùng lặp sẽ không gửi lần hai
        int dong = jdbc.update(
                "UPDATE thong_bao SET trang_thai_gui = 'DA_GUI' WHERE id = ? AND trang_thai_gui = 'CHO_GUI'", id);
        if (dong == 1) {
            System.out.println("[GIA LAP " + p[1] + " -> " + p[2] + "] " + p[3]);
        }
    }
}