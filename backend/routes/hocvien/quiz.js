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
                results: {
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
            ngayDenHan: q.ngayDenHan,
            daLam: q.results.length > 0,
            diem: q.results[0]?.diemSo || null
        }));

        res.json({
            success: true,
            data: result
        });
    } catch (error) {
        res.status(500).json({ error: error.message })
    }
})

function randomCauHoi(arr) {
    const array = [...arr];
    for (let i = array.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [array[i], array[j]] = [array[j], array[i]];
    }
    return array;
}
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
                questions: {
                    include: {
                        answers: true
                    }
                }
            }
        });
        if (!quiz) {
            return res.status(404).json({
                success: false,
                message: "Bài kiểm tra không tồn tại"
            });
        }
        if (!quiz.questions || quiz.questions.length === 0) {
            return res.status(400).json({
                success: false,
                message: "Bài kiểm tra chưa có câu hỏi. Vui lòng quay lại sau."
            });
        }
        for (const question of quiz.questions) {
            if (!question.answers || question.answers.length === 0) {
                return res.status(400).json({
                    success: false,
                    message: `Câu hỏi "${question.cauHoi}" chưa có đáp án. Vui lòng quay lại sau.`
                });
            }
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
        if (quiz.ngayDenHan && new Date() > new Date(quiz.ngayDenHan)) {
            return res.status(400).json({
                success: false,
                message: "Bài kiểm tra dã quá hạn"
            })
        }
        const questions = randomCauHoi(
            quiz.questions.map(q => ({
                idCauHoi: q.idCauHoi,
                cauHoi: q.cauHoi,
                diemCauHoi: q.diemCauHoi,
                answers: randomCauHoi(
                    q.answers.map(a => ({
                        idDapAn: a.idDapAn,
                        noiDung: a.noiDung
                    })))
            }))
        );
        res.json({
            success: true,
            data: {
                idQuiz: quiz.idQuiz,
                tenQuiz: quiz.tenQuiz,
                thoiGianLamBai: quiz.thoiGianLamBai,
                ngayDenHan: quiz.ngayDenHan,
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
                },
                quizzes: {
                    some: {
                        results: {
                            none: {
                                idNguoiDung: idNguoiDung
                            }
                        }
                    }
                }
            },
            select: {
                idKhoaHoc: true,
                tenKhoaHoc: true,
                quizzes: {
                    where: {
                        results: {
                            none: {
                                idNguoiDung: idNguoiDung
                            }
                        }
                    },
                    select: {
                        idQuiz: true,
                        tenQuiz: true,
                        thoiGianLamBai: true,
                        ngayDenHan: true,
                    },
                    orderBy: {
                        ngayTao: 'desc'
                    }
                }
            }
        });
        const filteredData = data.filter(khoaHoc => khoaHoc.quizzes.length > 0);

        res.json({
            success: true,
            data: filteredData,
            total: filteredData.length
        });

    } catch (error) {
        console.error("Lỗi lấy quiz chưa làm:", error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

// router.post('/:idQuiz/nopbai', checkHocVien, async (req, res) => {
//     try {
//         const idNguoiDung = req.user.idNguoiDung
//         const idQuiz = parseInt(req.params.idQuiz)
//         const { answers } = req.body
//         if (isNaN(idQuiz)) {
//             return res.status(400).json({
//                 success: false,
//                 message: "ID bài kiểm tra không hợp lệ"
//             });
//         }
//         if (!Array.isArray(answers)) {
//             return res.status(400).json({
//                 success: false,
//                 message: "Format answers phải là array"
//             });
//         }
//         const quiz = await prisma.quizzes.findUnique({
//             where: { idQuiz },
//             include: {
//                 khoahoc: true,
//                 questions:{
//                     include:{
//                         answers: true
//                     }
//                 }
//             }
//         });
//         if (!quiz) {
//             return res.status(404).json({
//                 success: false,
//                 message: "Bài kiểm tra không tồn tại"
//             });
//         }
//         const dangKy = await prisma.dangky_khoahoc.findFirst({
//             where: {
//                 idNguoiDung,
//                 idKhoaHoc: quiz.idKhoaHoc
//             }
//         });

//         if (!dangKy) {
//             return res.status(403).json({
//                 success: false,
//                 message: "Bạn chưa đăng ký khóa học"
//             });
//         }
//         const daLam = await prisma.quiz_results.findFirst({
//             where: {
//                 idNguoiDung,
//                 idQuiz
//             }
//         });
//         if (daLam) {
//             return res.status(400).json({
//                 success: false,
//                 message: "Bạn đã làm bài kiểm tra này rồi"
//             });
//         }
//         if (quiz.ngayDenHan && new Date() > new Date(quiz.ngayDenHan)) {
//             return res.status(400).json({
//                 success: false,
//                 message: "Đã quá hạn nộp bài"
//             });
//         }
//         const questionsIds = quiz.questions.map(q=>q.idCauHoi)
//         const answeredIds = answers.map(a=>a.idCauHoi);
//         const missing = questionsIds.filter(id=>!answeredIds.includes(id));
//         if(missing.length>0){
//             return res.status(400).json({
//                 success: false,
//                 message: "Bạn chưa trả lời hết tất cả câu hỏi",
//                 issingQuestions: missing
//             })
//         }
//         const uniqueAnswered = new Set(answeredIds);
//         if (uniqueAnswered.size !== answeredIds.length) {
//             return res.status(400).json({
//                 success: false,
//                 message: "Có câu trả lời bị trùng"
//             });
//         }
//         const answerMap = {};
//         for (const a of answers){
//             answerMap[a.idCauHoi]=a.idDapAn
//         }
//         let tongDiem = 0;
//         for (const q of quiz.questions) {
//             const userAnswerId = answerMap[q.idCauHoi];
//             if(!userAnswerId)
//                 continue;
//             const dapAnDung = q.answers.find(a=>a.laDung === true);
//             if(dapAnDung&&dapAnDung.idDapAn===userAnswerId){
//                 tongDiem+=Number(q.diemCauHoi);
//             }
//         }

//         const ketqua = await prisma.quiz_results.create({
//             data: {
//                 idNguoiDung,
//                 idQuiz,
//                 diemSo: tongDiem,
//                 thoiGianLamBai: quiz.thoiGianLamBai
//             }
//         })
//         res.json({
//             success: true,
//             message: "Nộp bài thành công",
//             data: {
//                 diem: ketqua.diemSo,
//                 idKetQua: ketqua.idKetQua
//             }
//         });
//     }
//     catch (error) {
//         res.status(500).json({ error: error.message })
//     }
// })

router.post('/:idQuiz/nopbai', checkHocVien, async (req, res) => {
    try {
        const idNguoiDung = req.user.idNguoiDung
        const idQuiz = parseInt(req.params.idQuiz)
        const { answers, thoiGianLamBai, gianLan } = req.body
        
        if (isNaN(idQuiz)) {
            return res.status(400).json({
                success: false,
                message: "ID bài kiểm tra không hợp lệ"
            });
        }
        if (!Array.isArray(answers)) {
            return res.status(400).json({
                success: false,
                message: "Format answers phải là array"
            });
        }
        
        const quiz = await prisma.quizzes.findUnique({
            where: { idQuiz },
            include: {
                khoahoc: true,
                questions: {
                    include: {
                        answers: true
                    }
                }
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
        
        if (quiz.ngayDenHan && new Date() > new Date(quiz.ngayDenHan)) {
            return res.status(400).json({
                success: false,
                message: "Đã quá hạn nộp bài"
            });
        }

        let tongDiem = 0;
        let answerMap = {};

        if (!gianLan) {
            const questionsIds = quiz.questions.map(q => q.idCauHoi);
            const answeredIds = answers.map(a => a.idCauHoi);
            const missing = questionsIds.filter(id => !answeredIds.includes(id));
            
            if (missing.length > 0) {
                return res.status(400).json({
                    success: false,
                    message: "Bạn chưa trả lời hết tất cả câu hỏi",
                    missingQuestions: missing
                });
            }
            
            const uniqueAnswered = new Set(answeredIds);
            if (uniqueAnswered.size !== answeredIds.length) {
                return res.status(400).json({
                    success: false,
                    message: "Có câu trả lời bị trùng"
                });
            }
            
            for (const a of answers) {
                answerMap[a.idCauHoi] = a.idDapAn;
            }
            
            for (const q of quiz.questions) {
                const userAnswerId = answerMap[q.idCauHoi];
                if (!userAnswerId) continue;
                const dapAnDung = q.answers.find(a => a.laDung === true);
                if (dapAnDung && dapAnDung.idDapAn === userAnswerId) {
                    tongDiem += Number(q.diemCauHoi);
                }
            }
        }
        const thoiGianThucTe = thoiGianLamBai || quiz.thoiGianLamBai || 0;

        const ketqua = await prisma.quiz_results.create({
            data: {
                idNguoiDung,
                idQuiz,
                diemSo: tongDiem,
                thoiGianLamBai: thoiGianThucTe
            }
        })
        
        res.json({
            success: true,
            message: gianLan ? "Bài làm bị hủy do gian lận" : "Nộp bài thành công",
            data: {
                diem: ketqua.diemSo,
                idKetQua: ketqua.idKetQua,
                thoiGianLamBai: ketqua.thoiGianLamBai,
                gianLan: gianLan || false
            }
        })
    }
    catch (error) {
        console.error("Lỗi nộp bài:", error);
        res.status(500).json({ 
            success: false, 
            error: error.message 
        })
    }
})
export default router
