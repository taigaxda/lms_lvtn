import express from 'express'
import { prisma } from './prisma/client.js'
import { count, group } from 'console'

const router = express.Router()

router.get('/', async (req, res) => {
    return res.json({ message: "API is working" })
})

router.get('/lopMax', async (req, res) => {
    const maxL = await prisma.dangky_khoahoc.groupBy({
        by: ['idKhoaHoc'],
        _count:{
            idDangKy: true
        },
        orderBy: {
            _count: {
                idDangKy: 'desc'
            }
        },
        take: 1
    })
    const max = maxL[0]._count.idDangKy
    const lopDongNhat = await prisma.khoahoc.findMany({
        where:{
            dangky_khoahoc:{
                some:{}
            }
        },
        select:{
            tenKhoaHoc: true,
            _count:{
                select:{
                    dangky_khoahoc: true
                }
            }
        }
    })
    const kq = lopDongNhat.filter(lop=>lop._count.dangky_khoahoc == max)
    res.json({
        kq
    })
})

router.get('/loptrongkhoang', async (req, res) => {
    const loptrongkhoang = await prisma.dangky_khoahoc.groupBy({
        by: ['idKhoaHoc'],
        _count: {
            idDangKy: true
        },
        having: {
            idDangKy: {
                _count: {
                    gte: 1,
                    lte: 3
                }
            }
        }
    })
    const idLops = loptrongkhoang.map(l => l.idKhoaHoc)
    const lop = await prisma.khoahoc.findMany({
        where: {
            idKhoaHoc: {
                in: idLops
            }
        },
        select: {
            tenKhoaHoc: true,
            _count: {
                select: {
                    dangky_khoahoc: true
                }
            }
        }
    })
    res.json({
        success: true,
        data: lop,
        total: lop.length
    })
})

