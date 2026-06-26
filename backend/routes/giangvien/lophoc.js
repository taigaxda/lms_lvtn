import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkGiangVien, checkHocVien } from '../middleware.js'

const router = express.Router()

router.get('/', checkGiangVien, async (req, res) => {
    try {
        const idGiangVien = req.user.idNguoiDung;
        const lopHocs = await prisma.khoahoc.findMany({
            where: {
                idGiangVien: idGiangVien,
                trangThai: true
            },
            select: {
                idKhoaHoc: true,
                tenKhoaHoc: true,
                code: true,
                moTa: true,
                danhMuc: true,
            }
        });

        res.status(200).json({
            success: true,
            data: lopHocs
        });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/luutru', checkGiangVien, async (req, res) => {
    try {
        const idGiangVien = req.user.idNguoiDung;
        const lopHocs = await prisma.khoahoc.findMany({
            where: {
                idGiangVien: idGiangVien,
                trangThai: false
            },
            select: {
                idKhoaHoc: true,
                tenKhoaHoc: true,
                code: true,
                moTa: true,
                danhMuc: true,
            }
        });

        res.status(200).json({
            success: true,
            data: lopHocs
        });

    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// router.get('/dashboard', checkGiangVien, async (req, res) => {
//   try {
//     const idGiangVien = req.user.idNguoiDung
//     const totalClasses = await prisma.khoahoc.count({
//       where: { idGiangVien: idGiangVien }
//     })

//     const totalStudents = await prisma.dangky_khoahoc.count({
//       where: {
//         khoahoc: { idGiangVien: idGiangVien }
//       }
//     })

//     const totalLessons = await prisma.baihoc.count({
//       where: {
//         khoahoc: { idGiangVien: idGiangVien }
//       }
//     })

//     const totalQuizzes = await prisma.quizzes.count({
//       where: {
//         khoahoc: { idGiangVien: idGiangVien }
//       }
//     })

//     const recentClasses = await prisma.khoahoc.findMany({
//       where: { idGiangVien: idGiangVien },
//       orderBy: { ngayTao: 'desc' },
//       take: 5,
//       select: {
//         idKhoaHoc: true,
//         tenKhoaHoc: true,
//         code: true,
//         ngayTao: true
//       }
//     })

//     const topClasses = await prisma.khoahoc.findMany({
//       where: { idGiangVien: idGiangVien },
//       include: {
//         _count: {
//           select: { dangky_khoahoc: true }
//         }
//       },
//       orderBy: {
//         dangky_khoahoc: {
//           _count: 'desc'
//         }
//       },
//       take: 5
//     })

//     const progressStats = await prisma.progress.groupBy({
//       by: ['trangThai'],
//       _count: true,
//       where: {
//         khoahoc: { idGiangVien: idGiangVien }
//       }
//     })

//     res.json({
//       overview: {
//         totalClasses,
//         totalStudents,
//         totalLessons,
//         totalQuizzes
//       },
//       recentClasses,
//       topClasses: topClasses.map(c => ({
//         idKhoaHoc: c.idKhoaHoc,
//         tenKhoaHoc: c.tenKhoaHoc,
//         totalStudents: c._count.dangky_khoahoc
//       })),
//       progressStats
//     })

//   } catch (error) {
//     res.status(500).json({ error: error.message })
//   }
// })
router.get('/dashboard', checkGiangVien, async (req, res) => {
  try {
    const idGiangVien = req.user.idNguoiDung;
    const now = new Date();
    const sevenDaysLater = new Date(now.getTime() + 7 * 24 * 60 * 60 * 1000);

    const [
      totalClasses,
      totalStudents,
      totalLessons,
      totalQuizzes,
      totalAssignments,
      pendingSubmissions,
      gradedSubmissions
    ] = await Promise.all([
      prisma.khoahoc.count({ where: { idGiangVien } }),
      prisma.dangky_khoahoc.count({
        where: { khoahoc: { idGiangVien } }
      }),
      prisma.baihoc.count({
        where: { khoahoc: { idGiangVien } }
      }),
      prisma.quizzes.count({
        where: { khoahoc: { idGiangVien } }
      }),
      prisma.assignments.count({
        where: { khoahoc: { idGiangVien } }
      }),
      prisma.submissions.count({
        where: {
          assignment: { khoahoc: { idGiangVien } },
          grades: null
        }
      }),
      prisma.submissions.count({
        where: {
          assignment: { khoahoc: { idGiangVien } },
          grades: { isNot: null }
        }
      })
    ]);

    const recentClasses = await prisma.khoahoc.findMany({
      where: { idGiangVien },
      orderBy: { ngayTao: 'desc' },
      take: 5,
      select: {
        idKhoaHoc: true,
        tenKhoaHoc: true,
        code: true,
        ngayTao: true,
        _count: {
          select: { dangky_khoahoc: true }
        }
      }
    });

    const topClasses = await prisma.khoahoc.findMany({
      where: { idGiangVien },
      include: {
        _count: {
          select: { dangky_khoahoc: true }
        }
      },
      orderBy: {
        dangky_khoahoc: {
          _count: 'desc'
        }
      },
      take: 5
    });

    const progressStats = await prisma.progress.groupBy({
      by: ['trangThai'],
      _count: true,
      where: {
        khoahoc: { idGiangVien }
      }
    });

    const upcomingDeadlines = await prisma.assignments.findMany({
      where: {
        khoahoc: { idGiangVien },
        hanNop: {
          gte: now,
          lte: sevenDaysLater
        }
      },
      orderBy: { hanNop: 'asc' },
      take: 5,
      include: {
        khoahoc: {
          select: {
            tenKhoaHoc: true
          }
        },
        _count: {
          select: { submissions: true }
        }
      }
    });

    const quizzesWithoutResults = await prisma.quizzes.findMany({
      where: {
        khoahoc: { idGiangVien },
        results: {
          none: {}
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
    });
    const avgScores = await prisma.grades.aggregate({
      where: {
        submission: {
          assignment: {
            khoahoc: { idGiangVien }
          }
        }
      },
      _avg: {
        diem: true
      },
      _max: {
        diem: true
      },
      _min: {
        diem: true
      }
    });

    res.json({
      success: true,
      overview: {
        totalClasses,
        totalStudents,
        totalLessons,
        totalQuizzes,
        totalAssignments,
        pendingSubmissions,
        gradedSubmissions
      },
      recentClasses: recentClasses.map(c => ({
        idKhoaHoc: c.idKhoaHoc,
        tenKhoaHoc: c.tenKhoaHoc,
        code: c.code,
        ngayTao: c.ngayTao,
        totalStudents: c._count.dangky_khoahoc
      })),
      topClasses: topClasses.map(c => ({
        idKhoaHoc: c.idKhoaHoc,
        tenKhoaHoc: c.tenKhoaHoc,
        totalStudents: c._count.dangky_khoahoc
      })),
      progressStats: progressStats.map(p => ({
        trangThai: p.trangThai,
        count: p._count
      })),
      upcomingDeadlines: upcomingDeadlines.map(a => ({
        idAssignment: a.idAssignment,
        tieuDe: a.tieuDe,
        hanNop: a.hanNop,
        tenKhoaHoc: a.khoahoc.tenKhoaHoc,
        totalSubmissions: a._count.submissions
      })),
      quizzesWithoutResults: quizzesWithoutResults.map(q => ({
        idQuiz: q.idQuiz,
        tenQuiz: q.tenQuiz,
        tenKhoaHoc: q.khoahoc.tenKhoaHoc
      })),
      avgScores: {
        avg: avgScores._avg.diem || 0,
        max: avgScores._max.diem || 0,
        min: avgScores._min.diem || 0
      }
    });

  } catch (error) {
    console.error("Lỗi Dashboard:", error);
    res.status(500).json({ 
      success: false,
      error: error.message 
    });
  }
});

router.get('/:id', checkGiangVien, async (req, res) => {
    try{
        const id = parseInt(req.params.id)
        const idGiangVien = req.user.idNguoiDung;
        const lopHoc = await prisma.khoahoc.findUnique({
            where: { idKhoaHoc: id },
            include: {
                nguoidung:{
                    select: {
                        hoTen: true
                    },
                },
            }
        })  
        if (!lopHoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy khóa học"
            })
        }
        if(lopHoc.idGiangVien !== idGiangVien){
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền xem chi tiết khóa học này"
            });
        }
        res.json({
            success: true,
            data: lopHoc
        });
    } catch (error) {
        res.status(500).json({ error: error.message })
    }
})

function taoCodeLopHoc(length = 6) {
    const char = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    let result = ''
    for (let i = 0; i < length; i++) {
        result += char.charAt(Math.floor(Math.random() * char.length))
    }
    return result
}

async function taoCodeUnique() {
    let code;
    let tonTai = true;
    while(tonTai){
        code = taoCodeLopHoc()
        const kiemTra = await prisma.khoahoc.findUnique({
            where: { code }
        })
        if(!kiemTra){
            tonTai = false
        }
    }
    return code;
}

router.post('/', checkGiangVien, async (req, res) => {
    try{
        let { tenKhoaHoc, moTa, danhMuc } = req.body
        tenKhoaHoc = tenKhoaHoc ? tenKhoaHoc.trim() : undefined
        moTa = moTa ? moTa.trim() : undefined
        danhMuc = danhMuc ? danhMuc.trim() : undefined
        if(!tenKhoaHoc || !moTa || !danhMuc){
            return res.status(400).json({
                success: false,
                message: "Vui lòng điền đầy đủ thông tin"
            })
        }
        const idGiangVien = req.user.idNguoiDung
        const codeLopHoc = await taoCodeUnique()
        const newLopHoc = await prisma.khoahoc.create({
            data: {
                tenKhoaHoc,
                moTa,
                danhMuc,
                code: codeLopHoc,
                trangThai: true,
                idGiangVien: idGiangVien
            }
        })
        res.json(newLopHoc)
    }
    catch (error) {
        res.status(500).json({ error: error.message })
    }
})

router.delete('/:id', checkGiangVien, async (req, res) => {
    const id = parseInt(req.params.id)
    const idGiangVien = req.user.idNguoiDung
    const { confirm } = req.query
    try {
        const khoahoc = await prisma.khoahoc.findUnique({
            where: { idKhoaHoc: id }
        })

        if (!khoahoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy khóa học"
            })
        }
        if(khoahoc.idGiangVien !== idGiangVien){
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền xóa khóa học này"
            })
        }

        const soLuongDangKy = await prisma.dangky_khoahoc.count({
            where: { idKhoaHoc: id }
        })

        if (soLuongDangKy > 0 && confirm !== "true") {
            return res.status(400).json({
                success: false,
                needConfirm: true,
                message: `Khóa học có ${soLuongDangKy} học viên. Bạn có chắc muốn xóa?`
            })
        }

        await prisma.$transaction([
            prisma.dangky_khoahoc.deleteMany({
                where: { idKhoaHoc: id }
            }),
            prisma.khoahoc.delete({
                where: { idKhoaHoc: id }
            })
        ])

        res.json({
            success: true,
            message: "Đã xóa khóa học và toàn bộ dữ liệu liên quan"
        })

    } catch (error) {
        res.status(500).json({ error: error.message })
    }
})

