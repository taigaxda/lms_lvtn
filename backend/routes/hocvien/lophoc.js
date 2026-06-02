import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkHocVien } from '../middleware.js'
import e from 'express'

const router = express.Router()

router.post('/thamgia', checkHocVien, async (req, res) => {
    try {
        let { codeLop } = req.body
        const idNguoiDung = req.user.idNguoiDung
        codeLop = codeLop ? codeLop.trim() : undefined
        if (!codeLop) {
            return res.status(400).json({
                success: false,
                message: "Chưa nhập code lớp học"
            })
        }
        const lopHoc = await prisma.khoahoc.findFirst({
            where: { code: codeLop }
        })
        if (!lopHoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy lớp học với code đã nhập"
            })
        }
        if (!lopHoc.trangThai) {
            return res.status(400).json({
                success: false,
                message: "Lớp học đã bị khóa, không thể tham gia"
            })
        }
        const daThamGia = await prisma.dangky_khoahoc.findFirst({
            where: {
                idNguoiDung,
                idKhoaHoc: lopHoc.idKhoaHoc
            }
        })
        if (daThamGia) {
            return res.status(400).json({
                success: false,
                message: "Bạn đã tham gia lớp học này rồi"
            })
        }
        const thamGia = await prisma.dangky_khoahoc.create({
            data: {
                idNguoiDung,
                idKhoaHoc: lopHoc.idKhoaHoc
            }
        })
        res.status(201).json({
            success: true,
            message: "Đăng ký lớp học thành công",
            data: thamGia
        })
    }
    catch (error) {
        res.status(500).json({ error: error.message })
    }
})

router.delete('/roilop', checkHocVien, async (req, res) => {
    try {
        const { idKhoaHoc } = req.body
        const idNguoiDung = req.user.idNguoiDung
        if (!idKhoaHoc) {
            return res.status(400).json({
                success: false,
                message: "Thiếu id khóa học"
            })
        }
        const daThamGia = await prisma.dangky_khoahoc.findFirst({
            where: {
                idNguoiDung,
                idKhoaHoc
            }
        })
        if (!daThamGia) {
            return res.status(404).json({
                success: false,
                message: "Bạn chưa tham gia lớp học này"
            })
        }
        await prisma.dangky_khoahoc.delete({
            where: {
                idDangKy: daThamGia.idDangKy
            }
        })
        res.status(200).json({
            success: true,
            message: "Rời lớp học thành công"
        })
    }
    catch (error) {
        res.status(500).json({ error: error.message })
    }
})

router.get('/', checkHocVien, async (req, res) => {
    try {
        const idNguoiDung = req.user.idNguoiDung
        const danhSachLop = await prisma.dangky_khoahoc.findMany({
            where: { idNguoiDung,
                khoahoc:{
                    trangThai: true
                }
             },
            include: {
                khoahoc: {
                    select: {
                        idKhoaHoc: true,
                        tenKhoaHoc: true,
                        code: true,
                        danhMuc: true,
                        nguoidung: {
                            select: {
                                hoTen: true,
                                email: true
                            }
                        }
                    }
                }
            }
        })
        res.status(200).json({
            success: true,
            data: danhSachLop
        })
    } catch (error) {
        res.status(500).json({ error: error.message })
    }
})

router.get('/luutru', checkHocVien, async (req, res) => {
    try {
        const idNguoiDung = req.user.idNguoiDung;
        const lopHocs = await prisma.dangky_khoahoc.findMany({
            where: {
                idNguoiDung: idNguoiDung,
                khoahoc:{
                    trangThai: false,
                }
            },
            include:{
                khoahoc:{
                    select: {
                        idKhoaHoc: true,
                        tenKhoaHoc: true,
                        code: true,
                        moTa: true,
                        danhMuc: true,
                        trangThai: true
                    }
                }
            }
        });
        res.status(200).json({
            success: true,
            data: lopHocs
        });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/:idKhoaHoc', checkHocVien, async (req, res) => {
    try{
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        const idNguoiDung = req.user.idNguoiDung
        if(isNaN(idKhoaHoc)) {
            return res.status(400).json({
                success: false,
                message: "ID khóa học không hợp lệ"
            })
        }
        const daThamGia = await prisma.dangky_khoahoc.findFirst({
            where: {
                idNguoiDung,
                idKhoaHoc
            }
        })
        if(!daThamGia) {
            return res.status(403).json({
                success: false,
                message: "Bạn chưa tham gia lớp học này"
            })
        }
        const lopHoc = await prisma.khoahoc.findUnique({
            where: { idKhoaHoc },
            select:{
                idKhoaHoc: true,
                tenKhoaHoc: true,
                moTa: true,
                danhMuc: true,
                code: true,
                nguoidung:{
                    select:{
                        hoTen: true,
                        email: true
                    }
                }
            }
        })
        if(!lopHoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy lớp học"
            })
        }
        res.status(200).json({
            success: true,
            data: lopHoc
        })
    }
    catch (error) {
        res.status(500).json({ error: error.message })
    }
})
export default router