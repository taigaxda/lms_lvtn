import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'themSuaThongBaoGVScreen.dart';

class Thongbaogvscreen extends StatefulWidget {
  final int idKhoaHoc;
  const Thongbaogvscreen({super.key, required this.idKhoaHoc});
  @override
  State<Thongbaogvscreen> createState() => _Thongbaogvscreen();
}

class _Thongbaogvscreen extends State<Thongbaogvscreen> {
  List thongBaoLop = [];
  List thongBaoHeThong = [];
  bool isLoading = true;
  final String apiUrl = '${ApiConfig.baseUrl}/giangvien/thongbao';
  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => isLoading = true);
    await Future.wait([fetchThongBaoLop(), fetchThongBaoHeThong()]);
    setState(() => isLoading = false);
  }

  Future<void> fetchThongBaoLop() async {
    try {
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
    }
  }

  Future<void> fetchThongBaoHeThong() async {
    try {
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
    }
  }
  String _formatDate(String? date) {
    if (date == null) return "Không rõ";
    final d = DateTime.tryParse(date);
    if (d == null) return "Không rõ";
    return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  Widget buildItem(Map tb, bool isHeThong) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(
          isHeThong ? Icons.public : Icons.school,
          color: isHeThong ? Colors.blue : Colors.green,
        ),
        title: Text(tb['tieuDe'] ?? ""),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tb['noiDung'] ?? ""),
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
        trailing: !isHeThong
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Themsuathongbaogvscreen(
                            idThongBao: tb['idThongBao'],
                          ),
                        ),
                      );

                      if (result == true) loadAll();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Xác nhận"),
                          content: const Text("Bạn có chắc muốn xóa?"),
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
                              child: const Text("Xóa"),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              )
            : null,
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
        loadAll();
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Thông báo"),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Lớp"),
              Tab(text: "Hệ thống"),
            ],
            labelStyle: TextStyle(color: Colors.white),
            unselectedLabelColor: Colors.black54,
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  ListView.builder(
                    itemCount: thongBaoLop.length,
                    itemBuilder: (context, index) =>
                        buildItem(thongBaoLop[index], false),
                  ),
                  ListView.builder(
                    itemCount: thongBaoHeThong.length,
                    itemBuilder: (context, index) =>
                        buildItem(thongBaoHeThong[index], true),
                  ),
                ],
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    Themsuathongbaogvscreen(idKhoaHoc: widget.idKhoaHoc),
              ),
            );

            if (result == true) {
              loadAll(); // reload list
            }
          },
          child: Icon(Icons.add),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
