import express from 'express';
import { prisma } from '../../prisma/client.js';
import { checkGroupPermission } from '../middleware.js';
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

//tao chu de tu message
router.post('/create-from-message/:idGroup', checkGroupPermission, async (req, res) => {
    try {
        const idGroup = parseInt(req.params.idGroup);
        const idNguoiDung = req.user.idNguoiDung;
        const { idMessageGoc, tieuDe, moTa } = req.body;

        if (!idMessageGoc || !tieuDe) {
            return res.status(400).json({
                success: false,
                message: "Vui lòng cung cấp tin nhắn gốc và tiêu đề"
            });
        }

        if (isNaN(idGroup)) {
            return res.status(400).json({
                success: false,
                message: "ID nhóm không hợp lệ"
            });
        }

        const messageGoc = await prisma.messages.findUnique({
            where: { idMessage: idMessageGoc },
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
        });

        if (!messageGoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy tin nhắn gốc"
            });
        }
        if (messageGoc.idGroup !== idGroup) {
            return res.status(400).json({
                success: false,
                message: "Tin nhắn không thuộc group"
            });
        }
        const tonTaiTopic = await prisma.discussion_topics.findUnique({
            where: {
                idMessageGoc: idMessageGoc
            }
        })
        if (tonTaiTopic) {
            return res.status(400).json({
                success: false,
                message: "Tin nhắn này đã được dùng để tạo chủ đề"
            });
        }

        const member = await prisma.group_members.findUnique({
            where: {
                idGroup_idNguoiDung: {
                    idGroup,
                    idNguoiDung
                }
            }
        });

        if (!member) {
            return res.status(403).json({
                success: false,
                message: "Bạn không phải thành viên của nhóm này"
            });
        }

        const topic = await prisma.discussion_topics.create({
            data: {
                idGroup: idGroup,
                idNguoiTao: idNguoiDung,
                idMessageGoc: idMessageGoc,
                tieuDe: tieuDe.trim(),
                moTa: moTa?.trim() || '',
                trangThai: 'active',
                ngayTao: new Date(new Date().getTime() + 7 * 60 * 60 * 1000)
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
                tinNhanGoc: {
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
                }
            }
        });

        await prisma.discussion_participants.create({
            data: {
                idTopic: topic.id,
                idNguoiDung: idNguoiDung,
                ngayThamGia: new Date(new Date().getTime() + 7 * 60 * 60 * 1000)
            }
        });

        const io = req.app.get('io');
        if (io) {
            io.to(`group_${idGroup}`).emit('new-topic', {
                topic: topic,
                message: `${req.user.hoTen} đã tạo chủ đề: "${tieuDe}"`
            });
        }

        res.status(201).json({
            success: true,
            message: "Tạo chủ đề thành công",
            data: topic
        });

    } catch (err) {
        console.error('Lỗi tạo chủ đề:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
});

// ds chu de
router.get('/topics/:idGroup', checkGroupPermission, async (req, res) => {
    try {
        const idGroup = parseInt(req.params.idGroup);
        const idNguoiDung = req.user.idNguoiDung;

        if (isNaN(idGroup)) {
            return res.status(400).json({
                success: false,
                message: "ID nhóm không hợp lệ"
            });
        }

        const topics = await prisma.discussion_topics.findMany({
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
                },
                tinNhanGoc: {
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
                },
                messages: {
                    select: {
                        id: true,
                        noiDung: true,
                        ngayTao: true,
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
                        ngayTao: 'desc'
                    },
                    take: 1
                },
                participants: {
                    where: {
                        idNguoiDung: idNguoiDung
                    }
                },
                _count: {
                    select: {
                        messages: true,
                        participants: true
                    }
                }
            },
            orderBy: {
                ngayCapNhat: 'desc'
            }
        });

        const result = topics.map(topic => ({
            id: topic.id,
            tieuDe: topic.tieuDe,
            moTa: topic.moTa,
            trangThai: topic.trangThai,
            nguoiTao: topic.nguoidung,
            tinNhanGoc: topic.tinNhanGoc,
            ngayTao: topic.ngayTao,
            ngayCapNhat: topic.ngayCapNhat,
            soTinNhan: topic._count.messages,
            soNguoiThamGia: topic._count.participants,
            tinNhanMoiNhat: topic.messages[0] || null,
            daXem: topic.participants.length > 0
        }));

        res.status(200).json({
            success: true,
            data: result,
            total: result.length
        });

    } catch (err) {
        console.error('Lỗi lấy danh sách chủ đề:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
});

