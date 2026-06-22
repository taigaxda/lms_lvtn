import express from 'express'
import test from './test.js'
import nguoiDungRoutes from './routes/admin/nguoidung.js'
import authRoutes from './routes/auth.js'
import lopHocAdminRoutes from './routes/admin/lophoc.js'
import lopHocHocVienRoutes from './routes/hocvien/lophoc.js'
import baiHocHocVienRoutes from './routes/hocvien/baihoc.js'
import lopHocGiangVienRoutes from './routes/giangvien/lophoc.js'
import baiHocGiangVienRoutes from './routes/giangvien/baihoc.js'
import quizGiangVienRoutes from './routes/giangvien/quiz.js'
import quizHocVienRoutes from './routes/hocvien/quiz.js'
import qlhvGiangVienRoutes from './routes/giangvien/hocvien.js'
import baiTapGiangVien from './routes/giangvien/baitap.js'
import baiTapHocVien from './routes/hocvien/baitap.js'
import thongBaoGiangVienRoutes from './routes/giangvien/thongbao.js'
import thongBaoHocVienRoutes from './routes/hocvien/thongbao.js'
import thongBaoAdminRoutes from './routes/admin/thongbao.js'
import cors from 'cors'

const app = express()
const PORT = process.env.PORT || 5000;

app.use(cors())

app.use(express.json()) 
app.use(express.urlencoded({ extended: true }));

app.use('/admin/nguoidung', nguoiDungRoutes)
app.use('/admin/lophoc', lopHocAdminRoutes)
app.use('/auth', authRoutes)
app.use('/hocvien/lophoc', lopHocHocVienRoutes)
app.use('/giangvien/lophoc', lopHocGiangVienRoutes)
app.use('/giangvien/baihoc',baiHocGiangVienRoutes)
app.use('/hocvien/baihoc', baiHocHocVienRoutes)
app.use('/giangvien/quiz',quizGiangVienRoutes)
app.use('/hocvien/quiz',quizHocVienRoutes)
app.use('/giangvien/qlhv',qlhvGiangVienRoutes)
app.use('/giangvien/baitap',baiTapGiangVien)
app.use('/hocvien/baitap',baiTapHocVien)
app.use('/giangvien/thongbao',thongBaoGiangVienRoutes)
app.use('/hocvien/thongbao',thongBaoHocVienRoutes)
app.use('/admin/thongbao',thongBaoAdminRoutes)
app.use('/', test)

app.listen(PORT, () => {
  console.log('Server chạy ở' + PORT)
})