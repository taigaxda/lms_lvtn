import express from 'express'
import { prisma } from '../prisma/client.js'
import jwt from 'jsonwebtoken'
import bcrypt from 'bcrypt'
import { generateOTP, saveOTP, verifyOTP } from './otp.js';
import { sendOTPEmail, sendPasswordChangedEmail } from './email.js';
import { checkAuth } from './middleware.js';
if (!process.env.JWT_SECRET) {
    throw new Error("Thiếu JWT_SECRET trong .env")
}

const router = express.Router()

const kiemTraPassword = (password)=>{
    const passwordRegex = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&.])[A-Za-z\d@$!%*?&.]{6,}$/
    if (!password) {
        return {
            isValid: false,
            message: "Vui lòng nhập mật khẩu"
        }
    }
    if (password.length < 6) {
        return {
            isValid: false,
            message: "Mật khẩu phải có ít nhất 6 ký tự"
        }
    }
    if (!passwordRegex.test(password)) {
        return {
            isValid: false,
            message: "Mật khẩu phải bao gồm chữ hoa, chữ thường, số và ký tự đặc biệt (@$!%*?&.)"
        }
    }
    return {
        isValid: true,
        message: "Mật khẩu hợp lệ"
    }
}
router.post("/login", async (req, res) => {
    try {
        let { taiKhoan, matKhau } = req.body

        taiKhoan = taiKhoan ? taiKhoan.trim() : undefined
        matKhau = matKhau ? matKhau.trim() : undefined

        if (!taiKhoan || !matKhau) {
            return res.status(400).json({
                success: false,
                message: "Vui lòng nhập tài khoản và mật khẩu"
            })
        }

        const nguoiDung = await prisma.nguoidung.findUnique({
            where: { taiKhoan }
        })

        if (!nguoiDung) {
            return res.status(401).json({
                success: false,
                message: "Tài khoản không tồn tại"
            })
        }
        if (!nguoiDung.trangThai) {
            return res.status(403).json({
                success: false,
                message: "Tài khoản đã bị khóa"
            })
        }
        const matKhauHopLe = await bcrypt.compare(matKhau,nguoiDung.matKhau)
        if (!matKhauHopLe) {
            return res.status(401).json({
                success: false,
                message: "Mật khẩu không chính xác"
            })
        }
        
        let duongDan = "/"
        switch (nguoiDung.vaiTro) {
            case "admin":
                duongDan = "/admin"
                break
            case "giangvien":
                duongDan = "/giangvien"
                break
            case "hocvien":
                duongDan = "/khoahoc"
                break
        }

        const token = jwt.sign(
            {
                id: nguoiDung.idNguoiDung,
                vaiTro: nguoiDung.vaiTro
            },
            process.env.JWT_SECRET,
            {
                expiresIn: process.env.JWT_EXPIRES_IN
            }
        )
        res.json({
            success: true,
            message: "Đăng nhập thành công",
            token,
            user: {
                id: nguoiDung.idNguoiDung,
                hoTen: nguoiDung.hoTen,
                taiKhoan: nguoiDung.taiKhoan,
                vaiTro: nguoiDung.vaiTro
            },
            redirectTo: duongDan
        })
    } catch (error) {
        res.status(500).json({ success: false, message: "Không thể đăng nhập" })
    }
})


router.post("/dangky", async (req, res) => {
    try {
        let { hoTen, taiKhoan, matKhau, confirmPassword, email,vaiTro } = req.body
        hoTen = hoTen ? hoTen.trim().replace(/\s+/g, ' ') : undefined
        taiKhoan = taiKhoan ? taiKhoan.trim() : undefined
        matKhau = matKhau ? matKhau.trim() : undefined
        confirmPassword = confirmPassword ? confirmPassword.trim() : undefined
        email = email ? email.trim() : undefined

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
        const nameRegex = /^[a-zA-ZÀ-ỹ\s]+$/

        if (!hoTen || !taiKhoan || !matKhau || !confirmPassword || !email) {
            return res.status(400).json({
                success: false,
                message: "Vui lòng điền đầy đủ thông tin"
            })
        }
        if (matKhau !== confirmPassword) {
            return res.status(400).json({
                success: false,
                message: "Mật khẩu xác nhận không khớp"
            })
        }

        if (!emailRegex.test(email)) {
            return res.status(400).json({
                success: false,
                message: "Email không hợp lệ"
            })
        }
        if (!nameRegex.test(hoTen)) {
            return res.status(400).json({
                success: false,
                message: "Họ tên chỉ được chứa chữ cái và khoảng trắng"
            })
        }
        const matKhauManh = kiemTraPassword(matKhau)
        if (!matKhauManh.isValid) {
            return res.status(400).json({
                success: false,
                message: matKhauManh.message
            })
        }
        const existing = await prisma.nguoidung.findUnique({
            where: { taiKhoan }
        })

        if (existing) {
            return res.status(409).json({
                success: false,
                message: "Tài khoản đã tồn tại"
            })
        }
        const matKhauHash = await bcrypt.hash(matKhau,10)
        const nguoiDungMoi = await prisma.nguoidung.create({
            data: {
                hoTen,
                taiKhoan,
                matKhau: matKhauHash,
                email,
                trangThai: true,
                vaiTro: ["giangvien", "hocvien"].includes(vaiTro)
                    ? vaiTro
                    : "hocvien"
            }
        })

        res.status(201).json({
            success: true,
            message: "Đăng ký thành công",
            user: nguoiDungMoi
        })

    } catch (error) {
        res.status(500).json({ success: false, message: "Không thể đăng ký" })
    }
})

