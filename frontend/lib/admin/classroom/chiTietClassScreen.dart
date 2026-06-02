import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chitietclassscreen extends StatefulWidget {
  final int idKhoaHoc;

  const Chitietclassscreen({super.key, required this.idKhoaHoc});

  @override
  State<Chitietclassscreen> createState() => _ChitietclassscreenState();
}

class _ChitietclassscreenState extends State<Chitietclassscreen> {
  Map<String, dynamic>? lopHoc;
  bool isLoading = true;

  Future<void> fetchChiTiet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/admin/lophoc/${widget.idKhoaHoc}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      final data = jsonDecode(res.body);

      setState(() {
        lopHoc = data;
        isLoading = false;
      });
    } catch (e) {
      print("Lỗi: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchChiTiet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết lớp học"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : lopHoc == null
          ? const Center(child: Text("Không có dữ liệu"))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lopHoc!["tenKhoaHoc"] ?? "",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),

                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.description, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  lopHoc!["moTa"] ?? "Không có mô tả",
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.category, color: Colors.orange),
                              const SizedBox(width: 8),
                              Text(
                                "Danh mục: ${lopHoc!["danhMuc"] ?? "Không có"}",
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  lopHoc!["nguoidung"]?["hoTen"] != null
                                      ? lopHoc!["nguoidung"]["hoTen"][0]
                                      : "?",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  lopHoc!["nguoidung"]?["hoTen"] ?? "Không có",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.people, color: Colors.green),
                                const SizedBox(width: 6),
                                Text(
                                  "${lopHoc!["_count"]["dangky_khoahoc"]} học viên",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: lopHoc!["dangky_khoahoc"].length,
                    itemBuilder: (context, index) {
                      final dk = lopHoc!["dangky_khoahoc"][index];
                      final user = dk["nguoidung"];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              user["hoTen"] != null && user["hoTen"].isNotEmpty
                                  ? user["hoTen"][0]
                                  : "?",
                            ),
                          ),
                          title: Text(user["hoTen"] ?? ""),
                          subtitle: Text(user["email"] ?? ""),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
