import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'themSuaBaiTapGV.dart';
import 'danhSachBaiNopGVScreen.dart';

class Baitapgvscreen extends StatefulWidget {
  final int idKhoaHoc;
  const Baitapgvscreen({super.key, required this.idKhoaHoc});
  @override
  State<Baitapgvscreen> createState() => _Baitapgvscreen();
}

class _Baitapgvscreen extends State<Baitapgvscreen> {
  List assignments = [];
  bool isLoading = true;
  final String apiUrl = '${ApiConfig.baseUrl}/giangvien/baitap';

  @override
  void initState() {
    super.initState();
    fetchBaiTap();
  }

  Future<void> fetchBaiTap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.get(
        Uri.parse('$apiUrl/${widget.idKhoaHoc}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      final data = jsonDecode(res.body);
      if (data['success']) {
        setState(() {
          assignments = data["data"];
        });
      }
    } catch (e) {
      debugPrint("Lỗi fetch assignments: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> xoaBaiTap(int idAssignment) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.delete(
        Uri.parse('$apiUrl/$idAssignment'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(res.body);

      if (data["success"]) {
        showMessage("Xóa bài tập thành công");
        fetchBaiTap();
      } else {
        showMessage(data["message"] ?? "Xóa thất bại", isError: true);
      }
    } catch (e) {
      showMessage("Lỗi kết nối server", isError: true);
    }
  }

  void confirmDelete(int idAssignment) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn muốn xóa bài tập này?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              xoaBaiTap(idAssignment);
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String formatDate(String? date) {
    if (date == null) return "Không có";

    final d = DateTime.tryParse(date);
    if (d == null) return "Không hợp lệ";

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return "${twoDigits(d.day)}/${twoDigits(d.month)}/${d.year} "
        "${twoDigits(d.hour)}:${twoDigits(d.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: const Text("Quản lý bài tập"),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blue,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Themsuabaitapgv(idKhoaHoc: widget.idKhoaHoc),
            ),
          );

          if (result == true) fetchBaiTap();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Thêm bài tập",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: fetchBaiTap,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : assignments.isEmpty
            ? const Center(
                child: Text(
                  "Chưa có bài tập",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final item = assignments[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Danhsachbainopgvscreen(
                              submissions: item["submissions"] ?? [],
                              tieuDe: item["tieuDe"] ?? "",
                            ),
                          ),
                        );
                      },
                      contentPadding: const EdgeInsets.all(12),
                      leading: const Icon(Icons.assignment, color: Colors.blue),
                      title: Text(
                        item["tieuDe"] ?? "Không có tiêu đề",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(item["moTa"] ?? ""),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14),
                              const SizedBox(width: 4),
                              Text("Hạn: ${formatDate(item["hanNop"])}"),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Số bài nộp: ${item["submissions"]?.length ?? 0}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
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
                                  builder: (_) => Themsuabaitapgv(
                                    idKhoaHoc: widget.idKhoaHoc,
                                    baiTap: item,
                                  ),
                                ),
                              );

                              if (result == true) fetchBaiTap();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                confirmDelete(item["idAssignment"]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
