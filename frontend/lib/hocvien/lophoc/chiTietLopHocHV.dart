import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'package:frontend/hocvien/menuUI/hocVienMenuBar.dart';
import 'package:frontend/hocvien/lophoc/hocBaiScreen.dart';
import 'package:frontend/hocvien/lophoc/danhSachBaiKTScreen.dart';

class ChiTietLopHocHVScreen extends StatefulWidget {
  final int idKhoaHoc;

  const ChiTietLopHocHVScreen({super.key, required this.idKhoaHoc});

  @override
  State<ChiTietLopHocHVScreen> createState() => _ChiTietLopHocHVScreenState();
}

class _ChiTietLopHocHVScreenState extends State<ChiTietLopHocHVScreen> {
  bool isLoading = true;
  Map<String, dynamic>? lopHoc;
  List baiHocs = [];

  final String apiUrl = '${ApiConfig.baseUrl}/hocvien';
  String hoTen = "";
  String vaiTro = "";

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    loadAllData();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> loadAllData() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([loadChiTietLopHoc(), loadBaiHoc()]);
    } catch (e) {
      debugPrint("Lỗi: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> openHocBaiScreen(Map<String, dynamic> baiHoc) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            HocBaiScreen(idKhoaHoc: widget.idKhoaHoc, baiHoc: baiHoc),
      ),
    );

    if (result == true) {
      await loadAllData();
    }
  }

  Future<void> loadChiTietLopHoc() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");

    final res = await http.get(
      Uri.parse('$apiUrl/lophoc/${widget.idKhoaHoc}'),
      headers: {
        "Content-Type": "application/json",
        "x-user-id": userId.toString(),
      },
    );

    if (res.statusCode == 200) {
      lopHoc = json.decode(res.body)['data'];
    }
  }

  Future<void> loadBaiHoc() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");

    final res = await http.get(
      Uri.parse('$apiUrl/baihoc/${widget.idKhoaHoc}'),
      headers: {
        "Content-Type": "application/json",
        "x-user-id": userId.toString(),
      },
    );

    if (res.statusCode == 200) {
      baiHocs = json.decode(res.body)['data'];
    }
  }

  Future<void> openDSBaiKiemTraScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Danhsachbaiktscreen(idKhoaHoc: widget.idKhoaHoc),
      ),
    );
    await loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isLoading ? "Đang tải..." : (lopHoc?['tenKhoaHoc'] ?? "Chi tiết lớp"),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: Hocvienmenubar(hoTen: hoTen, vaiTro: vaiTro),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(onRefresh: loadAllData, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lopHoc?['tenKhoaHoc'] ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  "Giảng viên: ${lopHoc?['nguoidung']?['hoTen'] ?? ""}",
                  style: const TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 6),

                Text(
                  "Danh mục: ${lopHoc?['danhMuc'] ?? ""}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              "MÔ TẢ KHÓA HỌC",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(lopHoc?['moTa'] ?? "Không có mô tả"),
          ),
           Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ElevatedButton.icon(
              onPressed: openDSBaiKiemTraScreen,
              icon: const Icon(Icons.quiz),
              label: const Text("Xem bài kiểm tra"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              "DANH SÁCH BÀI HỌC",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              "Tổng bài học: ${baiHocs.length}",
              style: const TextStyle(color: Colors.blue),
            ),
          ),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: baiHocs.length,
            itemBuilder: (context, index) {
              final b = baiHocs[index];

              final hasVideo = b['videoUrl'] != null && b['videoUrl'] != "";
              final status = b['trangThai'] ?? "chua_hoc";

              Color statusColor;
              String statusText;

              switch (status) {
                case "hoan_thanh":
                  statusColor = Colors.green;
                  statusText = "Đã học";
                  break;
                case "dang_hoc":
                  statusColor = Colors.orange;
                  statusText = "Đang học";
                  break;
                default:
                  statusColor = Colors.grey;
                  statusText = "Chưa học";
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: hasVideo
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    child: Icon(
                      hasVideo ? Icons.play_circle : Icons.description,
                      color: hasVideo ? Colors.blue : Colors.orange,
                    ),
                  ),
                  title: Text(
                    b['tenBaiHoc'] ?? "",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Thứ tự: ${b['thuTu'] ?? index + 1}"),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                  onTap: () {
                    openHocBaiScreen(b);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
