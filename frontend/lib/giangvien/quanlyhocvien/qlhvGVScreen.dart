import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'qldiemGVScreen.dart';

class QlhvGVScreen extends StatefulWidget {
  final int idKhoaHoc;
  const QlhvGVScreen({super.key, required this.idKhoaHoc});

  @override
  State<QlhvGVScreen> createState() => _QlhvGVScreenState();
}

class _QlhvGVScreenState extends State<QlhvGVScreen> {
  List hocViens = [];
  bool isLoading = true;
  final String apiUrl = '${ApiConfig.baseUrl}/giangvien/qlhv';
  @override
  void initState() {
    super.initState();
    loadHocVien();
  }

  Future<void> loadHocVien() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");

      final res = await http.get(
        Uri.parse('$apiUrl/${widget.idKhoaHoc}'),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId.toString(),
        },
      );

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        hocViens = data['data'];
      }
    } catch (e) {
      debugPrint("Lỗi load học viên: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteHocVien(int idNguoiDung) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");

      final res = await http.delete(
        Uri.parse('$apiUrl/kick/${widget.idKhoaHoc}/$idNguoiDung'),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId.toString(),
        },
      );

      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        loadHocVien();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đã xóa học viên")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Xóa thất bại")),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  void confirmDelete(int idNguoiDung, String ten) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa học viên"),
        content: Text("Bạn có chắc muốn xóa \"$ten\" khỏi lớp không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              deleteHocVien(idNguoiDung);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quản lý học viên"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bar_chart,color: Colors.white,),
                      label: const Text("Xem điểm bài kiểm tra",style: TextStyle(color: Colors.white),),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                QlDiemGVScreen(idKhoaHoc: widget.idKhoaHoc),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        "Tổng học viên: ${hocViens.length}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: loadHocVien,
                    child: ListView.builder(
                      itemCount: hocViens.length,
                      itemBuilder: (context, index) {
                        final hv = hocViens[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              child: const Icon(
                                Icons.person,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              hv['hoTen'] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(hv['email'] ?? ""),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                confirmDelete(
                                  hv['idNguoiDung'],
                                  hv['hoTen'] ?? "",
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
