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

class QlDiemGVScreen extends StatefulWidget {
  final int idKhoaHoc;

  const QlDiemGVScreen({super.key, required this.idKhoaHoc});

  @override
  State<QlDiemGVScreen> createState() => _QlDiemGVScreenState();
}

class _QlDiemGVScreenState extends State<QlDiemGVScreen> {
  List quizzes = [];
  List list = [];

  bool isLoading = true;
  int? selectedQuiz;

  final String baseUrl = ApiConfig.baseUrl;
  int daLam = 0;
  int chuaLam = 0;
  int trenTB = 0;
  int duoiTB = 0;

  @override
  void initState() {
    super.initState();
    loadQuiz();
  }

  Future<void> xuatFileExcel() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Sheet1'];

    sheet.appendRow(["STT", "Họ tên", "Email", "Điểm", "Trạng thái"]);

    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      sheet.appendRow([
        i + 1,
        item['hoTen'] ?? "",
        item['email'] ?? "",
        item['diemSo']?.toString() ?? "Chưa làm",
        item['trangThai'] ?? "",
      ]);
    }

    final bytes = excel.encode();
    if (bytes == null) return;
    if (kIsWeb) {
      final blob = html.Blob([Uint8List.fromList(bytes)]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "bang_diem.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã tải file xuống")));
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/bang_diem.xlsx");
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: "Bảng điểm bài kiểm tra");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Đã lưu file: ${file.path}")));
    }
  }

  Future<void> loadQuiz() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.get(
        Uri.parse('$baseUrl/giangvien/quiz/${widget.idKhoaHoc}'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        setState(() {
          quizzes = data['data'] ?? [];
          if (quizzes.isNotEmpty) {
            selectedQuiz = quizzes[0]['idQuiz'];
          }
        });

        if (selectedQuiz != null) {
          loadDiem(selectedQuiz!);
        }
      }
    } catch (e) {
      debugPrint("Lỗi load quiz: $e");
    }
  }

  Future<void> loadDiem(int idQuiz) async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.get(
        Uri.parse('$baseUrl/giangvien/quiz/diemhv/$idQuiz'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newList = data['data'] ?? [];

        int _daLam = 0;
        int _chuaLam = 0;
        int _trenTB = 0;
        int _duoiTB = 0;

        for (var item in newList) {
          final diem = item['diemSo'];

          if (diem == null) {
            _chuaLam++;
          } else {
            _daLam++;
            if (diem >= 5) {
              _trenTB++;
            } else {
              _duoiTB++;
            }
          }
        }

        setState(() {
          list = newList;
          daLam = _daLam;
          chuaLam = _chuaLam;
          trenTB = _trenTB;
          duoiTB = _duoiTB;
        });
      }
    } catch (e) {
      debugPrint("Lỗi load điểm: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> moLaiBaiKT(int idHocVien, String hoTen) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận mở lại'),
        content: Text(
          'Bạn có chắc muốn mở lại bài kiểm tra cho học viên "$hoTen"?\n\n'
          'Học viên sẽ được làm lại bài từ đầu và điểm cũ sẽ bị xóa.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận mở lại'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.put(
        Uri.parse(
          '$baseUrl/giangvien/quiz/molaibaiKT/${selectedQuiz!}/$idHocVien',
        ),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data['message'] ?? 'Đã mở lại bài kiểm tra'}'),
            backgroundColor: Colors.green,
          ),
        );
        if (selectedQuiz != null) {
          await loadDiem(selectedQuiz!);
        }
      } else {
        throw Exception(data['message'] ?? 'Mở lại thất bại');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // void _showMoLaiMenu(Map item) {
  //   final daLam = item['diemSo'] != null;
  //   final hoTen = item['hoTen'] ?? 'Unknown';
  //   final idHocVien = item['idNguoiDung'];

  //   if (!daLam) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Học viên chưa làm bài, không cần mở lại'),
  //         backgroundColor: Colors.grey,
  //       ),
  //     );
  //     return;
  //   }

  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) => SafeArea(
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Container(
  //             width: 40,
  //             height: 4,
  //             margin: const EdgeInsets.symmetric(vertical: 12),
  //             decoration: BoxDecoration(
  //               color: Colors.grey.shade300,
  //               borderRadius: BorderRadius.circular(2),
  //             ),
  //           ),
  //           const ListTile(
  //             leading: Icon(Icons.refresh, color: Colors.orange),
  //             title: Text(
  //               'Mở lại bài kiểm tra',
  //               style: TextStyle(fontWeight: FontWeight.bold),
  //             ),
  //             subtitle: Text('Học viên sẽ được làm lại từ đầu'),
  //           ),
  //           const Divider(),
  //           ListTile(
  //             leading: const Icon(Icons.person, color: Colors.blue),
  //             title: Text('Học viên: $hoTen'),
  //           ),
  //           ListTile(
  //             leading: const Icon(Icons.score, color: Colors.green),
  //             title: Text('Điểm hiện tại: ${item['diemSo'] ?? 'Chưa có'}'),
  //           ),
  //           const Divider(),
  //           Padding(
  //             padding: const EdgeInsets.all(16),
  //             child: Row(
  //               children: [
  //                 Expanded(
  //                   child: OutlinedButton(
  //                     onPressed: () => Navigator.pop(context),
  //                     style: OutlinedButton.styleFrom(
  //                       padding: const EdgeInsets.symmetric(vertical: 12),
  //                     ),
  //                     child: const Text('Hủy'),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: ElevatedButton(
  //                     onPressed: () {
  //                       Navigator.pop(context);
  //                       moLaiBaiKT(idHocVien, hoTen);
  //                     },
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.orange,
  //                       foregroundColor: Colors.white,
  //                       padding: const EdgeInsets.symmetric(vertical: 12),
  //                     ),
  //                     child: const Text('Xác nhận mở lại'),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Color getColor(diem) {
    if (diem == null) return Colors.grey;
    if (diem >= 8) return Colors.green;
    if (diem >= 5) return Colors.orange;
    return Colors.red;
  }

  Widget _buildStat(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          "$value",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label),
      ],
    );
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Điểm bài kiểm tra"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: xuatFileExcel,
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
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: double.infinity,
              child: DropdownButtonFormField<int>(
                value: selectedQuiz,
                decoration: const InputDecoration(
                  labelText: "Chọn bài kiểm tra",
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: quizzes.map<DropdownMenuItem<int>>((q) {
                  return DropdownMenuItem(
                    value: q['idQuiz'],
                    child: Text(
                      q['tenQuiz'] ?? "Quiz",
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedQuiz = value;
                  });
                  if (value != null) {
                    loadDiem(value);
                  }
                },
                isExpanded: true,
                menuMaxHeight: 300,
              ),
            ),
          ),

          if (quizzes.isEmpty && !isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "Không có bài kiểm tra nào",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),

          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat("Đã làm", daLam, Colors.green),
                    _buildStat("Chưa làm", chuaLam, Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(">= 5 điểm", trenTB, Colors.blue),
                    _buildStat("< 5 điểm", duoiTB, Colors.red),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(child: Text("Chưa có dữ liệu"))
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (selectedQuiz != null) {
                            await loadDiem(selectedQuiz!);
                          }
                        },
                        child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final daLam = item['diemSo'] != null;
                            final hoTen = item['hoTen'] ?? 'Unknown';
                            final idHocVien = item['idNguoiDung'];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: daLam ? Colors.blue : Colors.grey,
                                  child: Text(
                                    "${index + 1}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  hoTen,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(item['email'] ?? ""),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          item['diemSo'] != null
                                              ? "${item['diemSo']}"
                                              : "Chưa làm",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: getColor(item['diemSo']),
                                          ),
                                        ),
                                        Text(
                                          item['trangThai'] ?? "",
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    if (daLam)
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                                        onSelected: (value) {
                                          if (value == 'mo_lai') {
                                            moLaiBaiKT(idHocVien, hoTen);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem<String>(
                                            value: 'mo_lai',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.refresh,
                                                  color: Colors.orange,
                                                  size: 18,
                                                ),
                                                SizedBox(width: 8),
                                                Text('Mở lại bài kiểm tra'),
                                              ],
                                            ),
                                          ),
                                        ],
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