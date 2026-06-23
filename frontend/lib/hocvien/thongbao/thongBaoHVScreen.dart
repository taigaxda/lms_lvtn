import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class Thongbaohvscreen extends StatefulWidget {
  final int idKhoaHoc;
  const Thongbaohvscreen({super.key, required this.idKhoaHoc});
  @override
  State<Thongbaohvscreen> createState() => _Thongbaogvscreen();
}

class _Thongbaogvscreen extends State<Thongbaohvscreen> {
  List thongBaoLop = [];
  List thongBaoHeThong = [];
  bool isLoading = true;
  final String apiUrl = '${ApiConfig.baseUrl}/hocvien/thongbao';
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
            // Ngày đăng (xuống hàng)
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
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Thông báo"),
          backgroundColor: Colors.redAccent,
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
      ),
    );
  }
}
