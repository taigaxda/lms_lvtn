import express from 'express'
import { prisma } from '../prisma/client.js'
import jwt from 'jsonwebtoken'
import bcrypt from 'bcrypt'

if (!process.env.JWT_SECRET) {
    throw new Error("Thiếu JWT_SECRET trong .env")
}

const router = express.Router()
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
        const matKhauHopLe = await bcrypt.compare(matKhau,nguoiDung.matKhau)
        if (!matKhauHopLe) {
            return res.status(401).json({
                success: false,
                message: "Mật khẩu không chính xác"
            })
        }
        if (!nguoiDung.trangThai) {
            return res.status(403).json({
                success: false,
                message: "Tài khoản đã bị khóa"
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
        let { hoTen, taiKhoan, matKhau, email,vaiTro } = req.body
        hoTen = hoTen ? hoTen.trim().replace(/\s+/g, ' ') : undefined
        taiKhoan = taiKhoan ? taiKhoan.trim() : undefined
        matKhau = matKhau ? matKhau.trim() : undefined
        email = email ? email.trim() : undefined

        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
        const nameRegex = /^[a-zA-ZÀ-ỹ\s]+$/

        if (!hoTen || !taiKhoan || !matKhau || !email) {
            return res.status(400).json({
                success: false,
                message: "Vui lòng điền đầy đủ thông tin"
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

export default router