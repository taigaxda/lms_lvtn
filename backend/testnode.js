// test-socket.js
import { io } from 'socket.io-client';

const socket = io('https://lms-lvtn.onrender.com', {
  transports: ['websocket'],
});

// Kết nối thành công
socket.on('connect', () => {
  console.log('✅ Connected to server');
  console.log('🔍 Socket ID:', socket.id);
  
  // Join group
  socket.emit('join-group', { groupId: 7 });
  console.log('📢 Joined group 7');
  
  // Lắng nghe tin nhắn
  socket.on('receive-message', (data) => {
    console.log('📩 Received:', data);
  });
  
  // Gửi tin nhắn sau 2 giây
  setTimeout(() => {
    console.log('📤 Sending message...');
    socket.emit('send-message', {
      groupId: 7,
      userId: 999,
      userName: 'Node Test 1',
      content: 'Hello from Node.js!',
      vaiTro: 'hocvien',
    });
  }, 2000);
  
  // Gửi tin nhắn thứ 2 sau 4 giây
  setTimeout(() => {
    console.log('📤 Sending message 2...');
    socket.emit('send-message', {
      groupId: 7,
      userId: 999,
      userName: 'Node Test 1',
      content: 'Test realtime!',
      vaiTro: 'hocvien',
    });
  }, 4000);
});

socket.on('connect_error', (error) => {
  console.log('❌ Connection error:', error.message);
});

socket.on('disconnect', () => {
  console.log('❌ Disconnected');
});

// Lắng nghe tất cả sự kiện
socket.onAny((event, ...args) => {
  console.log(`📡 [${event}]`, args);
});