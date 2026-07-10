import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkHocVien } from '../middleware.js'
import { askAI, getDailyTasks, getSuggestedQuestions } from '../aiHelper.js'

const router = express.Router()

async function lopHocCuaHocVien(idNguoiDung) {
    const thamGia = await prisma.dangky_khoahoc.findMany({
        where: {
            idNguoiDung: idNguoiDung
        },
        select: {
            idKhoaHoc: true
        }
    })
    return thamGia.map(item => item.idKhoaHoc)
}

async function thongTin(idNguoiDung) {
    const dsIdKhoaHoc = await lopHocCuaHocVien(idNguoiDung)
    const homNay = new Date()
    const threeDaysLater = new Date(homNay.getTime() + 3 * 24 * 60 * 60 * 1000)

    const dsTB = await prisma.announcements.findMany({
        where: {
            idKhoaHoc: {
                in: dsIdKhoaHoc
            },
            ngayTao: {
                gte: new Date(homNay.getTime() - 7 * 24 * 60 * 60 * 1000)
            },
            loaiThongBao: 'thong_bao'
        },
        orderBy: {
            ngayTao: 'desc'
        },
        take: 5,
        include: {
            khoahoc: {
                select: {
                    tenKhoaHoc: true
                }
            }
        }
    })

    const baiTap = await prisma.assignments.findMany({
        where: {
            khoahoc: {
                idKhoaHoc: { in: dsIdKhoaHoc }
            },
            hanNop: {
                gte: homNay,
                lte: threeDaysLater
            }
        },
        include: {
            khoahoc: {
                select: {
                    tenKhoaHoc: true
                }
            }
        },
        take: 5
    })

    const quizChuaLam = await prisma.quizzes.findMany({
        where: {
            idKhoaHoc: { in: dsIdKhoaHoc },
            ngayDenHan: {
                gte: homNay
            },
            results: {
                none: {
                    idNguoiDung: idNguoiDung
                }
            }
        },
        include: {
            khoahoc: { select: { tenKhoaHoc: true } }
        },
        take: 5
    })

    const baiHocChuaHoanThanh = await prisma.baihoc.findMany({
        where: {
            khoahoc: {
                idKhoaHoc: { in: dsIdKhoaHoc }
            },
            NOT: {
                progress: {
                    some: {
                        idNguoiDung: idNguoiDung,
                        trangThai: 'hoan_thanh'
                    }
                }
            }
        },
        include: {
            khoahoc: { select: { tenKhoaHoc: true } },
            progress: {
                where: { idNguoiDung: idNguoiDung },
                select: { trangThai: true, thoiGianHoc: true }
            }
        },
        orderBy: {
            thuTu: 'asc'
        }
    })

    const baiHocDangHoc = baiHocChuaHoanThanh.filter(b =>
        b.progress.some(p => p.trangThai === 'dang_hoc')
    )
    const baiHocChuaHoc = baiHocChuaHoanThanh.filter(b =>
        b.progress.length === 0 || b.progress.every(p => p.trangThai === 'chua_hoc')
    )

    let context = `
    HÔM NAY: ${homNay.toLocaleDateString('vi-VN')}

    THÔNG BÁO MỚI (${dsTB.length} thông báo):
    ${dsTB.map(tb => `- ${tb.tieuDe}: ${tb.noiDung} (${tb.khoahoc?.tenKhoaHoc || 'Chung'})`).join('\n') || 'Không có thông báo mới.'}

    BÀI TẬP SẮP ĐẾN HẠN (${baiTap.length} bài):
    ${baiTap.map(bt => `- ${bt.tieuDe} (${bt.khoahoc.tenKhoaHoc}) - Hạn: ${new Date(bt.hanNop).toLocaleDateString('vi-VN')}`).join('\n') || 'Không có bài tập sắp đến hạn.'}

    QUIZ CHƯA LÀM (${quizChuaLam.length} bài):
    ${quizChuaLam.map(q => `- ${q.tenQuiz} (${q.khoahoc.tenKhoaHoc}) - Hạn: ${q.ngayDenHan ? new Date(q.ngayDenHan).toLocaleDateString('vi-VN') : 'Chưa có hạn'}`).join('\n') || 'Không có quiz nào.'}

    BÀI HỌC ĐANG HỌC (${baiHocDangHoc.length} bài):
    ${baiHocDangHoc.map(b => `- ${b.tenBaiHoc} (${b.khoahoc.tenKhoaHoc}) - Đang học`).join('\n') || 'Không có bài học đang học.'}

    BÀI HỌC CHƯA HỌC (${baiHocChuaHoc.length} bài):
    ${baiHocChuaHoc.map(b => `- ${b.tenBaiHoc} (${b.khoahoc.tenKhoaHoc}) - Chưa học`).join('\n') || 'Chúc mừng! Bạn đã học tất cả bài học.'}
    `

    return context
}

