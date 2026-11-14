package com.doan.buukien.thongbao;

import org.springframework.amqp.core.Queue;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    public static final String HANG_DOI = "thong_bao.gui";

    // Hàng đợi bền: khởi động lại RabbitMQ vẫn không mất tin
    @Bean
    public Queue hangDoiThongBao() {
        return new Queue(HANG_DOI, true);
    }
}