//chi tiet topic
router.get('/topic/:idTopic', checkGroupPermission, async (req, res) => {
    try {
        const idTopic = parseInt(req.params.idTopic);
        const idNguoiDung = req.user.idNguoiDung;

        const topic = await prisma.discussion_topics.findUnique({
            where: { id: idTopic },
            include: {
                nguoidung: {
                    select: {
                        idNguoiDung: true,
                        hoTen: true,
                        email: true,
                        vaiTro: true
                    }
                },
                tinNhanGoc: {
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
                },
                messages: {
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
                        ngayTao: 'asc'
                    }
                },
                participants: {
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
                },
                group: {
                    include: {
                        members: {
                            where: {
                                vaiTroNhom: 'truong_nhom'
                            },
                            select: {
                                idNguoiDung: true,
                                vaiTroNhom: true,
                                nguoidung: {
                                    select: {
                                        idNguoiDung: true,
                                        hoTen: true,
                                    }
                                }
                            }
                        }
                    }
                },
                _count: {
                    select: {
                        messages: true,
                        participants: true
                    }
                }
            }
        });

        if (!topic) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy chủ đề"
            });
        }

        await prisma.discussion_participants.upsert({
            where: {
                idTopic_idNguoiDung: {
                    idTopic: idTopic,
                    idNguoiDung: idNguoiDung
                }
            },
            update: {},
            create: {
                idTopic: idTopic,
                idNguoiDung: idNguoiDung,
                ngayThamGia: new Date(new Date().getTime() + 7 * 60 * 60 * 1000)
            }
        });

        res.status(200).json({
            success: true,
            data: topic
        });

    } catch (err) {
        console.error('Lỗi lấy chi tiết chủ đề:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
});
// gui tin nhan
router.post('/message/:idTopic', checkGroupPermission, upload.single('file'), async (req, res) => {
    try {
        const idTopic = parseInt(req.params.idTopic);
        const idNguoiDung = req.user.idNguoiDung;
        const { noiDung } = req.body;

        if (isNaN(idTopic)) {
            return res.status(400).json({
                success: false,
                message: "ID chủ đề không hợp lệ"
            });
        }

        const coNoiDung = noiDung && noiDung.trim().length > 0;
        const coFile = req.file !== undefined;

        if (!coFile && !coNoiDung) {
            return res.status(400).json({
                success: false,
                message: "Vui lòng nhập nội dung hoặc chọn file"
            });
        }

        const topic = await prisma.discussion_topics.findUnique({
            where: { 
                id: idTopic 
            },
            include: { 
                group: true 
            }
        });

        if (!topic) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy chủ đề"
            });
        }

        if (topic.trangThai !== 'active') {
            return res.status(400).json({
                success: false,
                message: "Chủ đề đã bị đóng"
            });
        }

        const member = await prisma.group_members.findUnique({
            where: {
                idGroup_idNguoiDung: {
                    idGroup: topic.idGroup,
                    idNguoiDung: idNguoiDung
                }
            }
        })

        if (!member) {
            return res.status(403).json({
                success: false,
                message: "Bạn không phải thành viên của nhóm này"
            })
        }

        let fileUrl = null;
        if (req.file) {
            fileUrl = await uploadToCloudinary(req.file);
        }

        const message = await prisma.discussion_messages.create({
            data: {
                idTopic: idTopic,
                idNguoiDung: idNguoiDung,
                noiDung: coNoiDung ? noiDung.trim() : null,
                fileUrl: fileUrl,
                ngayTao: new Date(new Date().getTime() + 7 * 60 * 60 * 1000)
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
        });

        await prisma.discussion_topics.update({
            where: { id: idTopic },
            data: { ngayCapNhat: new Date(new Date().getTime() + 7 * 60 * 60 * 1000) }
        })

        const io = req.app.get('io');
        if (io) {
            io.to(`topic_${idTopic}`).emit('receive-topic-message', {
                message: message,
                topicId: idTopic
            });

            io.to(`group_${topic.idGroup}`).emit('topic-updated', {
                topicId: idTopic,
                messageCount: await prisma.discussion_messages.count({
                    where: { idTopic: idTopic }
                })
            });
        }

        res.status(201).json({
            success: true,
            message: "Gửi tin nhắn thành công",
            data: message
        });

    } catch (err) {
        console.error('Lỗi gửi tin nhắn:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
});

