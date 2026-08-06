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

// router.post('/', checkGiangVien, async (req, res) => {
//     try {
//         let { idKhoaHoc, tenBaiHoc, thuTu} = req.body;
//         tenBaiHoc = tenBaiHoc ? tenBaiHoc.trim() : undefined;
//         const idKhoaHocInt = parseInt(idKhoaHoc)
//         const idNguoiDang = req.user.idNguoiDung
//         if (!tenBaiHoc) {
//             return res.status(400).json({ success: false, message: "Thiếu tên bài học!" });
//         }
//         if (!idKhoaHoc) {
//             return res.status(400).json({ success: false, message: "Thiếu ID lớp học!" });
//         }
//         const khoaHoc = await prisma.khoahoc.findUnique({
//             where: { 
//                 idKhoaHoc: idKhoaHocInt 
//             },
//             select: { 
//                 idGiangVien: true 
//             }
//         })
//         if (!khoaHoc) {
//             return res.status(404).json({
//                 success: false,
//                 message: "Không tìm thấy lớp học!"
//             })
//         }

//         if (khoaHoc.idGiangVien !== idNguoiDang) {
//             return res.status(403).json({
//                 success: false,
//                 message: "Bạn không phải là giảng viên của lớp học này!"
//             })
//         }
//         let thuTuCuoi = thuTu ? parseInt(thuTu) : null
//         if (!thuTuCuoi) {
//             const maxThuTu = await prisma.baihoc.aggregate({
//                 where: { 
//                     idKhoaHoc: idKhoaHocInt 
//                 },
//                 _max: { 
//                     thuTu: true 
//                 }
//             })
//             thuTuCuoi = (maxThuTu._max.thuTu ?? 0) + 1;
//         }
       
//         const newBaiHoc = await prisma.baihoc.create({
//             data: {
//                 idKhoaHoc: parseInt(idKhoaHoc),
//                 tenBaiHoc: tenBaiHoc,
//                 thuTu: thuTuCuoi
//             }
//         })

//         try {
//             const tieuDePush = "Bài học mới!"
//             const noiDungPush = `Giảng viên vừa thêm bài học mới: ${tenBaiHoc}`
//             const thongBao = await prisma.announcements.create({
//                 data: {
//                     idKhoaHoc: idKhoaHocInt,
//                     idNguoiDang: idNguoiDang,
//                     tieuDe: tieuDePush,
//                     noiDung: noiDungPush,
//                     loaiThongBao: "bai_hoc",
//                     ngayTao: new Date()
//                 }
//             })
//             const dsHocVien = await prisma.dangky_khoahoc.findMany({
//                 where: {
//                     idKhoaHoc: idKhoaHocInt
//                 },
//                 include: {
//                     nguoidung: {
//                         include: {
//                             fcm_tokens: true
//                         }
//                     }
//                 }
//             })
//             const tokensDich = [];
//             for (let i = 0; i < dsHocVien.length; i++) {
//                 const hv = dsHocVien[i].nguoidung;
//                 for (let j = 0; j < hv.fcm_tokens.length; j++) {
//                     tokensDich.push(hv.fcm_tokens[j].token);
//                 }
//             }
//             if (tokensDich.length > 0) {
//                 const oneSignalPayload = {
//                     app_id: process.env.ONESIGNAL_APP_ID,
//                     include_subscription_ids: tokensDich,
//                     target_channel: "push",
//                     headings: {
//                         en: tieuDePush
//                     },
//                     contents: {
//                         en: noiDungPush
//                     },
//                     data: {
//                         idKhoaHoc: idKhoaHocInt,
//                         idThongBao: thongBao.idThongBao,
//                         idBaiHoc: newBaiHoc.idBaiHoc,
//                         loai: "bai_hoc_moi"
//                     }
//                 };
//                 axios.post('https://api.onesignal.com/notifications', oneSignalPayload, {
//                     headers: {
//                         'Content-Type': 'application/json; charset=utf-8',
//                         'Authorization': `Key ${process.env.ONESIGNAL_REST_API_KEY}`
//                     }
//                 }).catch(err => {
//                     console.error("Lỗi gọi API OneSignal khi tạo bài học:", err.response?.data || err.message);
//                 });
//             }
//         }
//         catch (pushError) {
//             console.error("Lỗi xử lý lưu bảng tin / bắn thông báo:", pushError.message);
//         }

//         return res.status(201).json({ success: true, idBaiHoc: newBaiHoc.idBaiHoc });
//     } catch (error) {
//         return res.status(500).json({ success: false, error: error.message });
//     }
// });

