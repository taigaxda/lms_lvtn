import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkHocVien } from '../middleware.js'

const router = express.Router()

router.get('/dsquiz/:idKhoaHoc', checkHocVien, async (req, res) => {
    try {
        const idNguoiDung = req.user.idNguoiDung
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        const dangKy = await prisma.dangky_khoahoc.findFirst({
            where: {
                idNguoiDung,
                idKhoaHoc
            }
        });
        if (!dangKy) {
            return res.status(403).json({
                success: false,
                message: "Bạn chưa đăng ký khóa học"
            });
        }
        const quizzes = await prisma.quizzes.findMany({
            where: {
                idKhoaHoc
            },
            include: {
                quiz_results: {
                    where: {
                        idNguoiDung
                    }
                }
            }
        });
        const result = quizzes.map(q => ({
            idQuiz: q.idQuiz,
            tenQuiz: q.tenQuiz,
            thoiGianLamBai: q.thoiGianLamBai,
            daLam: q.quiz_results.length > 0,
            diem: q.quiz_results[0]?.diemSo || null
        }));

        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        res.status(500).json({ error: error.message })
    }
})
router.get('/baikiemtra/:idQuiz', checkHocVien, async (req, res) => {
    try {
        const idNguoiDung = req.user.idNguoiDung;
        const idQuiz = parseInt(req.params.idQuiz);
        if (isNaN(idQuiz)) {
            return res.status(400).json({
                success: false,
                message: "ID bài kiểm tra không hợp lệ"
            });
        }
        const quiz = await prisma.quizzes.findUnique({
            where: { idQuiz },
            include: {
                khoahoc: true,
                quiz_questions: true
            }
        });
        if (!quiz) {
            return res.status(404).json({
                success: false,
                message: "Bài kiểm tra không tồn tại"
            });
        }
        const dangKy = await prisma.dangky_khoahoc.findFirst({
            where: {
                idNguoiDung,
                idKhoaHoc: quiz.idKhoaHoc
            }
        });
        if (!dangKy) {
            return res.status(403).json({
                success: false,
                message: "Bạn chưa đăng ký lớp học"
            });
        }
        const daLam = await prisma.quiz_results.findFirst({
            where: {
                idNguoiDung,
                idQuiz
            }
        });
        if (daLam) {
            return res.status(400).json({
                success: false,
                message: "Bạn đã làm bài rồi"
            });
        }
        const questions = quiz.quiz_questions.map(q => {
            const data = JSON.parse(q.cauHoi);
            return {
                idCauHoi: q.idCauHoi,
                question: data.question,
                A: data.A,
                B: data.B,
                C: data.C,
                D: data.D
            };
        });
        res.json({
            success: true,
            data: {
                idQuiz: quiz.idQuiz,
                tenQuiz: quiz.tenQuiz,
                thoiGianLamBai: quiz.thoiGianLamBai,
                questions
            }
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/chualam', checkHocVien, async (req, res) => {
  try {
    const idNguoiDung = req.user.idNguoiDung;
    const data = await prisma.khoahoc.findMany({
      where: {
        dangky_khoahoc: {
          some: { idNguoiDung }
        }
      },
      select: {
        idKhoaHoc: true,
        tenKhoaHoc: true,
        quizzes: {
          where: {
            quiz_results: {
              none: { idNguoiDung }
            }
          },
          select: {
            idQuiz: true,
            tenQuiz: true,
            thoiGianLamBai: true
          }
        }
      }
    });
    res.json({
      success: true,
      data: data
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

router.post('/:idQuiz/nopbai', checkHocVien, async (req, res) => {
    try {
        const idNguoiDung = req.user.idNguoiDung
        const idQuiz = parseInt(req.params.idQuiz)
        const { answers } = req.body
        if (isNaN(idQuiz)) {
            return res.status(400).json({
                success: false,
                message: "ID bài kiểm tra không hợp lệ"
            });
        }
        const quiz = await prisma.quizzes.findUnique({
            where: { idQuiz },
            include: {
                khoahoc: true,
                quiz_questions: true
            }
        });
        if (!quiz) {
            return res.status(404).json({
                success: false,
                message: "Bài kiểm tra không tồn tại"
            });
        }
        const dangKy = await prisma.dangky_khoahoc.findFirst({
            where: {
                idNguoiDung,
                idKhoaHoc: quiz.idKhoaHoc
            }
        });

        if (!dangKy) {
            return res.status(403).json({
                success: false,
                message: "Bạn chưa đăng ký khóa học"
            });
        }
        const daLam = await prisma.quiz_results.findFirst({
            where: {
                idNguoiDung,
                idQuiz
            }
        });
        if (daLam) {
            return res.status(400).json({
                success: false,
                message: "Bạn đã làm bài kiểm tra này rồi"
            });
        }
        let tongDiem = 0;
        if (!answers) {
            return res.status(400).json({
                success: false,
                message: "Thiếu đáp án"
            });
        }
        for (const q of quiz.quiz_questions) {
            const dapAn = answers[q.idCauHoi];
            if (dapAn && dapAn === q.dapAnDung) {
                tongDiem += Number(q.diemCauHoi);
            }
        }

        const ketqua = await prisma.quiz_results.create({
            data: {
                idNguoiDung,
                idQuiz,
                diemSo: tongDiem,
                thoiGianLamBai: quiz.thoiGianLamBai
            }
        })
        res.json({
            success: true,
            message: "Nộp bài thành công",
            data: {
                diem: ketqua.diemSo,
                idKetQua: ketqua.idKetQua
            }
        });
    }
    catch (error) {
        res.status(500).json({ error: error.message })
    }
})
export default router
