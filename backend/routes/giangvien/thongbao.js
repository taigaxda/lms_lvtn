import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkGiangVien } from '../middleware.js'
import axios from 'axios'

const router = express.Router()
router.get('/hethong', checkGiangVien, async (req, res) => {
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
router.get('/:idKhoaHoc', checkGiangVien, async (req, res) => {
    try {
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        if (isNaN(idKhoaHoc)) {
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

router.get('/chitiet/:idThongBao', checkGiangVien, async (req, res) => {
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
router.post('/:idKhoaHoc', checkGiangVien, async (req, res) => {
    try {
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        let { tieuDe, noiDung } = req.body
        tieuDe = tieuDe?.trim()
        noiDung = noiDung?.trim()
        if (isNaN(idKhoaHoc)) {
            return res.status(400).json({
                success: false,
                message: "ID lớp học không hợp lệ"
            });
        }
        if (!noiDung || noiDung.length === 0) {
            return res.status(400).json({
                success: false,
                message: "Thiếu nội dung thông báo"
            })
        }
        if (!tieuDe || tieuDe.length === 0) {
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
            data: {
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
        const dsHocVien = await prisma.dangky_khoahoc.findMany({
            where: {
                idKhoaHoc: idKhoaHoc
            },
            include: {
                nguoidung: {
                    include: {
                        fcm_tokens: true
                    }
                }
            }
        })
        const tokensDich = [];
        for (let i = 0; i < dsHocVien.length; i++) {
            const hv = dsHocVien[i].nguoidung
            for (let j = 0; j < hv.fcm_tokens.length; j++) {
                const token = hv.fcm_tokens[j]
                tokensDich.push(token.token)
            }
        }
        if (tokensDich.length > 0) {
            const oneSignalPayload = {
                app_id: process.env.ONESIGNAL_APP_ID,
                include_subscription_ids: tokensDich, 
                target_channel: "push",
                headings: {
                    en: tieuDe
                },
                contents: {
                    en: noiDung
                },
                data: {
                    idKhoaHoc: idKhoaHoc,
                    idThongBao: thongBao.idThongBao,
                    loai: "thong_bao"
                }
            }

            axios.post('https://api.onesignal.com/notifications', oneSignalPayload, {
                headers: {
                    'Content-Type': 'application/json; charset=utf-8',
                    'Authorization': `Key ${process.env.ONESIGNAL_REST_API_KEY}`
                }
            }).catch(err => {
                console.error("Lỗi bắn thông báo OneSignal:", err.response?.data || err.message);
            })
        }
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
router.put('/:idThongBao', checkGiangVien, async (req, res) => {
    try {
        const idThongBao = parseInt(req.params.idThongBao)
        let { tieuDe, noiDung } = req.body
        if (isNaN(idThongBao)) {
            return res.status(400).json({
                success: false,
                message: "ID thông báo không hợp lệ"
            });
        }
        tieuDe = tieuDe?.trim()
        noiDung = noiDung?.trim()
        if (!noiDung || noiDung.length === 0) {
            return res.status(400).json({
                success: false,
                message: "Thiếu nội dung thông báo"
            })
        }
        if (!tieuDe || tieuDe.length === 0) {
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
            data: {
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
router.delete('/:idThongBao', checkGiangVien, async (req, res) => {
    try {
        const idThongBao = parseInt(req.params.idThongBao);
        const idNguoiDang = req.user.idNguoiDung;
        if (isNaN(idThongBao)) {
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