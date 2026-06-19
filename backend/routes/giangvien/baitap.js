import express from 'express'
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { prisma } from '../../prisma/client.js'
import { checkGiangVien } from '../middleware.js'
import { uploadToCloudinary } from './ggHelper.js'; 

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