// dong chu de
router.put('/close/:idTopic', checkGroupPermission, async (req, res) => {
    try {
        const idTopic = parseInt(req.params.idTopic);
        const idNguoiDung = req.user.idNguoiDung;

        if (isNaN(idTopic)) {
            return res.status(400).json({
                success: false,
                message: "ID chủ đề không hợp lệ"
            });
        }

        const topic = await prisma.discussion_topics.findUnique({
            where: { 
                id: idTopic
            },
            include: {
                group: {
                    include: {
                        members: true
                    }
                }
            }
        });

        if (!topic) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy chủ đề"
            });
        }

        const isCreator = topic.idNguoiTao === idNguoiDung;
        const isGroupLeader = topic.group.members.some(m => m.idNguoiDung === idNguoiDung && m.vaiTroNhom === 'truong_nhom');

        if (!isCreator && !isGroupLeader) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền đóng chủ đề này"
            });
        }
        if(topic.trangThai === "closed"){
            return res.status(400).json({
                success: false,
                message: "Chủ đề đã được đóng trước đó"
            });
        }

        const updated = await prisma.discussion_topics.update({
            where: { 
                id: idTopic 
            },
            data: { 
                trangThai: 'closed' 
            }
        });

        const io = req.app.get('io');
        if (io) {
            io.to(`group_${topic.idGroup}`).emit('topic-closed', {
                topicId: idTopic,
                message: `Chủ đề "${topic.tieuDe}" đã được đóng`
            });
        }

        res.status(200).json({
            success: true,
            message: "Đã đóng chủ đề",
            data: updated
        });

    } catch (err) {
        console.error('Lỗi đóng chủ đề:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
});

// reopen chu de
router.put('/reopen/:idTopic', checkGroupPermission, async (req, res) => {
    try {
        const idTopic = parseInt(req.params.idTopic);
        const idNguoiDung = req.user.idNguoiDung;

        if (isNaN(idTopic)) {
            return res.status(400).json({
                success: false,
                message: "ID chủ đề không hợp lệ"
            });
        }

        const topic = await prisma.discussion_topics.findUnique({
            where: { id: idTopic },
            include: {
                group: {
                    include: {
                        members: true
                    }
                }
            }
        });

        if (!topic) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy chủ đề"
            });
        }

        const isCreator = topic.idNguoiTao === idNguoiDung;
        const isGroupLeader = topic.group.members.some(m =>m.idNguoiDung === idNguoiDung && m.vaiTroNhom === 'truong_nhom');

        if (!isCreator && !isGroupLeader) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền mở lại chủ đề này"
            });
        }
        if(topic.trangThai === "active"){
            return res.status(400).json({
                success: false,
                message: "Chỉ có thể mở lại chủ đề đã đóng"
            });
        }

        const updated = await prisma.discussion_topics.update({
            where: { 
                id: idTopic 
            },
            data: { 
                trangThai: 'active' 
            }
        });

        const io = req.app.get('io');
        if (io) {
            io.to(`group_${topic.idGroup}`).emit('topic-reopened', {
                topicId: idTopic,
                message: `Chủ đề "${topic.tieuDe}" đã được mở lại`
            });
        }

        res.status(200).json({
            success: true,
            message: "Đã mở lại chủ đề",
            data: updated
        });

    } catch (err) {
        console.error('Lỗi mở lại chủ đề:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
})

