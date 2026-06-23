import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'package:frontend/admin/thongbao/themSuaThongBaoAdminScreen.dart';

class Thongbaolopadminscreen extends StatefulWidget {
  final int idKhoaHoc;
  const Thongbaolopadminscreen({super.key, required this.idKhoaHoc});
  @override
  State<Thongbaolopadminscreen> createState() => _ThongbaolopadminscreenState();
}

class _ThongbaolopadminscreenState extends State<Thongbaolopadminscreen> {
  List thongBaoLop = [];
  bool isLoading = true;
  final String apiUrl = '${ApiConfig.baseUrl}/admin/thongbao';

  @override
  void initState() {
    super.initState();
    fetchThongBaoLop();
  }

  Future<void> fetchThongBaoLop() async {
    try {
      setState(() => isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.get(
        Uri.parse('$apiUrl/${widget.idKhoaHoc}'),
        headers: {"Authorization": "Bearer $token"},
      );
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            thongBaoLop = data['data'] ?? [];
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception("Lỗi server: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi thông báo lớp: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải thông báo: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteThongBao(int idThongBao) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.delete(
        Uri.parse('$apiUrl/$idThongBao'),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(res.body);
      
      if (res.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Xóa thành công")),
        );
        fetchThongBaoLop(); // Refresh lại danh sách
      } else {
        throw Exception(data['message'] ?? 'Xóa thất bại');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  String _formatDate(String? date) {
    if (date == null) return "Không rõ";
    final d = DateTime.tryParse(date);
    if (d == null) return "Không rõ";
    return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  Widget buildItem(Map tb) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: const Icon(
          Icons.school,
          color: Colors.green,
        ),
        title: Text(
          tb['tieuDe'] ?? "",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tb['noiDung'] ?? "",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.person, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  "Người đăng: ${tb['nguoiDang']?['hoTen'] ?? 'Không rõ'}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  _formatDate(tb['ngayTao']),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            )
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Themsuathongbaoadminscreen(
                      idThongBao: tb['idThongBao'],
                      idKhoaHoc: widget.idKhoaHoc,
                    ),
                  ),
                );
                if (result == true) {
                  fetchThongBaoLop();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text("Xác nhận xóa"),
                    content: const Text("Bạn có chắc chắn muốn xóa thông báo này?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Hủy"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          deleteThongBao(tb['idThongBao']);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text("Xóa"),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        onTap: () => _showDetailDialog(context, tb),
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Map tb) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          tb['tieuDe'] ?? 'Thông báo',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tb['noiDung'] ?? ''),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  "Người đăng: ${tb['nguoiDang']?['hoTen'] ?? 'Không rõ'}",
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _formatDate(tb['ngayTao']),
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo lớp học"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchThongBaoLop,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : thongBaoLop.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "Chưa có thông báo nào",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchThongBaoLop,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: thongBaoLop.length,
                    itemBuilder: (context, index) =>
                        buildItem(thongBaoLop[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Themsuathongbaoadminscreen(
                idKhoaHoc: widget.idKhoaHoc,
              ),
            ),
          );
          if (result == true) {
            fetchThongBaoLop();
          }
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}