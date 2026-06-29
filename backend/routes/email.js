import axios from 'axios';
import dotenv from 'dotenv';

dotenv.config();

const BREVO_API_URL = 'https://api.brevo.com/v3';

console.log('📧 Brevo initialized via Axios');

// Gửi email OTP
export const sendOTPEmail = async (email, otp, hoTen) => {
    try {
        console.log(`📧 Sending OTP email to: ${email}`);
        
        const response = await axios.post(
            `${BREVO_API_URL}/smtp/email`,
            {
                sender: {
                    name: 'Hệ thống học tập',
                    email: process.env.BREVO_FROM
                },
                to: [{ email: email }],
                subject: '🔐 Mã OTP xác thực - Quên mật khẩu',
                htmlContent: `
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
                `
            },
            {
                headers: {
                    'api-key': process.env.BREVO_API_KEY,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log('✅ Email sent successfully:', response.data);
        return { success: true, message: 'Email đã được gửi' };
    } catch (error) {
        console.error('❌ Error sending email:', error.message);
        if (error.response) {
            console.error('❌ Response:', error.response.data);
        }
        return { success: false, message: error.message };
    }
};

// Gửi email xác nhận đổi mật khẩu
export const sendPasswordChangedEmail = async (email, hoTen) => {
    try {
        console.log(`📧 Sending password changed email to: ${email}`);
        
        const response = await axios.post(
            `${BREVO_API_URL}/smtp/email`,
            {
                sender: {
                    name: 'Hệ thống học tập',
                    email: process.env.BREVO_FROM
                },
                to: [{ email: email }],
                subject: '✅ Mật khẩu đã được thay đổi',
                htmlContent: `
                    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
                        <h2 style="color: #4CAF50; text-align: center;">Mật khẩu đã được thay đổi</h2>
                        <hr style="border: 1px solid #e0e0e0;">
                        <p>Xin chào <strong>${hoTen || 'người dùng'}</strong>,</p>
                        <p>Mật khẩu của bạn đã được thay đổi thành công.</p>
                        <p style="color: #666; font-size: 14px;">🔒 Nếu bạn không thực hiện thay đổi này, vui lòng liên hệ với quản trị viên ngay lập tức.</p>
                        <hr style="border: 1px solid #e0e0e0;">
                        <p style="color: #999; font-size: 12px; text-align: center;">© ${new Date().getFullYear()} Hệ thống học tập.</p>
                    </div>
                `
            },
            {
                headers: {
                    'api-key': process.env.BREVO_API_KEY,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log('✅ Password changed email sent:', response.data);
        return { success: true };
    } catch (error) {
        console.error('❌ Error sending password changed email:', error.message);
        if (error.response) {
            console.error('❌ Response:', error.response.data);
        }
        return { success: false };
    }
};

// Test email
export const testSendEmail = async (email) => {
    try {
        const response = await axios.post(
            `${BREVO_API_URL}/smtp/email`,
            {
                sender: {
                    name: 'Hệ thống học tập',
                    email: process.env.BREVO_FROM
                },
                to: [{ email: email }],
                subject: '✅ Test email từ Brevo',
                htmlContent: `
                    <h1>✅ Test thành công!</h1>
                    <p>Brevo đang hoạt động tốt.</p>
                    <p>Thời gian: ${new Date().toLocaleString()}</p>
                    <p>Email gửi đến: ${email}</p>
                `
            },
            {
                headers: {
                    'api-key': process.env.BREVO_API_KEY,
                    'Content-Type': 'application/json'
                }
            }
        );
        
        console.log('✅ Test email sent:', response.data);
        return { success: true, message: 'Test email sent successfully' };
    } catch (error) {
        console.error('❌ Test email error:', error.message);
        if (error.response) {
            console.error('❌ Response:', error.response.data);
        }
        return { success: false, message: error.message };
    }
};