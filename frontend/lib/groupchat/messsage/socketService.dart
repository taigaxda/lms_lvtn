// // socketService.dart
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:frontend/api.dart';

// class SocketService {
//   static IO.Socket? _socket;
//   static bool _isConnected = false;
//   static List<Map<String, dynamic>> _pendingEvents = [];
//   static String? _currentGroupId;

//   // ==================== CONNECT ====================
//   static void connect() async {
//     print('🔍 [CONNECT] Called, _isConnected: $_isConnected');
    
//     if (_isConnected) {
//       print('✅ [CONNECT] Already connected, skipping');
//       return;
//     }

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString('token');

//       print('🔍 [CONNECT] Token exists: ${token != null && token.isNotEmpty}');

//       if (token == null || token.isEmpty) {
//         print('❌ [CONNECT] Chưa có token, không thể kết nối Socket');
//         return;
//       }

//       print('🔍 [CONNECT] Connecting to: ${ApiConfig.baseUrl}');

//       _socket = IO.io(
//         ApiConfig.baseUrl,
//         {
//           'transports': ['websocket'],
//           'autoConnect': true,
//           'reconnection': true,
//           'reconnectionAttempts': 10,
//           'reconnectionDelay': 1000,
//           'extraHeaders': {
//             'Authorization': 'Bearer $token',
//           },
//         },
//       );

//       print('🔍 [CONNECT] Socket instance created: ${_socket != null}');

//       _socket!.onConnect((_) {
//         _isConnected = true;
//         print('✅ [CONNECT] Socket.IO connected!');
//         print('🔍 [CONNECT] Socket ID: ${_socket?.id}');
//         print('🔍 [CONNECT] Processing ${_pendingEvents.length} pending events...');
//         _processPendingEvents();
//       });

//       _socket!.onDisconnect((_) {
//         _isConnected = false;
//         print('❌ [CONNECT] Socket.IO disconnected');
//         _currentGroupId = null;
//       });

//       _socket!.onConnectError((error) {
//         print('❌ [CONNECT] Socket.IO connection error: $error');
//         _isConnected = false;
//       });

//       _socket!.onError((error) {
//         print('❌ [CONNECT] Socket.IO error: $error');
//       });

//       _socket!.on('joined-group', (data) {
//         print('✅ [CONNECT] Joined group confirmed from server: $data');
//       });

//       _socket!.on('join-error', (data) {
//         print('❌ [CONNECT] Join group error from server: $data');
//       });

//       print('🔍 [CONNECT] Calling socket.connect()...');
//       _socket!.connect();
//       print('🔍 [CONNECT] socket.connect() called');

//     } catch (e) {
//       print('❌ [CONNECT] Socket.IO init error: $e');
//     }
//   }

//   // ==================== PROCESS PENDING EVENTS ====================
//   static void _processPendingEvents() {
//     if (_pendingEvents.isEmpty) {
//       print('📤 [PENDING] No pending events to process');
//       return;
//     }
    
//     print('📤 [PENDING] Processing ${_pendingEvents.length} pending events...');
    
//     for (var event in _pendingEvents) {
//       final eventName = event['event'];
//       final data = event['data'];
      
//       print('📤 [PENDING] Processing event: $eventName with data: $data');
      
//       if (eventName == 'join-group') {
//         _socket!.emit('join-group', data);
//         print('📢 [PENDING] Joined group (delayed): $data');
//       } else if (eventName == 'send-message') {
//         _socket!.emit('send-message', data);
//         print('📤 [PENDING] Message sent (delayed)');
//       }
//     }
    
//     _pendingEvents.clear();
//     print('📤 [PENDING] All pending events processed and cleared');
//   }

//   // ==================== DISCONNECT ====================
//   static void disconnect() {
//     print('🔍 [DISCONNECT] Called, _isConnected: $_isConnected, _socket: ${_socket != null}');
    
//     if (_socket != null && _isConnected) {
//       _socket!.disconnect();
//       _socket!.dispose();
//       _isConnected = false;
//       _pendingEvents.clear();
//       _currentGroupId = null;
//       print('🔌 [DISCONNECT] Socket.IO disconnected manually');
//     } else {
//       print('⚠️ [DISCONNECT] Socket already disconnected or null');
//     }
//   }

