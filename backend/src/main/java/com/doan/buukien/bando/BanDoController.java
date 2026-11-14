package com.doan.buukien.bando;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ban-do")
public class BanDoController {

    private final BanDoService service;

    public BanDoController(BanDoService service) {
        this.service = service;
    }

    @GetMapping("/tu")
    public List<Map<String, Object>> tatCaTu() {
        return service.tatCaTu();
    }

    @GetMapping("/tu-gan-nhat")
    public List<Map<String, Object>> tuGanNhat(
            @RequestParam(name = "kinhDo") double kinhDo,
            @RequestParam(name = "viDo") double viDo,
            @RequestParam(name = "kichCo", defaultValue = "S") String kichCo) {

        if (!Double.isFinite(kinhDo) || kinhDo < -180 || kinhDo > 180) {
            throw new IllegalArgumentException("kinhDo phải nằm trong khoảng -180 đến 180");
        }
        if (!Double.isFinite(viDo) || viDo < -90 || viDo > 90) {
            throw new IllegalArgumentException("viDo phải nằm trong khoảng -90 đến 90");
        }
        if (kichCo != null && !kichCo.matches("S|M|L")) {
            throw new IllegalArgumentException("kichCo chỉ nhận S, M hoặc L");
        }
        return service.tuGanNhat(kinhDo, viDo, kichCo);
    }
}