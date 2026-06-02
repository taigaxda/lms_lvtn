import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkGiangVien } from '../middleware.js'

const router = express.Router();

router.get('/:idKhoaHoc', checkGiangVien, async (req, res) => {
    try {
        const idGiangVien = req.user.idNguoiDung
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        const khoaHoc = await prisma.khoahoc.findFirst({
            where: {
                idKhoaHoc,
                idGiangVien
            }
        })
        if (!khoaHoc) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền xem lớp này"
            })
        }
        const dsHocVien = await prisma.dangky_khoahoc.findMany({
            where: { idKhoaHoc },
            include: {
                nguoidung: {
                    select: {
                        idNguoiDung: true,
                        hoTen: true,
                        email: true,
                        taiKhoan: true,
                        trangThai: true
                    }
                }
            },
            orderBy: {
                ngayDangKy: 'desc'
            }
        })
        const result = dsHocVien.map(item => ({
            idNguoiDung: item.nguoidung.idNguoiDung,
            hoTen: item.nguoidung.hoTen,
            email: item.nguoidung.email,
            taiKhoan: item.nguoidung.taiKhoan,
            trangThai: item.nguoidung.trangThai,
            ngayDangKy: item.ngayDangKy
        }))
        res.json({
            success: true,
            data: result
        })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})
router.delete('/kick/:idKhoaHoc/:idNguoiDung', checkGiangVien, async (req, res) => {
    try {
        const idGiangVien = req.user.idNguoiDung
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        const idNguoiDung = parseInt(req.params.idNguoiDung)
        const khoaHoc = await prisma.khoahoc.findFirst({
            where: {
                idKhoaHoc,
                idGiangVien
            }
        })
        if (!khoaHoc) {
            return res.status(403).json({
                message: "Bạn không có quyền xóa"
            })
        }
        const dangKy = await prisma.dangky_khoahoc.findFirst({
            where: {
                idKhoaHoc,
                idNguoiDung
            }
        })
        if (!dangKy) {
            return res.status(404).json({
                success: false,
                message: "Học viên không tồn tại trong lớp"
            })
        }
        await prisma.dangky_khoahoc.delete({
            where: {
                idDangKy: dangKy.idDangKy
            }
        })
        res.json({
            success: true,
            message: "Đã xóa học viên khỏi lớp"
        })
    } catch (err) {
        res.status(500).json({ error: err.message })
    }
})


export default router