router.post('/', checkGiangVien, async (req, res) => {
    try {
        let { idKhoaHoc, idChuong, tenBaiHoc, thuTu } = req.body;
        tenBaiHoc = tenBaiHoc ? tenBaiHoc.trim() : undefined;
        const idKhoaHocInt = parseInt(idKhoaHoc);
        const idNguoiDang = req.user.idNguoiDung;

        if (!tenBaiHoc) {
            return res.status(400).json({ success: false, message: "Thiếu tên bài học!" });
        }
        if (!idKhoaHoc) {
            return res.status(400).json({ success: false, message: "Thiếu ID lớp học!" });
        }

        const khoaHoc = await prisma.khoahoc.findUnique({
            where: { idKhoaHoc: idKhoaHocInt },
            select: { idGiangVien: true }
        });
        if (!khoaHoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy lớp học!"
            });
        }
        if (khoaHoc.idGiangVien !== idNguoiDang) {
            return res.status(403).json({
                success: false,
                message: "Bạn không phải là giảng viên của lớp học này!"
            });
        }

        let idChuongInt = null;
        if (idChuong) {
            idChuongInt = parseInt(idChuong);
            const chuong = await prisma.chuong.findUnique({
                where: { idChuong: idChuongInt }
            });
            if (!chuong) {
                return res.status(404).json({
                    success: false,
                    message: "Không tìm thấy chương!"
                });
            }
            if (chuong.idKhoaHoc !== idKhoaHocInt) {
                return res.status(400).json({
                    success: false,
                    message: "Chương không thuộc khóa học này!"
                });
            }
        }

        let thuTuCuoi = thuTu ? parseInt(thuTu) : null;
        if (!thuTuCuoi) {
            const whereCondition = idChuongInt
                ? { idKhoaHoc: idKhoaHocInt, idChuong: idChuongInt }
                : { idKhoaHoc: idKhoaHocInt, idChuong: null };

            const maxThuTu = await prisma.baihoc.aggregate({
                where: whereCondition,
                _max: { thuTu: true }
            });
            thuTuCuoi = (maxThuTu._max.thuTu ?? 0) + 1;
        } else {
            const whereCondition = idChuongInt
                ? { idKhoaHoc: idKhoaHocInt, idChuong: idChuongInt, thuTu: thuTuCuoi }
                : { idKhoaHoc: idKhoaHocInt, idChuong: null, thuTu: thuTuCuoi };

            const existing = await prisma.baihoc.findFirst({
                where: whereCondition
            });
            if (existing) {
                return res.status(400).json({
                    success: false,
                    message: `Thứ tự ${thuTuCuoi} đã tồn tại trong ${idChuongInt ? 'chương này' : 'khóa học'}!`
                });
            }
        }

        const newBaiHoc = await prisma.baihoc.create({
            data: {
                idKhoaHoc: idKhoaHocInt,
                idChuong: idChuongInt,
                tenBaiHoc: tenBaiHoc,
                thuTu: thuTuCuoi
            }
        });

        try {
            const tieuDePush = "Bài học mới!";
            const noiDungPush = `Giảng viên vừa thêm bài học mới: ${tenBaiHoc}`;
            const thongBao = await prisma.announcements.create({
                data: {
                    idKhoaHoc: idKhoaHocInt,
                    idNguoiDang: idNguoiDang,
                    tieuDe: tieuDePush,
                    noiDung: noiDungPush,
                    loaiThongBao: "bai_hoc",
                    ngayTao: new Date()
                }
            });
            const dsHocVien = await prisma.dangky_khoahoc.findMany({
                where: { idKhoaHoc: idKhoaHocInt },
                include: {
                    nguoidung: {
                        include: {
                            fcm_tokens: true
                        }
                    }
                }
            });
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
                    headings: { en: tieuDePush },
                    contents: { en: noiDungPush },
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
                    console.error("Lỗi gọi API OneSignal:", err.response?.data || err.message);
                });
            }
        } catch (pushError) {
            console.error("Lỗi xử lý thông báo:", pushError.message);
        }

        return res.status(201).json({
            success: true,
            idBaiHoc: newBaiHoc.idBaiHoc,
            data: newBaiHoc
        });
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

// router.get('/:idKhoaHoc', checkGiangVien, async (req, res) => {
//     try {
//         const idGiangVien = req.user.idNguoiDung;
//         const idKhoaHoc = parseInt(req.params.idKhoaHoc);

//         const khoaHoc = await prisma.khoahoc.findFirst({
//             where: {
//                 idKhoaHoc: idKhoaHoc,
//                 idGiangVien: idGiangVien
//             }
//         });