router.get('/tinnhan/:idGroup', async (req, res) => {
    const idGroup = parseInt(req.params.idGroup)
    const tinNhan = await prisma.messages.groupBy({
        by: ['idNguoiDung'],
        where: {
            idGroup: idGroup
        },
        _count: {
            idMessage: true
        },
        orderBy: {
            _count: {
                idMessage: 'desc'
            }
        },
        take: 1
    })
    const max = tinNhan[0]._count.idMessage
    //relation xài some
    const ttnd = await prisma.nguoidung.findMany({
        where: {
            group_members:{
                some:{                
                    idGroup: idGroup
                }
            }
        },
        select: {
            hoTen: true,
            _count: {
                select: {
                    messages:{
                        where:{
                            idGroup: idGroup
                        }
                    }
                }
            },
            group_members: {
                where:{
                    idGroup: idGroup
                },
                select:{
                    group: true
                }
            }
        }
    })
    const rs = ttnd.filter(t=>t._count.messages === max)
    res.json({
        success: true,
        data: rs,
    })
})
router.get('/top-enrollment-all', async (req, res) => {
    try {
        const maxEnrollment = await prisma.dangky_khoahoc.groupBy({
            by: ['idKhoaHoc'],
            _count: {
                idDangKy: true
            },
            orderBy: {
                _count: {
                    idDangKy: 'desc'
                }
            },
            take: 1
        });

        if (!maxEnrollment || maxEnrollment.length === 0) {
            return res.status(404).json({
                success: false,
                message: "Không có lớp học nào"
            });
        }

        const maxCount = maxEnrollment[0]._count.idDangKy;
        const topClasses = await prisma.dangky_khoahoc.groupBy({
            by: ['idKhoaHoc'],
            _count: {
                idDangKy: true
            },
            having: {
                idDangKy: {
                    _count: {
                        equals: maxCount
                    }
                }
            }
        });
        const courseIds = topClasses.map(c => c.idKhoaHoc);
        const courses = await prisma.khoahoc.findMany({
            where: {
                idKhoaHoc: { in: courseIds }
            },
            include: {
                nguoidung: {
                    select: {
                        hoTen: true,
                        email: true
                    }
                },
                _count: {
                    select: {
                        dangky_khoahoc: true
                    }
                }
            }
        });

        res.json({
            success: true,
            data: courses,
            total: courses.length,
            soLuongMax: maxCount
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

router.get('/diemCaoNhatTrongBT/:idAssignment', async (req, res) => {
    const idAssignment = parseInt(req.params.idAssignment)
    const diemMax = await prisma.grades.findFirst({
        where: {
            submission: {
                idAssignment: idAssignment
            }
        },
        orderBy: {
            diem: 'desc'
        },
        select: {
            diem: true
        }
    })
    const nguoiDiemMax = await prisma.grades.findMany({
        where: {
            AND: [
                {
                    submission: {
                        idAssignment: idAssignment
                    },
                }, {
                    diem: diemMax.diem
                }
            ]
        },
        include: {
            submission: {
                include: {
                    nguoidung: {
                        select: {
                            hoTen: true
                        }
                    }
                }
            }
        }
    })
    res.json({
        success: true,
        data: nguoiDiemMax
    });
})

router.get('/hocviennopbaiMax/:idKhoaHoc', async (req, res) => {
    const idKhoaHoc = parseInt(req.params.idKhoaHoc)
    const nopNhieuNhat = await prisma.submissions.groupBy({
        by: ['idNguoiDung'],
        where: {
            assignment: {
                idKhoaHoc: idKhoaHoc
            }
        },
        _count: {
            idSubmission: true
        },
        orderBy: {
            _count: {
                idSubmission: 'desc'
            }
        },
    })
    const soMax = nopNhieuNhat[0]._count.idSubmission
    const ids = nopNhieuNhat.map(t => t.idNguoiDung)
    const soNguoiMax = []
    for (const d of nopNhieuNhat) {
        if (d._count.idSubmission === soMax) {
            soNguoiMax.push(d.idNguoiDung)
        }
    }
    const ttnd = await prisma.nguoidung.findMany({
        where: {
            idNguoiDung: {
                in: soNguoiMax
            }
        },
                select: {
                    hoTen: true
                }
    })
    res.json({
        success: true,
        data: ttnd,
        sobaitap: soMax,
        soLuong: ttnd.length
    });
})

router.get('/dsChuaNopBaiTap/:idKhoaHoc',async(req,res)=>{
    const idKhoaHoc = parseInt(req.params.idKhoaHoc)
    const bt = await prisma.assignments.findMany({
        where:{
            idKhoaHoc: idKhoaHoc
        }
    })
    const idsBT = bt.map(b=>b.idAssignment)
    const daNopBai = await prisma.submissions.findMany({
        where:{
            idAssignment:{
                in: idsBT
            }
        },
        select:{
            idNguoiDung: true,
        },
        distinct: ['idNguoiDung'] //lay duy nhat
    })
    const daNopIds =    daNopBai.map(d=>d.idNguoiDung)
    const dsLop = await prisma.dangky_khoahoc.findMany({
        where:{
            idKhoaHoc: idKhoaHoc
        },
        include:{
            nguoidung:{
                select:{
                    idNguoiDung: true,
                    hoTen: true
                }
                
            }
        }
    })
    const dsChuaNop = []
    for(const d of dsLop){
        if(!daNopIds.includes(d.nguoidung.idNguoiDung)){
            dsChuaNop.push(d)
        }
    }
    if(dsChuaNop.length===0){
        return res.json({
            message: "Tat ca da nop bai"
        })
    }
    return res.json({
        success: true,
        data: dsChuaNop
    })
})

router.get('/btchuacohvnop/:idKhoaHoc',async(req,res)=>{
    const idKhoaHoc = parseInt(req.params.idKhoaHoc)
    const bt = await prisma.assignments.findMany({
        where:{
            idKhoaHoc: idKhoaHoc
        },
        select:{
            idAssignment: true,
            tieuDe: true,
            _count:{
                select:{
                    submissions: true
                }
            }
        }
    })
    const btChuaCoBai = []
    for(const b of bt){
        if(b._count.submissions === 0){
            btChuaCoBai.push(b)
        }
    }
    
    return res.json({
        success: true,
        data: btChuaCoBai
    })
})
router.get('/hvchuathamgia',async(req,res)=>{
    const ds = await prisma.nguoidung.findMany({
        where:{
            vaiTro: 'giangvien',
            khoahoc: {
                none:{}
            }
        },
        select:{
            hoTen: true
        }
    })
    
    return res.json({
        success: true,
        data: ds
    })
})
router.get('/nguoidungthamgianhieunhom',async(req,res)=>{
    const soNhomThamGia = await prisma.group_members.groupBy({
        by:['idNguoiDung'],
        _count:{
            idGroup: true
        },
        orderBy:{
            _count:{
                idGroup: 'desc'
            }
        }
    })
    const soNhomMax = soNhomThamGia[0]._count.idGroup
    const nguoiMax = []
    for(const n of soNhomThamGia){
        if(n._count.idGroup===soNhomMax){
            nguoiMax.push(n.idNguoiDung)
        }
    }
    const idsMax = nguoiMax.map(m=>m.idNguoiDung)
    const dsNd = await prisma.nguoidung.findMany({
        where:{
            idNguoiDung:{
                in:
                    nguoiMax
                
            }
        }
    })
    
    return res.json({
        success: true,
        data: dsNd
    })
})

router.get('/nguoidungchuathamgianhom',async(req,res)=>{
    const dsNd = await prisma.nguoidung.findMany({
        where:{
            vaiTro:{
                in: ['hocvien','giangvien']
            },
            group_members:{
                none:{
                }
            }
        }
    })
    
    return res.json({
        success: true,
        data: dsNd
    })
})
router.get('/diemMaxTatCaBaiKT',async(req,res)=>{
    const dsBaiKT = await prisma.quizzes.findMany({
        select:{
            idQuiz: true,
            tenQuiz: true,
                khoahoc:{
                    select:{
                        tenKhoaHoc: true
                    }
                
            }
        }
    })
    const tongBaiKT = await prisma.quizzes.count()
    const diemMaxTungBai = await prisma.quiz_results.groupBy({
        by:['idQuiz'],
        _max :{
            diemSo: true
        }
    })
    const kq =[]
    for(const kt of dsBaiKT){
        const diemMax =  diemMaxTungBai.find(d=>d.idQuiz==kt.idQuiz)
        if (!diemMax || diemMax._max.diemSo === null) {
                kq.push({
                    idQuiz: kt.idQuiz,
                    tenQuiz: kt.tenQuiz,
                    khoahoc: kt.khoahoc,
                    diemCaoNhat: null,
                    thongTinNguoiDung: []
                });
                continue;
            }
        const thongTinNguoiDung = await prisma.quiz_results.findMany({
            where:{
                idQuiz: kt.idQuiz,
                diemSo: diemMax._max.diemSo
            },
            select:{
                diemSo: true,
                nguoidung:{
                    select:{
                    hoTen: true
                    }

                },
            }
        })
        kq.push({
            ...kt,
            diemCaoNhat: diemMax,
            thongTinNguoiDung: thongTinNguoiDung
        })
    }
   
    
    res.json({
        data: kq
    })
})

export default router