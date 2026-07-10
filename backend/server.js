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
import topicsRoutes from './routes/group/topic.js'
import hocVienAIRoutes from './routes/hocvien/ai.js'
import cors from 'cors'
import dotenv from 'dotenv';
dotenv.config();

const app = express()
const PORT = process.env.PORT || 5000;

//socket
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.CLIENT_URL || '*',
    methods: ["GET", "POST"],
    credentials: true,
  },
  transports: ['websocket', 'polling'],
  pingTimeout: 60000,
  pingInterval: 25000,
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
app.use('/topics',topicsRoutes)
app.use('/hocvien/ai',hocVienAIRoutes)
app.use('/', test)

io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  socket.onAny((event, ...args) => {
    console.log(`[${event}]`, JSON.stringify(args));
  });
  // Join group - Hỗ trợ cả object và number
  socket.on('join-group', (data) => {
    let groupId;
    
    // Kiểm tra nếu data là object (từ Flutter gửi {groupId: 1})
    if (typeof data === 'object' && data !== null) {
      groupId = data.groupId || data.id || data.group;
    } else {
      groupId = data;
    }
    
    if (groupId) {
      socket.join(`group_${groupId}`);
      console.log(`User joined group: ${groupId}`);
      
      // Gửi xác nhận đã join group
      socket.emit('joined-group', { 
        groupId: groupId, 
        success: true 
      });
    } else {
      console.log('Invalid groupId:', data);
      socket.emit('join-error', { 
        message: 'Invalid groupId', 
        data: data 
      });
    }
  });

  // Leave group
  socket.on('leave-group', (data) => {
    let groupId;
    
    if (typeof data === 'object' && data !== null) {
      groupId = data.groupId || data.id || data.group;
    } else {
      groupId = data;
    }
    
    if (groupId) {
      socket.leave(`group_${groupId}`);
      console.log(`User left group: ${groupId}`);
    }
  });

  // Gửi tin nhắn - Broadcast đến tất cả trong group
  socket.on('send-message', (data) => {
    console.log(`Message from ${data.userName || 'Unknown'} to group ${data.groupId}: ${data.content || data.message}`);
    
    const groupId = data.groupId;
    if (!groupId) {
      console.log('Missing groupId in send-message');
      return;
    }
    
    // Broadcast tin nhắn đến tất cả trong group
    io.to(`group_${groupId}`).emit('receive-message', {
      idMessage: data.idMessage || Date.now(),
      content: data.content || data.message || '',
      fileUrl: data.fileUrl || null,
      userId: data.userId,
      userName: data.userName || 'Unknown',
      vaiTro: data.vaiTro || 'hocvien',
      thoiGian: data.thoiGian || new Date().toISOString(),
    });
  });

  // Edit message
  socket.on('edit-message', (data) => {
    const groupId = data.groupId;
    if (!groupId) return;
    
    io.to(`group_${groupId}`).emit('message-edited', {
      idMessage: data.idMessage,
      noiDung: data.newContent || data.content,
      edited: true,
    });
  });

  // Delete message
  socket.on('delete-message', (data) => {
    const groupId = data.groupId;
    if (!groupId) return;
    
    io.to(`group_${groupId}`).emit('message-deleted', {
      idMessage: data.idMessage,
      deleted: true,
    });
  });

  socket.on('typing', (data) => {
    const groupId = data.groupId;
    if (!groupId) return;
    
    socket.to(`group_${groupId}`).emit('user-typing', {
      userId: data.userId,
      userName: data.userName,
      isTyping: data.isTyping,
    });
  });

  socket.on('join-topic', (data) => {
    let topicId;
    if (typeof data === 'object' && data !== null) {
      topicId = data.topicId || data.id || data.topic;
    } else {
      topicId = data;
    }
    
    if (topicId) {
      socket.join(`topic_${topicId}`);
      console.log(`User joined topic: ${topicId}`);
      socket.emit('joined-topic', { topicId, success: true });
    } else {
      console.log('Invalid topicId:', data);
    }
  });

  // Leave topic
  socket.on('leave-topic', (data) => {
    let topicId;
    if (typeof data === 'object' && data !== null) {
      topicId = data.topicId || data.id || data.topic;
    } else {
      topicId = data;
    }
    
    if (topicId) {
      socket.leave(`topic_${topicId}`);
      console.log(`User left topic: ${topicId}`);
    }
  });

  //Gửi tin nhắn trong topic - Broadcast đến tất cả trong topic
  socket.on('send-topic-message', (data) => {
    console.log(`Topic message from ${data.userName || 'Unknown'} to topic ${data.topicId}: ${data.content || data.message}`);
    
    const topicId = data.topicId;
    if (!topicId) {
      console.log('Missing topicId in send-topic-message');
      return;
    }
    
    io.to(`topic_${topicId}`).emit('receive-topic-message', {
      idMessage: data.idMessage || Date.now(),
      content: data.content || data.message || '',
      fileUrl: data.fileUrl || null,
      userId: data.userId,
      userName: data.userName || 'Unknown',
      vaiTro: data.vaiTro || 'hocvien',
      thoiGian: data.thoiGian || new Date().toISOString(),
    });
  });

  //Sửa tin nhắn trong topic
  socket.on('edit-topic-message', (data) => {
    const topicId = data.topicId;
    if (!topicId) return;
    
    io.to(`topic_${topicId}`).emit('topic-message-edited', {
      idMessage: data.idMessage,
      noiDung: data.newContent || data.content,
      edited: true,
    });
  });

  //Xóa tin nhắn trong topic
  socket.on('delete-topic-message', (data) => {
    const topicId = data.topicId;
    if (!topicId) return;
    
    io.to(`topic_${topicId}`).emit('topic-message-deleted', {
      idMessage: data.idMessage,
      deleted: true,
    });
  });

  // Disconnect
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });

  // Error handling
  socket.on('error', (error) => {
    console.error('Socket error:', error);
  });
});

server.listen(PORT, () => {
  console.log('Server chạy ở' + PORT)
  console.log(`Socket.IO sẵn sàng`)
})