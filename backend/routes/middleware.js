import { prisma } from '../prisma/client.js'
import jwt from 'jsonwebtoken'

const checkRole = (role) => {
    return async (req, res, next) => {
        try {
            const authHeader = req.headers.authorization

            if(!authHeader|| !authHeader.startsWith("Bearer ")){
                return res.status(401).json({
                    success: false,
                    error:"Thiếu token để xác thực"
                })
            }
            const token = authHeader.split(" ")[1]
            const decoded = jwt.verify(token,process.env.JWT_SECRET)

            const user = await prisma.nguoidung.findUnique({
                where: { idNguoiDung: decoded.id }
            })

            if (!user) {
                return res.status(401).json({
                    success: false,
                    error: "Người dùng không tồn tại"
                })
            }

            if (user.vaiTro !== role) {
                return res.status(403).json({
                    success: false,
                    error: `Chỉ ${role} mới có quyền`
                })
            }

            req.user = user

            console.log("User authenticated:", {
                id: user.idNguoiDung,
                hoTen: user.hoTen,
                vaiTro: user.vaiTro
            })

            next()
        } catch (error) {
            console.error(`Lỗi check ${role}:`, error)
            return res.status(403).json({
                success: false,
                error: "Token không hợp lệ hoặc đã hết hạn"
            })
        }
    }
}
const checkComment = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization

        if(!authHeader|| !authHeader.startsWith("Bearer ")){
            return res.status(401).json({
                success: false,
                error:"Thiếu token để xác thực"
            })
        }
        const token = authHeader.split(" ")[1]
        const decoded = jwt.verify(token,process.env.JWT_SECRET)

        const user = await prisma.nguoidung.findUnique({
            where: { idNguoiDung: decoded.id }
        })

        if (!user) {
            return res.status(401).json({
                success: false,
                error: "Người dùng không tồn tại"
            })
        }

        if (user.vaiTro !== 'hocvien' && user.vaiTro !== 'giangvien') {
            return res.status(403).json({
                success: false,
                error: "Chỉ học viên và giảng viên mới có quyền comment"
            })
        }

        req.user = user

        console.log("User comment authenticated:", {
            id: user.idNguoiDung,
            hoTen: user.hoTen,
            vaiTro: user.vaiTro
        })

        next()
    } catch (error) {
        console.error("Lỗi check comment:", error)
        return res.status(403).json({
            success: false,
            error: "Token không hợp lệ hoặc đã hết hạn"
        })
    }
}

const checkAdmin = checkRole("admin")
const checkGiangVien = checkRole("giangvien")
const checkHocVien = checkRole("hocvien")

export { checkAdmin, checkGiangVien, checkHocVien, checkComment }