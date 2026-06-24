import express from 'express'
import { prisma } from '../prisma/client.js'
import { checkComment } from './middleware.js'

const router = express.Router();
router.get('/commentbaihoc/:idBaiHoc', checkComment, async (req, res) => {
    try {
        const idBaiHoc = parseInt(req.params.idBaiHoc);
        if (isNaN(idBaiHoc)) {
            return res.status(400).json({
                success: false,
                message: "ID bài học không hợp lệ"
            });
        }
        const baiHoc = await prisma.baihoc.findUnique({
            where: {
                idBaiHoc: idBaiHoc
            }
        })
        if (!baiHoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy bài học"
            });
        }
        const comments = await prisma.comments.findMany({
            where: {
                idBaiHoc: idBaiHoc,
                parentId: null
            },
            include: {
                nguoidung: {
                    select: {
                        idNguoiDung: true,
                        hoTen: true,
                        email: true,
                        vaiTro: true,
                    }
                },
                replies: {
                    include: {
                        nguoidung: {
                            select: {
                                idNguoiDung: true,
                                hoTen: true,
                                email: true,
                                vaiTro: true,
                            }
                        }
                    },
                    orderBy: {
                        ngayTao: 'asc'
                    }
                }
            },
            orderBy: {
                ngayTao: 'asc'
            }
        })
        const soComments = await prisma.comments.count({
            where: {
                idBaiHoc: idBaiHoc,
                parentId: null
            }
        })
        res.status(200).json({
            success: true,
            data: comments,
            total: soComments,
            message: "Lấy danh sách comment thành công"
        });
    }
    catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.get('/chitiet/:idComment', checkComment, async (req, res) => {
    try {
        const idComment = parseInt(req.params.idComment);
        if (isNaN(idComment)) {
            return res.status(400).json({
                success: false,
                message: "ID comment không hợp lệ"
            });
        }
        const comment = await prisma.comments.findUnique({
            where: {
                idComment: idComment
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
                replies: {
                    include: {
                        nguoidung: {
                            select: {
                                idNguoiDung: true,
                                hoTen: true,
                                email: true,
                                vaiTro: true
                            }
                        },
                    },
                    orderBy: {
                        ngayTao: 'asc'
                    }
                },
                baihoc: {
                    select: {
                        idBaiHoc: true,
                        tenBaiHoc: true,
                    }
                },
                parent: {
                    include: {
                        nguoidung: {
                            select: {
                                hoTen: true,
                                email: true,
                            }
                        }
                    }
                }
            }
        })
        if (!comment) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy comment"
            });
        }
        res.status(200).json({
            success: true,
            data: comment,
            message: "Lấy chi tiết comment thành công"
        });
    }
    catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.post('/', checkComment, async (req, res) => {
    try {
        const { idBaiHoc, noiDung } = req.body;
        const idNguoiDung = req.user.idNguoiDung
        if (!idBaiHoc) {
            return res.status(400).json({
                success: false,
                message: "Thiếu ID bài học"
            });
        }
        if (!noiDung || noiDung.trim().length === 0) {
            return res.status(400).json({
                success: false,
                message: "Nội dung không được để trống"
            });
        }
        const baiHoc = await prisma.baihoc.findUnique({
            where: { idBaiHoc: parseInt(idBaiHoc) }
        });
        if (!baiHoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy bài học"
            });
        }
        const comment = await prisma.comments.create({
            data: {
                idBaiHoc: parseInt(idBaiHoc),
                idNguoiDung: idNguoiDung,
                noiDung: noiDung.trim(),
                ngayTao: new Date()
            },
            include: {
                nguoidung: {
                    select: {
                        idNguoiDung: true,
                        hoTen: true,
                        email: true,
                        vaiTro: true,
                    }
                }
            }
        })
        res.status(201).json({
            success: true,
            message: "Tạo comment thành công",
            data: comment
        });
    }
    catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.post('/reply', checkComment, async (req, res) => {
    try {
        const { idComment, noiDung } = req.body;
        const idNguoiDung = req.user.idNguoiDung
        if (!idComment) {
            return res.status(400).json({
                success: false,
                message: "Thiếu ID comment cha"
            });
        }
        if (!noiDung || noiDung.trim().length === 0) {
            return res.status(400).json({
                success: false,
                message: "Nội dung không được để trống"
            });
        }
        const commentCha = await prisma.comments.findUnique({
            where: {
                idComment: parseInt(idComment)
            }
        })
        if (!commentCha) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy comment cha"
            });
        }
        const reply = await prisma.comments.create({
            data: {
                idBaiHoc: commentCha.idBaiHoc,
                idNguoiDung: idNguoiDung,
                noiDung: noiDung.trim(),
                parentId: parseInt(idComment),
                ngayTao: new Date()
            },
            include: {
                nguoidung: {
                    select: {
                        idNguoiDung: true,
                        hoTen: true,
                        email: true,
                        vaiTro: true,
                    }
                },
                parent: {
                    include: {
                        nguoidung: {
                            select: {
                                hoTen: true,
                                email: true,
                            }
                        }
                    }
                }
            }
        })
        res.status(201).json({
            success: true,
            message: "Reply comment thành công",
            data: reply
        });
    }
    catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.put('/:idComment', checkComment, async (req, res) => {
    try {
        const idComment = parseInt(req.params.idComment)
        const { noiDung } = req.body
        const idNguoiDung = req.user.idNguoiDung
        if (isNaN(idComment)) {
            return res.status(400).json({
                success: false,
                message: "ID comment không hợp lệ"
            });
        }
        if (!noiDung || noiDung.trim().length === 0) {
            return res.status(400).json({
                success: false,
                message: "Nội dung không được để trống"
            });
        }
        const comment = await prisma.comments.findUnique({
            where: {
                idComment: idComment
            },
            include: {
                parent: {
                    include: {
                        nguoidung: {
                            select: {
                                hoTen: true,
                                email: true,
                            }
                        }
                    }
                }
            }
        });
        if (!comment) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy comment"
            });
        }
        if (comment.idNguoiDung !== idNguoiDung) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền sửa comment này"
            });
        }
        const isReply = comment.parentId !== null;
        const updateComment = await prisma.comments.update({
            where: {
                idComment: idComment
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
                        vaiTro: true,
                    }
                },
                parent: {
                    include: {
                        nguoidung: {
                            select: {
                                hoTen: true,
                                email: true,
                            }
                        }
                    }
                }
            }
        })
        res.status(200).json({
            success: true,
            message: isReply ? "Cập nhật reply thành công" : "Cập nhật comment thành công",
            data: updateComment,
            isReply: isReply
        });
    }
    catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.delete('/:idComment', checkComment, async (req, res) => {
    try {
        const idComment = parseInt(req.params.idComment)
        const idNguoiDung = req.user.idNguoiDung
        const vaiTro = req.user.vaiTro
        if (isNaN(idComment)) {
            return res.status(400).json({
                success: false,
                message: "ID comment không hợp lệ"
            });
        }
        const comment = await prisma.comments.findUnique({
            where: {
                idComment: idComment
            },
            include: {
                replies: {
                    include: {
                        nguoidung: {
                            select: {
                                hoTen: true,
                                email: true,
                            }
                        }
                    }
                },
                baihoc: {
                    include: {
                        khoahoc: {
                            select: {
                                idGiangVien: true
                            }
                        }
                    }
                }
            }
        })
        if (!comment) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy comment"
            });
        }
        const laNguoiDang = comment.idNguoiDung === idNguoiDung
        const laGVLopHoc = vaiTro === 'giangvien' && comment.baihoc?.khoahoc?.idGiangVien === idNguoiDung;
        if (!laNguoiDang && !laGVLopHoc) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền xóa comment này",
                detail: "Chỉ người tạo hoặc giảng viên của khóa học mới có quyền xóa"
            });
        }
        const deletedRepliesCount = comment.replies.length
        if (deletedRepliesCount > 0) {
            await prisma.comments.deleteMany({
                where: {
                    parentId: idComment
                }
            })
        }
        await prisma.comments.delete({
            where: { 
                idComment: idComment 
            }
        });
        let message = "Xóa comment thành công";
        if (comment.parentId !== null) {
            message = "Xóa reply thành công";
        } else if (deletedRepliesCount > 0) {
            message = `Xóa comment và ${deletedRepliesCount} reply thành công`;
        }
        res.status(200).json({
            success: true,
            message: message,
            data: {
                idComment: idComment,
                isReply: comment.parentId !== null,
                deletedReplies: deletedRepliesCount,
                nguoiXoa: {
                    id: req.user.idNguoiDung,
                    hoTen: req.user.hoTen,
                    vaiTro: vaiTro
                }
            }
        });
    }
    catch (err) {
        return res.status(500).json({
            success: false,
            message: err.message
        });
    }
})

export default router;