import crypto from 'crypto';

const otpStorage = new Map();

const OTP_EXPIRY = 5 * 60 * 1000;

export const generateOTP = () => {
    return Math.floor(100000 + Math.random() * 900000).toString();
};

export const saveOTP = (email, otp) => {
    otpStorage.set(email, {
        otp: otp,
        createdAt: Date.now(),
        expiresAt: Date.now() + OTP_EXPIRY,
        attempts: 0
    });
    
    setTimeout(() => {
        otpStorage.delete(email);
    }, OTP_EXPIRY);
};

export const verifyOTP = (email, otp) => {
    const record = otpStorage.get(email);
    
    if (!record) {
        return { valid: false, message: 'OTP không tồn tại hoặc đã hết hạn' };
    }
    
    if (Date.now() > record.expiresAt) {
        otpStorage.delete(email);
        return { valid: false, message: 'OTP đã hết hạn' };
    }

    if (record.attempts >= 5) {
        otpStorage.delete(email);
        return { valid: false, message: 'Đã vượt quá số lần thử, vui lòng yêu cầu OTP mới' };
    }
    
    if (record.otp !== otp) {
        record.attempts += 1;
        return { valid: false, message: 'OTP không chính xác', remainingAttempts: 5 - record.attempts };
    }

    otpStorage.delete(email);
    return { valid: true, message: 'Xác thực OTP thành công' };
};

export const getOTPInfo = (email) => {
    return otpStorage.get(email);
};