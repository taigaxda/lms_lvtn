// lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;

  // ✅ Kết nối Socket
  static void connect() async {
    if (_isConnected) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        print('❌ Chưa có token, không thể kết nối Socket');
        return;
      }

      _socket = IO.io(
        ApiConfig.baseUrl, // Ví dụ: http://localhost:5000
        {
          'transports': ['websocket'],
          'autoConnect': true,
          'extraHeaders': {
            'Authorization': 'Bearer $token',
          },
        },
      );

      // ✅ Lắng nghe kết nối thành công
      _socket!.onConnect((_) {
        _isConnected = true;
        print('✅ Socket.IO connected');
      });

      // ✅ Lắng nghe ngắt kết nối
      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('❌ Socket.IO disconnected');
      });

      // ✅ Lắng nghe lỗi kết nối
      _socket!.onConnectError((error) {
        print('❌ Socket.IO connection error: $error');
      });

      // ✅ Lắng nghe lỗi
      _socket!.onError((error) {
        print('❌ Socket.IO error: $error');
      });

      // ✅ Kết nối
      _socket!.connect();
    } catch (e) {
      print('❌ Socket.IO init error: $e');
    }
  }

  // ✅ Ngắt kết nối
  static void disconnect() {
    if (_socket != null && _isConnected) {
      _socket!.disconnect();
      _socket!.dispose();
      _isConnected = false;
      print('✅ Socket.IO disconnected manually');
    }
  }

  // ✅ Tham gia nhóm chat
  static void joinGroup(int groupId) {
    if (!_isConnected || _socket == null) {
      print('❌ Socket chưa kết nối, không thể join group');
      return;
    }
    _socket!.emit('join-group', groupId);
    print('✅ Joined group: $groupId');
  }

  // ✅ Rời nhóm chat
  static void leaveGroup(int groupId) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('leave-group', groupId);
    print('✅ Left group: $groupId');
  }

  // ✅ Gửi tin nhắn
  static void sendMessage({
    required int groupId,
    required int userId,
    required String message,
    required String userName,
  }) {
    if (!_isConnected || _socket == null) {
      print('❌ Socket chưa kết nối, không thể gửi tin nhắn');
      return;
    }

    final data = {
      'groupId': groupId,
      'userId': userId,
      'message': message,
      'userName': userName,
    };

    _socket!.emit('send-message', data);
    print('✅ Message sent: $message');
  }

  // ✅ Lắng nghe tin nhắn mới
  static void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    if (_socket == null) return;
    _socket!.on('receive-message', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // ✅ Lắng nghe tin nhắn đã sửa
  static void onMessageEdited(Function(Map<String, dynamic>) callback) {
    if (_socket == null) return;
    _socket!.on('message-edited', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // ✅ Lắng nghe tin nhắn đã xóa
  static void onMessageDeleted(Function(Map<String, dynamic>) callback) {
    if (_socket == null) return;
    _socket!.on('message-deleted', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // ✅ Lắng nghe typing indicator
  static void onUserTyping(Function(Map<String, dynamic>) callback) {
    if (_socket == null) return;
    _socket!.on('user-typing', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  // ✅ Gửi typing indicator
  static void sendTyping({
    required int groupId,
    required int userId,
    required String userName,
    required bool isTyping,
  }) {
    if (!_isConnected || _socket == null) return;

    _socket!.emit('typing', {
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'isTyping': isTyping,
    });
  }

  // ✅ Kiểm tra trạng thái kết nối
  static bool isConnected() {
    return _isConnected;
  }

  // ✅ Lấy Socket instance (nếu cần)
  static IO.Socket? get socket => _socket;
}