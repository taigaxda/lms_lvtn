import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkGroupPermission } from '../middleware.js'

const router = express.Router();
router.get('/:idKhoaHoc', checkGroupPermission, async (req, res) => {
    try {
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        const idNguoiDung = req.user.idNguoiDung
        const vaiTro = req.user.vaiTro
        if (isNaN(idKhoaHoc)) {
            return res.status(400).json({
                success: false,
                message: "ID lớp học không hợp lệ"
            });
        }
        const khoaHoc = await prisma.khoahoc.findUnique({
            where: {
                idKhoaHoc: idKhoaHoc
            }
        })
        if (!khoaHoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy lớp học"
            });
        }
        const dangKy = await prisma.dangky_khoahoc.findFirst({
            where: {
                idNguoiDung,
                idKhoaHoc
            }
        });
        const isGiangVien = vaiTro === 'giangvien' && khoaHoc.idGiangVien === idNguoiDung;
        if (!dangKy && !isGiangVien) {
            return res.status(403).json({
                success: false,
                message: "Bạn không thuộc lớp học này"
            });
        }
        const groups = await prisma.groups.findMany({
            where: {
                idKhoaHoc: idKhoaHoc
            },
            include: {
                members: {
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
                _count: {
                    select: {
                        members: true
                    }
                }
            },
            orderBy: {
                ngayTao: 'desc'
            }
        });
        const formattedGroups = groups.map(group => {
            const isMember = group.members.some(m => m.idNguoiDung === idNguoiDung);
            const isTruongNhom = group.members.some(m => m.idNguoiDung === idNguoiDung && m.vaiTroNhom === 'truong_nhom');
            return {
                ...group,
                isMember,
                isTruongNhom,
                memberCount: group._count.members
            };
        });
        res.status(200).json({
            success: true,
            data: formattedGroups,
            total: formattedGroups.length
        });
    }
    catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.get('/chitiet/:idGroup', checkGroupPermission, async (req, res) => {
    try {
        const idGroup = parseInt(req.params.idGroup);
        const idNguoiDung = req.user.idNguoiDung;
        const group = await prisma.groups.findUnique({
            where: {
                idGroup: idGroup
            },
            include: {
                khoahoc: {
                    select: {
                        idKhoaHoc: true,
                        tenKhoaHoc: true,
                        code: true
                    }
                },
                members: {
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
                _count: {
                    select: {
                        members: true
                    }
                }
            }
        })
        if (!group) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy nhóm"
            });
        }
        const isMember = group.members.some(m => m.idNguoiDung === idNguoiDung);
        const isTruongNhom = group.members.some(m =>
            m.idNguoiDung === idNguoiDung && m.vaiTroNhom === 'truong_nhom'
        );
        res.status(200).json({
            success: true,
            data: {
                ...group,
                isMember,
                isTruongNhom,
                memberCount: group._count.members
            }
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.post('/:idKhoaHoc', checkGroupPermission, async (req, res) => {
    try {
        const idKhoaHoc = parseInt(req.params.idKhoaHoc);
        let { tenNhom, moTa } = req.body;
        const idNguoiDung = req.user.idNguoiDung;
        const vaiTro = req.user.vaiTro;
        tenNhom = tenNhom?.trim()
        moTa = moTa?.trim()
        if (isNaN(idKhoaHoc)) {
            return res.status(400).json({
                success: false,
                message: "ID lớp không hợp lệ"
            });
        }
        if (!tenNhom || tenNhom.length === 0) {
            return res.status(400).json({
                success: false,
                message: "Thiếu thông tin tên nhóm"
            })
        }
        if (!moTa || moTa.length === 0) {
            return res.status(400).json({
                success: false,
                message: "Thiếu thông tin mô tả nhóm"
            })
        }
        const khoaHoc = await prisma.khoahoc.findUnique({
            where: {
                idKhoaHoc: idKhoaHoc
            }
        })
        if (!khoaHoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy lớp học"
            });
        }
        const dangKy = await prisma.dangky_khoahoc.findFirst({
            where: {
                idNguoiDung,
                idKhoaHoc
            }
        });
        const isGiangVien = vaiTro === 'giangvien' && khoaHoc.idGiangVien === idNguoiDung;

        if (!dangKy && !isGiangVien) {
            return res.status(403).json({
                success: false,
                message: "Bạn không thuộc lớp học này"
            })
        }
        const groupExist = await prisma.groups.findFirst({
            where: {
                idKhoaHoc,
                tenNhom: tenNhom
            }
        })
        if (groupExist) {
            return res.status(400).json({
                success: false,
                message: "Tên nhóm đã tồn tại trong lớp học này"
            });
        }
        const group = await prisma.groups.create({
            data: {
                idKhoaHoc,
                tenNhom: tenNhom,
                moTa: moTa,
                ngayTao: new Date()
            }
        })
        await prisma.group_members.create({
            data: {
                idGroup: group.idGroup,
                idNguoiDung: idNguoiDung,
                vaiTroNhom: 'truong_nhom'
            }
        });
        const nhomMoi = await prisma.groups.findUnique({
            where: {
                idGroup: group.idGroup
            },
            include: {
                members: {
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
                _count: {
                    select: {
                        members: true
                    }
                }
            }
        })
        res.status(201).json({
            success: true,
            message: "Tạo nhóm thành công",
            data: nhomMoi
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.put('/:idGroup', checkGroupPermission, async (req, res) => {
    try {
        const idGroup = parseInt(req.params.idGroup);
        let { tenNhom, moTa } = req.body;
        const idNguoiDung = req.user.idNguoiDung;
        const vaiTro = req.user.vaiTro;
        if (isNaN(idGroup)) {
            return res.status(400).json({
                success: false,
                message: "ID nhóm không hợp lệ"
            });
        }
        if (!tenNhom || tenNhom.length === 0) {
            return res.status(400).json({
                success: false,
                message: "Tên nhóm không được để trống"
            });
        }
        if (!moTa || moTa.length === 0) {
            return res.status(400).json({
                success: false,
                message: "Mô tả nhóm không được để trống"
            });
        }
        const group = await prisma.groups.findUnique({
            where: { idGroup },
            include: {
                members: true,
                khoahoc: true
            }
        });
        if (!group) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy nhóm"
            });
        }
        const isTruongNhom = group.members.some(m => m.idNguoiDung === idNguoiDung && m.vaiTroNhom === 'truong_nhom');
        if (!isTruongNhom) {
            return res.status(403).json({
                success: false,
                message: "Chỉ trưởng nhóm mới có quyền sửa nhóm"
            });
        }
        if (tenNhom !== group.tenNhom) {
            const groupExist = await prisma.groups.findFirst({
                where: {
                    idKhoaHoc: group.idKhoaHoc,
                    tenNhom: tenNhom,
                    idGroup: {
                        not: idGroup
                    }
                }
            })
            if (groupExist) {
                return res.status(400).json({
                    success: false,
                    message: "Tên nhóm đã tồn tại trong lớp học này"
                })
            }
        }
        const updatedGroup = await prisma.groups.update({
            where: {
                idGroup: idGroup
            },
            data: {
                tenNhom: tenNhom,
                moTa: moTa
            },
            include: {
                members: {
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
                _count: {
                    select: {
                        members: true
                    }
                }
            }
        })
        res.status(200).json({
            success: true,
            message: "Cập nhật nhóm thành công",
            data: updatedGroup
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.delete('/:idGroup', checkGroupPermission, async (req, res) => {
    try {
        const idGroup = parseInt(req.params.idGroup);
        const idNguoiDung = req.user.idNguoiDung;
        const vaiTro = req.user.vaiTro;
        if (isNaN(idGroup)) {
            return res.status(400).json({
                success: false,
                message: "ID nhóm không hợp lệ"
            })
        }
        const group = await prisma.groups.findUnique({
            where: {
                idGroup: idGroup
            },
            include: {
                members: true,
                khoahoc: true
            }
        })
        if (!group) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy nhóm"
            })
        }
        const isTruongNhom = group.members.some(m =>
            m.idNguoiDung === idNguoiDung &&
            m.vaiTroNhom === 'truong_nhom'
        );
        const isGiangVien = vaiTro === 'giangvien' && group.khoahoc.idGiangVien === idNguoiDung;
        if (!isGiangVien && !isTruongNhom) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền xóa nhóm này"
            });
        }
        await prisma.groups.delete({
            where: {
                idGroup: idGroup
            }
        })
        res.status(200).json({
            success: true,
            message: "Xóa nhóm thành công"
        })
    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
})

//-----------------------------Thành viên nhóm
router.post('/join/:idGroup', checkGroupPermission, async (req, res) => {
    try {
        const idGroup = parseInt(req.params.idGroup);
        const idNguoiDung = req.user.idNguoiDung;
        const vaiTro = req.user.vaiTro;
        if (isNaN(idGroup)) {
            return res.status(400).json({
                success: false,
                message: "ID nhóm không hợp lệ"
            })
        }
        const group = await prisma.groups.findUnique({
            where: {
                idGroup: idGroup
            },
            include: {
                khoahoc: true
            }
        })
        if (!group) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy nhóm"
            });
        }
        const dangKy = await prisma.dangky_khoahoc.findFirst({
            where: {
                idNguoiDung,
                idKhoaHoc: group.idKhoaHoc
            }
        });
        const isGiangVien = vaiTro === 'giangvien' && group.khoahoc.idGiangVien === idNguoiDung;

        if (!dangKy && !isGiangVien) {
            return res.status(403).json({
                success: false,
                message: "Bạn không thuộc lớp học này"
            });
        }
        const daLaThanhVien = await prisma.group_members.findUnique({
            where: {
                idGroup_idNguoiDung: {
                    idGroup,
                    idNguoiDung
                }
            }
        });

        if (daLaThanhVien) {
            return res.status(400).json({
                success: false,
                message: "Bạn đã là thành viên của nhóm này"
            });
        }
        const member = await prisma.group_members.create({
            data: {
                idGroup,
                idNguoiDung,
                vaiTroNhom: 'thanh_vien'
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

        res.status(200).json({
            success: true,
            message: "Tham gia nhóm thành công",
            data: member
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.post('/leave/:idGroup', checkGroupPermission, async (req, res) => {
    try {
        const idGroup = parseInt(req.params.idGroup);
        const idNguoiDung = req.user.idNguoiDung;
        const vaiTro = req.user.vaiTro;
        if (isNaN(idGroup)) {
            return res.status(400).json({
                success: false,
                message: "ID nhóm không hợp lệ"
            })
        }
        const group = await prisma.groups.findUnique({
            where: {
                idGroup: idGroup
            }
        })
        if (!group) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy nhóm"
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
            return res.status(404).json({
                success: false,
                message: "Bạn không phải thành viên của nhóm này"
            });
        }
        if (member.vaiTroNhom === 'truong_nhom') {
            return res.status(400).json({
                success: false,
                message: "Trưởng nhóm không thể rời nhóm. Hãy chuyển trưởng nhóm hoặc xóa nhóm."
            });
        }
        await prisma.group_members.delete({
            where: {
                idGroup_idNguoiDung: {
                    idGroup,
                    idNguoiDung
                }
            }
        });
        res.status(200).json({
            success: true,
            message: "Rời nhóm thành công",
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.post('/kick/:idGroup', checkGroupPermission, async (req, res) => {
    try {
        const idGroup = parseInt(req.params.idGroup);
        const { idNguoiDungKick } = req.body;
        const idNguoiDung = req.user.idNguoiDung;
        const vaiTro = req.user.vaiTro;
        if (isNaN(idGroup)) {
            return res.status(400).json({
                success: false,
                message: "ID nhóm không hợp lệ"
            })
        }
        if (!idNguoiDungKick || isNaN(parseInt(idNguoiDungKick))) {
            return res.status(400).json({
                success: false,
                message: "ID người dùng không hợp lệ"
            });
        }
        const idNguoiDungKickInt = parseInt(idNguoiDungKick);
        const group = await prisma.groups.findUnique({
            where: {
                idGroup: idGroup
            }
        })
        if (!group) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy nhóm"
            });
        }
        const kicker = await prisma.group_members.findUnique({
            where: {
                idGroup_idNguoiDung: {
                    idGroup,
                    idNguoiDung
                }
            }
        });

        if (!kicker) {
            return res.status(404).json({
                success: false,
                message: "Bạn không phải thành viên của nhóm này"
            });
        }
        if (kicker.vaiTroNhom !== 'truong_nhom') {
            return res.status(403).json({
                success: false,
                message: "Chỉ trưởng nhóm mới có quyền kick thành viên"
            });
        }
        const targetMember = await prisma.group_members.findUnique({
            where: {
                idGroup_idNguoiDung: {
                    idGroup,
                    idNguoiDung: idNguoiDungKickInt
                }
            }
        });

        if (!targetMember) {
            return res.status(404).json({
                success: false,
                message: "Thành viên không tồn tại trong nhóm"
            });
        }
        if (targetMember.vaiTroNhom === 'truong_nhom') {
            return res.status(400).json({
                success: false,
                message: "Không thể kick trưởng nhóm"
            });
        }
        const targetUser = await prisma.nguoidung.findUnique({
            where: {
                idNguoiDung: idNguoiDungKickInt
            }
        });

        if (targetUser?.vaiTro === 'giangvien') {
            return res.status(403).json({
                success: false,
                message: "Không thể kick giảng viên khỏi nhóm"
            });
        }
        if (idNguoiDungKickInt === idNguoiDung) {
            return res.status(400).json({
                success: false,
                message: "Bạn không thể kick chính mình"
            });
        }
        await prisma.group_members.delete({
            where: {
                idGroup_idNguoiDung: {
                    idGroup,
                    idNguoiDung: idNguoiDungKickInt
                }
            }
        });
        res.status(200).json({
            success: true,
            message: "Đã kick thành viên khỏi nhóm"
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
router.put('/chuyenNT/:idGroup', checkGroupPermission, async (req, res) => {
    try {
        const idGroup = parseInt(req.params.idGroup);
        const { idNguoiDungMoi } = req.body;
        const idNguoiDung = req.user.idNguoiDung;
        if (isNaN(idGroup)) {
            return res.status(400).json({
                success: false,
                message: "ID nhóm không hợp lệ"
            });
        }
        if (!idNguoiDungMoi || isNaN(parseInt(idNguoiDungMoi))) {
            return res.status(400).json({
                success: false,
                message: "ID người dùng mới không hợp lệ"
            });
        }
        const idNguoiDungMoiInt = parseInt(idNguoiDungMoi);
        const group = await prisma.groups.findUnique({
            where: {
                idGroup
            },
            include: {
                members: true
            }
        })
        if (!group) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy nhóm"
            });
        }
        const currentLeader = await prisma.group_members.findUnique({
            where: {
                idGroup_idNguoiDung: {
                    idGroup,
                    idNguoiDung
                }
            }
        })
        if (!currentLeader || currentLeader.vaiTroNhom !== 'truong_nhom') {
            return res.status(403).json({
                success: false,
                message: "Bạn không phải trưởng nhóm"
            })
        }
        const newLeader = await prisma.group_members.findUnique({
            where: {
                idGroup_idNguoiDung: {
                    idGroup,
                    idNguoiDung: idNguoiDungMoiInt
                }
            }
        })
        if (!newLeader) {
            return res.status(404).json({
                success: false,
                message: "Người dùng không có trong nhóm"
            })
        }
        if (idNguoiDungMoiInt === idNguoiDung) {
            return res.status(400).json({
                success: false,
                message: "Bạn không thể chuyển trưởng nhóm cho chính mình"
            });
        }
        await prisma.$transaction([
            prisma.group_members.update({
                where: {
                    idGroup_idNguoiDung: {
                        idGroup,
                        idNguoiDung
                    }
                },
                data: { vaiTroNhom: 'thanh_vien' }
            }),
            prisma.group_members.update({
                where: {
                    idGroup_idNguoiDung: {
                        idGroup,
                        idNguoiDung: idNguoiDungMoiInt
                    }
                },
                data: { vaiTroNhom: 'truong_nhom' }
            })
        ]);
        const updatedGroup = await prisma.groups.findUnique({
            where: { idGroup },
            include: {
                members: {
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
                _count: {
                    select: { members: true }
                }
            }
        });

        res.status(200).json({
            success: true,
            message: "Chuyển trưởng nhóm thành công",
            data: updatedGroup
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            message: err.message
        });
    }
})
export default router