router.get('/dexuat', checkHocVien, async (req, res) => {
    try {
        const idNguoiDung = req.user.idNguoiDung
        const context = await thongTin(idNguoiDung)

        const questions = await getSuggestedQuestions(context)

        res.json({
            success: true,
            data: questions
        })

    } catch (error) {
        console.error('Lỗi đề xuất câu hỏi:', error)
        res.json({
            success: true,
            data: [
                { question: 'Hôm nay có gì cần lưu ý?' },
                { question: 'Deadline nào sắp tới?' },
                { question: 'Nên học bài nào trước?' },
                { question: 'Có thông báo mới nào không?' },
                { question: 'Hôm nay nên làm gì?' }
            ]
        })
    }
})

router.post('/ask', checkHocVien, async (req, res) => {
    try {
        const idNguoiDung = req.user.idNguoiDung
        const { question } = req.body

        if (!question) {
            return res.status(400).json({
                success: false,
                message: 'Vui lòng nhập câu hỏi'
            })
        }

        const context = await thongTin(idNguoiDung)
        const answer = await askAI(question, context)

        res.json({
            success: true,
            data: {
                question: question,
                answer: answer
            }
        })

    } catch (error) {
        console.error('Lỗi AI:', error)
        res.status(500).json({
            success: false,
            message: error.message
        })
    }
})

router.get('/daily-tasks', checkHocVien, async (req, res) => {
    try {
        const idNguoiDung = req.user.idNguoiDung
        const dsIdKhoaHoc = await lopHocCuaHocVien(idNguoiDung)
        const homNay = new Date()
        const threeDaysLater = new Date(homNay.getTime() + 3 * 24 * 60 * 60 * 1000)

        const [baiHocChuaHoc, baiTapChuaNop, quizChuaLam, thongBaoMoi] = await Promise.all([
            prisma.progress.count({
                where: {
                    idNguoiDung,
                    trangThai: { in: ['chua_hoc', 'dang_hoc'] }
                }
            }),
            prisma.assignments.count({
                where: {
                    khoahoc: { idKhoaHoc: { in: dsIdKhoaHoc } },
                    hanNop: { gte: homNay, lte: threeDaysLater }
                }
            }),
            prisma.quizzes.count({
                where: {
                    khoahoc: { idKhoaHoc: { in: dsIdKhoaHoc } },
                    ngayDenHan: { gte: homNay },
                    results: { none: { idNguoiDung: idNguoiDung } }
                }
            }),
            prisma.announcements.count({
                where: {
                    idKhoaHoc: { in: dsIdKhoaHoc },
                    ngayTao: { gte: new Date(homNay.getTime() - 7 * 24 * 60 * 60 * 1000) }
                }
            })
        ])

        const studentData = {
            baiHocChuaHoc: baiHocChuaHoc,
            baiTapChuaNop: baiTapChuaNop,
            quizChuaLam: quizChuaLam,
            thongBaoMoi: thongBaoMoi
        }

        const suggestion = await getDailyTasks(studentData)

        res.json({
            success: true,
            data: {
                suggestion: suggestion,
                summary: studentData
            }
        })

    } catch (error) {
        console.error('Lỗi đề xuất công việc:', error)
        res.status(500).json({
            success: false,
            message: error.message
        })
    }
})

export default router