router.put('/:id', checkGiangVien, async (req, res) => {
    try{
        const id = parseInt(req.params.id)
        let { tenKhoaHoc, moTa, danhMuc, trangThai } = req.body
        tenKhoaHoc = tenKhoaHoc ? tenKhoaHoc.trim() : undefined
        moTa = moTa ? moTa.trim() : undefined
        danhMuc = danhMuc ? danhMuc.trim() : undefined
        if(!tenKhoaHoc || !moTa || !danhMuc){
            return res.status(400).json({
                success: false,
                message: "Vui lòng điền đầy đủ thông tin"
            })
        }
        const khoahoc = await prisma.khoahoc.findUnique({
            where: { idKhoaHoc: id }
        })
        const idGiangVien = req.user.idNguoiDung
        if(khoahoc.idGiangVien !== idGiangVien){
            return res.status(403).json({
                success: false,
                message: "Bạn không có quyền chỉnh sửa khóa học này"
            })
        }
        if (!khoahoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy khóa học"
            })
        }
        const updatedLopHoc = await prisma.khoahoc.update({
            where: { idKhoaHoc: id },
            data: {
                tenKhoaHoc,
                moTa,
                danhMuc,
                trangThai
            }
        })
        res.json(updatedLopHoc)
    }
    catch (error) {
        res.status(500).json({ error: error.message })
    }
})



export default router