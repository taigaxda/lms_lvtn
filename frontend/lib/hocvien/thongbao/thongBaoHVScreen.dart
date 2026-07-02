import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class Thongbaohvscreen extends StatefulWidget {
  final int idKhoaHoc;
  const Thongbaohvscreen({super.key, required this.idKhoaHoc});
  @override
  State<Thongbaohvscreen> createState() => _Thongbaohvscreen();
}

class _Thongbaohvscreen extends State<Thongbaohvscreen> {
  List thongBaoLop = [];
  List thongBaoHeThong = [];
  List thongBaoHocTap = [];
  bool isLoading = true;
  final String apiUrl = '${ApiConfig.baseUrl}/hocvien/thongbao';
  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => isLoading = true);
    await Future.wait([
      fetchThongBaoLop(),
      fetchThongBaoHeThong(),
      fetchThongBaoHocTap(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> fetchThongBaoLop() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.get(
        Uri.parse('$apiUrl/${widget.idKhoaHoc}/?loaiThongBao=thong_bao'),
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

  Future<void> fetchThongBaoHocTap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final loaiThongBao = 'quiz,bai_tap,bai_hoc';
      final res = await http.get(
        Uri.parse('$apiUrl/${widget.idKhoaHoc}?loaiThongBao=$loaiThongBao'),
        headers: {"Authorization": "Bearer $token"},
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['success'] == true) {
          setState(() {
            thongBaoHocTap = data['data'] ?? [];
          });
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception("Lỗi server: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi thông báo học tập: $e");
    }
  }

  String _formatDate(String? date) {
    if (date == null) return "Không rõ";
    final d = DateTime.tryParse(date);
    if (d == null) return "Không rõ";
    return "${d.day}/${d.month}/${d.year} ${d.hour}:${d.minute.toString().padLeft(2, '0')}";
  }

  String _getLoaiThongBaoText(String? loai) {
    switch (loai) {
      case 'quiz':
        return 'Quiz';
      case 'bai_tap':
        return 'Bài tập';
      case 'bai_hoc':
        return 'Bài học';
      default:
        return 'Thông báo';
    }
  }

  Color _getLoaiThongBaoColor(String? loai) {
    switch (loai) {
      case 'quiz':
        return Colors.purple;
      case 'bai_tap':
        return Colors.orange;
      case 'bai_hoc':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget buildItem(Map tb, bool isHeThong, {bool showLoai = false}) {
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
            if (showLoai && tb['loaiThongBao'] != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getLoaiThongBaoColor(
                    tb['loaiThongBao'],
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getLoaiThongBaoColor(
                      tb['loaiThongBao'],
                    ).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getLoaiThongBaoText(tb['loaiThongBao']),
                  style: TextStyle(
                    fontSize: 11,
                    color: _getLoaiThongBaoColor(tb['loaiThongBao']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Thông báo"),
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: "Lớp"),
              Tab(text: "Hệ thống"),
              Tab(text: "Học tập"),
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
                  thongBaoHocTap.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_off,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Không có thông báo học tập',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: thongBaoHocTap.length,
                          itemBuilder: (context, index) => buildItem(
                            thongBaoHocTap[index],
                            false,
                            showLoai: true,
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}
