import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class Chitietcommentscreen extends StatefulWidget {
  final int idComment;
  final int idBaiHoc;

  const Chitietcommentscreen({
    super.key,
    required this.idComment,
    required this.idBaiHoc,
  });

  @override
  State<Chitietcommentscreen> createState() => _Chitietcommentscreen();
}

class _Chitietcommentscreen extends State<Chitietcommentscreen> {
  Map<String, dynamic>? commentData;
  bool isLoading = true;
  final TextEditingController _replyController = TextEditingController();
  final String apiUrl = '${ApiConfig.baseUrl}/comments';
  String hoTen = "";
  String vaiTro = "";
  int idNguoiDung = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUserInfo();
    fetchCommentDetail();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
      idNguoiDung = prefs.getInt("userId") ?? 0;
      print("User Info - ID: $idNguoiDung, Role: $vaiTro");
    });
  }

  Future<void> fetchCommentDetail() async {
    try {
      setState(() {
        isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.get(
        Uri.parse('$apiUrl/chitiet/${widget.idComment}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            commentData = data['data'];
            isLoading = false;
          });
        }
      } else {
        throw Exception("Lỗi tải chi tiết comment");
      }
    } catch (e) {
      debugPrint("Lỗi fetch chi tiết: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> replyComment() async {
    final noiDung = _replyController.text.trim();
    if (noiDung.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập nội dung phản hồi")),
      );
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.post(
        Uri.parse('$apiUrl/reply'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({"idComment": widget.idComment, "noiDung": noiDung}),
      );
      if (res.statusCode == 201) {
        _replyController.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Phản hồi thành công")));
        fetchCommentDetail();
      } else {
        throw Exception("Phản hồi thất bại");
      }
    } catch (e) {
      debugPrint("Lỗi phản hồi: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Future<void> suaComment(int idComment, String noiDungMoi) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.put(
        Uri.parse('$apiUrl/$idComment'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({"noiDung": noiDungMoi}),
      );
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cập nhật thành công")));
        fetchCommentDetail();
      } else {
        throw Exception("Cập nhật thất bại");
      }
    } catch (e) {
      debugPrint("Lỗi sửa: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Future<void> xoaComment(int idComment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.delete(
        Uri.parse('$apiUrl/$idComment'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Xóa thành công")));
        fetchCommentDetail();
      } else {
        throw Exception("Xóa thất bại");
      }
    } catch (e) {
      debugPrint("Lỗi xóa: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  String _formatDate(String? date) {
    if (date == null) return "";
    final d = DateTime.tryParse(date);
    if (d == null) return "";
    return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  void _showEditDialog(int idComment, String noiDungHienTai) {
    final TextEditingController editController = TextEditingController(
      text: noiDungHienTai,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sửa bình luận"),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "Nhập nội dung mới",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              final noiDungMoi = editController.text.trim();
              if (noiDungMoi.isNotEmpty) {
                Navigator.pop(context);
                suaComment(idComment, noiDungMoi);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Nội dung không được để trống")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int idComment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa bình luận này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              xoaComment(idComment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(Map comment, {bool isReply = false}) {
    final int commentUserId =
        int.tryParse(comment['nguoidung']['idNguoiDung'].toString()) ?? 0;
    final isOwner = commentUserId == idNguoiDung && idNguoiDung != 0;
    final isGiangVien = vaiTro == 'giangvien';
    final canEdit = isOwner;
    final canDelete = isOwner || isGiangVien;
    return Card(
      margin: EdgeInsets.only(left: isReply ? 16 : 0, bottom: 8),
      elevation: isReply ? 0 : 1,
      color: isReply ? Colors.grey.shade50 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: isReply ? 14 : 18,
                  backgroundColor: comment['nguoidung']['vaiTro'] == 'giangvien'
                      ? Colors.blue
                      : Colors.green,
                  child: Text(
                    comment['nguoidung']['hoTen'][0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isReply ? 10 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              comment['nguoidung']['hoTen'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isReply ? 13 : 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  comment['nguoidung']['vaiTro'] == 'giangvien'
                                  ? Colors.blue.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              comment['nguoidung']['vaiTro'] == 'giangvien'
                                  ? 'Giảng viên'
                                  : 'Học viên',
                              style: TextStyle(
                                fontSize: 10,
                                color:
                                    comment['nguoidung']['vaiTro'] ==
                                        'giangvien'
                                    ? Colors.blue
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDate(comment['ngayTao']),
                        style: TextStyle(
                          fontSize: isReply ? 10 : 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEdit)
                      IconButton(
                        onPressed: () {
                          _showEditDialog(
                            comment['idComment'],
                            comment['noiDung'],
                          );
                        },
                        icon: Icon(
                          Icons.edit,
                          size: isReply ? 16 : 18,
                          color: Colors.orange,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        splashRadius: 20,
                      ),
                    if (canDelete)
                      IconButton(
                        onPressed: () {
                          _showDeleteDialog(comment['idComment']);
                        },
                        icon: Icon(
                          Icons.delete,
                          size: isReply ? 16 : 18,
                          color: Colors.red,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        splashRadius: 20,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment['noiDung'] ?? '',
              style: TextStyle(fontSize: isReply ? 14 : 15),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết bình luận"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchCommentDetail,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : commentData == null
          ? const Center(child: Text("Không tìm thấy bình luận"))
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Comment cha
                      _buildCommentCard(commentData!),

                      // Tiêu đề replies
                      if (commentData!['replies'] != null &&
                          commentData!['replies'].isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.reply,
                                size: 16,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "${commentData!['replies'].length} phản hồi",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),

                      if (commentData!['replies'] != null)
                        ...(commentData!['replies'] as List)
                            .map(
                              (reply) =>
                                  _buildCommentCard(reply, isReply: true),
                            )
                            .toList(),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _replyController,
                          decoration: const InputDecoration(
                            hintText: "Viết phản hồi...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(24),
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          maxLines: null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: replyComment,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
