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
                quiz_questions: true
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
        let { tenQuiz, thoiGianLamBai, idKhoaHoc } = req.body;
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
        const idGiangVien = req.user.idNguoiDung;
        const { question, A, B, C, D, dapAnDung } = req.body;
        const quiz = await prisma.quizzes.findUnique({
            where: { idQuiz },
            include: { khoahoc: true, quiz_questions: true }
        });
        if (!quiz || quiz.khoahoc.idGiangVien !== idGiangVien) {
            return res.status(403).json({ error: "Không có quyền" });
        }
        const tongCau = quiz.quiz_questions.length + 1;
        const diemMoiCau = Number((10 / tongCau).toFixed(2));
        let newQuestion;
        await prisma.$transaction(async (tx) => {
            newQuestion = await tx.quiz_questions.create({ // Lưu lại câu hỏi mới
                data: {
                    idQuiz,
                    cauHoi: JSON.stringify({ question, A, B, C, D }),
                    dapAnDung,
                    diemCauHoi: diemMoiCau
                }
            });
            await tx.quiz_questions.updateMany({
                where: { idQuiz },
                data: { diemCauHoi: diemMoiCau }
            });
        });

        res.json({
            success: true,
            data: newQuestion,
            message: "Thêm câu hỏi thành công + chia lại điểm"
        });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});
router.put('/cauhoi/:idCauHoi', checkGiangVien, async (req, res) => {
    try {
        const idCauHoi = parseInt(req.params.idCauHoi);
        const idGiangVien = req.user.idNguoiDung;
        const { question, A, B, C, D, dapAnDung } = req.body;
        const cauHoi = await prisma.quiz_questions.findUnique({
            where: { idCauHoi },
            include: {
                quizzes: {
                    include: { khoahoc: true }
                }
            }
        });
        if (!question || !A || !B || !C || !D || !dapAnDung) {
            return res.status(400).json({
                error: "Thiếu dữ liệu câu hỏi"
            });
        }

        if (!['A', 'B', 'C', 'D'].includes(dapAnDung)) {
            return res.status(400).json({
                error: "Đáp án không hợp lệ"
            });
        }
        if (!cauHoi || cauHoi.quizzes.khoahoc.idGiangVien !== idGiangVien) {
            return res.status(403).json({ error: "Không có quyền" });
        }
        const updated = await prisma.quiz_questions.update({
            where: { idCauHoi },
            data: {
                cauHoi: JSON.stringify({ question, A, B, C, D }),
                dapAnDung
            }
        });

        res.json({
            success: true,
            data: updated
        });

    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});
router.delete('/cauhoi/:idCauHoi', checkGiangVien, async (req, res) => {
    try {
        const idCauHoi = parseInt(req.params.idCauHoi);
        const idGiangVien = req.user.idNguoiDung;
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
        if (!cauHoi.quizzes || !cauHoi.quizzes.khoahoc) {
            return res.status(500).json({
                success: false,
                error: "Dữ liệu quiz bị lỗi"
            });
        }
        if (cauHoi.quizzes.khoahoc.idGiangVien !== idGiangVien) {
            return res.status(403).json({
                success: false,
                error: "Không có quyền"
            });
        }
        const idQuiz = cauHoi.idQuiz;
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
        const idGiangVien = req.user.idNguoiDung;
        let { tenQuiz, thoiGianLamBai } = req.body;
        if (isNaN(idQuiz)) {
            return res.status(400).json({
                success: false,
                error: "idQuiz không hợp lệ"
            });
        }
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
        if (quiz.khoahoc.idGiangVien !== idGiangVien) {
            return res.status(403).json({
                success: false,
                error: "Bạn không có quyền"
            });
        }
        const updatedQuiz = await prisma.quizzes.update({
            where: { idQuiz },
            data: {
                ...(tenQuiz !== undefined && { tenQuiz }),
                ...(thoiGianLamBai !== undefined && { thoiGianLamBai })
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
        const idGiangVien = req.user.idNguoiDung;
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
        if (quiz.khoahoc.idGiangVien !== idGiangVien) {
            return res.status(403).json({
                success: false,
                error: "Bạn không có quyền xoá quiz này"
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