router.post("/luu-fcm-token", async(req, res)=>{
    try{
        const {idNguoiDung, token} = req.body
        if(!idNguoiDung||!token){
            return res.status(400).json({
                success: false,
                message:"Thiếu id ngdung hoặc token"
            })
        }
        const result = await prisma.fcm_tokens.upsert({
            where:{
                token: token
            },
            update: {
                idNguoiDung: idNguoiDung
            },
            create:{
                idNguoiDung: idNguoiDung,
                token: token
            }
        })
        res.json({
            success: true,
            message: "Lưu FCMToken thành công"
        })
    }
    catch(error){
        console.error("Lỗi lưu FCM token:", error)
        res.status(500).json({ success: false, message: "Không thể lưu FCM token" })
    }
})
router.post('/forgot-password', async (req, res) => {
    try {
        const { taiKhoan, email } = req.body;
        
        if (!taiKhoan || !taiKhoan.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng nhập tài khoản'
            });
        }
        
        if (!email || !email.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng nhập email'
            });
        }

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(email)) {
            return res.status(400).json({
                success: false,
                message: 'Email không hợp lệ'
            });
        }

        const user = await prisma.nguoidung.findFirst({
            where: {
                taiKhoan: taiKhoan.trim(),
                email: email.trim()
            }
        });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Tài khoản hoặc email không chính xác'
            });
        }

        if (!user.trangThai) {
            return res.status(403).json({
                success: false,
                message: 'Tài khoản đã bị khóa'
            });
        }

        // Tao otp 6 so
        const otp = Math.floor(100000 + Math.random() * 900000).toString();
        
        // Lưu OTP với key là email (vẫn dùng email làm key)
        saveOTP(email.trim(), otp);
        
        // Goi email
        const emailResult = await sendOTPEmail(email.trim(), otp, user.hoTen);
        
        if (!emailResult.success) {
            return res.status(500).json({
                success: false,
                message: 'Không thể gửi email, vui lòng thử lại sau'
            })
        }

        res.status(200).json({
            success: true,
            message: 'Mã OTP đã được gửi đến email của bạn',
            data: {
                email: email.trim(),
                taiKhoan: taiKhoan.trim(),
                expiresIn: '5 phút'
            }
        });
    } catch (error) {
        console.error('Lỗi forgot-password:', error);
        res.status(500).json({
            success: false,
            message: 'Không thể xử lý yêu cầu'
        })
    }
})

// Xac thuc otp
router.post('/verify-otp', async (req, res) => {
    try {
        const { taiKhoan, otp } = req.body;
        
        if (!taiKhoan || !taiKhoan.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng nhập tài khoản'
            })
        }
        
        if (!otp || !otp.trim()) {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng nhập mã OTP'
            })
        }

       
        const user = await prisma.nguoidung.findUnique({
            where: { 
                taiKhoan: taiKhoan.trim() 
            }
        })

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Tài khoản không tồn tại'
            })
        }

        // Kiểm tra OTP với email của user
        const result = verifyOTP(user.email, otp.trim());
        
        if (!result.valid) {
            return res.status(400).json({
                success: false,
                message: result.message,
                remainingAttempts: result.remainingAttempts
            });
        }

        // Tạo reset token
        const resetToken = jwt.sign(
            { 
                taiKhoan: taiKhoan.trim(),
                email: user.email 
            },
            process.env.JWT_SECRET,
            { expiresIn: '5m' }
        )

        res.status(200).json({
            success: true,
            message: 'Xác thực OTP thành công',
            data: {
                resetToken: resetToken,
                expiresIn: '5 phút'
            }
        })
    } catch (error) {
        console.error('Lỗi verify-otp:', error);
        res.status(500).json({
            success: false,
            message: 'Không thể xác thực OTP'
        })
    }
})

