import 'package:flutter/material.dart';
import 'chamDiemBaiNopGV.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';

class Danhsachbainopgvscreen extends StatefulWidget {
  final List submissions;
  final String tieuDe;
  const Danhsachbainopgvscreen({
    super.key,
    required this.submissions,
    required this.tieuDe,
  });
  @override
  State<Danhsachbainopgvscreen> createState() => _Danhsachbainopgvscreen();
}

class _Danhsachbainopgvscreen extends State<Danhsachbainopgvscreen> {
  late List submissions;
  @override
  void initState() {
    super.initState();
    submissions = [...widget.submissions];
    submissions.sort((a, b) {
      final aChuaCham = a["grades"] == null;
      final bChuaCham = b["grades"] == null;
      if (aChuaCham && !bChuaCham) return -1;
      if (!aChuaCham && bChuaCham) return 1;
      return 0;
    });
  }

  String formatDate(String? date) {
    if (date == null) return "Không rõ";
    final d = DateTime.tryParse(date);
    if (d == null) return "Không hợp lệ";

    String two(int n) => n.toString().padLeft(2, '0');

    return "${two(d.day)}/${two(d.month)}/${d.year} "
        "${two(d.hour)}:${two(d.minute)}";
  }
  // Future<void> xuatFileExcel() async {
  //   if (submissions.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text("Không có dữ liệu để xuất")),
  //     );
  //     return;
  //   }

  //   try {
  //     var excel = Excel.createExcel();
  //     Sheet sheet = excel['Sheet1'];
  //     sheet.appendRow([
  //       "STT",
  //       "Họ tên",
  //       "Email",
  //       "Ngày nộp",
  //       "Trạng thái",
  //       "Điểm",
  //       "Nhận xét",
  //     ]);

  //     for (int i = 0; i < submissions.length; i++) {
  //       final sub = submissions[i];
  //       final user = sub["nguoidung"];
  //       final grade = sub["grades"];
  //       final chuaCham = grade == null;

  //       sheet.appendRow([
  //         i + 1,
  //         user?["hoTen"] ?? "Không rõ",
  //         user?["email"] ?? "Không có",
  //         formatDate(sub["ngayNop"]),
  //         chuaCham ? "Chưa chấm" : "Đã chấm",
  //         grade != null ? grade["diem"]?.toString() ?? "" : "",
  //         grade != null ? grade["nhanXet"] ?? "" : "",
  //       ]);
  //     }

  //     final bytes = excel.encode();
  //     if (bytes == null) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Lỗi tạo file Excel")),
  //       );
  //       return;
  //     }

  //     final dir = await getApplicationDocumentsDirectory();
  //       final fileName = "bang_diem_${widget.tieuDe}_${DateTime.now().millisecondsSinceEpoch}.xlsx";
  //       final file = File("${dir.path}/$fileName");
  //       await file.writeAsBytes(bytes);
  //       await OpenFilex.open(file.path); 
  //       await Share.shareXFiles(
  //         [XFile(file.path)],
  //         text: "Bảng điểm bài tập: ${widget.tieuDe}",
  //       );
        
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Đã lưu file: $fileName")),
  //       );
  //   } catch (e) {
  //     debugPrint("Lỗi xuất file: $e");
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Lỗi xuất file: $e")),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Bài nộp - ${widget.tieuDe}"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.download),
        //     onPressed: submissions.isEmpty ? null : xuatFileExcel,
        //     tooltip: 'Xuất bảng điểm',
        //   ),
        // ],
      ),
      body: submissions.isEmpty
          ? const Center(child: Text("Chưa có bài nộp"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: submissions.length,
              itemBuilder: (context, index) {
                final sub = submissions[index];
                final user = sub["nguoidung"];
                final grade = sub['grades'];
                final chuaCham = grade == null;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            user?["hoTen"] ?? "Không rõ",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 6),
                          Text("Nộp: ${formatDate(sub["ngayNop"])}"),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: chuaCham
                                  ? Colors.red.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              chuaCham ? "Chưa chấm" : "Đã chấm",
                              style: TextStyle(
                                color: chuaCham ? Colors.red : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (grade != null)
                            Text(
                              "Điểm: ${grade["diem"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Chamdiembainopgv(idSubmission: sub['idSubmission'],),
                              ),
                            );
                            if (result != null && result['success'] == true) {
                              setState(() {
                                final index = submissions.indexWhere(
                                  (item) =>item['idSubmission'] == sub['idSubmission'],
                                );
                                if (index != -1) {
                                  submissions[index]['grades'] = {
                                    'diem': result['diem'],
                                    'nhanXet': result['nhanXet'],
                                  };
                                }
                              });
                            }
                          },
                          child: const Text(
                            "Chấm điểm",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
