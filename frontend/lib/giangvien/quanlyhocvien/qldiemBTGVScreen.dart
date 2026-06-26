import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

class Qldiembtgvscreen extends StatefulWidget {
  final int idKhoaHoc;

  const Qldiembtgvscreen({super.key, required this.idKhoaHoc});

  @override
  State<Qldiembtgvscreen> createState() => _QlDiemBaiTapGVScreenState();
}

class _QlDiemBaiTapGVScreenState extends State<Qldiembtgvscreen> {
  List assignments = [];
  List list = [];

  bool isLoading = true;
  int? selectedAssignment;

  final String baseUrl = ApiConfig.baseUrl;
  int daNop = 0;
  int chuaNop = 0;
  int daCham = 0;
  int chuaCham = 0;
  double diemCaoNhat = 0;
  double diemThapNhat = 0;
  double diemTrungBinh = 0;

  @override
  void initState() {
    super.initState();
    loadAssignments();
  }

  Future<void> xuatFileExcel() async {
    if (list.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Không có dữ liệu để xuất")));
      return;
    }

    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Sheet1'];
      sheet.appendRow([
        "STT",
        "Họ tên",
        "Email",
        "Ngày nộp",
        "Trạng thái",
        "Điểm",
        "Nhận xét",
      ]);
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        sheet.appendRow([
          i + 1,
          item['hoTen'] ?? "",
          item['email'] ?? "",
          item['ngayNop'] ?? "Chưa nộp",
          item['trangThai'] ?? "",
          item['grade'] != null
              ? item['grade']['diem']?.toString() ?? ""
              : "Chưa chấm",
          item['grade'] != null ? item['grade']['nhanXet'] ?? "" : "",
        ]);
      }

      final bytes = excel.encode();
      if (bytes == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Lỗi tạo file Excel")));
        return;
      }

      if (kIsWeb) {
        final blob = html.Blob([Uint8List.fromList(bytes)]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "bang_diem_bai_tap.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đã tải file xuống")));
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File("${dir.path}/bang_diem_bai_tap.xlsx");
        await file.writeAsBytes(bytes);
        await OpenFilex.open(file.path);
        await Share.shareXFiles([XFile(file.path)], text: "Bảng điểm bài tập");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Đã lưu file: ${file.path}")));
      }
    } catch (e) {
      debugPrint("Lỗi xuất file: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi xuất file: $e")));
    }
  }

  Future<void> loadAssignments() async {
    try {
      setState(() => isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.get(
        Uri.parse('$baseUrl/giangvien/baitap/${widget.idKhoaHoc}'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          assignments = data['data'] ?? [];
          if (assignments.isNotEmpty) {
            selectedAssignment = assignments[0]['idAssignment'];
          }
        });

        if (selectedAssignment != null) {
          loadDiemBaiTap(selectedAssignment!);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Lỗi load assignments: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> loadDiemBaiTap(int idAssignment) async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.get(
        Uri.parse('$baseUrl/giangvien/baitap/dsbainop/$idAssignment'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newList = data['data'] ?? [];
        final stats = data['stats'] ?? {};

        setState(() {
          list = newList;
          daNop = stats['daNop'] ?? 0;
          chuaNop = stats['chuaNop'] ?? 0;
          daCham = stats['daCham'] ?? 0;
          chuaCham = stats['chuaCham'] ?? 0;
          diemCaoNhat = (stats['diemCaoNhat'] ?? 0).toDouble();
          diemThapNhat = (stats['diemThapNhat'] ?? 0).toDouble();
          diemTrungBinh = (stats['diemTrungBinh'] ?? 0).toDouble();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi tải điểm: ${res.statusCode}")),
        );
      }
    } catch (e) {
      debugPrint("Lỗi load điểm: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi tải điểm: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Color getColor(diem) {
    if (diem == null) return Colors.grey;
    if (diem >= 8) return Colors.green;
    if (diem >= 5) return Colors.orange;
    return Colors.red;
  }

  String getStatusText(Map item) {
    if (item['grade'] != null) return "Đã chấm";
    if (item['daNop'] == true) return "Đã nộp";
    return "Chưa nộp";
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Điểm bài tập"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: list.isEmpty ? null : xuatFileExcel,
              icon: const Icon(Icons.download, size: 18),
              label: const Text("Xuất bảng điểm"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Dropdown chọn bài tập
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<int>(
              value: selectedAssignment,
              decoration: const InputDecoration(
                labelText: "Chọn bài tập",
                border: OutlineInputBorder(),
              ),
              items: assignments.map<DropdownMenuItem<int>>((q) {
                return DropdownMenuItem(
                  value: q['idAssignment'],
                  child: Text(q['tieuDe'] ?? "Bài tập"),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedAssignment = value;
                });
                if (value != null) {
                  loadDiemBaiTap(value);
                }
              },
            ),
          ),

          // Thông báo nếu không có bài tập
          if (assignments.isEmpty && !isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "Không có bài tập nào",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),

          // Thống kê
          if (assignments.isNotEmpty)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat("Đã nộp", "$daNop", Colors.green),
                      _buildStat("Chưa nộp", "$chuaNop", Colors.grey),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat("Đã chấm", "$daCham", Colors.blue),
                      _buildStat("Chưa chấm", "$chuaCham", Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat(
                        "Điểm cao",
                        diemCaoNhat.toStringAsFixed(1),
                        Colors.green,
                      ),
                      _buildStat(
                        "Điểm thấp",
                        diemThapNhat.toStringAsFixed(1),
                        Colors.red,
                      ),
                      _buildStat(
                        "TB",
                        diemTrungBinh.toStringAsFixed(1),
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Danh sách điểm
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty && assignments.isNotEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Chưa có dữ liệu điểm",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Học viên chưa nộp bài tập này",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      if (selectedAssignment != null) {
                        await loadDiemBaiTap(selectedAssignment!);
                      }
                    },
                    child: ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final item = list[index];
                        final grade = item['grade'];
                        final diem = grade != null ? grade['diem'] : null;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: getColor(diem).withOpacity(0.1),
                              child: Text(
                                "${index + 1}",
                                style: TextStyle(
                                  color: getColor(diem),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              item['hoTen'] ?? "",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['email'] ?? "",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  getStatusText(item),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: getColor(diem),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  grade != null
                                      ? "${(grade['diem'] as num).toStringAsFixed(1)} điểm"
                                      : item['daNop'] == true
                                      ? "Chờ chấm"
                                      : "Chưa nộp",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: getColor(diem),
                                  ),
                                ),
                                if (grade != null && grade['nhanXet'] != null)
                                  Text(
                                    grade['nhanXet'] ?? "",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
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
