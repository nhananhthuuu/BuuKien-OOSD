package com.doan.buukien.thongbao;

import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

@Component
public class ThongBaoDispatcher {

    private final JdbcTemplate jdbc;
    private final RabbitTemplate rabbit;

    public ThongBaoDispatcher(JdbcTemplate jdbc, RabbitTemplate rabbit) {
        this.jdbc = jdbc;
        this.rabbit = rabbit;
    }

    @Scheduled(fixedDelay = 10000)
    public void guiThongBaoChoGui() {
        List<Map<String, Object>> ds = jdbc.queryForList(
                "SELECT id, kenh_gui, noi_dung, sdt, email FROM v_thong_bao_chua_gui LIMIT 50");
        for (Map<String, Object> tb : ds) {
            String kenh = String.valueOf(tb.get("kenh_gui"));
            String dich;
            if ("SMS".equals(kenh)) {
                dich = String.valueOf(tb.get("sdt"));
            } else if ("EMAIL".equals(kenh)) {
                dich = String.valueOf(tb.get("email"));
            } else {
                dich = "app";
            }
            String noiDung = String.valueOf(tb.get("noi_dung")).replace("|", " ");
            rabbit.convertAndSend(RabbitConfig.HANG_DOI,
                    tb.get("id") + "|" + kenh + "|" + dich + "|" + noiDung);
        }
    }
}