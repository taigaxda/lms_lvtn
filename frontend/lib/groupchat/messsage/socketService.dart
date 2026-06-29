import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;
  static List<Map<String, dynamic>> _pendingEvents = [];

  // Kết nối Socket
  static void connect() async {
    if (_isConnected) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        print('Chưa có token, không thể kết nối Socket');
        return;
      }

      print('Đang kết nối Socket...');

      _socket = IO.io(
        ApiConfig.baseUrl,
        {
          'transports': ['websocket'],
          'autoConnect': true,
          'extraHeaders': {
            'Authorization': 'Bearer $token',
          },
        },
      );

      _socket!.onConnect((_) {
        _isConnected = true;
        print('Socket.IO connected');
        _processPendingEvents();
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('Socket.IO disconnected');
      });

      _socket!.onConnectError((error) {
        print('Socket.IO connection error: $error');
      });

      _socket!.onError((error) {
        print('Socket.IO error: $error');
      });

      _socket!.connect();
    } catch (e) {
      print('Socket.IO init error: $e');
    }
  }

  static void _processPendingEvents() {
    if (_pendingEvents.isEmpty) return;
    
    print('Đang gửi ${_pendingEvents.length} events đang chờ...');
    
    for (var event in _pendingEvents) {
      final eventName = event['event'];
      final data = event['data'];
      
      if (eventName == 'join-group') {
        _socket!.emit('join-group', data);
        print('Joined group (delayed): $data');
      } else if (eventName == 'send-message') {
        _socket!.emit('send-message', data);
        print('Message sent (delayed)');
      }
    }
    
    _pendingEvents.clear();
  }

  static void disconnect() {
    if (_socket != null && _isConnected) {
      _socket!.disconnect();
      _socket!.dispose();
      _isConnected = false;
      _pendingEvents.clear();
      print('Socket.IO disconnected manually');
    }
  }

  static void joinGroup(int groupId) {
    if (_isConnected && _socket != null) {
      _socket!.emit('join-group', groupId);
      print('Joined group: $groupId');
    } else {
      print('Socket đang kết nối, sẽ join group sau...');
      _pendingEvents.add({
        'event': 'join-group',
        'data': groupId,
      });
    }
  }

  static void leaveGroup(int groupId) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('leave-group', groupId);
    print('Left group: $groupId');
  }

  static void sendMessage({
    required int groupId,
    required int userId,
    required String message,
    required String userName,
  }) {
    final data = {
      'groupId': groupId,
      'userId': userId,
      'message': message,
      'userName': userName,
    };

    if (_isConnected && _socket != null) {
      _socket!.emit('send-message', data);
      print('Message sent: $message');
    } else {
      print('Socket đang kết nối, sẽ gửi tin nhắn sau...');
      _pendingEvents.add({
        'event': 'send-message',
        'data': data,
      });
    }
  }

  static void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    if (_socket == null) return;
    _socket!.on('receive-message', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  static void onMessageEdited(Function(Map<String, dynamic>) callback) {
    if (_socket == null) return;
    _socket!.on('message-edited', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  static void onMessageDeleted(Function(Map<String, dynamic>) callback) {
    if (_socket == null) return;
    _socket!.on('message-deleted', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

  static void onUserTyping(Function(Map<String, dynamic>) callback) {
    if (_socket == null) return;
    _socket!.on('user-typing', (data) {
      callback(data as Map<String, dynamic>);
    });
  }

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

  static bool isConnected() {
    return _isConnected;
  }

  static IO.Socket? get socket => _socket;
}