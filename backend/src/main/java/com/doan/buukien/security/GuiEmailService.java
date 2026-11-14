package com.doan.buukien.security;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class GuiEmailService {

    private static final Logger log = LoggerFactory.getLogger(GuiEmailService.class);

    private final JavaMailSender mailSender;

    // Gmail dùng để gửi (lấy từ biến môi trường MAIL_USERNAME, có thể trống)
    @Value("${spring.mail.username:}")
    private String guiTu;

    // Chỉ bật khi test trên máy, chưa có Gmail: in OTP ra console thay vì gửi email
    @Value("${app.otp.dev-in-console:false}")
    private boolean devInConsole;

    public GuiEmailService(JavaMailSender mailSender) {
        this.mailSender = mailSender;
    }

    /**
     * Gửi OTP đến email người dùng.
     * Trả về true nếu đã gửi (hoặc đã in ra console ở chế độ dev), false nếu thất bại.
     */
    public boolean guiOtp(String emailNhan, String otp, int phutHetHan) {
        // Chưa cấu hình Gmail gửi
        if (guiTu == null || guiTu.isBlank()) {
            if (devInConsole) {
                log.warn("[CHE DO DEV] Chua cau hinh Gmail. OTP gui toi {} la: {}", emailNhan, otp);
                return true;
            }
            log.error("Chua cau hinh MAIL_USERNAME/MAIL_PASSWORD, khong the gui email OTP");
            return false;
        }

        try {
            SimpleMailMessage msg = new SimpleMailMessage();
            msg.setFrom(guiTu);
            msg.setTo(emailNhan);
            msg.setSubject("Mã OTP đặt lại mật khẩu - Hệ thống quản lý bưu kiện");
            msg.setText("""
                    Xin chào,

                    Mã OTP để đặt lại mật khẩu của bạn là: %s

                    Mã có hiệu lực trong %d phút. Vui lòng không chia sẻ mã này cho bất kỳ ai.

                    Nếu bạn không yêu cầu đặt lại mật khẩu, hãy bỏ qua email này.
                    """.formatted(otp, phutHetHan));
            mailSender.send(msg);
            return true;
        } catch (Exception e) {
            log.error("Gui email OTP that bai: {}", e.getMessage());
            return false;
        }
    }
}