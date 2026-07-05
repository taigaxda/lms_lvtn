import express from 'express'
import { prisma } from './prisma/client.js'
import { count } from 'console'

const router = express.Router()

router.get('/', async (req, res) => {
    return res.json({ message: "API is working" })
})

router.get('/lopMax', async (req, res) => {
    const lopDongNhat = await prisma.khoahoc.findMany({
        take: 1,
        orderBy: {
            dangky_khoahoc: {
                _count: 'desc'
            }
        },
        select: {
            _count: {
                select: {
                    dangky_khoahoc: true
                }
            },
            nguoidung: true
        }
    })
    res.json({
        success: true,
        data: lopDongNhat
    })
})

router.get('/loptrongkhoang', async (req, res) => {
    const loptrongkhoang = await prisma.dangky_khoahoc.groupBy({
        by: ['idKhoaHoc'],
        _count:{
            idDangKy: true
        },
        having:{
            idDangKy:{
                _count:{
                    gte: 1,
                    lte: 3
                }
            }
        }
    })
    const idLops = loptrongkhoang.map(l=>l.idKhoaHoc)
    const lop = await prisma.khoahoc.findMany({
        where:{
            idKhoaHoc: {
                in: idLops
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
    res.json({
        success: true,
        data: lop,
        total: lop.length
    })
})
export default router