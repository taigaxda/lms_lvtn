import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkGroupPermission } from '../middleware.js'
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { uploadToCloudinary } from './ggHelper.js';

const router = express.Router();
const uploadDir = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const upload = multer({ dest: uploadDir });

router.get('/messgr/:idGroup', checkGroupPermission, async (req, res) => {
    try {
        const idGroup = parseInt(req.params.idGroup);
        const idNguoiDung = req.user.idNguoiDung;
        const { page = 1, limit = 20 } = req.query;
        if (isNaN(idGroup)) {
            return res.status(400).json({
                success: false,
                message: "ID nhóm không hợp lệ"
            });
        }
        const member = await prisma.group_members.findUnique({
            where: {
                idGroup_idNguoiDung: {
                    idGroup,
                    idNguoiDung
                }
            }
        })
        if (!member) {
            return res.status(403).json({
                success: false,
                message: "Bạn không phải thành viên của nhóm này"
            })
        }
        const skip = (parseInt(page) - 1) * parseInt(limit);
        const messages = await prisma.messages.findMany({
            where: {
                idGroup: idGroup
            },
            include: {
                nguoidung: {
                    select: {
                        idNguoiDung: true,
                        hoTen: true,
                        email: true,
                        vaiTro: true
                    }
                }
            },
            orderBy: {
                thoiGian: 'desc'
            },
            skip: skip,
            take: parseInt(limit)
        })
        const total = await prisma.messages.count({
            where: {
                idGroup: idGroup
            }
        })
        res.status(200).json({
            success: true,
            data: messages.reverse(),
            message: "Lấy danh sách tin nhắn thành công",
            pagination: {
                page: parseInt(page),
                limit: parseInt(limit),
                total: total,
                totalPages: Math.ceil(total / parseInt(limit))
            }
        })
    }
    catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        })
    }
})
router.get('/chitiet/:idMessage', checkGroupPermission, async (req, res) => {
    try {
        const idMessage = parseInt(req.params.idMessage);
        const idNguoiDung = req.user.idNguoiDung;
        if (isNaN(idMessage)) {
            return res.status(400).json({
                success: false,
                message: "ID tin nhắn không hợp lệ"
            })
        }
        const message = await prisma.messages.findUnique({
            where: {
                idMessage
            },
            include: {
                nguoidung: {
                    select: {
                        idNguoiDung: true,
                        hoTen: true,
                        email: true,
                        vaiTro: true
                    }
                },
                group: {
                    select: {
                        idGroup: true,
                        tenNhom: true
                    }
                }
            }
        })

        if (!message) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy tin nhắn"
            });
        }

        const member = await prisma.group_members.findUnique({
            where: {
                idGroup_idNguoiDung: {
                    idGroup: message.idGroup,
                    idNguoiDung
                }
            }
        })

        if (!member) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền xem tin nhắn này"
            })
        }

        res.status(200).json({
            success: true,
            data: message,
            message: "Lấy chi tiết tin nhắn thành công"
        })

    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        })
    }
});
router.post('/tinnhan/:idGroup', checkGroupPermission, upload.single('file'), async (req, res) => {
    try {
        const idGroup = parseInt(req.params.idGroup);
        const idNguoiDung = req.user.idNguoiDung;
        const { noiDung } = req.body;
        if (isNaN(idGroup)) {
            return res.status(400).json({
                success: false,
                message: "ID nhóm không hợp lệ"
            })
        }
        const member = await prisma.group_members.findUnique({
            where: {
                idGroup_idNguoiDung: {
                    idGroup,
                    idNguoiDung
                }
            }
        })
        if (!member) {
            return res.status(403).json({
                success: false,
                message: "Bạn không phải thành viên của nhóm này"
            })
        }
        const coNoiDung = noiDung && noiDung.trim().length > 0
        const coFile = req.file !== undefined
        if (!coFile && !coNoiDung) {
            return res.status(400).json({
                success: false,
                message: "Vui lòng nhập nội dung hoặc chọn file"
            })
        }
        let fileUrl = null
        if (req.file) {
            fileUrl = await uploadToCloudinary(req.file)
        }
        const message = await prisma.messages.create({
            data: {
                idGroup,
                idNguoiDung,
                noiDung: coNoiDung ? noiDung.trim() : null,
                fileUrl: fileUrl,
                thoiGian: new Date()
            },
            include: {
                nguoidung: {
                    select: {
                        idNguoiDung: true,
                        hoTen: true,
                        email: true,
                        vaiTro: true
                    }
                }
            }
        })
        const io = req.app.get('io')
        if (io) {
            io.to(`group_${idGroup}`).emit('receive-message', message)
        }
        res.status(201).json({
            success: true,
            message: "Gửi tin nhắn thành công",
            data: message
        });
    }
    catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        })
    }
})
router.delete('/:idMessage', checkGroupPermission, async (req, res) => {
    try {
        const idMessage = parseInt(req.params.idMessage)
        const idNguoiDung = req.user.idNguoiDung
        const message = await prisma.messages.findUnique({
            where: { idMessage },
            include: {
                group: {
                    include: {
                        members: true
                    }
                }
            }
        })
        if (!message) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy tin nhắn"
            })
        }
        const laNguoiGui = message.idNguoiDung === idNguoiDung
        const laTruongNhom = message.group.members.some(m => m.idNguoiDung === idNguoiDung && m.vaiTroNhom === 'truong_nhom')
        if (!laNguoiGui && !laTruongNhom) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền xóa tin nhắn này"
            })
        }
        await prisma.messages.delete({
            where: { idMessage }
        })
        const io = req.app.get('io');
        if (io) {
            io.to(`group_${message.idGroup}`).emit('message-deleted', {
                idMessage: idMessage
            })
        }
        res.status(200).json({
            success: true,
            message: "Xóa tin nhắn thành công"
        });
    }
    catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        })
    }
})
router.put('/:idMessage', checkGroupPermission, async (req, res) => {
    try {
        const idMessage = parseInt(req.params.idMessage)
        const idNguoiDung = req.user.idNguoiDung
        const { noiDung } = req.body
        if (isNaN(idMessage)) {
            return res.status(400).json({
                success: false,
                message: "ID tin nhắn không hợp lệ"
            });
        }

        if (!noiDung || noiDung.trim().length === 0) {
            return res.status(400).json({
                success: false,
                message: "Nội dung không được để trống"
            });
        }

        const message = await prisma.messages.findUnique({
            where: {
                idMessage: idMessage
            }
        })

        if (!message) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy tin nhắn"
            })
        }

        if (message.idNguoiDung !== idNguoiDung) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền sửa tin nhắn này"
            })
        }

        const updatedMessage = await prisma.messages.update({
            where: {
                idMessage: idMessage
            },
            data: {
                noiDung: noiDung.trim()
            },
            include: {
                nguoidung: {
                    select: {
                        idNguoiDung: true,
                        hoTen: true,
                        email: true,
                        vaiTro: true
                    }
                }
            }
        })
        const io = req.app.get('io');
        if (io) {
            io.to(`group_${message.idGroup}`).emit('message-edited', updatedMessage);
        }
        res.status(200).json({
            success: true,
            message: "Sửa tin nhắn thành công",
            data: updatedMessage
        })
    }
    catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        })
    }
})
export default router