//   // ==================== JOIN GROUP ====================
//   static void joinGroup(int groupId) {
//   print('🔍 [JOIN] Called with groupId: $groupId');
//   print('🔍 [JOIN] _isConnected: $_isConnected');
//   print('🔍 [JOIN] _socket is null? ${_socket == null}');
//   print('🔍 [JOIN] _socket?.connected: ${_socket?.connected}');
  
//   _currentGroupId = groupId.toString();
  
//   if (_isConnected && _socket != null && _socket!.connected) {
//     final data = { 'groupId': groupId };
//     print('📤 [JOIN] EMITTING join-group with data: $data');
    
//     // ✅ Chỉ dùng emit, không dùng emitWithAck
//     _socket!.emit('join-group', data);
    
//     print('✅ [JOIN] EMIT done for join-group');
//     print('📢 [JOIN] Joined group: $groupId');
//   } else {
//     print('⏳ [JOIN] Socket not connected, adding to pending...');
//     print('⏳ [JOIN] _isConnected: $_isConnected, _socket: ${_socket != null}, connected: ${_socket?.connected}');
    
//     _pendingEvents.add({
//       'event': 'join-group',
//       'data': { 'groupId': groupId },
//     });
//     print('⏳ [JOIN] Added to pending. Total pending: ${_pendingEvents.length}');
//   }
// }

//   // ==================== LEAVE GROUP ====================
//   static void leaveGroup(int groupId) {
//     print('🔍 [LEAVE] Called with groupId: $groupId');
//     print('🔍 [LEAVE] _isConnected: $_isConnected');
    
//     if (!_isConnected || _socket == null) {
//       print('❌ [LEAVE] Socket not connected, cannot leave');
//       return;
//     }
    
//     _socket!.emit('leave-group', groupId);
//     if (_currentGroupId == groupId.toString()) {
//       _currentGroupId = null;
//     }
//     print('🚪 [LEAVE] Left group: $groupId');
//   }

//   // ==================== SEND MESSAGE ====================
//   static void sendMessage({
//     required int groupId,
//     required int userId,
//     required String message,
//     required String userName,
//     String? fileUrl,
//     String? vaiTro,
//   }) {
//     print('🔍 [SEND] Called with groupId: $groupId, userId: $userId, message: $message');
//     print('🔍 [SEND] _isConnected: $_isConnected, _socket: ${_socket != null}');
    
//     final data = {
//       'groupId': groupId,
//       'userId': userId,
//       'userName': userName,
//       'content': message,
//       'fileUrl': fileUrl,
//       'vaiTro': vaiTro ?? 'hocvien',
//       'timestamp': DateTime.now().toIso8601String(),
//     };

//     print('📤 [SEND] Data: $data');

//     if (_isConnected && _socket != null && _socket!.connected) {
//       _socket!.emit('send-message', data);
//       print('✅ [SEND] EMIT done for send-message');
//       print('📤 [SEND] Message sent: $message');
//     } else {
//       print('⏳ [SEND] Socket not connected, adding to pending...');
//       _pendingEvents.add({
//         'event': 'send-message',
//         'data': data,
//       });
//       print('⏳ [SEND] Added to pending. Total pending: ${_pendingEvents.length}');
//     }
//   }

//   // ==================== ON RECEIVE MESSAGE ====================
//   static void onReceiveMessage(Function(Map<String, dynamic>) callback) {
//     print('🔍 [ON] Registering receive-message listener');
//     if (_socket == null) {
//       print('❌ [ON] Socket is null, cannot register listener');
//       return;
//     }
//     _socket!.on('receive-message', (data) {
//       print('📩 [ON] receive-message received: $data');
//       callback(data as Map<String, dynamic>);
//     });
//     print('✅ [ON] receive-message listener registered');
//   }

//   static void onMessageEdited(Function(Map<String, dynamic>) callback) {
//     print('🔍 [ON] Registering message-edited listener');
//     if (_socket == null) return;
//     _socket!.on('message-edited', (data) {
//       print('📝 [ON] message-edited received: $data');
//       callback(data as Map<String, dynamic>);
//     });
//   }

