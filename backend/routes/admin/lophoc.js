import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkAdmin } from '../middleware.js'

const router = express.Router()

router.get('/', checkAdmin, async (req, res) => {
    try{
        const lopHocs = await prisma.khoahoc.findMany({
            include: {
                nguoidung:{
                    select: {
                        hoTen: true
                    },
                },
            }
        })
        res.json(lopHocs)
    } catch (error) {
        res.status(500).json({ error: error.message })
    }
})

router.get('/dashboard', checkAdmin, async (req, res) => {
  try {
    const [
      totalUsers,
      totalStudents,
      totalTeachers,
      totalClasses,
      totalEnrollments,
      totalLessons
    ] = await Promise.all([
      prisma.nguoidung.count(),
      prisma.nguoidung.count({ where: { vaiTro: 'hocvien' } }),
      prisma.nguoidung.count({ where: { vaiTro: 'giangvien' } }),
      prisma.khoahoc.count(),
      prisma.dangky_khoahoc.count(),
      prisma.baihoc.count()
    ]);

    const topClasses = await prisma.khoahoc.findMany({
      include: {
        _count: {
          select: { dangky_khoahoc: true }
        },
        nguoidung: {
          select: { hoTen: true }
        }
      },
      orderBy: {
        dangky_khoahoc: { _count: 'desc' }
      },
      take: 5
    });

    const recentUsers = await prisma.nguoidung.findMany({
      orderBy: { idNguoiDung: 'desc' }, 
      take: 5,
      select: {
        idNguoiDung: true,
        hoTen: true,
        email: true,
        vaiTro: true,
      }
    });
    const userRoleStats = await prisma.nguoidung.groupBy({
      by: ['vaiTro'],
      _count: true
    });

    const systemProgress = await prisma.progress.groupBy({
      by: ['trangThai'],
      _count: true
    });

    res.json({
      overview: {
        totalUsers,
        totalStudents,
        totalTeachers,
        totalClasses,
        totalEnrollments,
        totalLessons
      },
      topClasses: topClasses.map(c => ({
        idKhoaHoc: c.idKhoaHoc,
        tenKhoaHoc: c.tenKhoaHoc,
        giangVien: c.nguoidung?.hoTen || "Chưa phân công",
        totalStudents: c._count.dangky_khoahoc
      })),
      recentUsers,
      userRoleStats,
      systemProgress
    });

  } catch (error) {
    console.error("Lỗi Admin Dashboard:", error);
    res.status(500).json({ error: "Lỗi hệ thống khi lấy dữ liệu Dashboard Admin" });
  }
});

router.get('/:id', checkAdmin, async (req, res) => {
    try{
        const id = parseInt(req.params.id)
        const lopHoc = await prisma.khoahoc.findUnique({
            where: { 
                idKhoaHoc: id 
            },
            include: {
                nguoidung:{
                    select: {
                        hoTen: true
                    },
                },
                dangky_khoahoc:{
                    select:{
                        idNguoiDung: true,
                        nguoidung:{
                            select:{
                                hoTen: true,
                                email: true
                            }
                        }
                    }
                },
                _count:{
                    select:{
                        dangky_khoahoc: true
                    }
                }
            },
        })  
        if (!lopHoc) {
            return res.status(404).json({
                success: false,
                message: "Không tìm thấy khóa học"
            })
        }
        res.json(lopHoc)
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

router.post('/', checkAdmin, async (req, res) => {
    try{
        let { tenKhoaHoc, moTa, danhMuc, idGiangVien } = req.body
        tenKhoaHoc = tenKhoaHoc ? tenKhoaHoc.trim() : undefined
        moTa = moTa ? moTa.trim() : undefined
        danhMuc = danhMuc ? danhMuc.trim() : undefined
        if(!tenKhoaHoc || !moTa || !danhMuc || isNaN(idGiangVien)){
            return res.status(400).json({
                success: false,
                message: "Vui lòng điền đầy đủ thông tin"
            })
        }
        const giangVien = await prisma.nguoidung.findUnique({
            where: { idNguoiDung: idGiangVien }
        });

        if (!giangVien || giangVien.vaiTro !== "giangvien") {
            return res.status(400).json({
                success: false,
                message: "Giảng viên không hợp lệ"
            });
        }
        const codeLopHoc = await taoCodeUnique()
        const newLopHoc = await prisma.khoahoc.create({
            data: {
                tenKhoaHoc,
                moTa,
                danhMuc,
                code: codeLopHoc,
                trangThai: true,
                idGiangVien
            }
        })
        res.json(newLopHoc)
    }
    catch (error) {
        res.status(500).json({ error: error.message })
    }
})

router.delete('/:id', checkAdmin, async (req, res) => {
    const id = parseInt(req.params.id)
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

router.put('/:id', checkAdmin, async (req, res) => {
    try{
        const id = parseInt(req.params.id)
        let { tenKhoaHoc, moTa, danhMuc, idGiangVien, trangThai } = req.body
        tenKhoaHoc = tenKhoaHoc ? tenKhoaHoc.trim() : undefined
        moTa = moTa ? moTa.trim() : undefined
        danhMuc = danhMuc ? danhMuc.trim() : undefined
        if(!tenKhoaHoc || !moTa || !danhMuc || isNaN(idGiangVien)){
            return res.status(400).json({
                success: false,
                message: "Vui lòng điền đầy đủ thông tin"
            })
        }
        const giangVien = await prisma.nguoidung.findUnique({
            where: { idNguoiDung: idGiangVien }
        });
         if (!giangVien || giangVien.vaiTro !== "giangvien") {
            return res.status(400).json({
                success: false,
                message: "Giảng viên không hợp lệ"
            });
        }
        const khoahoc = await prisma.khoahoc.findUnique({
            where: { idKhoaHoc: id }
        })
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
                idGiangVien,
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