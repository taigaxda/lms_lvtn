import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'chiTietTopicScreen.dart';

class DanhSachTopicScreen extends StatefulWidget {
  final int idGroup;
  final String tenNhom;

  const DanhSachTopicScreen({
    super.key,
    required this.idGroup,
    required this.tenNhom,
  });

  @override
  State<DanhSachTopicScreen> createState() => _DanhSachTopicScreenState();
}

class _DanhSachTopicScreenState extends State<DanhSachTopicScreen> {
  List topics = [];
  bool isLoading = true;
  bool isCreating = false;
  int _currentUserId = 0;

  final String apiUrl = '${ApiConfig.baseUrl}/topics';

  @override
  void initState() {
    super.initState();
    fetchTopics();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentUserId = prefs.getInt('userId') ?? 0;
    });
  }

  Future<void> fetchTopics() async {
    try {
      setState(() {
        isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.get(
        Uri.parse('$apiUrl/topics/${widget.idGroup}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          topics = data['data'] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception("Lỗi tải danh sách chủ đề");
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải danh sách chủ đề: $e")));
    }
  }

  Future<void> _createTopicFromMessage() async {
    _showCreateTopicDialog();
  }

  void _showCreateTopicDialog() {
    final TextEditingController _tieuDeController = TextEditingController();
    final TextEditingController _moTaController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Tạo chủ đề thảo luận'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tieuDeController,
              decoration: const InputDecoration(
                labelText: 'Tiêu đề chủ đề *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _moTaController,
              decoration: const InputDecoration(
                labelText: 'Mô tả (không bắt buộc)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_tieuDeController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vui lòng nhập tiêu đề')),
                );
                return;
              }
              Navigator.pop(context);
              await _createTopic(
                tieuDe: _tieuDeController.text.trim(),
                moTa: _moTaController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tạo chủ đề'),
          ),
        ],
      ),
    );
  }

  Future<void> _closeTopic(int topicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.put(
        Uri.parse('$apiUrl/close/$topicId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã đóng chủ đề'),
            backgroundColor: Colors.orange,
          ),
        );
        await fetchTopics();
      } else {
        throw Exception(data['message'] ?? 'Đóng chủ đề thất bại');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _confirmCloseTopic(int topicId, String tieuDe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đóng chủ đề'),
        content: Text(
          'Bạn có chắc chắn muốn đóng chủ đề "$tieuDe"?\n\nSau khi đóng, không ai có thể gửi tin nhắn mới vào chủ đề này.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _closeTopic(topicId);
            },
            child: const Text('Đóng chủ đề'),
          ),
        ],
      ),
    );
  }

  void _confirmReopenTopic(int topicId, String tieuDe) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mở lại chủ đề'),
        content: Text(
          'Bạn có chắc chắn muốn mở lại chủ đề "$tieuDe"?\n\nMọi người sẽ có thể tiếp tục thảo luận.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _reopenTopic(topicId);
            },
            child: const Text('Mở lại chủ đề'),
          ),
        ],
      ),
    );
  }

  Future<void> _reopenTopic(int topicId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.put(
        Uri.parse('$apiUrl/reopen/$topicId'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã mở lại chủ đề'),
            backgroundColor: Colors.green,
          ),
        );
        await fetchTopics();
      } else {
        throw Exception(data['message'] ?? 'Mở lại chủ đề thất bại');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _createTopic({
    required String tieuDe,
    required String moTa,
  }) async {
    try {
      setState(() {
        isCreating = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final response = await http.post(
        Uri.parse('$apiUrl/create-from-message/${widget.idGroup}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "idMessageGoc": null,
          "tieuDe": tieuDe,
          "moTa": moTa,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tạo chủ đề thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        await fetchTopics();
        setState(() {
          isCreating = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Tạo chủ đề thất bại');
      }
    } catch (e) {
      setState(() {
        isCreating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  void _navigateToTopicDetail(Map topic) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChiTietTopicScreen(
          topicId: topic['id'],
          tieuDe: topic['tieuDe'] ?? 'Chủ đề',
          idGroup: widget.idGroup,
        ),
      ),
    ).then((result) {
      if (result == true) {
        fetchTopics();
      }
    });
  }

  Widget _buildTopicItem(Map topic) {
    final nguoiTao = topic['nguoiTao'];
    final soTinNhan = topic['soTinNhan'] ?? 0;
    final soNguoiThamGia = topic['soNguoiThamGia'] ?? 0;
    final trangThai = topic['trangThai'] ?? 'active';
    final tinNhanMoiNhat = topic['tinNhanMoiNhat'];
    final daXem = topic['daXem'] ?? false;
    final isClosed = trangThai == 'closed';
    final currentUserId = _getCurrentUserId();
    final isCreator = currentUserId == nguoiTao?['idNguoiDung'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isClosed ? Colors.grey : Colors.orange,
          child: Icon(
            isClosed ? Icons.lock : Icons.forum,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          topic['tieuDe'] ?? 'Không có tiêu đề',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isClosed ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${nguoiTao?['hoTen'] ?? 'Unknown'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 2),
            Wrap(
              spacing: 8,
              children: [
                Text(
                  '$soTinNhan tin nhắn',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                Text(
                  '$soNguoiThamGia người tham gia',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                if (isClosed)
                  const Text(
                    'Đã đóng',
                    style: TextStyle(fontSize: 11, color: Colors.red),
                  ),
                if (tinNhanMoiNhat != null)
                  Text(
                    '${_formatTime(tinNhanMoiNhat['ngayTao'])}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
            if (topic['moTa'] != null && topic['moTa'].isNotEmpty)
              Text(
                topic['moTa'],
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (topic['tinNhanGoc'] != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tin nhắn gốc:',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      topic['tinNhanGoc']['noiDung'] ?? '',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!daXem && !isClosed)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            if (isCreator)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'close') {
                    _confirmCloseTopic(topic['id'], topic['tieuDe']);
                  } else if (value == 'reopen') {
                    _confirmReopenTopic(topic['id'], topic['tieuDe']);
                  }
                },
                itemBuilder: (context) => [
                  if (!isClosed)
                    const PopupMenuItem<String>(
                      value: 'close',
                      child: Row(
                        children: [
                          Icon(Icons.lock, color: Colors.orange, size: 16),
                          SizedBox(width: 8),
                          Text('Đóng chủ đề', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                  if (isClosed)
                    const PopupMenuItem<String>(
                      value: 'reopen',
                      child: Row(
                        children: [
                          Icon(Icons.lock_open, color: Colors.green, size: 16),
                          SizedBox(width: 8),
                          Text('Mở lại chủ đề', style: TextStyle(fontSize: 13)),
                        ],
                      ),
                    ),
                ],
              ),
            IconButton(
              icon: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isClosed ? Colors.grey : Colors.blue,
              ),
              onPressed: () => _navigateToTopicDetail(topic),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        onTap: () => _navigateToTopicDetail(topic),
      ),
    );
  }

  int _getCurrentUserId() {
    return _currentUserId;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "Chưa có chủ đề nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hãy tạo chủ đề thảo luận từ tin nhắn",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? time) {
    if (time == null) return '';
    final d = DateTime.tryParse(time);
    if (d == null) return '';
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inDays > 0) {
      return '${diff.inDays} ngày trước';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} phút trước';
    } else {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('💬 Chủ đề - ${widget.tenNhom}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchTopics,
            tooltip: "Tải lại",
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : topics.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: fetchTopics,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                itemCount: topics.length,
                itemBuilder: (context, index) {
                  return _buildTopicItem(topics[index]);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: isCreating ? null : _createTopicFromMessage,
        child: isCreating
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        tooltip: "Tạo chủ đề mới",
      ),
    );
  }
}
