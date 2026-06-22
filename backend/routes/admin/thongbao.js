import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkAdmin } from '../middleware.js'

const router = express.Router()
router.get('/:idKhoaHoc', checkAdmin, async (req, res) => {
    try {
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        if(isNaN(idKhoaHoc)){
            return res.status(400).json({
                success: false,
                message: "ID lớp học không hợp lệ"
            });
        }
        const dsThongBaoGV = await prisma.announcements.findMany({
            where: {
                AND: [
                    {
                        idKhoaHoc: idKhoaHoc
                    },
                    {
                        loaiThongBao: 'thong_bao'
                    }
                ]
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
            data: dsThongBaoGV,
            message: "Lấy ds thông báo thành công"
        })
    }
    catch (err) {
        return res.status(500).json({ success: false, error: err.message });
    }
})
router.get('/hethong', checkAdmin, async (req, res) => {
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
router.get('/chitiet/:idThongBao', checkAdmin, async (req, res) => {
    try {
        const idThongBao = parseInt(req.params.idThongBao)
        if(isNaN(idThongBao)){
            return res.status(400).json({
                success: false,
                message: "ID thông báo không hợp lệ"
            });
        }
        const tonTai = await prisma.announcements.findUnique({
            where:{
                idThongBao: idThongBao
            }
        })
        if(!tonTai){
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
router.post('/:idKhoaHoc', checkAdmin, async (req, res) => {
    try {
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        let { tieuDe, noiDung } = req.body
        tieuDe = tieuDe?.trim()
        noiDung = noiDung?.trim()
        if(isNaN(idKhoaHoc)){
            return res.status(400).json({
                success: false,
                message: "ID lớp học không hợp lệ"
            });
        }
        if (!noiDung||noiDung.length===0) {
            return res.status(400).json({
                success: false,
                message: "Thiếu nội dung thông báo"
            })
        }
        if (!tieuDe || tieuDe.length===0) {
            return res.status(400).json({
                success: false,
                message: "Thiếu tiêu đề thông báo"
            })
        }
        const idNguoiDang = req.user.idNguoiDung
        const khoaHoc = await prisma.khoahoc.findUnique({
            where: { idKhoaHoc: idKhoaHoc }
        });
        if (!khoaHoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy lớp học"
            });
        }
        const thongBao = await prisma.announcements.create({
            data:{
                idKhoaHoc: idKhoaHoc,
                idNguoiDang: idNguoiDang,
                noiDung: noiDung,
                tieuDe: tieuDe,
                loaiThongBao: 'thong_bao',
                ngayTao: new Date()
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
        return res.status(201).json({
            success: true,
            message: "Tạo thông báo thành công",
            data: thongBao
        })
    }
    catch (err) {
        return res.status(500).json({ success: false, error: err.message });
    }
})
router.put('/:idThongBao',checkAdmin,async(req,res)=>{
    try {
        const idThongBao = parseInt(req.params.idThongBao)
        let { tieuDe, noiDung } = req.body
        if(isNaN(idThongBao)){
            return res.status(400).json({
                success: false,
                message: "ID thông báo không hợp lệ"
            });
        }
        tieuDe = tieuDe?.trim()
        noiDung = noiDung?.trim()
        if (!noiDung||noiDung.length===0) {
            return res.status(400).json({
                success: false,
                message: "Thiếu nội dung thông báo"
            })
        }
        if (!tieuDe || tieuDe.length===0) {
            return res.status(400).json({
                success: false,
                message: "Thiếu tiêu đề thông báo"
            })
        }
        const idNguoiDang = req.user.idNguoiDung
        const tonTaiThongBao = await prisma.announcements.findUnique({
            where: { idThongBao: idThongBao }
        })
        if (!tonTaiThongBao) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy thông báo"
            });
        }
        if (tonTaiThongBao.idNguoiDang !== idNguoiDang) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền sửa thông báo này (chỉ được sửa thông báo do mình tạo)"
            });
        }
        if (tonTaiThongBao.idKhoaHoc === null) {
            return res.status(403).json({
                success: false,
                message: "Không thể sửa thông báo hệ thống"
            });
        }
        const updatedthongBao = await prisma.announcements.update({
            where: {
                idThongBao: idThongBao
            },
            data:{
                noiDung: noiDung ?? tonTaiThongBao.noiDung,
                tieuDe: tieuDe ?? tonTaiThongBao.tieuDe,
                ngayTao: new Date()
            }
        })
        return res.status(200).json({
            success: true,
            message: "Cập nhật thông báo thành công",
            data: updatedthongBao
        })
    }
    catch (err) {
        return res.status(500).json({ success: false, error: err.message });
    }
})
router.delete('/:idThongBao',checkAdmin,async(req,res)=>{
    try{
        const idThongBao = parseInt(req.params.idThongBao);
        const idNguoiDang = req.user.idNguoiDung;
        if(isNaN(idThongBao)){
            return res.status(400).json({
                success: false,
                message: "ID thông báo không hợp lệ"
            });
        }
        const thongBao = await prisma.announcements.findUnique({
            where:
            {
                idThongBao: idThongBao
            }
        })
         if (!thongBao) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy thông báo"
            });
        }
        if (thongBao.idNguoiDang !== idNguoiDang) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền xóa thông báo này (chỉ được xóa thông báo do mình tạo)"
            });
        }
        if (thongBao.idKhoaHoc === null) {
            return res.status(403).json({
                success: false,
                message: "Không thể xóa thông báo hệ thống"
            });
        }
        await prisma.announcements.delete({
            where: { idThongBao: idThongBao }
        });
        return res.status(200).json({
            success: true,
            message: "Xóa thông báo thành công"
        });
    }
    catch (err) {
        return res.status(500).json({ success: false, error: err.message });
    }
})
export default router;