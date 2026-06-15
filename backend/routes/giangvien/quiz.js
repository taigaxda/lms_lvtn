import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkGiangVien } from '../middleware.js'

const router = express.Router()

router.get('/:idKhoaHoc', checkGiangVien, async (req, res) => {
    try {
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        const idGiangVien = req.user.idNguoiDung
        if (isNaN(idKhoaHoc)) {
            return res.status(400).json({
                success: false,
                error: "ID khóa học không hợp lệ"
            });
        }
        const lophoc = await prisma.khoahoc.findFirst({
            where: {
                idGiangVien: idGiangVien,
                idKhoaHoc: idKhoaHoc
            }
        });
        if (!lophoc) {
            return res.status(403).json({
                success: false,
                error: "Bạn không có quyền"
            });
        }
        const quizzes = await prisma.quizzes.findMany({
            where: {
                idKhoaHoc: idKhoaHoc
            },
            include: {
                questions: {
                    include:{
                        answers: true
                    }
                }
            },
            orderBy: {
                idQuiz: 'desc'
            }
        });
        res.json({
            success: true,
            data: quizzes
        });
    }
    catch (err) {
        res.status(500).json({
            error: err.message
        });
    }
})
router.get('/diemhv/:idQuiz', checkGiangVien, async (req, res) => {
    try {
        const idGiangVien = req.user.idNguoiDung
        const idQuiz = parseInt(req.params.idQuiz)
        const quiz = await prisma.quizzes.findFirst({
            where: {
                idQuiz,
                khoahoc: {
                    idGiangVien
                }
            },
            include: {
                khoahoc: true
            }
        })
        if (!quiz) {
            return res.status(403).json({
                success: false,
                message: "Không có quyền xem điểm"
            })
        }
        const idKhoaHoc = quiz.khoahoc.idKhoaHoc
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
        })
        const results = await prisma.quiz_results.findMany({
            where: { idQuiz }
        })
        const mapKetQua = new Map()
        results.forEach(r => {
            mapKetQua.set(r.idNguoiDung, r)
        })
        const finalData = hocViens.map(hv => {
            const kq = mapKetQua.get(hv.idNguoiDung)
            return {
                idNguoiDung: hv.idNguoiDung,
                hoTen: hv.nguoidung.hoTen,
                email: hv.nguoidung.email,
                diemSo: kq ? Number(kq.diemSo) : null,
                trangThai: kq ? "Đã làm" : "Chưa làm",
                ngayLamBai: kq ? kq.ngayLamBai : null
            }
        })
        finalData.sort((a, b) => {
            if (a.diemSo == null) return 1
            if (b.diemSo == null) return -1
            return b.diemSo - a.diemSo
        })
        res.json({
            success: true,
            data: finalData
        })
    }
    catch (err) {
        res.status(500).json({
            error: err.message
        });
    }

})
router.post('/', checkGiangVien, async (req, res) => {
    try {
        let { tenQuiz, thoiGianLamBai, ngayDenHan, idKhoaHoc } = req.body;
        tenQuiz = tenQuiz?.trim();
        if (!tenQuiz || !idKhoaHoc) {
            return res.status(400).json({
                success: false,
                error: "Thiếu thông tin"
            });
        }
        if (thoiGianLamBai !== undefined) {
            if (isNaN(thoiGianLamBai)) {
                return res.status(400).json({
                    success: false,
                    error: "Thời gian phải là số"
                });
            }
            thoiGianLamBai = parseInt(thoiGianLamBai);
        }
        let parsedNgayDenHan = null;
        if (ngayDenHan && ngayDenHan !== "") {
            const deadline = new Date(ngayDenHan);
            const now = new Date();

            if (isNaN(deadline.getTime())) {
                return res.status(400).json({
                    success: false,
                    error: "Ngày đến hạn không hợp lệ"
                });
            }

            if (deadline <= now) {
                return res.status(400).json({
                    success: false,
                    error: "Ngày đến hạn phải lớn hơn hiện tại"
                });
            }

            parsedNgayDenHan = deadline;
        }
        const idGiangVien = req.user.idNguoiDung;
        const lophoc = await prisma.khoahoc.findFirst({
            where: {
                idKhoaHoc,
                idGiangVien
            }
        });
        if (!lophoc) {
            return res.status(403).json({
                success: false,
                error: "Bạn không có quyền"
            });
        }
        const quiz = await prisma.quizzes.create({
            data: {
                tenQuiz,
                thoiGianLamBai,
                ngayDenHan: parsedNgayDenHan,
                idKhoaHoc
            }
        });
        res.json({
            success: true,
            data: quiz
        });
    } catch (err) {
        res.status(500).json({
            error: err.message
        });
    }
})