//         if (!khoaHoc) {
//             return res.status(403).json({
//                 success: false,
//                 message: "Bạn không có quyền truy cập lớp này"
//             });
//         }

//         const baiHocs = await prisma.baihoc.findMany({
//             where: {
//                 idKhoaHoc: idKhoaHoc
//             },
//             select: {
//                 idBaiHoc: true,
//                 tenBaiHoc: true,
//                 videoUrl: true,
//                 taiLieuUrl: true,
//                 thuTu: true
//             },
//             orderBy: {
//                 thuTu: 'asc'
//             }
//         });
//         const kq = baiHocs.map(b => ({
//             ...b, loai: b.videoUrl ? 'video' : b.taiLieuUrl ? 'taiLieu' : 'none'
//         }));

//         res.status(200).json({
//             success: true,
//             data: kq
//         });

//     } catch (error) {
//         res.status(500).json({ error: error.message });
//     }
// });

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

        const chuongs = await prisma.chuong.findMany({
            where: {
                idKhoaHoc: idKhoaHoc
            },
            include: {
                baihoc: {
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
                }
            },
            orderBy: {
                thuTu: 'asc'
            }
        });

        const baiHocKhongChuong = await prisma.baihoc.findMany({
            where: {
                idKhoaHoc: idKhoaHoc,
                idChuong: null
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

        // 4. Format dữ liệu trả về
        const data = {
            khoaHoc: {
                idKhoaHoc: khoaHoc.idKhoaHoc,
                tenKhoaHoc: khoaHoc.tenKhoaHoc
            },
            chuongs: chuongs.map(chuong => ({
                idChuong: chuong.idChuong,
                tenChuong: chuong.tenChuong,
                thuTu: chuong.thuTu,
                baiHocs: chuong.baihoc.map(b => ({
                    ...b,
                    loai: b.videoUrl ? 'video' : b.taiLieuUrl ? 'taiLieu' : 'none'
                }))
            })),
            baiHocKhongChuong: baiHocKhongChuong.map(b => ({
                ...b,
                loai: b.videoUrl ? 'video' : b.taiLieuUrl ? 'taiLieu' : 'none'
            }))
        };

        res.status(200).json({
            success: true,
            data: data
        });

    } catch (error) {
        console.error('Lỗi lấy danh sách bài học:', error);
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

// router.put('/:idBaiHoc', checkGiangVien, async (req, res) => {
//     try {
//         const idBaiHoc = parseInt(req.params.idBaiHoc);
//         const idGiangVien = req.user.idNguoiDung;
//         let { tenBaiHoc, thuTu } = req.body;
//         if (isNaN(idBaiHoc)) {
//             return res.status(400).json({
//                 success: false,
//                 message: "ID bài học không hợp lệ"
//             });
//         }
//         const baiHoc = await prisma.baihoc.findFirst({
//             where: {
//                 idBaiHoc: idBaiHoc,
//                 khoahoc: {
//                     idGiangVien: idGiangVien
//                 }
//             }
//         });
//         if (!baiHoc) {
//             return res.status(403).json({
//                 success: false,
//                 message: "Không có quyền hoặc không tồn tại bài học"
//             })
//         }
//         const updateData = {};
//         if (tenBaiHoc) {
//             updateData.tenBaiHoc = tenBaiHoc.trim();
//         }
//         if (thuTu) {
//             updateData.thuTu = parseInt(thuTu);
//         }
//         await prisma.baihoc.update({
//             where: {
//                 idBaiHoc: idBaiHoc
//             },
//             data: updateData
//         })
//         return res.json({
//             success: true,
//             message: "Cập nhật thành công"
//         })
//     } catch (error) {
//         return res.status(500).json({
//             success: false,
//             error: error.message
//         })
//     }
// })

router.put('/:idBaiHoc', checkGiangVien, async (req, res) => {
    try {
        const idBaiHoc = parseInt(req.params.idBaiHoc);
        const idGiangVien = req.user.idNguoiDung;
        let { tenBaiHoc, idChuong, thuTu } = req.body;

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
            },
            include: {
                khoahoc: {
                    select: {
                        idKhoaHoc: true
                    }
                }
            }
        });

        if (!baiHoc) {
            return res.status(403).json({
                success: false,
                message: "Không có quyền hoặc không tồn tại bài học"
            });
        }

        const idKhoaHoc = baiHoc.khoahoc.idKhoaHoc;

        let idChuongInt = null;
        if (idChuong !== undefined) {
            if (idChuong === null || idChuong === '') {
                idChuongInt = null;
            } else {
                idChuongInt = parseInt(idChuong);
                const chuong = await prisma.chuong.findUnique({
                    where: { idChuong: idChuongInt }
                });
                if (!chuong) {
                    return res.status(404).json({
                        success: false,
                        message: "Không tìm thấy chương!"
                    });
                }
                if (chuong.idKhoaHoc !== idKhoaHoc) {
                    return res.status(400).json({
                        success: false,
                        message: "Chương không thuộc khóa học này!"
                    });
                }
            }
        }

        const updateData = {};

        if (tenBaiHoc !== undefined) {
            if (!tenBaiHoc.trim()) {
                return res.status(400).json({
                    success: false,
                    message: "Tên bài học không được để trống"
                });
            }
            updateData.tenBaiHoc = tenBaiHoc.trim();
        }

        if (idChuong !== undefined) {
            updateData.idChuong = idChuongInt;
        }

        if (thuTu !== undefined) {
            const thuTuInt = parseInt(thuTu);
            
            const targetChuong = idChuong !== undefined ? idChuongInt : baiHoc.idChuong;
            const whereCondition = targetChuong
                ? { idKhoaHoc: idKhoaHoc, idChuong: targetChuong, thuTu: thuTuInt }
                : { idKhoaHoc: idKhoaHoc, idChuong: null, thuTu: thuTuInt };

            const existing = await prisma.baihoc.findFirst({
                where: {
                    ...whereCondition,
                    idBaiHoc: { not: idBaiHoc }
                }
            });

            if (existing) {
                return res.status(400).json({
                    success: false,
                    message: `Thứ tự ${thuTuInt} đã tồn tại trong ${targetChuong ? 'chương này' : 'khóa học'}!`
                });
            }

            updateData.thuTu = thuTuInt;
        }

        const updated = await prisma.baihoc.update({
            where: { idBaiHoc: idBaiHoc },
            data: updateData
        });

        return res.json({
            success: true,
            message: "Cập nhật thành công",
            data: updated
        });

    } catch (error) {
        console.error('Lỗi cập nhật bài học:', error);
        return res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

router.get('/thoigianhoc/:idBaiHoc', checkGiangVien, async (req, res) => {
    try {
        const idBaiHoc = parseInt(req.params.idBaiHoc)
        const idGiangVien = req.user.idNguoiDung
        const baiHoc = await prisma.baihoc.findFirst({
            where: {
                idBaiHoc: idBaiHoc,
                khoahoc: {
                    idGiangVien: idGiangVien
                }
            },
            include: {
                khoahoc: true
            }
        })
        if (!baiHoc) {
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền hoặc bài học không tồn tại"
            })
        }
        const dsHocVien = await prisma.dangky_khoahoc.findMany({
            where: {
                idKhoaHoc: baiHoc.idKhoaHoc
            },
            include: {
                nguoidung: {
                    select: {
                        idNguoiDung: true,
                        hoTen: true,
                        taiKhoan: true,
                        email: true
                    }
                }
            }
        })
        const dsProgress = await prisma.progress.findMany({
            where:{
                idBaiHoc: idBaiHoc,
            }
        })
        const result = dsHocVien.map(dk=>{
            const progress = dsProgress.find(p=>p.idNguoiDung === dk.idNguoiDung)
            let trangThai = 'chua_hoc'
            if(progress){
                if (progress.trangThai === 'hoan_thanh') {
                    trangThai = 'hoan_thanh'
                } else if (progress.trangThai === 'dang_hoc') {
                    trangThai = 'dang_hoc'
                } else {
                    trangThai = 'chua_hoc'
                }
            }
            return{
                idNguoiDung: dk.nguoidung.idNguoiDung,
                hoTen: dk.nguoidung.hoTen,
                taiKhoan: dk.nguoidung.taiKhoan,
                email: dk.nguoidung.email,
                thoiGianHoc: progress?.thoiGianHoc || 0,
                trangThai: trangThai
            }
        })
        const chuaHoc = result.filter(r=>r.trangThai === 'chua_hoc')
        const dangHoc = result.filter(r=>r.trangThai === 'dang_hoc')
        const hoanThanh = result.filter(r=>r.trangThai === 'hoan_thanh')
        const daHoc = [...dangHoc, ...hoanThanh]
        const tongThoiGian = daHoc.reduce((sum, r) => sum + r.thoiGianHoc, 0)
        res.status(200).json({
            success: true,
            message: "Lấy ds progress thành công",
            data: {
                baiHoc: {
                    idBaiHoc: baiHoc.idBaiHoc,
                    tenBaiHoc: baiHoc.tenBaiHoc,
                    videoUrl: baiHoc.videoUrl,
                    taiLieuUrl: baiHoc.taiLieuUrl
                },
                thongKe: {
                    tongHocVien: dsHocVien.length,
                    chuaHoc: chuaHoc.length,
                    dangHoc: dangHoc.length,
                    hoanThanh: hoanThanh.length,
                    daHoc: daHoc.length,
                    tongThoiGianHoc: tongThoiGian,
                    thoiGianTrungBinh: daHoc.length > 0 ? Math.round(tongThoiGian / daHoc.length) : 0
                },
                danhSach: {
                    chuaHoc: chuaHoc,
                    dangHoc: dangHoc,
                    hoanThanh: hoanThanh
                }
            }
        })
    }
    catch (error) {
        res.status(500).json({
            success: false,
            error: error.message
        })
    }
})
//Chương
router.post('/chuong/:idKhoaHoc', checkGiangVien, async (req, res) => {
  try {
    const {tenChuong, thuTu } = req.body;
    const idKhoaHoc = parseInt(req.params.idKhoaHoc); 

    if (!tenChuong || !tenChuong.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng điền đầy đủ thông tin'
      });
    }

    const khoahoc = await prisma.khoahoc.findUnique({
      where: { idKhoaHoc }
    });

    if (!khoahoc) {
      return res.status(404).json({
        success: false,
        message: 'Lớp học không tồn tại'
      });
    }

    let finalThuTu = thuTu;
    if (!finalThuTu) {
      const maxThuTu = await prisma.chuong.aggregate({
        where: { idKhoaHoc },
        _max: { thuTu: true }
      });
      finalThuTu = (maxThuTu._max.thuTu || 0) + 1;
    }

    const newChuong = await prisma.chuong.create({
      data: {
        idKhoaHoc,
        tenChuong: tenChuong.trim(),
        thuTu: finalThuTu
      }
    });

    res.status(201).json({
      success: true,
      data: newChuong
    });
  } catch (error) {
    if (error.code === 'P2002') {
      return res.status(400).json({
        success: false,
        message: 'Thứ tự chương đã tồn tại trong khóa học này'
      });
    }
    res.status(500).json({ error: error.message });
  }
});

