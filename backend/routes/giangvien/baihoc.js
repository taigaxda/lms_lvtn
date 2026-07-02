import express from 'express';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { prisma } from '../../prisma/client.js';
import { checkGiangVien } from '../middleware.js';
import { uploadToCloudinary } from './ggHelper.js';
import axios from 'axios';

const router = express.Router();

const uploadDir = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const upload = multer({ dest: uploadDir });

router.post('/', checkGiangVien, async (req, res) => {
    try {
        let { idKhoaHoc, tenBaiHoc, thuTu } = req.body;
        tenBaiHoc = tenBaiHoc ? tenBaiHoc.trim() : undefined;

        if (!tenBaiHoc) {
            return res.status(400).json({ success: false, message: "Thiếu tên bài học!" });
        }
        if (!idKhoaHoc) {
            return res.status(400).json({ success: false, message: "Thiếu ID khóa học!" });
        }
        const idKhoaHocInt = parseInt(idKhoaHoc)
        const idNguoiDang = req.user.idNguoiDung
        const newBaiHoc = await prisma.baihoc.create({
            data: {
                idKhoaHoc: parseInt(idKhoaHoc),
                tenBaiHoc: tenBaiHoc,
                thuTu: thuTu ? parseInt(thuTu) : 1
            }
        })

        try {
            const tieuDePush = "Bài học mới!"
            const noiDungPush = `Giảng viên vừa thêm bài học mới: ${tenBaiHoc}`
            const thongBao = await prisma.announcements.create({
                data: {
                    idKhoaHoc: idKhoaHocInt,
                    idNguoiDang: idNguoiDang,
                    tieuDe: tieuDePush,
                    noiDung: noiDungPush,
                    loaiThongBao: "bai_hoc",
                    ngayTao: new Date()
                }
            })
            const dsHocVien = await prisma.dangky_khoahoc.findMany({
                where: {
                    idKhoaHoc: idKhoaHocInt
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
                const hv = dsHocVien[i].nguoidung;
                for (let j = 0; j < hv.fcm_tokens.length; j++) {
                    tokensDich.push(hv.fcm_tokens[j].token);
                }
            }
            if (tokensDich.length > 0) {
                const oneSignalPayload = {
                    app_id: process.env.ONESIGNAL_APP_ID,
                    include_subscription_ids: tokensDich,
                    target_channel: "push",
                    headings: {
                        en: tieuDePush
                    },
                    contents: {
                        en: noiDungPush
                    },
                    data: {
                        idKhoaHoc: idKhoaHocInt,
                        idThongBao: thongBao.idThongBao,
                        idBaiHoc: newBaiHoc.idBaiHoc,
                        loai: "bai_hoc_moi"
                    }
                };
                axios.post('https://api.onesignal.com/notifications', oneSignalPayload, {
                    headers: {
                        'Content-Type': 'application/json; charset=utf-8',
                        'Authorization': `Key ${process.env.ONESIGNAL_REST_API_KEY}`
                    }
                }).catch(err => {
                    console.error("Lỗi gọi API OneSignal khi tạo bài học:", err.response?.data || err.message);
                });
            }
        }
        catch (pushError) {
            console.error("Lỗi xử lý lưu bảng tin / bắn thông báo:", pushError.message);
        }

        return res.status(201).json({ success: true, idBaiHoc: newBaiHoc.idBaiHoc });
    } catch (error) {
        return res.status(500).json({ success: false, error: error.message });
    }
});

router.post('/upload-file/:idBaiHoc', checkGiangVien, upload.single('taiLieu'), async (req, res) => {
    try {
        const { idBaiHoc } = req.params;
        const file = req.file;

        if (!file) {
            return res.status(400).json({
                success: false,
                message: "Chưa chọn file"
            });
        }

        console.log("MIME:", file.mimetype);
        console.log("NAME:", file.originalname);

        const secureUrl = await uploadToCloudinary(file);

        const ext = file.originalname.split('.').pop().toLowerCase();

        let updateData = {};

        if (["mp4", "mov", "avi", "mkv", "webm"].includes(ext)) {
            updateData.videoUrl = secureUrl;
            updateData.taiLieuUrl = null;
        } else {
            updateData.taiLieuUrl = secureUrl;
            updateData.videoUrl = null;
        }

        await prisma.baihoc.update({
            where: { idBaiHoc: parseInt(idBaiHoc) },
            data: updateData
        });

        return res.json({
            success: true,
            message: "Upload file thành công!",
            url: secureUrl
        });

    } catch (error) {
        console.error("Lỗi Upload:", error);
        return res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

router.get('/:idKhoaHoc', checkGiangVien, async (req, res) => {
    try {
        const idGiangVien = req.user.idNguoiDung;
        const idKhoaHoc = parseInt(req.params.idKhoaHoc);

        const khoaHoc = await prisma.khoahoc.findFirst({
            where: {
                idKhoaHoc: idKhoaHoc,
                idGiangVien: idGiangVien
            }
        });

        if (!khoaHoc) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền truy cập lớp này"
            });
        }

        const baiHocs = await prisma.baihoc.findMany({
            where: {
                idKhoaHoc: idKhoaHoc
            },
            select: {
                idBaiHoc: true,
                tenBaiHoc: true,
                videoUrl: true,
                taiLieuUrl: true,
                thuTu: true
            },
            orderBy: {
                thuTu: 'asc'
            }
        });
        const kq = baiHocs.map(b => ({
            ...b, loai: b.videoUrl ? 'video' : b.taiLieuUrl ? 'taiLieu' : 'none'
        }));

        res.status(200).json({
            success: true,
            data: kq
        });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.delete('/:idBaiHoc', checkGiangVien, async (req, res) => {
    try {
        const idBaiHoc = parseInt(req.params.idBaiHoc);
        const idGiangVien = req.user.idNguoiDung;
        if (isNaN(idBaiHoc)) {
            return res.status(400).json({
                success: false,
                message: "ID bài học không hợp lệ"
            });
        }
        const baiHoc = await prisma.baihoc.findFirst({
            where: {
                idBaiHoc: idBaiHoc,
                khoahoc: {
                    idGiangVien
                }
            },
            include: {
                khoahoc: true
            }
        });
        if (!baiHoc) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền hoặc bài học không tồn tại"
            });
        }
        await prisma.baihoc.delete({
            where: {
                idBaiHoc: idBaiHoc
            }
        })
        return res.json({
            success: true,
            message: "Xoá bài học thành công"
        });
    } catch (error) {
        return res.status(500).json({ success: false, error: error.message });
    }
})

router.put('/:idBaiHoc', checkGiangVien, async (req, res) => {
    try {
        const idBaiHoc = parseInt(req.params.idBaiHoc);
        const idGiangVien = req.user.idNguoiDung;
        let { tenBaiHoc, thuTu } = req.body;
        if (isNaN(idBaiHoc)) {
            return res.status(400).json({
                success: false,
                message: "ID bài học không hợp lệ"
            });
        }
        const baiHoc = await prisma.baihoc.findFirst({
            where: {
                idBaiHoc: idBaiHoc,
                khoahoc: {
                    idGiangVien: idGiangVien
                }
            }
        });
        if (!baiHoc) {
            return res.status(403).json({
                success: false,
                message: "Không có quyền hoặc không tồn tại bài học"
            })
        }
        const updateData = {};
        if (tenBaiHoc) {
            updateData.tenBaiHoc = tenBaiHoc.trim();
        }
        if (thuTu) {
            updateData.thuTu = parseInt(thuTu);
        }
        await prisma.baihoc.update({
            where: {
                idBaiHoc: idBaiHoc
            },
            data: updateData
        })
        return res.json({
            success: true,
            message: "Cập nhật thành công"
        })
    } catch (error) {
        return res.status(500).json({
            success: false,
            error: error.message
        })
    }
})

export default router;