router.post('/:idQuiz/cauhoi', checkGiangVien, async (req, res) => {
    try {
        const idQuiz = parseInt(req.params.idQuiz);
        const { tongDiem = 10, questions } = req.body;
        if (!questions || questions.length === 0) {
            return res.status(400).json({
                success: false,
                error: "Phải có ít nhất 1 câu hỏi"
            })
        }
        const quiz = await prisma.quizzes.findUnique({
            where: {
                idQuiz: idQuiz
            }
        })
        if (!quiz) {
            return res.status(404).json({
                success: false,
                error: "Quiz không tồn tại"
            })
        }
        const soCauHienTai= await prisma.quiz_questions.count({
            where:{
                idQuiz
            }
        })
        const tongSoCau = soCauHienTai+ questions.length
        const diemMoiCauHoi = tongDiem / tongSoCau;
        await prisma.quiz_questions.updateMany({
            where: { idQuiz },
            data: { diemCauHoi: diemMoiCauHoi }
        });
        for (const q of questions) {
            const validAnswers = (q.answers || []).filter(a => a.noiDung && a.noiDung.trim() !== "");
            if (validAnswers.length < 4) {
                return res.status(400).json({
                    success: false,
                    error: "Mỗi câu hỏi phải có ít nhất 4 đáp án hợp lệ"
                });
            }
            if (!validAnswers.some(a => a.laDung)) {
                return res.status(400).json({
                    success: false,
                    error: "Mỗi câu hỏi phải có ít nhất 1 đáp án đúng"
                });
            }
            q.answers = validAnswers;
        }
        const result = await prisma.$transaction(
            questions.map(q => prisma.quiz_questions.create({
                data: {
                    cauHoi: q.cauHoi,
                    diemCauHoi: diemMoiCauHoi,
                    quizzes: {
                        connect:
                        {
                            idQuiz
                        }
                    },
                    answers: {
                        create: q.answers.map(a => ({
                            noiDung: a.noiDung.trim(),
                            laDung: a.laDung
                        }))
                    }
                },
                include: {
                    answers: true
                }
            }))
        )
        res.json({
            success: true,
            message: "Tạo câu hỏi thành công",
            tongDiem,
            diemMoiCauHoi,
            soCau: result.length,
            data: result
        })
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});
router.put('/cauhoi/:idCauHoi', checkGiangVien, async (req, res) => {
    try {
        const idCauHoi = parseInt(req.params.idCauHoi);
        const { cauHoi, answers } = req.body;
        const existing = await prisma.quiz_questions.findUnique({
            where: { idCauHoi },
            include: {
                quizzes: {
                    include: { khoahoc: true }
                },
                answers: true
            }
        });
        if (!existing) {
            return res.status(404).json({
                success: false,
                error: "Câu hỏi không tồn tại"
            })
        }
        const validAnswers = answers.filter(a => a.noiDung && a.noiDung.trim() !== "");

        if (validAnswers.length < 4) {
            return res.status(400).json({
                success: false,
                error: "Phải có ít nhất 4 đáp án hợp lệ"
            });
        }

        if (!validAnswers.some(a => a.laDung)) {
            return res.status(400).json({ success: false, error: "Phải có đáp án đúng" });
        }
        const result = await prisma.$transaction(async (tx) => {
            const idsGuiLen = validAnswers.filter(a => a.idDapAn).map(a => a.idDapAn);
            await tx.quiz_answers.deleteMany({
                where: {
                    idCauHoi,
                    idDapAn: { notIn: idsGuiLen.length ? idsGuiLen : [0] }
                }
            });
            for (const a of validAnswers) {
                if (a.idDapAn) {
                    await tx.quiz_answers.update({
                        where: { idDapAn: a.idDapAn },
                        data: {
                            noiDung: a.noiDung,
                            laDung: a.laDung
                        }
                    })
                }
                else {
                    await tx.quiz_answers.create({
                        data: {
                            noiDung: a.noiDung,
                            laDung: a.laDung,
                            idCauHoi
                        }
                    })
                }
            }
            return await tx.quiz_questions.update({
                where: { idCauHoi },
                data: {
                    cauHoi: cauHoi ?? existing.cauHoi
                },
                include: {
                    answers: true
                }
            })
        })
        res.json({
            success: true,
            message: "Update thành công",
            data: result
        })
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});
router.delete('/cauhoi/:idCauHoi', checkGiangVien, async (req, res) => {
    try {
        const idCauHoi = parseInt(req.params.idCauHoi);
        const cauHoi = await prisma.quiz_questions.findUnique({
            where: { idCauHoi },
            include: {
                quizzes: {
                    include: { khoahoc: true }
                }
            }
        });
        if (!cauHoi) {
            return res.status(404).json({
                success: false,
                error: "Không tìm thấy câu hỏi"
            });
        }
        const idQuiz = cauHoi.idQuiz;
        const quiz = await prisma.quizzes.findUnique({
            where:
            {
                idQuiz
            }
        });
        await prisma.$transaction(async (tx) => {
            await tx.quiz_questions.delete({
                where: { idCauHoi }
            });
            const conLai = await tx.quiz_questions.count({
                where: { idQuiz }
            });
            if (conLai > 0) {
                const diemMoiCau = Number((10 / conLai).toFixed(2));

                await tx.quiz_questions.updateMany({
                    where: { idQuiz },
                    data: { diemCauHoi: diemMoiCau }
                });
            }
        });
        res.json({
            success: true,
            message: "Xoá câu hỏi thành công"
        });
    } catch (err) {
        console.error("DELETE ERROR:", err);
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});
router.put('/:idQuiz', checkGiangVien, async (req, res) => {
    try {
        const idQuiz = parseInt(req.params.idQuiz);
        let { tenQuiz, thoiGianLamBai, ngayDenHan } = req.body;
        if (isNaN(idQuiz)) {
            return res.status(400).json({
                success: false,
                error: "idQuiz không hợp lệ"
            });
        }
        const quiz = await prisma.quizzes.findUnique({
            where: { idQuiz },
            include: { khoahoc: true }
        });
        if (tenQuiz !== undefined) {
            tenQuiz = tenQuiz.trim();
            if (!tenQuiz) {
                return res.status(400).json({
                    success: false,
                    error: "Tên quiz không hợp lệ"
                });
            }
        }
        if (thoiGianLamBai !== undefined) {
            if (isNaN(thoiGianLamBai)) {
                return res.status(400).json({
                    success: false,
                    error: "Thời gian phải là số"
                });
            }
            thoiGianLamBai = parseInt(thoiGianLamBai);
            if (thoiGianLamBai <= 0) {
                return res.status(400).json({
                    success: false,
                    error: "Thời gian phải > 0"
                });
            }
        }
        let parsedNgayDenHan;
        if (ngayDenHan !== undefined) {
            if(ngayDenHan === null || ngayDenHan === "") {
                parsedNgayDenHan = null;
            }
            else{
                 const deadline = new Date(ngayDenHan);

                if (isNaN(deadline.getTime())) {
                    return res.status(400).json({
                        success: false,
                        error: "Ngày không hợp lệ"
                    });
                }

                if (deadline <= quiz.ngayTao) {
                    return res.status(400).json({
                        success: false,
                        error: "Ngày đến hạn phải lớn hơn ngày tạo"
                    });
                }

                parsedNgayDenHan = deadline;
            }
        }
        
        if (!quiz) {
            return res.status(404).json({
                success: false,
                error: "Quiz không tồn tại"
            });
        }
        const updatedQuiz = await prisma.quizzes.update({
            where: { idQuiz },
            data: {
                ...(tenQuiz !== undefined && { tenQuiz }),
                ...(thoiGianLamBai !== undefined && { thoiGianLamBai }),
                ...(ngayDenHan !== undefined && { ngayDenHan: parsedNgayDenHan })
            }
        });
        res.json({
            success: true,
            message: "Cập nhật quiz thành công",
            data: updatedQuiz
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
});
router.delete('/:idQuiz', checkGiangVien, async (req, res) => {
    try {
        const idQuiz = parseInt(req.params.idQuiz);
        if (isNaN(idQuiz)) {
            return res.status(400).json({
                success: false,
                error: "idQuiz không hợp lệ"
            });
        }
        const quiz = await prisma.quizzes.findUnique({
            where: { idQuiz },
            include: { khoahoc: true }
        });
        if (!quiz) {
            return res.status(404).json({
                success: false,
                error: "Quiz không tồn tại"
            });
        }
        await prisma.quizzes.delete({
            where: { idQuiz }
        });
        res.json({
            success: true,
            message: "Xoá quiz thành công"
        });
    } catch (err) {
        res.status(500).json({
            success: false,
            error: err.message
        });
    }
})

export default router