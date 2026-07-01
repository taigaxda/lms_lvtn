// utils/firebase.js
import admin from 'firebase-admin';
import dotenv from 'dotenv';
import { prisma } from '../prisma/client.js';

dotenv.config();

// ==================== KHỞI TẠO FIREBASE ====================
if (!admin.apps.length) {
    try {
        // ✅ Dùng service account từ .env
        const serviceAccount = {
            type: "service_account",
            project_id: process.env.FIREBASE_PROJECT_ID,
            private_key_id: process.env.FIREBASE_PRIVATE_KEY_ID,
            private_key: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n'),
            client_email: process.env.FIREBASE_CLIENT_EMAIL,
            client_id: process.env.FIREBASE_CLIENT_ID,
            auth_uri: "https://accounts.google.com/o/oauth2/auth",
            token_uri: "https://oauth2.googleapis.com/token",
            auth_provider_x509_cert_url: "https://www.googleapis.com/oauth2/v1/certs",
            client_x509_cert_url: process.env.FIREBASE_CLIENT_CERT_URL,
            universe_domain: "googleapis.com"
        };

        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });

        console.log('✅ Firebase Admin initialized');
    } catch (error) {
        console.error('❌ Firebase Admin error:', error);
    }
}

// ==================== GỬI THÔNG BÁO ====================
export const sendNotificationToClass = async (idKhoaHoc, title, body, data = {}, excludeUserId = null) => {
    try {
        console.log(`📤 Sending notification to class ${idKhoaHoc}: ${title}`);

        // ✅ Lấy tất cả học viên trong lớp
        const hocViens = await prisma.dangky_khoahoc.findMany({
            where: {
                idKhoaHoc: idKhoaHoc,
                nguoidung: {
                    vaiTro: 'hocvien'
                },
                ...(excludeUserId && { idNguoiDung: { not: excludeUserId } }),
            },
            include: {
                nguoidung: {
                    include: {
                        fcm_tokens: {
                            select: { token: true },
                        },
                    },
                },
            },
        });

        console.log(`📊 Found ${hocViens.length} students in class`);

        // ✅ Lấy tất cả FCM tokens
        const allTokens = [];
        hocViens.forEach(hv => {
            if (hv.nguoidung.fcm_tokens && hv.nguoidung.fcm_tokens.length > 0) {
                hv.nguoidung.fcm_tokens.forEach(token => {
                    if (token.token) {
                        allTokens.push(token.token);
                    }
                });
            }
        });

        console.log(`📱 Found ${allTokens.length} FCM tokens`);

        if (allTokens.length === 0) {
            console.log(`⚠️ No tokens found for class ${idKhoaHoc}`);
            return { success: false, message: 'No tokens found' };
        }

        // ✅ Gửi thông báo
        const result = await sendNotificationToDevices(allTokens, title, body, data);
        console.log(`✅ Notification sent to class ${idKhoaHoc}:`, result);
        return result;
    } catch (error) {
        console.error(`❌ Error sending notification to class ${idKhoaHoc}:`, error.message);
        return { success: false, error: error.message };
    }
};

/**
 * Gửi thông báo đến 1 thiết bị
 */
export const sendNotificationToDevice = async (token, title, body, data = {}) => {
    try {
        if (!token) {
            return { success: false, message: 'No token' };
        }

        const message = {
            notification: { title, body },
            data: data,
            token: token,
        };

        const response = await admin.messaging().send(message);
        console.log('✅ Notification sent:', response);
        return { success: true, messageId: response };
    } catch (error) {
        console.error('❌ Error:', error.message);
        return { success: false, error: error.message };
    }
};

/**
 * Gửi thông báo đến nhiều thiết bị
 */
export const sendNotificationToDevices = async (tokens, title, body, data = {}) => {
    try {
        if (!tokens || tokens.length === 0) {
            return { success: false, message: 'No tokens' };
        }

        const message = {
            notification: { title, body },
            data: data,
            tokens: tokens,
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log('✅ Sent:', response.successCount, 'success,', response.failureCount, 'failed');

        // ✅ Xóa token không hợp lệ
        const invalidTokens = [];
        response.responses.forEach((resp, idx) => {
            if (!resp.success) {
                invalidTokens.push(tokens[idx]);
            }
        });

        if (invalidTokens.length > 0) {
            await prisma.fcm_tokens.deleteMany({
                where: { token: { in: invalidTokens } },
            });
            console.log(`🗑️ Deleted ${invalidTokens.length} invalid tokens`);
        }

        return {
            success: true,
            successCount: response.successCount,
            failureCount: response.failureCount,
        };
    } catch (error) {
        console.error('❌ Error:', error.message);
        return { success: false, error: error.message };
    }
};

/**
 * Gửi thông báo đến tất cả thiết bị của 1 user
 */
export const sendNotificationToUser = async (userId, title, body, data = {}) => {
    try {
        const tokens = await prisma.fcm_tokens.findMany({
            where: { idNguoiDung: userId },
            select: { token: true },
        });

        if (!tokens || tokens.length === 0) {
            return { success: false, message: 'No tokens found' };
        }

        const tokenList = tokens.map(t => t.token);
        return await sendNotificationToDevices(tokenList, title, body, data);
    } catch (error) {
        console.error('❌ Error:', error.message);
        return { success: false, error: error.message };
    }
};

/**
 * Gửi thông báo đến tất cả thành viên trong group (trừ người gửi)
 */
export const sendNotificationToGroup = async (groupId, title, body, data = {}, excludeUserId = null) => {
    try {
        const members = await prisma.group_members.findMany({
            where: {
                idGroup: groupId,
                ...(excludeUserId && { idNguoiDung: { not: excludeUserId } }),
            },
            include: {
                nguoidung: {
                    include: {
                        fcm_tokens: {
                            select: { token: true },
                        },
                    },
                },
            },
        });

        const allTokens = [];
        members.forEach(member => {
            member.nguoidung.fcm_tokens.forEach(token => {
                if (token.token) {
                    allTokens.push(token.token);
                }
            });
        });

        if (allTokens.length === 0) {
            return { success: false, message: 'No tokens found' };
        }

        return await sendNotificationToDevices(allTokens, title, body, data);
    } catch (error) {
        console.error('❌ Error:', error.message);
        return { success: false, error: error.message };
    }
};