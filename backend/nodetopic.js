// test-topic.js
import { io } from 'socket.io-client';

// ==================== CONFIG ====================
const TOPIC_ID = 1;
const USER_ID = 999;
const USER_NAME = 'Node Test';
const USER_ROLE = 'hocvien';
const SERVER_URL = 'http://localhost:5000';

// ==================== KẾT NỐI SOCKET ====================
const socket = io(SERVER_URL, {
  transports: ['websocket'],
});

// Biến lưu ID tin nhắn
let lastMessageId = null;
let messageIds = []; // Lưu nhiều ID để test

socket.on('connect', () => {
  console.log('✅ Connected to server');
  console.log('🔍 Socket ID:', socket.id);
  console.log(`📢 Joining topic ${TOPIC_ID}...`);

  socket.emit('join-topic', { topicId: TOPIC_ID });

  socket.on('joined-topic', (data) => {
    console.log('✅ Joined topic confirmed:', data);
  });

  // ==================== LẮNG NGHE SỰ KIỆN ====================

  socket.on('receive-topic-message', (data) => {
    console.log('📩 [RECEIVED] Tin nhắn mới:', data);
    console.log('📩 Nội dung:', data.noiDung || data.content);
    console.log('📩 Người gửi:', data.nguoidung?.hoTen || data.userName);
    
    // ✅ SỬA: Lấy ID từ idMessage (không phải id)
    const msgId = data.idMessage || data.id;
    if (msgId) {
      lastMessageId = msgId;
      messageIds.push(msgId);
      console.log(`💾 Saved message ID: ${lastMessageId}`);
      console.log(`📋 All message IDs: ${messageIds.join(', ')}`);
    }
    console.log('---');
  });

  socket.on('topic-message-edited', (data) => {
    console.log('📝 [EDITED] Tin nhắn đã sửa:', data);
    console.log('📝 ID:', data.idMessage);
    console.log('📝 Nội dung mới:', data.noiDung || data.newContent);
    console.log('---');
  });

  socket.on('topic-message-deleted', (data) => {
    console.log('🗑️ [DELETED] Tin nhắn đã xóa:', data);
    console.log('🗑️ ID:', data.idMessage);
    console.log('---');
  });

  socket.on('topic-updated', (data) => {
    console.log('🔄 [UPDATED] Chủ đề cập nhật:', data);
    console.log('---');
  });

  // ==================== TEST LUỒNG ====================

  // 1. Gửi tin nhắn (sau 2 giây)
  setTimeout(() => {
    const message = 'Hello từ Node.js! 🚀';
    console.log(`📤 [SENDING] Gửi tin nhắn: "${message}"`);
    socket.emit('send-topic-message', {
      topicId: TOPIC_ID,
      userId: USER_ID,
      userName: USER_NAME,
      content: message,
      vaiTro: USER_ROLE,
      timestamp: new Date().toISOString(),
    });
  }, 2000);

  // 2. Gửi tin nhắn thứ 2 (sau 4 giây)
  setTimeout(() => {
    const message = 'Test realtime topic! ✅';
    console.log(`📤 [SENDING] Gửi tin nhắn 2: "${message}"`);
    socket.emit('send-topic-message', {
      topicId: TOPIC_ID,
      userId: USER_ID,
      userName: USER_NAME,
      content: message,
      vaiTro: USER_ROLE,
      timestamp: new Date().toISOString(),
    });
  }, 4000);

  // 3. Sửa tin nhắn đầu tiên (sau 6 giây)
  setTimeout(() => {
    if (messageIds.length > 0) {
      const idToEdit = messageIds[0];
      const newContent = 'Nội dung đã được sửa! ✏️';
      console.log(`📝 [EDITING] Sửa tin nhắn ID ${idToEdit}: "${newContent}"`);
      socket.emit('edit-topic-message', {
        topicId: TOPIC_ID,
        idMessage: idToEdit,
        newContent: newContent,
      });
    } else {
      console.log('⚠️ Không có ID tin nhắn để sửa');
    }
  }, 6000);

  // 4. Xóa tin nhắn đầu tiên (sau 8 giây)
  setTimeout(() => {
    if (messageIds.length > 0) {
      const idToDelete = messageIds[0];
      console.log(`🗑️ [DELETING] Xóa tin nhắn ID ${idToDelete}`);
      socket.emit('delete-topic-message', {
        topicId: TOPIC_ID,
        idMessage: idToDelete,
      });
    } else {
      console.log('⚠️ Không có ID tin nhắn để xóa');
    }
  }, 8000);

  // 5. Gửi tin nhắn thứ 3 (sau 10 giây)
  setTimeout(() => {
    const message = 'Topic discussion is working! 🎉';
    console.log(`📤 [SENDING] Gửi tin nhắn 3: "${message}"`);
    socket.emit('send-topic-message', {
      topicId: TOPIC_ID,
      userId: USER_ID,
      userName: USER_NAME,
      content: message,
      vaiTro: USER_ROLE,
      timestamp: new Date().toISOString(),
    });
  }, 10000);

  // 6. Sửa tin nhắn thứ 3 (sau 12 giây)
  setTimeout(() => {
    if (messageIds.length >= 3) {
      const idToEdit = messageIds[2];
      const newContent = 'Nội dung đã sửa lần 2! ✏️✏️';
      console.log(`📝 [EDITING] Sửa tin nhắn ID ${idToEdit}: "${newContent}"`);
      socket.emit('edit-topic-message', {
        topicId: TOPIC_ID,
        idMessage: idToEdit,
        newContent: newContent,
      });
    } else {
      console.log('⚠️ Chưa có đủ tin nhắn để sửa');
    }
  }, 12000);

  // 7. Xóa tin nhắn thứ 2 (sau 14 giây)
  setTimeout(() => {
    if (messageIds.length >= 2) {
      const idToDelete = messageIds[1];
      console.log(`🗑️ [DELETING] Xóa tin nhắn ID ${idToDelete}`);
      socket.emit('delete-topic-message', {
        topicId: TOPIC_ID,
        idMessage: idToDelete,
      });
    } else {
      console.log('⚠️ Không có ID tin nhắn để xóa');
    }
  }, 14000);
});

// ==================== XỬ LÝ LỖI ====================
socket.on('connect_error', (error) => {
  console.log('❌ Connection error:', error.message);
});

socket.on('disconnect', () => {
  console.log('❌ Disconnected');
});

// Lắng nghe tất cả sự kiện để debug
socket.onAny((event, ...args) => {
  if (event !== 'ping' && event !== 'pong') {
    console.log(`📡 [${event}]`, JSON.stringify(args));
  }
});

// ==================== THOÁT SAU 18 GIÂY ====================
setTimeout(() => {
  console.log('🔌 Đóng kết nối...');
  console.log(`📋 Final message IDs: ${messageIds.join(', ')}`);
  socket.disconnect();
  process.exit(0);
}, 18000);