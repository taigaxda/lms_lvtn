// testnode2.js
import { io } from 'socket.io-client';

const socket = io('http://localhost:5000', {
  transports: ['websocket'],
});

socket.on('connect', () => {
  console.log('✅ Client 2 connected');
  socket.emit('join-group', { groupId: 7 });
  
  socket.on('receive-message', (data) => {
    console.log('📩 Client 2 received:', data.content);
  });
  
  // Gửi tin nhắn sau 3 giây
  setTimeout(() => {
    console.log('📤 Client 2 sending...');
    socket.emit('send-message', {
      groupId: 7,
      userId: 888,
      userName: 'Client 2',
      content: 'Hello from Client 2!',
      vaiTro: 'hocvien',
    });
  }, 3000);
  
  // Gửi tin nhắn sau 6 giây
  setTimeout(() => {
    console.log('📤 Client 2 sending again...');
    socket.emit('send-message', {
      groupId: 7,
      userId: 888,
      userName: 'Client 2',
      content: 'Another message from Client 2!',
      vaiTro: 'hocvien',
    });
  }, 6000);
});