import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkHocVien } from '../middleware.js'

const router = express.Router()

router.get("/chuahoc", checkHocVien, async (req, res) => {
  try {
    const idNguoiDung = req.user.idNguoiDung;
    
    const data = await prisma.khoahoc.findMany({
      where: {
        dangky_khoahoc: {
          some: { idNguoiDung },
        },
      },
      include: {
        baihoc: {
          where: {
            progress: {
              none: {
                idNguoiDung: idNguoiDung,
                trangThai: "hoan_thanh",
              },
            },
          },
          include:{
            progress:{
              where:{
                idNguoiDung: idNguoiDung
              }
            }
          },
          orderBy: {
            thuTu: "asc",
          },
        },
      },
    });
    const filteredData = data.filter(khoaHoc => khoaHoc.baihoc.length > 0);
    
    res.json({
      success: true,
      data: filteredData
    });
    
  } catch (error) {
    console.error("Lỗi lấy bài học chưa học:", error);
    res.status(500).json({ 
      success: false, 
      message: error.message 
    });
  }
});

router.get("/:idKhoaHoc", checkHocVien, async (req, res) => {
  try {
    const idNguoiDung = req.user.idNguoiDung;
    const idKhoaHoc = parseInt(req.params.idKhoaHoc);

    const dangKy = await prisma.dangky_khoahoc.findUnique({
      where: {
        idNguoiDung_idKhoaHoc: {
          idNguoiDung,
          idKhoaHoc,
        },
      },
    });

    if (!dangKy) {
      return res.status(403).json({
        success: false,
        message: "Bạn chưa đăng ký khóa học này",
      });
    }

    const baiHocList = await prisma.baihoc.findMany({
      where: { idKhoaHoc },
      orderBy: { thuTu: "asc" },
      include: {
        progress: {
          where: {
            idNguoiDung,
          },
          select: {
            trangThai: true,
            thoiGianHoc: true,
          },
        },
      },
    });

    const result = baiHocList.map((bh) => {
      const p = bh.progress[0];

      return {
        idBaiHoc: bh.idBaiHoc,
        tenBaiHoc: bh.tenBaiHoc,
        videoUrl: bh.videoUrl,
        taiLieuUrl: bh.taiLieuUrl,
        thuTu: bh.thuTu,

        trangThai: p?.trangThai || "chua_hoc",
        thoiGianHoc: p?.thoiGianHoc || 0,
      };
    });

    res.json({
      success: true,
      data: result,
    });
  } catch (error) {
    console.error("Lỗi lấy bài học:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi server",
    });
  }
});

// router.post("/hoc-bai", checkHocVien, async (req, res) => {
//   try {
//     const idNguoiDung = parseInt(req.user.idNguoiDung);
//     const { idKhoaHoc, idBaiHoc, trangThai, thoiGianHoc } = req.body;

//     if (!idKhoaHoc || !idBaiHoc) {
//       return res.status(400).json({
//         success: false,
//         message: "Thiếu dữ liệu",
//       });
//     }

//     const dangKy = await prisma.dangky_khoahoc.findUnique({
//       where: {
//         idNguoiDung_idKhoaHoc: {
//           idNguoiDung,
//           idKhoaHoc,
//         },
//       },
//     });

//     if (!dangKy) {
//       return res.status(403).json({
//         success: false,
//         message: "Bạn chưa đăng ký khóa học này",
//       });
//     }

//     const baiHoc = await prisma.baihoc.findFirst({
//       where: {
//         idBaiHoc,
//         idKhoaHoc,
//       },
//     });

//     if (!baiHoc) {
//       return res.status(404).json({
//         success: false,
//         message: "Bài học không tồn tại",
//       });
//     }

//     const existing = await prisma.progress.findFirst({
//       where: {
//         idNguoiDung,
//         idKhoaHoc,
//         idBaiHoc,
//       },
//     });

//     let progress;

//     if (!existing) {
//       progress = await prisma.progress.create({
//         data: {
//           idNguoiDung,
//           idKhoaHoc,
//           idBaiHoc,
//           trangThai: trangThai || "dang_hoc",
//           thoiGianHoc: thoiGianHoc || 0,
//         },
//       });
//     } else {
//       progress = await prisma.progress.update({
//         where: { idProgress: existing.idProgress },
//         data: {
//           trangThai: trangThai || existing.trangThai,
//           thoiGianHoc: thoiGianHoc ?? existing.thoiGianHoc,
//         },
//       });
//     }

//     res.json({
//       success: true,
//       message: "Cập nhật tiến độ thành công",
//       data: progress,
//     });

//   } catch (error) {
//     console.error("Lỗi học bài:", error);
//     res.status(500).json({
//       success: false,
//       message: "Lỗi server",
//     });
//   }
// });

router.post("/hoc-bai", checkHocVien, async (req, res) => {
  try {
    const idNguoiDung = parseInt(req.user.idNguoiDung);
    const { idKhoaHoc, idBaiHoc, trangThai, thoiGianHoc } = req.body;

    if (!idKhoaHoc || !idBaiHoc) {
      return res.status(400).json({
        success: false,
        message: "Thiếu dữ liệu",
      });
    }

    const dangKy = await prisma.dangky_khoahoc.findUnique({
      where: {
        idNguoiDung_idKhoaHoc: {
          idNguoiDung,
          idKhoaHoc,
        },
      },
    });

    if (!dangKy) {
      return res.status(403).json({
        success: false,
        message: "Bạn chưa đăng ký khóa học này",
      });
    }

    const baiHoc = await prisma.baihoc.findFirst({
      where: {
        idBaiHoc,
        idKhoaHoc,
      },
    });

    if (!baiHoc) {
      return res.status(404).json({
        success: false,
        message: "Bài học không tồn tại",
      });
    }

    const progress = await prisma.progress.upsert({
      where: {
        idNguoiDung_idBaiHoc: {
          idNguoiDung: idNguoiDung,
          idBaiHoc: idBaiHoc,
        }
      },
      update: {
        thoiGianHoc: {
          increment: thoiGianHoc || 0
        },
        trangThai: trangThai || undefined,
      },
      create: {
        idNguoiDung: idNguoiDung,
        idKhoaHoc: idKhoaHoc,
        idBaiHoc: idBaiHoc,
        trangThai: trangThai || "dang_hoc",
        thoiGianHoc: thoiGianHoc || 0,
      },
    });

    res.json({
      success: true,
      message: "Cập nhật tiến độ thành công",
      data: progress,
    });

  } catch (error) {
    console.error("Lỗi học bài:", error);
    res.status(500).json({
      success: false,
      message: "Lỗi server",
    });
  }
});

export default router