router.put('/message/:idMessage', checkGroupPermission, async (req, res) => {
    try {
        const idMessage = parseInt(req.params.idMessage);
        const idNguoiDung = req.user.idNguoiDung;
        const { noiDung } = req.body;

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

        const message = await prisma.discussion_messages.findUnique({
            where: { id: idMessage },
            include: {
                topic: {
                    include: {
                        group: {
                            include: {
                                members: true
                            }
                        }
                    }
                }
            }
        });

        if (!message) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy tin nhắn"
            });
        }

        if (message.idNguoiDung !== idNguoiDung) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền sửa tin nhắn này"
            });
        }

        if (message.topic.trangThai !== 'active') {
            return res.status(400).json({
                success: false,
                message: "Chủ đề đã đóng, không thể sửa tin nhắn"
            });
        }

        const updatedMessage = await prisma.discussion_messages.update({
            where: { 
                id: idMessage 
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
        });

        const io = req.app.get('io');
        if (io) {
            io.to(`topic_${message.idTopic}`).emit('topic-message-edited', {
                idMessage: idMessage,
                noiDung: noiDung.trim(),
                topicId: message.idTopic
            });
        }

        res.status(200).json({
            success: true,
            message: "Sửa tin nhắn thành công",
            data: updatedMessage
        });

    } catch (err) {
        console.error('Lỗi sửa tin nhắn:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
});

// xoa tin nhan
router.delete('/message/:idMessage', checkGroupPermission, async (req, res) => {
    try {
        const idMessage = parseInt(req.params.idMessage);
        const idNguoiDung = req.user.idNguoiDung;
        const vaiTro = req.user.vaiTro;

        if (isNaN(idMessage)) {
            return res.status(400).json({
                success: false,
                message: "ID tin nhắn không hợp lệ"
            });
        }

        const message = await prisma.discussion_messages.findUnique({
            where: { id: idMessage },
            include: {
                nguoidung: {
                    select: {
                        vaiTro: true,
                        hoTen: true
                    }
                },
                topic: {
                    include: {
                        group: {
                            include: {
                                members: true
                            }
                        }
                    }
                }
            }
        });

        if (!message) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy tin nhắn"
            });
        }

        
        const isGiangVienMessage = message.nguoidung.vaiTro === 'giangvien';
        const isGiangVien = vaiTro === 'giangvien';

        if (isGiangVienMessage && !isGiangVien) {
            return res.status(403).json({
                success: false,
                message: "Chỉ giảng viên mới có quyền xóa tin nhắn của giảng viên"
            });
        }

        const laNguoiGui = message.idNguoiDung === idNguoiDung;
        const laTruongNhom = message.topic.group.members.some(m =>
            m.idNguoiDung === idNguoiDung && m.vaiTroNhom === 'truong_nhom'
        );

        if (!laNguoiGui && !laTruongNhom) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền xóa tin nhắn này"
            });
        }

        if (message.topic.trangThai !== 'active') {
            return res.status(400).json({
                success: false,
                message: "Chủ đề đã đóng, không thể xóa tin nhắn"
            });
        }

        await prisma.discussion_messages.delete({
            where: { id: idMessage }
        });

        const io = req.app.get('io');
        if (io) {
            io.to(`topic_${message.idTopic}`).emit('topic-message-deleted', {
                idMessage: idMessage,
                topicId: message.idTopic
            });
        }

        res.status(200).json({
            success: true,
            message: "Xóa tin nhắn thành công"
        });

    } catch (err) {
        console.error('Lỗi xóa tin nhắn:', err);
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
});

export default router;