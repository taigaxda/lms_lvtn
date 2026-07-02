import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkHocVien } from '../middleware.js'

const router = express.Router()

router.get('/hethong', checkHocVien, async (req, res) => {
    try {
        const dsThongBaoHeThong = await prisma.announcements.findMany({
            where: {
                idKhoaHoc: null
            },
            orderBy: {
                ngayTao: 'desc'
            },
            include: {
                nguoiDang: {
                    select: {
                        hoTen: true,
                        vaiTro: true
                    }
                }
            }
        })
        return res.status(200).json({
            success: true,
            data: dsThongBaoHeThong,
            message: "Lấy ds thông báo thành công"
        })
    }
    catch (err) {
        return res.status(500).json({ success: false, error: err.message });
    }
})
router.get('/:idKhoaHoc', checkHocVien, async (req, res) => {
    try {
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        const { loaiThongBao } = req.query
        let whereCondition = {
            idKhoaHoc: idKhoaHoc
        }
        if (loaiThongBao) {
            const loaiArray = loaiThongBao.split(',')
            whereCondition.loaiThongBao = {
                in: loaiArray
            }
        }
        if (isNaN(idKhoaHoc)) {
            return res.status(400).json({
                success: false,
                message: "ID lớp học không hợp lệ"
            });
        }
        const dsThongBaoHV = await prisma.announcements.findMany({
            where: whereCondition,
            orderBy: {
                ngayTao: 'desc'
            },
            include: {
                nguoiDang: {
                    select: {
                        hoTen: true,
                        vaiTro: true
                    }
                }
            }
        })
        return res.status(200).json({
            success: true,
            data: dsThongBaoHV,
            message: "Lấy ds thông báo thành công"
        })
    }
    catch (err) {
        return res.status(500).json({ success: false, error: err.message });
    }
})

router.get('/chitiet/:idThongBao', checkHocVien, async (req, res) => {
    try {
        const idThongBao = parseInt(req.params.idThongBao)
        if (isNaN(idThongBao)) {
            return res.status(400).json({
                success: false,
                message: "ID thông báo không hợp lệ"
            });
        }
        const tonTai = await prisma.announcements.findUnique({
            where: {
                idThongBao: idThongBao
            },
            include: {
                nguoiDang: {
                    select: {
                        hoTen: true,
                        vaiTro: true,
                        email: true
                    }
                },
                khoahoc: {
                    select: {
                        tenKhoaHoc: true
                    }
                }
            }
        })
        if (!tonTai) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy thông báo"
            });
        }
        return res.status(200).json({
            success: true,
            data: tonTai,
            message: "Lấy thông báo thành công"
        })
    }
    catch (err) {
        return res.status(500).json({ success: false, error: err.message });
    }
})
export default router;
