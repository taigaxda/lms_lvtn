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

  bool isQuaHan(String? hanNop) {
    if (hanNop == null) return false;
    final han = DateTime.tryParse(hanNop);
    if (han == null) return false;
    return DateTime.now().isAfter(han);
  }

  String getTrangThai(Map b) {
    final submissions = b['submissions'];
    final hanNop = b['hanNop'];
    final daNop = submissions != null && submissions.isNotEmpty;
    final daQuaHan = isQuaHan(hanNop);

    if (daNop) {
      final sub = submissions[0];
      if (sub['grades'] != null) {
        return "Đã chấm";
      }
      if (daQuaHan) {
        return "Chờ chấm (quá hạn)";
      }
      return "Đã nộp";
    }
    if (daQuaHan) {
      return "Quá hạn";
    }
    return "Chưa nộp";
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
        return Colors.blue;
      case "Chờ chấm (quá hạn)":
        return Colors.orange;
      case "Quá hạn":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getIcon(String status) {
    switch (status) {
      case "Đã chấm":
        return Icons.check_circle;
      case "Đã nộp":
        return Icons.cloud_done;
      case "Chờ chấm (quá hạn)":
        return Icons.hourglass_top;
      case "Quá hạn":
        return Icons.cancel;
      default:
        return Icons.assignment;
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
              child: dsBaiTap.isEmpty
                  ? const Center(
                      child: Text(
                        "Chưa có bài tập nào",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: dsBaiTap.length,
                      itemBuilder: (context, index) {
                        final bt = dsBaiTap[index];
                        final status = getTrangThai(bt);
                        final color = getColor(status);
                        final icon = getIcon(status);
                        final isOverdue =
                            status == "Quá hạn" ||
                            status == "Chờ chấm (quá hạn)";

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
                              child: Icon(icon, color: color),
                            ),
                            title: Text(
                              bt['tieuDe'] ?? "",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isOverdue ? Colors.red : null,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Hạn: ${formatDate(bt["hanNop"])}",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isOverdue
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                    ),
                                    if (isOverdue) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.warning,
                                        size: 14,
                                        color: Colors.red,
                                      ),
                                    ],
                                  ],
                                ),
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
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChiTietBaiTapHVScreen(
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
