import express from 'express'
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { prisma } from '../../prisma/client.js'
import { checkGiangVien } from '../middleware.js'
import { uploadToCloudinary } from './ggHelper.js'; 
import axios from 'axios';

const router = express.Router();

const uploadDir = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

const upload = multer({ dest: uploadDir });

router.get('/:idKhoaHoc', checkGiangVien, async (req, res) => {
    try {
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        const dsBaiTap = await prisma.assignments.findMany({
            where: {
                idKhoaHoc: idKhoaHoc,
            },
            orderBy: {
                ngayTao: 'desc'
            },
            include: {
                submissions: {
                    include:{
                        nguoidung: true,
                        grades: true
                    },
                    orderBy:[
                        {
                            grades:{
                                idGrade: 'asc'
                            }
                        },
                        {
                            ngayNop: 'desc'
                        }
                    ]
                }
            }
        })
        return res.status(200).json({
            success: true,
            message: "Lấy danh sách bài tập thành công",
            data: dsBaiTap
        })
    }
    catch(err){
        return res.status(500).json({
            success: false,
            message: err.message
        })
    }
})
router.get('/dsbainop/:idAssignment', checkGiangVien, async (req, res) => {
    try {
        const idGiangVien = req.user.idNguoiDung;
        const idAssignment = parseInt(req.params.idAssignment);
        if (isNaN(idAssignment)) {
            return res.status(400).json({
                success: false,
                message: "ID bài tập không hợp lệ"
            });
        }
        
        const assignment = await prisma.assignments.findFirst({
            where: {
                idAssignment: idAssignment,
                khoahoc: {
                    idGiangVien: idGiangVien
                }
            },
            include: {
                khoahoc: true
            }
        });
        
        if (!assignment) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy bài tập hoặc bạn không có quyền"
            });
        }
        
        const idKhoaHoc = assignment.khoahoc.idKhoaHoc;
        
        const hocViens = await prisma.dangky_khoahoc.findMany({
            where: { idKhoaHoc },
            include: {
                nguoidung: {
                    select: {
                        idNguoiDung: true,
                        hoTen: true,
                        email: true
                    }
                }
            }
        });
        
        const submissions = await prisma.submissions.findMany({
            where: { idAssignment },
            include: {
                grades: true
            }
        });
        
        const mapSubmissions = new Map();
        submissions.forEach(s => {
            mapSubmissions.set(s.idNguoiDung, s);
        });
        
        const finalData = hocViens.map(hv => {
            const sub = mapSubmissions.get(hv.idNguoiDung);
            return {
                idNguoiDung: hv.idNguoiDung,
                hoTen: hv.nguoidung.hoTen,
                email: hv.nguoidung.email,
                daNop: sub ? true : false,
                fileNop: sub ? sub.fileNop : null,
                noiDung: sub ? sub.noiDung : null,
                ngayNop: sub ? sub.ngayNop : null,
                grade: sub?.grades ? {
                    diem: sub.grades.diem,
                    nhanXet: sub.grades.nhanXet,
                    ngayCham: sub.grades.ngayCham
                } : null,
                trangThai: sub ? (sub.grades ? "Đã chấm" : "Đã nộp") : "Chưa nộp"
            };
        });
        finalData.sort((a, b) => {
            if (!a.daNop && b.daNop) return -1;
            if (a.daNop && !b.daNop) return 1;
            if (a.grade && !b.grade) return 1;
            if (!a.grade && b.grade) return -1;
            return 0;
        });
        
        const stats = {
            tongHocVien: finalData.length,
            daNop: finalData.filter(hv => hv.daNop).length,
            chuaNop: finalData.filter(hv => !hv.daNop).length,
            daCham: finalData.filter(hv => hv.grade).length,
            chuaCham: finalData.filter(hv => hv.daNop && !hv.grade).length,
            diemCaoNhat: (() => {
                const diems = finalData.filter(hv => hv.grade).map(hv => hv.grade.diem);
                return diems.length > 0 ? Math.max(...diems) : 0;
            })(),
            diemThapNhat: (() => {
                const diems = finalData.filter(hv => hv.grade).map(hv => hv.grade.diem);
                return diems.length > 0 ? Math.min(...diems) : 0;
            })(),
            diemTrungBinh: (() => {
                const diems = finalData.filter(hv => hv.grade).map(hv => hv.grade.diem);
                return diems.length > 0 ? diems.reduce((a, b) => a + b, 0) / diems.length : 0;
            })()
        };
        
        res.status(200).json({
            success: true,
            data: finalData,
            stats: stats,
            assignment: {
                idAssignment: assignment.idAssignment,
                tieuDe: assignment.tieuDe,
                hanNop: assignment.hanNop
            }
        });
        
    } catch (err) {
        console.error("Lỗi lấy danh sách bài nộp:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});
router.post('/:idKhoaHoc',checkGiangVien,upload.single('fileDinhKem'), async (req, res)=>{
    try{
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        let {tieuDe,moTa,hanNop}=req.body
        tieuDe = tieuDe?.trim()
        moTa = moTa?.trim()
        if(!tieuDe || !moTa){
            return res.status(400).json({
                success: false,
                message: "Thiếu thông tin bài tập"
            })
        }
        if (!hanNop || isNaN(new Date(hanNop))) {
            return res.status(400).json({
                success: false,
                message: "Hạn nộp không hợp lệ"
            });
        }
        let fileUrl = null;
        if (req.file) {
            fileUrl = await uploadToCloudinary(req.file);
        } 
        const baiTap = await prisma.assignments.create({
            data:{
                idKhoaHoc,
                tieuDe,
                moTa,
                fileDinhKem: fileUrl,
                hanNop: new Date(hanNop)
            }
        })
        try{
            const idNguoiDang = req.user.idNguoiDung;
            const tieuDePush = "Bài tập mới!";
            const noiDungPush = `Lớp có bài tập mới: "${tieuDe}". Hạn nộp: ${new Date(hanNop).toLocaleDateString('vi-VN')}`;
            const thongBao = await prisma.announcements.create({
                data: {
                    idKhoaHoc: idKhoaHoc,
                    idNguoiDang: idNguoiDang,
                    tieuDe: tieuDePush,
                    noiDung: noiDungPush,
                    loaiThongBao: "bai_tap",
                    ngayTao: new Date()
                }
            });
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
            const tokensDich = []
            for (let i = 0; i < dsHocVien.length; i++) {
                const hv = dsHocVien[i].nguoidung
                if (hv && Array.isArray(hv.fcm_tokens)) {
                    for (let j = 0; j < hv.fcm_tokens.length; j++) {
                        if (hv.fcm_tokens[j]?.token) {
                            tokensDich.push(hv.fcm_tokens[j].token)
                        }
                    }
                }
            }
            if(tokensDich.length > 0){
                const oneSignalPayload ={
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
                        idKhoaHoc: idKhoaHoc,
                        idThongBao: thongBao.idThongBao,
                        idAssignment: baiTap.idAssignment,
                        loai: "bai_tap_moi"
                    }
                }
                axios.post('https://api.onesignal.com/notifications', oneSignalPayload, {
                    headers: {
                        'Content-Type': 'application/json; charset=utf-8',
                        'Authorization': `Key ${process.env.ONESIGNAL_REST_API_KEY}`
                    }
                }).catch(err => {
                    console.error("Lỗi gọi API OneSignal khi tạo bài tập:", err.response?.data || err.message);
                })
            }
        }
        catch(pushError){
            console.error("Lỗi xử lý lưu bảng tin / bắn thông báo:", pushError.message);
        }
        return res.status(200).json({
            success: true,
            message: "Tạo bài tập thành công",
            data: baiTap
        })
    }
    catch(err){
        return res.status(500).json({
            success: false,
            message: err.message
        })
    }
})
router.put('/:idAssignment',checkGiangVien,upload.single('fileDinhKem'), async (req, res)=>{
    try{
        const idAssignment = parseInt(req.params.idAssignment)
        let {tieuDe,moTa,hanNop}=req.body
        tieuDe = tieuDe?.trim()
        moTa = moTa?.trim()
        if (!idAssignment || isNaN(idAssignment)) {
            return res.status(400).json({
                success: false,
                message: "idBaiTap không hợp lệ"
            });
        }
        if(!tieuDe || !moTa){
            return res.status(400).json({
                success: false,
                message: "Thiếu thông tin bài tập"
            })
        }
        if (!hanNop || isNaN(new Date(hanNop))) {
            return res.status(400).json({
                success: false,
                message: "Hạn nộp không hợp lệ"
            });
        }
        const tonTai = await prisma.assignments.findUnique({
            where:{
                idAssignment: idAssignment
            }
        })
        if(!tonTai){
            return res.status(404).json({
                success: false,
                message: "Không tồn tại bài tập"
            })
        }
        let fileUrl = tonTai.fileDinhKem;
        if (req.file) {
            fileUrl = await uploadToCloudinary(req.file);
        } 
        const updated = await prisma.assignments.update({
            where:{
                idAssignment: idAssignment
            },
            data:{
                tieuDe: tieuDe ?? tonTai.tieuDe,
                moTa: moTa ?? tonTai.moTa,
                hanNop: hanNop ? new Date(hanNop) : tonTai.hanNop,
                fileDinhKem: fileUrl
            }
        })
        return res.status(200).json({
            success: true,
            message: "Cập nhật bài tập thành công",
            data: updated
        })
    }
    catch(err){
        return res.status(500).json({
            success: false,
            message: err.message
        })
    }
})
router.delete('/:idAssignment',checkGiangVien, async (req, res)=>{
    try{
        const idAssignment = parseInt(req.params.idAssignment)
        if (!idAssignment || isNaN(idAssignment)) {
            return res.status(400).json({
                success: false,
                message: "idBaiTap không hợp lệ"
            });
        }
        const tonTai = await prisma.assignments.findUnique({
            where:{
                idAssignment: idAssignment
            }
        })
        if(!tonTai){
            return res.status(404).json({
                success: false,
                message: "Không tồn tại bài tập"
            })
        }
        await prisma.assignments.delete({
            where:{
                idAssignment: idAssignment
            }
        })
        return res.status(200).json({
            success: true,
            message: "Xóa bài tập thành công",
        })
    }
    catch(err){
        return res.status(500).json({
            success: false,
            message: err.message
        })
    }
})
router.get('/chitietbt/:idSubmission',checkGiangVien,async(req,res)=>{
    try{
        const idSubmission = parseInt(req.params.idSubmission)
        const chiTiet = await prisma.submissions.findUnique({
            where:{
                idSubmission: idSubmission
            },
            include:{
                nguoidung:{
                    select:{
                        idNguoiDung: true,
                        hoTen: true,
                        email: true
                    }
                },
                grades: true
            }
        });
        if(!chiTiet){
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy bài nộp"
            });
        }
         return res.status(200).json({
            success: true,
            message: "Lấy bài nộp của học viên thành công",
            data: chiTiet
        });
    }
    catch(err){
        return res.status(500).json({
            success: false,
            message: err.message
        })
    }
})
router.post('/chamdiem/:idSubmission',checkGiangVien,async(req,res)=>{
    try{
        const idSubmission = parseInt(req.params.idSubmission)
        let {diem, nhanXet}=req.body
        diem = parseFloat(diem);
        nhanXet = nhanXet?.trim();
        if (!idSubmission || isNaN(diem)) {
            return res.status(400).json({
                success: false,
                message: "Thiếu idSubmission hoặc điểm không hợp lệ"
            });
        }
        if(diem<0||diem>10){
            return res.status(400).json({
                success: false,
                message: "Điểm phải từ 0-10 điểm"
            });
        }
        if(!diem){
            return res.status(400).json({
                success: false,
                message: "Thiếu điểm"
            })
        }
        const tonTaiBT = await prisma.submissions.findUnique({
            where:{
                idSubmission: idSubmission
            }
        })
        if(!tonTaiBT){
            return res.status(404).json({
                success: false,
                message: "Không tồn tại bài nộp này"
            });
        }
        const grade = await prisma.grades.upsert({
            where:{
                idSubmission: idSubmission
            },
            update:{
                diem: diem,
                nhanXet: nhanXet,
                ngayCham: new Date()
            },
            create:{
                idSubmission: idSubmission,
                diem: diem,
                nhanXet: nhanXet,
                ngayCham: new Date()
            }
        })
        return res.status(200).json({
            success: true,
            message: "Chấm điểm thành công",
            data: grade
        })
    }
    catch(err){
        return res.status(500).json({
            success: false,
            message: err.message
        })
    }
})
export default router