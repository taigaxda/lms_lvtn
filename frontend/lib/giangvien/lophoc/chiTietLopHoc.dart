import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/api.dart';
import 'package:frontend/giangvien/menuUI/giangVienMenuBar.dart';
import 'addBaiHocScreen.dart';
import 'package:frontend/giangvien/baikiemtra/baiKiemTraGVScreen.dart';
import 'package:frontend/giangvien/quanlyhocvien/qlhvGVScreen.dart';

class ChiTietLopHocScreen extends StatefulWidget {
  final int idKhoaHoc;
  const ChiTietLopHocScreen({super.key, required this.idKhoaHoc});

  @override
  State<ChiTietLopHocScreen> createState() => _ChiTietLopHocScreen();
}

class _ChiTietLopHocScreen extends State<ChiTietLopHocScreen> {
  int _selectedIndex = 0;
  bool isLoading = true;
  Map<String, dynamic>? lopHoc;
  List baiHocs = [];

  final String apiUrl = '${ApiConfig.baseUrl}/giangvien';
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
      debugPrint("Lỗi tải dữ liệu: $e");
    } finally {
      setState(() => isLoading = false);
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
    if (res.statusCode == 200) lopHoc = json.decode(res.body)['data'];
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
      setState(() {
        baiHocs = json.decode(res.body)['data'];
      });
    }
  }

  Future<void> openAddBaiHoc(int id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Addbaihocscreen(idKhoaHoc: id)),
    );
    if (result == true) loadAllData();
  }

  Future<void> deleteBaiHoc(int idBaiHoc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");
      final response = await http.delete(
        Uri.parse('${apiUrl}/baihoc/$idBaiHoc'),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId.toString(),
        },
      );
      final data = jsonDecode(response.body);
      if (data["success"] == true) {
        loadAllData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Xoá bài học thành công")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Xoá thất bại")),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  void confirmDelete(int idBaiHoc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xoá bài học"),
        content: const Text("Bạn có chắc muốn xoá bài học này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Huỷ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteBaiHoc(idBaiHoc);
            },
            child: const Text("Xoá", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      openAddBaiHoc(widget.idKhoaHoc);
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Baikiemtragvscreen(idKhoaHoc: widget.idKhoaHoc),
        ),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QlhvGVScreen(idKhoaHoc: widget.idKhoaHoc),
        ),
      );
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  Future<void> _openFile(String? url) async {
    if (url == null || url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể mở liên kết này")),
      );
    }
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
        elevation: 0,
      ),
      drawer: GiangVienMenuBar(hoTen: hoTen, vaiTro: vaiTro),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadAllData,
              child: _buildBodyContent(),
            ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Bài học"),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: "Tạo bài học",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.quiz),
            label: "Bài kiểm tra",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Quản lý học viên",
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.qr_code,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Mã lớp: ${lopHoc?['code'] ?? ""}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "Số bài học: ${baiHocs.length}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              "DANH SÁCH BÀI GIẢNG",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: baiHocs.length,
            itemBuilder: (context, index) {
              final b = baiHocs[index];
              final hasVideo = b['videoUrl'] != null && b['videoUrl'] != "";
              final hasDoc = b['taiLieuUrl'] != null && b['taiLieuUrl'] != "";

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text("Thứ tự: ${b['thuTu'] ?? index + 1}"),
                  ),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      final id = b['idBaiHoc'];
                      confirmDelete(id);
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