//   static void onMessageDeleted(Function(Map<String, dynamic>) callback) {
//     print('🔍 [ON] Registering message-deleted listener');
//     if (_socket == null) return;
//     _socket!.on('message-deleted', (data) {
//       print('🗑️ [ON] message-deleted received: $data');
//       callback(data as Map<String, dynamic>);
//     });
//   }

//   static void onUserTyping(Function(Map<String, dynamic>) callback) {
//     print('🔍 [ON] Registering user-typing listener');
//     if (_socket == null) return;
//     _socket!.on('user-typing', (data) {
//       print('⌨️ [ON] user-typing received: $data');
//       callback(data as Map<String, dynamic>);
//     });
//   }

//   // ==================== TYPING ====================
//   static void sendTyping({
//     required int groupId,
//     required int userId,
//     required String userName,
//     required bool isTyping,
//   }) {
//     print('🔍 [TYPING] Called: groupId: $groupId, userId: $userId, isTyping: $isTyping');
    
//     if (!_isConnected || _socket == null) {
//       print('❌ [TYPING] Socket not connected');
//       return;
//     }

//     _socket!.emit('typing', {
//       'groupId': groupId,
//       'userId': userId,
//       'userName': userName,
//       'isTyping': isTyping,
//     });
//     print('✅ [TYPING] Sent');
//   }

//   // ==================== UTILITY ====================
//   static bool isConnected() {
//     print('🔍 [UTIL] isConnected called, returning: $_isConnected');
//     return _isConnected;
//   }

//   static IO.Socket? get socket {
//     print('🔍 [UTIL] get socket called, is null? ${_socket == null}');
//     return _socket;
//   }

//   // ==================== DEBUG - LOG ALL EVENTS ====================
//   static void logAllEvents() {
//     if (_socket == null) {
//       print('❌ [DEBUG] Socket is null, cannot log events');
//       return;
//     }
    
//     print('🔍 [DEBUG] Setting up event listeners for debugging...');
    
//     _socket!.onAny((event, args) {
//       print('📡 [DEBUG] Event received: $event, args: $args');
//     });
    
