import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/api.dart';
import 'package:chewie/chewie.dart';
import '../socketService.dart';
import 'package:video_player/video_player.dart';

class ChiTietTopicScreen extends StatefulWidget {
  final int topicId;
  final String tieuDe;
  final int idGroup;

  const ChiTietTopicScreen({
    super.key,
    required this.topicId,
    required this.tieuDe,
    required this.idGroup,
  });

  @override
  State<ChiTietTopicScreen> createState() => _ChiTietTopicScreenState();
}

class _ChiTietTopicScreenState extends State<ChiTietTopicScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String apiUrl = '${ApiConfig.baseUrl}/topics';

  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isSending = false;
  int userId = 0;
  String userName = '';
  String userVaiTro = '';
  File? _selectedFile;
  PlatformFile? _pickedFile;
  bool _isSocketConnected = false;
  Map<String, dynamic>? topicDetail;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    SocketService.leaveTopic(widget.topicId);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndReconnectSocket();
    }
  }

  // ==================== LOAD USER INFO ====================
  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('userId') ?? 0;
      final name = prefs.getString('hoTen') ?? '';
      final vaiTro = prefs.getString('vaiTro') ?? 'hocvien';

      print('User loaded - ID: $id, Name: $name, Role: $vaiTro');

      setState(() {
        userId = id;
        userName = name;
        userVaiTro = vaiTro;
      });

      if (userId != 0) {
        await _connectSocket();
        await _loadTopicDetail();
      }
    } catch (e) {
      print('Lỗi load user info: $e');
    }
  }

  // ==================== SOCKET ====================
  Future<void> _connectSocket() async {
    if (userId == 0) return;

    print('[UI] Connecting socket for topic...');

    if (!SocketService.isConnected()) {
      print('[UI] Socket not connected, calling connect()...');
      SocketService.connect();
    }

    _waitForSocketConnection();
  }

  Future<void> _waitForSocketConnection() async {
    int attempts = 0;
    const maxAttempts = 20;

    while (attempts < maxAttempts) {
      if (SocketService.isConnected()) {
        _isSocketConnected = true;
        print('Socket connected, joining topic ${widget.topicId}...');

        SocketService.joinTopic(widget.topicId);

        SocketService.onReceiveTopicMessage((data) {
          _onReceiveMessage(data);
        });
        SocketService.onTopicMessageEdited((data) {
          _onMessageEdited(data);
        });
        SocketService.onTopicMessageDeleted((data) {
          _onMessageDeleted(data);
        });

        setState(() {});
        return;
      }

      attempts++;
      print('Waiting for socket... ($attempts/$maxAttempts)');
      await Future.delayed(const Duration(milliseconds: 500));
    }

    print('Cannot connect to socket after $maxAttempts attempts');
    setState(() {
      _isSocketConnected = false;
    });
  }

  void _checkAndReconnectSocket() {
    if (!_isSocketConnected && userId != 0) {
      print('Reconnecting socket...');
      _connectSocket();
    }
  }

  void _reconnectSocket() {
    setState(() {
      _isSocketConnected = false;
    });
    SocketService.disconnect();
    SocketService.connect();
    _waitForSocketConnection();
  }

  // ==================== SOCKET EVENT HANDLERS ====================
  void _onReceiveMessage(Map<String, dynamic> data) {
    if (!mounted) return;

    final messageData = data['message'] ?? data;

    print(
      'Received topic message: ${messageData['noiDung'] ?? messageData['content']}',
    );

    final exists = messages.any((m) => m['id'] == messageData['id']);
    if (exists) return;

    final newMessage = {
      'id': messageData['id'] ?? DateTime.now().millisecondsSinceEpoch,
      'noiDung': messageData['noiDung'] ?? messageData['content'] ?? '',
      'fileUrl': messageData['fileUrl'],
      'ngayTao': messageData['ngayTao'] ?? DateTime.now().toIso8601String(),
      'nguoidung': {
        'idNguoiDung':
            messageData['nguoidung']?['idNguoiDung'] ??
            messageData['userId'] ??
            0,
        'hoTen':
            messageData['nguoidung']?['hoTen'] ??
            messageData['userName'] ??
            'Unknown',
        'vaiTro':
            messageData['nguoidung']?['vaiTro'] ??
            messageData['vaiTro'] ??
            'hocvien',
      },
    };

    setState(() {
      messages.add(newMessage);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onMessageEdited(Map<String, dynamic> data) {
    if (!mounted) return;
    print('Topic message edited: ${data['idMessage']}');

    setState(() {
      final index = messages.indexWhere((m) => m['id'] == data['idMessage']);
      if (index != -1) {
        messages[index]['noiDung'] = data['noiDung'] ?? data['newContent'];
      }
    });
  }

  void _onMessageDeleted(Map<String, dynamic> data) {
    if (!mounted) return;
    print('Topic message deleted: ${data['idMessage']}');

    setState(() {
      messages.removeWhere((m) => m['id'] == data['idMessage']);
    });
  }

  // ==================== LOAD TOPIC DETAIL ====================
 Future<void> _loadTopicDetail() async {
  try {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('$apiUrl/topic/${widget.topicId}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final topic = data['data'];
      setState(() {
        topicDetail = topic;
        messages = List<Map<String, dynamic>>.from(topic['messages'] ?? []);
        isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } else {
      throw Exception('Lỗi tải chi tiết chủ đề');
    }
  } catch (e) {
    print('Lỗi load topic detail: $e');
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Lỗi tải chi tiết chủ đề: $e')));
  }
}

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  // ==================== SEND MESSAGE ====================
  Future<void> _sendMessage({String? text,File? file, PlatformFile? platformFile,}) async {
    final messageText = text ?? _messageController.text.trim();
    if (messageText.isEmpty && file == null && platformFile == null) return;

    setState(() => isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Chưa đăng nhập');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$apiUrl/message/${widget.topicId}'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      if (messageText.isNotEmpty) {
        request.fields['noiDung'] = messageText;
      }

      if (kIsWeb && platformFile != null) {
        final bytes = platformFile.bytes;
        if (bytes != null) {
          final multipartFile = http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: platformFile.name,
          );
          request.files.add(multipartFile);
        }
      } else if (!kIsWeb && file != null) {
        final stream = http.ByteStream(file.openRead());
        final length = await file.length();
        final multipartFile = http.MultipartFile(
          'file',
          stream,
          length,
          filename: file.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();

      if (response.statusCode == 201) {
        _messageController.clear();
        setState(() {
          _selectedFile = null;
          _pickedFile = null;
        });
      } else {
        final responseData = await response.stream.bytesToString();
        final data = jsonDecode(responseData);
        throw Exception(data['message'] ?? 'Gửi tin nhắn thất bại');
      }
    } catch (e) {
      print('Lỗi gửi tin nhắn: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi gửi tin nhắn: $e')));
      }
    } finally {
      setState(() => isSending = false);
    }
  }

  // ==================== FILE PICKER ====================
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          _pickedFile = result.files.first;
          _selectedFile = null;
        } else {
          _selectedFile = File(result.files.first.path!);
          _pickedFile = null;
        }
      });
    }
  }

  // ==================== DELETE MESSAGE ====================
  Future<void> _deleteMessage(int idMessage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Chưa đăng nhập');
      }

      final response = await http.delete(
        Uri.parse('$apiUrl/message/$idMessage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Xóa tin nhắn thất bại');
      }
    } catch (e) {
      print('Lỗi xóa tin nhắn: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi xóa tin nhắn: $e')));
      }
    }
  }

  // ==================== EDIT MESSAGE ====================
  Future<void> _editMessage(int idMessage, String newText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('Chưa đăng nhập');
      }

      final response = await http.put(
        Uri.parse('$apiUrl/message/$idMessage'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'noiDung': newText}),
      );

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Sửa tin nhắn thất bại');
      }
    } catch (e) {
      print('Lỗi sửa tin nhắn: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi sửa tin nhắn: $e')));
      }
    }
  }

  // ==================== DELETE DIALOG ====================
  void _showDeleteDialog(int idMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tin nhắn'),
        content: const Text('Bạn có chắc muốn xóa tin nhắn này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(idMessage);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // ==================== EDIT DIALOG ====================
  void _showEditDialog(int idMessage, String currentText) {
    final controller = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sửa tin nhắn'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Nhập nội dung mới',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                Navigator.pop(context);
                _editMessage(idMessage, newText);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // ==================== OPEN FILE ====================
  Future<void> _openFile(String url) async {
    if (url.isEmpty) return;

    final extension = url.split('.').last.toLowerCase();

    if (extension == 'mp4' || extension == 'mov' || extension == 'avi') {
      _showVideoPopup(context, url);
      return;
    }

    String finalUrl = url;

    if (url.contains("upload/") &&
        (extension == 'pdf' ||
            extension == 'png' ||
            extension == 'jpg' ||
            extension == 'jpeg')) {
      finalUrl = url.replaceFirst("upload/", "upload/fl_attachment/");
    }

    final uri = Uri.parse(finalUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await _fallbackOpen(url);
      }
    } catch (e) {
      debugPrint("Lỗi mở file: $e");
      await _fallbackOpen(url);
    }
  }

  Future<void> _fallbackOpen(String url) async {
    final extension = url.split('.').last.toLowerCase();

    try {
      if (extension == 'doc' || extension == 'docx') {
        final viewer = "https://docs.google.com/gview?embedded=true&url=$url";
        await launchUrl(
          Uri.parse(viewer),
          mode: LaunchMode.externalApplication,
        );
        return;
      }
      await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint("Fallback cũng fail: $e");
    }
  }

  void _showVideoPopup(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayerWidget(url: url),
        ),
      ),
    );
  }
  // ==================== BUILD MESSAGE ITEM ====================
  Widget _buildMessageItem(Map<String, dynamic> message) {
    final isMe = message['nguoidung']['idNguoiDung'] == userId;
    final hasFile = message['fileUrl'] != null && message['fileUrl'].isNotEmpty;
    final hasText = message['noiDung'] != null && message['noiDung'].isNotEmpty;
    final isGiangVienMessage = message['nguoidung']['vaiTro'] == 'giangvien';
    final isLeader = _isTruongNhom();
    final canDelete = isMe || (isLeader && !isGiangVienMessage);
    final canEdit = isMe;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Row(
                      children: [
                        Text(
                          message['nguoidung']['hoTen'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (isGiangVienMessage)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'GV',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (!isMe) const SizedBox(height: 2),
                  if (hasText)
                    Text(
                      message['noiDung'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isGiangVienMessage ? Colors.red.shade700 : null,
                      ),
                    ),
                  if (hasFile && hasText) const SizedBox(height: 4),
                  if (hasFile)
                    GestureDetector(
                      onTap: () => _openFile(message['fileUrl']),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.attach_file, size: 14),
                            SizedBox(width: 4),
                            Text('Xem file', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message['ngayTao']),
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                      if (canDelete || canEdit)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 14),
                          onSelected: (value) {
                            if (value == 'edit' && canEdit) {
                              _showEditDialog(
                                message['id'],
                                message['noiDung'] ?? '',
                              );
                            } else if (value == 'delete') {
                              _showDeleteDialog(message['id']);
                            }
                          },
                          itemBuilder: (context) => [
                            if (canEdit)
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                      color: Colors.orange,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text('Sửa', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                            if (canDelete)
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text('Xóa', style: TextStyle(fontSize: 13)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isTruongNhom() {
    if (topicDetail == null) {
      return false;
    }
    if (topicDetail!['group'] == null) {
      return false;
    }
    final group = topicDetail!['group'];
    if (group['members'] == null) {
      return false;
    }
    final members = group['members'] as List;
    for (var member in members) {
      final memberId = member['idNguoiDung'] ?? member['nguoidung']?['idNguoiDung'];
      print('memberId: $memberId, userId: $userId');
      if (memberId == userId) {
        print('User $userId is group leader');
        return true;
      }
    }
    print('User $userId is NOT group leader');
    return false;
  }

  String _formatTime(String? time) {
    if (time == null) return '';
    final d = DateTime.tryParse(time);
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tieuDe, overflow: TextOverflow.ellipsis),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _isSocketConnected ? Icons.wifi : Icons.wifi_off,
              color: _isSocketConnected ? Colors.green : Colors.red,
            ),
            onPressed: _reconnectSocket,
            tooltip: _isSocketConnected
                ? 'Đã kết nối'
                : 'Mất kết nối, nhấn để kết nối lại',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTopicDetail,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Chưa có tin nhắn trong chủ đề',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Hãy là người đầu tiên thảo luận!',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    cacheExtent: 100.0,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = messages.length - 1 - index;
                      return _buildMessageItem(messages[reversedIndex]);
                    },
                  ),
          ),
          if (_selectedFile != null || _pickedFile != null) _buildFilePreview(),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ==================== BUILD FILE PREVIEW ====================
  Widget _buildFilePreview() {
    final fileName = kIsWeb
        ? _pickedFile?.name ?? ''
        : _selectedFile?.path.split('/').last ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => setState(() {
                      _selectedFile = null;
                      _pickedFile = null;
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD INPUT BAR ====================
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, size: 22),
            onPressed: isSending ? null : _pickFile,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Nhập tin nhắn...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
              ),
              onChanged: (text) {
                if (text.isNotEmpty && userId != 0 && _isSocketConnected) {
                  SocketService.sendTyping(
                    groupId: widget.idGroup,
                    userId: userId,
                    userName: userName,
                    isTyping: true,
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: isSending
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  )
                : const Icon(Icons.send, color: Colors.blue, size: 24),
            onPressed: isSending
                ? null
                : () {
                    if (_selectedFile != null) {
                      _sendMessage(file: _selectedFile);
                    } else if (_pickedFile != null) {
                      _sendMessage(platformFile: _pickedFile);
                    } else {
                      _sendMessage();
                    }
                  },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ==================== VIDEO PLAYER WIDGET ====================
class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _controller = VideoPlayerController.network(widget.url);
      await _controller!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.lightBlue,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.blue),
          ),
        ),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Lỗi load video: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Đang tải video...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    if (_chewieController == null || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 48),
              SizedBox(height: 16),
              Text(
                'Không thể tải video',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Chewie(controller: _chewieController!);
  }
}
