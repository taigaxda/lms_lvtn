import express from 'express'
import http from 'http'
import { Server } from 'socket.io'
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
import commentsRoutes from './routes/comments.js'
import groupRoutes from './routes/group/group.js'
import messageRoutes from './routes/group/message.js'
import cors from 'cors'

const app = express()
const PORT = process.env.PORT || 5000;

//socket
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});
app.set('io', io);

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
app.use('/comments',commentsRoutes)
app.use('/groups',groupRoutes)
app.use('/messages',messageRoutes)
app.use('/', test)

io.on('connection', (socket) => {
  console.log('✅ Client connected:', socket.id);
  
  // ✅ Join group
  socket.on('join-group', (groupId) => {
    socket.join(`group_${groupId}`);
    console.log(`👤 User joined group: ${groupId}`);
  });
  
  // ✅ Leave group
  socket.on('leave-group', (groupId) => {
    socket.leave(`group_${groupId}`);
    console.log(`👤 User left group: ${groupId}`);
  });
  
  // ✅ Gửi tin nhắn
  socket.on('send-message', async (data) => {
    console.log(`💬 Message from ${data.userName} to group ${data.groupId}: ${data.message}`);
    // Lưu tin nhắn vào database (nếu cần)
    // io.to(`group_${data.groupId}`).emit('receive-message', message);
  });
  
  socket.on('disconnect', () => {
    console.log('❌ Client disconnected:', socket.id);
  });
});

server.listen(PORT, () => {
  console.log('Server chạy ở' + PORT)
  console.log(`Socket.IO sẵn sàng`)
})