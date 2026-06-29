// utils/email.js
import nodemailer from 'nodemailer';
import dotenv from 'dotenv';

dotenv.config();

// Log để debug
console.log('📧 Nodemailer loaded successfully');

// Tạo transporter với cấu hình đầy đủ
const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: false, // true cho port 465, false cho port 587
    auth: {
        user: process.env.SMTP_USER,
        pass: process.env.SMTP_PASS,
    },
    tls: {
        rejectUnauthorized: false
    },
    connectionTimeout: 5000,
    greetingTimeout: 5000,
    socketTimeout: 5000
});

// Kiểm tra kết nối SMTP
export const verifyConnection = async () => {
    try {
        await transporter.verify();
        console.log('✅ SMTP connection successful');
        return true;
    } catch (error) {
        console.error('❌ SMTP connection failed:', error.message);
        return false;
    }
};

// Gửi email OTP
export const sendOTPEmail = async (email, otp, hoTen) => {
    try {
        console.log(`📧 Sending OTP email to: ${email}`);
        
        const mailOptions = {
            from: `"Hệ thống học tập" <${process.env.SMTP_FROM}>`,
            to: email,
            subject: '🔐 Mã OTP xác thực - Quên mật khẩu',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
                    <h2 style="color: #2196F3; text-align: center;">Xác thực quên mật khẩu</h2>
                    <hr style="border: 1px solid #e0e0e0;">
                    <p>Xin chào <strong>${hoTen || 'người dùng'}</strong>,</p>
                    <p>Bạn đã yêu cầu đặt lại mật khẩu. Vui lòng sử dụng mã OTP dưới đây:</p>
                    <div style="background-color: #f5f5f5; padding: 20px; text-align: center; margin: 20px 0; border-radius: 5px;">
                        <h1 style="color: #2196F3; font-size: 32px; letter-spacing: 5px; margin: 0;">${otp}</h1>
                    </div>
                    <p style="color: #666; font-size: 14px;">⏰ Mã OTP có hiệu lực trong <strong>5 phút</strong>.</p>
                    <p style="color: #666; font-size: 14px;">🔒 Nếu bạn không yêu cầu đặt lại mật khẩu, vui lòng bỏ qua email này.</p>
                    <hr style="border: 1px solid #e0e0e0;">
                    <p style="color: #999; font-size: 12px; text-align: center;">© ${new Date().getFullYear()} Hệ thống học tập.</p>
                </div>
            `,
        };

        const info = await transporter.sendMail(mailOptions);
        console.log('✅ Email sent successfully');
        console.log('📧 Message ID:', info.messageId);
        console.log('📧 Response:', info.response);
        return { success: true, message: 'Email đã được gửi' };
    } catch (error) {
        console.error('❌ Error sending email:', error.message);
        console.error('❌ Full error:', error);
        return { success: false, message: error.message };
    }
};

// Gửi email xác nhận đổi mật khẩu
export const sendPasswordChangedEmail = async (email, hoTen) => {
    try {
        console.log(`📧 Sending password changed email to: ${email}`);
        
        const mailOptions = {
            from: `"Hệ thống học tập" <${process.env.SMTP_FROM}>`,
            to: email,
            subject: '✅ Mật khẩu đã được thay đổi',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
                    <h2 style="color: #4CAF50; text-align: center;">Mật khẩu đã được thay đổi</h2>
                    <hr style="border: 1px solid #e0e0e0;">
                    <p>Xin chào <strong>${hoTen || 'người dùng'}</strong>,</p>
                    <p>Mật khẩu của bạn đã được thay đổi thành công.</p>
                    <p style="color: #666; font-size: 14px;">🔒 Nếu bạn không thực hiện thay đổi này, vui lòng liên hệ với quản trị viên ngay lập tức.</p>
                    <hr style="border: 1px solid #e0e0e0;">
                    <p style="color: #999; font-size: 12px; text-align: center;">© ${new Date().getFullYear()} Hệ thống học tập.</p>
                </div>
            `,
        };

        await transporter.sendMail(mailOptions);
        console.log('✅ Password changed email sent successfully');
        return { success: true };
    } catch (error) {
        console.error('❌ Error sending password changed email:', error.message);
        return { success: false };
    }
};