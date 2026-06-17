import express from 'express'
import { prisma } from '../../prisma/client.js'
import { checkHocVien } from '../middleware.js'

const router = express.Router();

router.get('/:idKhoaHoc', checkHocVien, async (req, res) => {
    try {
        const idKhoaHoc = parseInt(req.params.idKhoaHoc)
        const dsBaiTap = await prisma.assignments.findMany({
            where: {
                idKhoaHoc: idKhoaHoc,
            },
            orderBy: {
                ngayTao: 'desc'
            },
            include: {
                submissions: true
            }
        })
        return res.status(200).json({
            success: true,
            message: "Lấy danh sách bài tập thành công",
            data: dsBaiTap
        })
    }
    catch(err){
        return res.status(500).json({
            success: false,
            message: err.message
        })
    }
})

export default router