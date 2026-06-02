import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/hocvien/menuUI/hocVienMenuBar.dart';
import 'package:frontend/api.dart';
import 'package:frontend/hocvien/lophoc/chiTietLopHocHV.dart';

class HocVienScreen extends StatefulWidget {
  const HocVienScreen({super.key});

  @override
  State<HocVienScreen> createState() => _HocVienScreenState();
}

class _HocVienScreenState extends State<HocVienScreen> {
  List lopHocs = [];
  bool isLoading = true;

  final String apiUrl = '${ApiConfig.baseUrl}/hocvien/lophoc';
  String hoTen = "";
  String vaiTro = "";

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    fetchDSLopHoc();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> fetchDSLopHoc() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId != null ? userId.toString() : "",
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          lopHocs = data["data"] ?? [];
          isLoading = false;
        });
      } else {
        throw Exception('Lỗi load data');
      }
    } catch (e) {
      print(e);
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> openChiTietClass(Map<String, dynamic> lop) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChiTietLopHocHVScreen(idKhoaHoc: lop['idKhoaHoc']),
      ),
    );
    if (result == true) {
      fetchDSLopHoc();
    }
  }

  Future<void> thamGiaLopHoc(String codeLopHoc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy người dùng")),
        );
        return;
      }
      final response = await http.post(
        Uri.parse('$apiUrl/thamgia'),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId.toString(),
        },
        body: json.encode({"codeLop": codeLopHoc.trim()}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Tham gia thành công")));
        setState(() {
          isLoading = true;
        });
        await fetchDSLopHoc();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Có lỗi xảy ra")),
        );
      }
    } catch (e) {
      print("Lỗi tham gia lớp: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lỗi kết nối server")));
    }
  }

  void _showJoinDialog() {
    final TextEditingController _codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Tham gia lớp"),
          content: TextField(
            controller: _codeController,
            decoration: const InputDecoration(labelText: "Nhập mã lớp"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () {
                final code = _codeController.text.trim();
                if (code.isNotEmpty) {
                  thamGiaLopHoc(code);
                  Navigator.pop(context);
                }
              },
              child: const Text("Tham gia"),
            ),
          ],
        );
      },
    );
  }

  Future<void> roiLopHoc(int idKhoaHoc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy người dùng")),
        );
        return;
      }
      final response = await http.delete(
        Uri.parse('$apiUrl/roilop'),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId.toString(),
        },
        body: json.encode({"idKhoaHoc": idKhoaHoc}),
      );
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Rời lớp thành công")));
        setState(() {
          isLoading = true;
        });
        await fetchDSLopHoc();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Có lỗi xảy ra")),
        );
      }
    } catch (e) {
      print("Lỗi rời lớp: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lỗi kết nối server")));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.class_, size: 80, color: Colors.grey),
          const SizedBox(height: 12),
          const Text(
            "Chưa có lớp học",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Hãy tham gia lớp bằng mã lớp",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showJoinDialog,
            icon: const Icon(Icons.add),
            label: const Text("Tham gia lớp học"),
          ),
        ],
      ),
    );
  }

  void confirmRoiLop(int idKhoaHoc) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rời lớp"),
          content: const Text("Bạn có chắc muốn rời lớp học này không?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 230, 81, 71),
              ),
              onPressed: () async {
                Navigator.pop(context); // đóng dialog
                await roiLopHoc(idKhoaHoc); // gọi API
              },
              child: const Text("Rời lớp"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Học Viên"),
      backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      drawer: Hocvienmenubar(hoTen: hoTen, vaiTro: vaiTro),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : lopHocs.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: lopHocs.length,
              itemBuilder: (context, index) {
                final lop = lopHocs[index];
                final khoaHoc = lop['khoahoc'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        openChiTietClass(lop);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header giống Classroom
                          Container(
                            height: 90,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.blue.shade300],
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  khoaHoc?['tenKhoaHoc'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  "Giảng viên: ${khoaHoc?['nguoidung']?['hoTen'] ?? 'Chưa có GV'}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "Code: ${khoaHoc?['code'] ?? ''}",
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Xem chi tiết",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      confirmRoiLop(khoaHoc['idKhoaHoc']),
                                  icon: const Icon(Icons.exit_to_app),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showJoinDialog,
        child: const Icon(Icons.add,color: Colors.white,),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