//     print('✅ [DEBUG] Event listeners set up');
//   }
// }
// socketService.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class SocketService {
  static IO.Socket? _socket;
  static bool _isConnected = false;
  static List<Map<String, dynamic>> _pendingEvents = [];
  static String? _currentGroupId;
  static String? _currentTopicId;

  // ==================== CONNECT ====================
  static void connect() async {
    print('🔍 [CONNECT] Called, _isConnected: $_isConnected');
    
    if (_isConnected) {
      print('✅ [CONNECT] Already connected, skipping');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      print('🔍 [CONNECT] Token exists: ${token != null && token.isNotEmpty}');

      if (token == null || token.isEmpty) {
        print('❌ [CONNECT] Chưa có token, không thể kết nối Socket');
        return;
      }

      print('🔍 [CONNECT] Connecting to: ${ApiConfig.baseUrl}');

      _socket = IO.io(
        ApiConfig.baseUrl,
        {
          'transports': ['websocket'],
          'autoConnect': true,
          'reconnection': true,
          'reconnectionAttempts': 10,
          'reconnectionDelay': 1000,
          'extraHeaders': {
            'Authorization': 'Bearer $token',
          },
        },
      );

      print('🔍 [CONNECT] Socket instance created: ${_socket != null}');

      _socket!.onConnect((_) {
        _isConnected = true;
        print('✅ [CONNECT] Socket.IO connected!');
        print('🔍 [CONNECT] Socket ID: ${_socket?.id}');
        print('🔍 [CONNECT] Processing ${_pendingEvents.length} pending events...');
        _processPendingEvents();
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        print('❌ [CONNECT] Socket.IO disconnected');
        _currentGroupId = null;
        _currentTopicId = null;
      });

      _socket!.onConnectError((error) {
        print('❌ [CONNECT] Socket.IO connection error: $error');
        _isConnected = false;
      });

      _socket!.onError((error) {
        print('❌ [CONNECT] Socket.IO error: $error');
      });

      _socket!.on('joined-group', (data) {
        print('✅ [CONNECT] Joined group confirmed from server: $data');
      });

      _socket!.on('join-error', (data) {
        print('❌ [CONNECT] Join group error from server: $data');
      });

      // ✅ Lắng nghe xác nhận join topic
      _socket!.on('joined-topic', (data) {
        print('✅ [CONNECT] Joined topic confirmed from server: $data');
      });

      print('🔍 [CONNECT] Calling socket.connect()...');
      _socket!.connect();
      print('🔍 [CONNECT] socket.connect() called');

    } catch (e) {
      print('❌ [CONNECT] Socket.IO init error: $e');
    }
  }

  // ==================== PROCESS PENDING EVENTS ====================
  static void _processPendingEvents() {
    if (_pendingEvents.isEmpty) {
      print('📤 [PENDING] No pending events to process');
      return;
    }
    
    print('📤 [PENDING] Processing ${_pendingEvents.length} pending events...');
    
    for (var event in _pendingEvents) {
      final eventName = event['event'];
      final data = event['data'];
      
      print('📤 [PENDING] Processing event: $eventName with data: $data');
      
      if (eventName == 'join-group') {
        _socket!.emit('join-group', data);
        print('📢 [PENDING] Joined group (delayed): $data');
      } else if (eventName == 'send-message') {
        _socket!.emit('send-message', data);
        print('📤 [PENDING] Message sent (delayed)');
      } else if (eventName == 'join-topic') {
        _socket!.emit('join-topic', data);
        print('📢 [PENDING] Joined topic (delayed): $data');
      } else if (eventName == 'send-topic-message') {
        _socket!.emit('send-topic-message', data);
        print('📤 [PENDING] Topic message sent (delayed)');
      }
    }
    
    _pendingEvents.clear();
    print('📤 [PENDING] All pending events processed and cleared');
  }

  // ==================== DISCONNECT ====================
  static void disconnect() {
    print('🔍 [DISCONNECT] Called, _isConnected: $_isConnected, _socket: ${_socket != null}');
    
    if (_socket != null && _isConnected) {
      _socket!.disconnect();
      _socket!.dispose();
      _isConnected = false;
      _pendingEvents.clear();
      _currentGroupId = null;
      _currentTopicId = null;
      print('🔌 [DISCONNECT] Socket.IO disconnected manually');
    } else {
      print('⚠️ [DISCONNECT] Socket already disconnected or null');
    }
  }

  // ==================== JOIN GROUP ====================
  static void joinGroup(int groupId) {
    print('🔍 [JOIN] Called with groupId: $groupId');
    print('🔍 [JOIN] _isConnected: $_isConnected');
    print('🔍 [JOIN] _socket is null? ${_socket == null}');
    print('🔍 [JOIN] _socket?.connected: ${_socket?.connected}');
    
    _currentGroupId = groupId.toString();
    
    if (_isConnected && _socket != null && _socket!.connected) {
      final data = { 'groupId': groupId };
      print('📤 [JOIN] EMITTING join-group with data: $data');
      
      _socket!.emit('join-group', data);
      
      print('✅ [JOIN] EMIT done for join-group');
      print('📢 [JOIN] Joined group: $groupId');
    } else {
      print('⏳ [JOIN] Socket not connected, adding to pending...');
      print('⏳ [JOIN] _isConnected: $_isConnected, _socket: ${_socket != null}, connected: ${_socket?.connected}');
      
      _pendingEvents.add({
        'event': 'join-group',
        'data': { 'groupId': groupId },
      });
      print('⏳ [JOIN] Added to pending. Total pending: ${_pendingEvents.length}');
    }
  }

  // ==================== LEAVE GROUP ====================
  static void leaveGroup(int groupId) {
    print('🔍 [LEAVE] Called with groupId: $groupId');
    print('🔍 [LEAVE] _isConnected: $_isConnected');
    
    if (!_isConnected || _socket == null) {
      print('❌ [LEAVE] Socket not connected, cannot leave');
      return;
    }
    
    _socket!.emit('leave-group', groupId);
    if (_currentGroupId == groupId.toString()) {
      _currentGroupId = null;
    }
    print('🚪 [LEAVE] Left group: $groupId');
  }

  // ==================== JOIN TOPIC ====================
  static void joinTopic(int topicId) {
    print('🔍 [JOIN_TOPIC] Called with topicId: $topicId');
    print('🔍 [JOIN_TOPIC] _isConnected: $_isConnected');
    print('🔍 [JOIN_TOPIC] _socket is null? ${_socket == null}');
    
    _currentTopicId = topicId.toString();
    
    if (_isConnected && _socket != null && _socket!.connected) {
      final data = { 'topicId': topicId };
      print('📤 [JOIN_TOPIC] EMITTING join-topic with data: $data');
      
      _socket!.emit('join-topic', data);
      
      print('✅ [JOIN_TOPIC] EMIT done for join-topic');
      print('📢 [JOIN_TOPIC] Joined topic: $topicId');
    } else {
      print('⏳ [JOIN_TOPIC] Socket not connected, adding to pending...');
      
      _pendingEvents.add({
        'event': 'join-topic',
        'data': { 'topicId': topicId },
      });
      print('⏳ [JOIN_TOPIC] Added to pending. Total pending: ${_pendingEvents.length}');
    }
  }

  // ==================== LEAVE TOPIC ====================
  static void leaveTopic(int topicId) {
    print('🔍 [LEAVE_TOPIC] Called with topicId: $topicId');
    print('🔍 [LEAVE_TOPIC] _isConnected: $_isConnected');
    
    if (!_isConnected || _socket == null) {
      print('❌ [LEAVE_TOPIC] Socket not connected, cannot leave');
      return;
    }
    
    _socket!.emit('leave-topic', { 'topicId': topicId });
    if (_currentTopicId == topicId.toString()) {
      _currentTopicId = null;
    }
    print('🚪 [LEAVE_TOPIC] Left topic: $topicId');
  }

  // ==================== SEND MESSAGE ====================
  static void sendMessage({
    required int groupId,
    required int userId,
    required String message,
    required String userName,
    String? fileUrl,
    String? vaiTro,
  }) {
    print('🔍 [SEND] Called with groupId: $groupId, userId: $userId, message: $message');
    print('🔍 [SEND] _isConnected: $_isConnected, _socket: ${_socket != null}');
    
    final data = {
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'content': message,
      'fileUrl': fileUrl,
      'vaiTro': vaiTro ?? 'hocvien',
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('📤 [SEND] Data: $data');

    if (_isConnected && _socket != null && _socket!.connected) {
      _socket!.emit('send-message', data);
      print('✅ [SEND] EMIT done for send-message');
      print('📤 [SEND] Message sent: $message');
    } else {
      print('⏳ [SEND] Socket not connected, adding to pending...');
      _pendingEvents.add({
        'event': 'send-message',
        'data': data,
      });
      print('⏳ [SEND] Added to pending. Total pending: ${_pendingEvents.length}');
    }
  }

  // ==================== SEND TOPIC MESSAGE ====================
  static void sendTopicMessage({
    required int topicId,
    required int userId,
    required String message,
    required String userName,
    String? fileUrl,
    String? vaiTro,
  }) {
    print('🔍 [SEND_TOPIC] Called with topicId: $topicId, userId: $userId, message: $message');
    print('🔍 [SEND_TOPIC] _isConnected: $_isConnected, _socket: ${_socket != null}');
    
    final data = {
      'topicId': topicId,
      'userId': userId,
      'userName': userName,
      'content': message,
      'fileUrl': fileUrl,
      'vaiTro': vaiTro ?? 'hocvien',
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('📤 [SEND_TOPIC] Data: $data');

    if (_isConnected && _socket != null && _socket!.connected) {
      _socket!.emit('send-topic-message', data);
      print('✅ [SEND_TOPIC] EMIT done for send-topic-message');
      print('📤 [SEND_TOPIC] Topic message sent: $message');
    } else {
      print('⏳ [SEND_TOPIC] Socket not connected, adding to pending...');
      _pendingEvents.add({
        'event': 'send-topic-message',
        'data': data,
      });
      print('⏳ [SEND_TOPIC] Added to pending. Total pending: ${_pendingEvents.length}');
    }
  }

  // ==================== ON RECEIVE MESSAGE ====================
  static void onReceiveMessage(Function(Map<String, dynamic>) callback) {
    print('🔍 [ON] Registering receive-message listener');
    if (_socket == null) {
      print('❌ [ON] Socket is null, cannot register listener');
      return;
    }
    _socket!.on('receive-message', (data) {
      print('📩 [ON] receive-message received: $data');
      callback(data as Map<String, dynamic>);
    });
    print('✅ [ON] receive-message listener registered');
  }

  static void onMessageEdited(Function(Map<String, dynamic>) callback) {
    print('🔍 [ON] Registering message-edited listener');
    if (_socket == null) return;
    _socket!.on('message-edited', (data) {
      print('📝 [ON] message-edited received: $data');
      callback(data as Map<String, dynamic>);
    });
  }

  static void onMessageDeleted(Function(Map<String, dynamic>) callback) {
    print('🔍 [ON] Registering message-deleted listener');
    if (_socket == null) return;
    _socket!.on('message-deleted', (data) {
      print('🗑️ [ON] message-deleted received: $data');
      callback(data as Map<String, dynamic>);
    });
  }

  // ==================== ON RECEIVE TOPIC MESSAGE ====================
  static void onReceiveTopicMessage(Function(Map<String, dynamic>) callback) {
    print('🔍 [ON_TOPIC] Registering receive-topic-message listener');
    if (_socket == null) {
      print('❌ [ON_TOPIC] Socket is null, cannot register listener');
      return;
    }
    _socket!.on('receive-topic-message', (data) {
      print('📩 [ON_TOPIC] receive-topic-message received: $data');
      callback(data as Map<String, dynamic>);
    });
    print('✅ [ON_TOPIC] receive-topic-message listener registered');
  }

  static void onTopicMessageEdited(Function(Map<String, dynamic>) callback) {
    print('🔍 [ON_TOPIC] Registering topic-message-edited listener');
    if (_socket == null) return;
    _socket!.on('topic-message-edited', (data) {
      print('📝 [ON_TOPIC] topic-message-edited received: $data');
      callback(data as Map<String, dynamic>);
    });
  }

  static void onTopicMessageDeleted(Function(Map<String, dynamic>) callback) {
    print('🔍 [ON_TOPIC] Registering topic-message-deleted listener');
    if (_socket == null) return;
    _socket!.on('topic-message-deleted', (data) {
      print('🗑️ [ON_TOPIC] topic-message-deleted received: $data');
      callback(data as Map<String, dynamic>);
    });
  }

  static void onUserTyping(Function(Map<String, dynamic>) callback) {
    print('🔍 [ON] Registering user-typing listener');
    if (_socket == null) return;
    _socket!.on('user-typing', (data) {
      print('⌨️ [ON] user-typing received: $data');
      callback(data as Map<String, dynamic>);
    });
  }

  // ==================== TYPING ====================
  static void sendTyping({
    required int groupId,
    required int userId,
    required String userName,
    required bool isTyping,
  }) {
    print('🔍 [TYPING] Called: groupId: $groupId, userId: $userId, isTyping: $isTyping');
    
    if (!_isConnected || _socket == null) {
      print('❌ [TYPING] Socket not connected');
      return;
    }

    _socket!.emit('typing', {
      'groupId': groupId,
      'userId': userId,
      'userName': userName,
      'isTyping': isTyping,
    });
    print('✅ [TYPING] Sent');
  }

  // ==================== UTILITY ====================
  static bool isConnected() {
    print('🔍 [UTIL] isConnected called, returning: $_isConnected');
    return _isConnected;
  }

  static IO.Socket? get socket {
    print('🔍 [UTIL] get socket called, is null? ${_socket == null}');
    return _socket;
  }

  // ==================== DEBUG - LOG ALL EVENTS ====================
  static void logAllEvents() {
    if (_socket == null) {
      print('❌ [DEBUG] Socket is null, cannot log events');
      return;
    }
    
    print('🔍 [DEBUG] Setting up event listeners for debugging...');
    
    _socket!.onAny((event, args) {
      print('📡 [DEBUG] Event received: $event, args: $args');
    });
    
    print('✅ [DEBUG] Event listeners set up');
  }
}