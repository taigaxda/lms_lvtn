import express from 'express'
import multer from 'multer';
import fs from 'fs';
import { prisma } from '../../prisma/client.js'
import { checkHocVien } from '../middleware.js'
import { uploadToCloudinary } from './ggHelper.js';
import { create } from 'domain';
import path from 'path';

const router = express.Router();

const uploadDir = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const upload = multer({ dest: uploadDir });

router.get('/chitiet/:idAssignment', checkHocVien, async (req, res) => {
    try {
        const idAssignment = parseInt(req.params.idAssignment);
        const idNguoiDung = req.user.idNguoiDung;
        
        const assignment = await prisma.assignments.findUnique({
            where: {
                idAssignment: idAssignment
            },
            include: {
                submissions: {
                    where: {
                        idNguoiDung: idNguoiDung
                    },
                    include: {
                        grades: true
                    }
                }
            }
        });
        
        if (!assignment) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy bài tập"
            });
        }
        
        return res.status(200).json({
            success: true,
            message: "Lấy chi tiết bài tập thành công",
            data: assignment
        });
    }
    catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        });
    }
});

router.get('/:idKhoaHoc', checkHocVien, async (req, res) => {
    try {
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        const idNguoiDung = req.user.idNguoiDung
        const dsBaiTap = await prisma.assignments.findMany({
            where: {
                idKhoaHoc: idKhoaHoc,
            },
            orderBy: {
                ngayTao: 'desc'
            },
            include: {
                submissions: {
                    where: {
                        idNguoiDung: idNguoiDung
                    },
                    include: {
                        grades: true
                    }
                }
            }
        })
        return res.status(200).json({
            success: true,
            message: "Lấy danh sách bài tập của bạn thành công",
            data: dsBaiTap
        })
    }
    catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        })
    }
})

router.post('/:idAssignment/nopbai', checkHocVien, upload.single('fileNop'), async (req, res) => {
    try {
        const idAssignment = parseInt(req.params.idAssignment);
        const idNguoiDung = req.user.idNguoiDung
        let { noiDung } = req.body
        noiDung = noiDung ? noiDung.trim() : null
        if (!idAssignment || isNaN(idAssignment)) {
            return res.status(400).json({
                success: false,
                message: "idAssignment không hợp lệ"
            })
        }
        const baiTap = await prisma.assignments.findUnique({
            where: {
                idAssignment: idAssignment
            }
        })
        if (!baiTap) {
            return res.status(404).json({
                success: false,
                message: "Bài tập khôn còn tồn tại"
            })
        }
        if (baiTap.hanNop && new Date() > baiTap.hanNop) {
            return res.status(400).json({
                success: false,
                message: "Đã quá hạn nộp bài"
            })
        }
        let fileUrl = null;
        if (req.file) {
            fileUrl = await uploadToCloudinary(req.file)
        }
        const baiNopCu = await prisma.submissions.findUnique({
            where: {
                idAssignment_idNguoiDung: {
                    idAssignment,
                    idNguoiDung
                }
            }
        });
        const baiNop = await prisma.submissions.upsert({
            where: {
                idAssignment_idNguoiDung: {
                    idAssignment,
                    idNguoiDung
                }
            },
            update: {
                fileNop: fileUrl ?? baiNopCu?.fileNop,
                noiDung: noiDung ?? baiNopCu?.noiDung,
                ngayNop: new Date()
            },
            create: {
                idAssignment,
                idNguoiDung,
                fileNop: fileUrl,
                noiDung: noiDung,
                ngayNop: new Date()
            }
        })
        return res.status(200).json({
            success: true,
            message: "Bạn đã nộp bài thành công",
            data: baiNop
        })
    }
    catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        })
    }
})

export default router