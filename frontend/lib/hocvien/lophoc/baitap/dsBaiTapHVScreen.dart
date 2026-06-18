import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'chiTietBaiTapHVScreen.dart';

class Dsbaitaphvscreen extends StatefulWidget {
  final int idKhoaHoc;

  const Dsbaitaphvscreen({super.key, required this.idKhoaHoc});

  @override
  State<Dsbaitaphvscreen> createState() => _Dsbaitaphvscreen();
}

class _Dsbaitaphvscreen extends State<Dsbaitaphvscreen> {
  bool isLoading = true;
  List dsBaiTap = [];

  final String apiUrl = '${ApiConfig.baseUrl}/hocvien/baitap';
  @override
  void initState() {
    super.initState();
    loadBaiTap();
  }

  Future<void> loadBaiTap() async {
    setState(() {
      isLoading = true;
    });
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
      if (res.statusCode == 200) {
        setState(() {
          dsBaiTap = json.decode(res.body)['data'];
        });
      } else {
        throw Exception("Lỗi server: ${res.statusCode}");
      }
    } catch (e) {
      debugPrint("Lỗi load bài tập: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Không thể tải bài tập")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  String getTrangThai(Map b) {
    final submissions = b['submissions'];
    if (submissions == null || submissions.isEmpty) {
      return "Chưa nộp";
    }
    final sub = submissions[0];
    if (sub['grades'] != null) {
      return "Đã chấm";
    }
    return "Đã nộp";
  }

  String formatDate(String? date) {
    if (date == null) return "Không có";

    final d = DateTime.tryParse(date);
    if (d == null) return "Không hợp lệ";

    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return "${twoDigits(d.day)}/${twoDigits(d.month)}/${d.year} "
        "${twoDigits(d.hour)}:${twoDigits(d.minute)}";
  }

  Color getColor(String status) {
    switch (status) {
      case "Đã chấm":
        return Colors.green;
      case "Đã nộp":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh sách bài tập"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadBaiTap,
              child: ListView.builder(
                itemCount: dsBaiTap.length,
                itemBuilder: (context, index) {
                  final bt = dsBaiTap[index];
                  final status = getTrangThai(bt);
                  final color = getColor(status);
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
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(Icons.assignment, color: color),
                      ),
                      title: Text(
                        bt['tieuDe'] ?? "",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hạn: ${formatDate(bt["hanNop"])}"),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChiTietBaiTapHVScreen(
                              // baiTap: bt
                              idAssignment: bt['idAssignment'],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
