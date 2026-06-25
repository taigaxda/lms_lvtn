import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'chitietCommentScreen.dart';

class Commentsscreen extends StatefulWidget {
  final int idBaiHoc;
  const Commentsscreen({super.key, required this.idBaiHoc});
  @override
  State<Commentsscreen> createState() => _Commentsscreen();
}

class _Commentsscreen extends State<Commentsscreen> {
  List comments = [];
  bool isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  final String apiUrl = '${ApiConfig.baseUrl}/comments';
  String hoTen = "";
  String vaiTro = "";
  int idNguoiDung = 0;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUserInfo();
    fetchComments();
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

  Future<void> fetchComments() async {
    try {
      setState(() {
        isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.get(
        Uri.parse('$apiUrl/commentbaihoc/${widget.idBaiHoc}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            comments = data['data'];
            isLoading = false;
          });
        }
      } else {
        throw Exception("Lỗi tải comment");
      }
    } catch (e) {
      debugPrint("Lỗi fetch comments: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> taoComment() async {
    final noiDung = _commentController.text.trim();
    if (noiDung.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập nội dung bình luận")),
      );
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final body = {"idBaiHoc": widget.idBaiHoc, "noiDung": noiDung};
      final res = await http.post(
        Uri.parse('$apiUrl/'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode(body),
      );
      if (res.statusCode == 201) {
        _commentController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng tải bình luận thành công")),
        );
        fetchComments();
      } else {
        throw Exception("Đăng tải bình luận thất bại");
      }
    } catch (e) {
      debugPrint("Lỗi tạo comment: $e");
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
        fetchComments();
      } else {
        throw Exception("Cập nhật thất bại");
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật comment: $e");
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
        fetchComments();
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

  void openChiTietComment(Map comment) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Chitietcommentscreen(
          idComment: comment['idComment'],
          idBaiHoc: widget.idBaiHoc,
        ),
      ),
    ).then((_) => fetchComments());
  }

  Widget _buildCommentItem(Map comment) {
    final isOwner = comment['nguoidung']['idNguoiDung'] == idNguoiDung;
    final isGiangVien = vaiTro == 'giangvien';
    final canDelete = isOwner || isGiangVien;
    final canEdit = isOwner;
    final replyCount = (comment['replies'] as List?)?.length ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          openChiTietComment(comment);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        comment['nguoidung']['vaiTro'] == 'giangvien'
                        ? Colors.blue
                        : Colors.green,
                    child: Text(
                      comment['nguoidung']['hoTen'][0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow:
                                    TextOverflow.ellipsis, 
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
                                    comment['nguoidung']['vaiTro'] ==
                                        'giangvien'
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
                          style: const TextStyle(
                            fontSize: 11,
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
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
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
                          icon: const Icon(
                            Icons.delete,
                            size: 18,
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
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 8),
              if (replyCount > 0)
                Row(
                  children: [
                    const Icon(Icons.reply, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '$replyCount phản hồi',
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bình luận"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchComments),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : comments.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.comment, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Chưa có bình luận nào",
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Hãy là người đầu tiên bình luận!",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: fetchComments,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return _buildCommentItem(comments[index]);
                      },
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 4),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: "Viết bình luận...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
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
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: taoComment,
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