// Rs pass
router.post('/reset-password', async (req, res) => {
    try {
        const { resetToken, newPassword, confirmPassword } = req.body;
        
        if (!resetToken || !newPassword || !confirmPassword) {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng điền đầy đủ thông tin'
            });
        }
        const matKhauManh = kiemTraPassword(newPassword)

        if (!matKhauManh.isValid) {
            return res.status(400).json({
                success: false,
                message: matKhauManh.message
            })
        }

        if (newPassword !== confirmPassword) {
            return res.status(400).json({
                success: false,
                message: 'Mật khẩu xác nhận không khớp'
            });
        }

        // Verify reset token
        let decoded;
        try {
            decoded = jwt.verify(resetToken, process.env.JWT_SECRET);
        } catch (error) {
            return res.status(401).json({
                success: false,
                message: 'Token không hợp lệ hoặc đã hết hạn'
            });
        }

        const taiKhoan = decoded.taiKhoan;
        
        // Tìm người dùng theo tài khoản
        const user = await prisma.nguoidung.findUnique({
            where: { taiKhoan: taiKhoan }
        });

        if (!user) {
            return res.status(404).json({
                success: false,
                message: 'Người dùng không tồn tại'
            });
        }

        // Hash mật khẩu mới
        const hashedPassword = await bcrypt.hash(newPassword, 10);
        
        // Cập nhật mật khẩu
        await prisma.nguoidung.update({
            where: { taiKhoan: taiKhoan },
            data: { matKhau: hashedPassword }
        });

        // Gửi email xác nhận
        await sendPasswordChangedEmail(user.email, user.hoTen);

        res.status(200).json({
            success: true,
            message: 'Đặt lại mật khẩu thành công'
        });
    } catch (error) {
        console.error('Lỗi reset-password:', error);
        res.status(500).json({
            success: false,
            message: 'Không thể đặt lại mật khẩu'
        });
    }
});

router.get('/profile', checkAuth, async (req, res) => {
    try {
        const user = await prisma.nguoidung.findUnique({
            where: { idNguoiDung: req.user.idNguoiDung },
            select: {
                idNguoiDung: true,
                hoTen: true,
                taiKhoan: true,
                email: true,
                vaiTro: true,
                trangThai: true
            }
        })

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy người dùng"
            })
        }

        res.status(200).json({
            success: true,
            data: user
        })
    } catch (error) {
        console.error('Lỗi lấy profile:', error)
        res.status(500).json({
            success: false,
            message: "Không thể lấy thông tin người dùng"
        })
    }
})

router.put('/profile', checkAuth, async (req, res) => {
    try {
        const idNguoiDung = req.user.idNguoiDung
        let { hoTen, email } = req.body

        hoTen = hoTen ? hoTen.trim().replace(/\s+/g, ' ') : undefined
        email = email ? email.trim() : undefined

        if (!hoTen && !email) {
            return res.status(400).json({
                success: false,
                message: "Vui lòng cập nhật ít nhất một trường"
            })
        }

        if (email) {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
            if (!emailRegex.test(email)) {
                return res.status(400).json({
                    success: false,
                    message: "Email không hợp lệ"
                })
            }
        }

        if (hoTen) {
            const nameRegex = /^[a-zA-ZÀ-ỹ\s]+$/
            if (!nameRegex.test(hoTen)) {
                return res.status(400).json({
                    success: false,
                    message: "Họ tên chỉ được chứa chữ cái và khoảng trắng"
                })
            }
        }

        const updatedUser = await prisma.nguoidung.update({
            where: { idNguoiDung: idNguoiDung },
            data: {
                ...(hoTen && { hoTen }),
                ...(email && { email })
            },
            select: {
                idNguoiDung: true,
                hoTen: true,
                taiKhoan: true,
                email: true,
                vaiTro: true,
                trangThai: true
            }
        })

        res.status(200).json({
            success: true,
            message: "Cập nhật thông tin thành công",
            data: updatedUser
        })
    } catch (error) {
        console.error('Lỗi cập nhật profile:', error)
        res.status(500).json({
            success: false,
            message: "Không thể cập nhật thông tin"
        })
    }
})

router.put('/change-password', checkAuth, async (req, res) => {
    try {
        const idNguoiDung = req.user.idNguoiDung
        const { oldPassword, newPassword, confirmPassword } = req.body

        if (!oldPassword || !newPassword || !confirmPassword) {
            return res.status(400).json({
                success: false,
                message: "Vui lòng điền đầy đủ thông tin"
            })
        }

        const matKhauManh = kiemTraPassword(newPassword)
        if (!matKhauManh.isValid) {
            return res.status(400).json({
                success: false,
                message: matKhauManh.message
            })
        }

        if (newPassword !== confirmPassword) {
            return res.status(400).json({
                success: false,
                message: "Mật khẩu xác nhận không khớp"
            })
        }

        const user = await prisma.nguoidung.findUnique({
            where: { idNguoiDung: idNguoiDung }
        })

        if (!user) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy người dùng"
            })
        }

        const isPasswordValid = await bcrypt.compare(oldPassword, user.matKhau)
        if (!isPasswordValid) {
            return res.status(401).json({
                success: false,
                message: "Mật khẩu cũ không chính xác"
            })
        }

        const hashedPassword = await bcrypt.hash(newPassword, 10)

        await prisma.nguoidung.update({
            where: { 
                idNguoiDung: idNguoiDung 
            },
            data: { 
                matKhau: hashedPassword 
            }
        })

        res.status(200).json({
            success: true,
            message: "Đổi mật khẩu thành công"
        })
    } catch (error) {
        console.error('Lỗi đổi mật khẩu:', error)
        res.status(500).json({
            success: false,
            message: "Không thể đổi mật khẩu"
        })
    }
})

export default router