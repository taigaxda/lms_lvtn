import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'themSuaThongBaoAdminScreen.dart';
import '../menuUI/adminMenuBar.dart';

class Thongbaoadminscreen extends StatefulWidget {
  const Thongbaoadminscreen({super.key});
  @override
  State<Thongbaoadminscreen> createState() => _Thongbaogvscreen();
}

class _Thongbaogvscreen extends State<Thongbaoadminscreen> {
  List thongBaoHeThong = [];
  bool isLoading = true;
  String hoTen = "";
  String vaiTro = "";
  final String apiUrl = '${ApiConfig.baseUrl}/admin/thongbao';
  @override
  void initState() {
    super.initState();
    loadUserInfo();
    fetchThongBaoHeThong();
  }
  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> fetchThongBaoHeThong() async {
    try {
      setState(() {
        isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.get(
        Uri.parse('$apiUrl/hethong'),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            thongBaoHeThong = data['data'] ?? [];
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception("Lỗi server: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi thông báo hệ thống: $e");
    } finally{
      setState(() {
        isLoading = false;
      });
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
          Icons.public,
          color: Colors.blue,
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
            ),
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
                      idKhoaHoc: null,  
                    ),
                  ),
                );
                if (result == true) {
                  fetchThongBaoHeThong();
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
                    content: const Text("Bạn có chắc chắn muốn xóa thông báo hệ thống này?"),
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
      ),
    );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Xóa thành công")));
        fetchThongBaoHeThong();
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo hệ thống"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchThongBaoHeThong,
            tooltip: 'Tải lại',
          ),
        ],
      ),
      drawer: AdminMenuBar(hoTen: hoTen, vaiTro: vaiTro),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : thongBaoHeThong.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "Chưa có thông báo hệ thống nào",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchThongBaoHeThong,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: thongBaoHeThong.length,
                    itemBuilder: (context, index) =>
                        buildItem(thongBaoHeThong[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Themsuathongbaoadminscreen(
                idKhoaHoc: null, 
              ),
            ),
          );
          if (result == true) {
            fetchThongBaoHeThong();
          }
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
