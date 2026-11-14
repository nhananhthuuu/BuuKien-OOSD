package com.doan.buukien.quahan;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
@EnableScheduling
public class QuaHanJob {

    private static final Logger log = LoggerFactory.getLogger(QuaHanJob.class);

    private final QuaHanService service;

    public QuaHanJob(QuaHanService service) {
        this.service = service;
    }

    @Scheduled(fixedDelayString = "${app.job.quet-qua-han-ms:60000}", initialDelay = 15000)
    public void quet() {
        try {
            int n = service.quet();
            if (n > 0) {
                log.info("[JOB QUA HAN] Da chuyen {} buu kien sang QUA_HAN", n);
            }
        } catch (Exception e) {
            log.warn("[JOB QUA HAN] Quet that bai: {}", e.getMessage());
        }
    }
}