router.put('/chuong/:idChuong', checkGiangVien, async (req, res) => {
  try {
    const idChuong = parseInt(req.params.idChuong);
    const { tenChuong, thuTu } = req.body;

    const existingChuong = await prisma.chuong.findUnique({
      where: { idChuong }
    });

    if (!existingChuong) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy chương'
      });
    }

    const khoahoc = await prisma.khoahoc.findUnique({
      where: { idKhoaHoc: existingChuong.idKhoaHoc }
    });

    if (!khoahoc || khoahoc.idGiangVien !== req.user.idNguoiDung) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền sửa chương này'
      });
    }

    const dataUpdate = {};
    if (tenChuong !== undefined) {
      if (!tenChuong.trim()) {
        return res.status(400).json({
          success: false,
          message: 'Tên chương không được để trống'
        });
      }
      dataUpdate.tenChuong = tenChuong.trim();
    }

    if (thuTu !== undefined) {
      dataUpdate.thuTu = thuTu;
    }

    const updatedChuong = await prisma.chuong.update({
      where: { idChuong },
      data: dataUpdate
    });

    res.status(200).json({
      success: true,
      data: updatedChuong
    });

  } catch (error) {
    if (error.code === 'P2002') {
      return res.status(400).json({
        success: false,
        message: 'Thứ tự chương đã tồn tại trong khóa học này'
      });
    }
    console.error('Lỗi sửa chương:', error);
    res.status(500).json({ error: error.message });
  }
});

router.delete('/chuong/:idChuong', checkGiangVien, async (req, res) => {
  try {
    const idChuong = parseInt(req.params.idChuong);

    const existingChuong = await prisma.chuong.findUnique({
      where: { idChuong }
    });

    if (!existingChuong) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy chương'
      });
    }

    const khoahoc = await prisma.khoahoc.findUnique({
      where: { idKhoaHoc: existingChuong.idKhoaHoc }
    });

    if (!khoahoc || khoahoc.idGiangVien !== req.user.idNguoiDung) {
      return res.status(403).json({
        success: false,
        message: 'Bạn không có quyền xóa chương này'
      });
    }

    await prisma.chuong.delete({
      where: { idChuong }
    });

    res.status(200).json({
      success: true,
      message: 'Xóa chương thành công'
    });

  } catch (error) {
    console.error('Lỗi xóa chương:', error);
    res.status(500).json({ error: error.message });
  }
});
export default router;