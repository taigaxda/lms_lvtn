// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:frontend/api.dart';
// import 'package:excel/excel.dart';
// import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:open_filex/open_filex.dart';
// import 'package:share_plus/share_plus.dart';

// class QlDiemGVScreen extends StatefulWidget {
//   final int idKhoaHoc;

//   const QlDiemGVScreen({super.key, required this.idKhoaHoc});

//   @override
//   State<QlDiemGVScreen> createState() => _QlDiemGVScreenState();
// }

// class _QlDiemGVScreenState extends State<QlDiemGVScreen> {
//   List quizzes = [];
//   List list = [];

//   bool isLoading = true;
//   int? selectedQuiz;

//   final String baseUrl = ApiConfig.baseUrl;
//   int daLam = 0;
//   int chuaLam = 0;
//   int trenTB = 0;
//   int duoiTB = 0;

//   @override
//   void initState() {
//     super.initState();
//     loadQuiz();
//   }

//   Future<void> xuatFileExcel() async {
//     var excel = Excel.createExcel();
//     Sheet sheet = excel['BangDiem'];
//     sheet.appendRow([
//       "STT",
//       "Họ tên",
//       "Email",
//       "Điểm",
//       "Trạng thái",
//     ]);
//     for(int i =0 ;i< list.length;i++){
//       final item = list[i];
//       sheet.appendRow([
//         i+1,
//         item['hoTen'] ?? "",
//         item['email'] ?? "",
//         item['diemSo']?.toString() ?? "Chưa làm",
//       ]);
//     }
//     final dir = await getApplicationDocumentsDirectory();
//     final file = File("${dir.path}/bang_diem.xlsx");

//     final bytes = excel.encode();
//     if (bytes != null) {
//       await file.writeAsBytes(bytes);
//     }
//     await OpenFilex.open(file.path);
//     await Share.shareXFiles(
//       [XFile(file.path)],
//       text: "Bảng điểm bài kiểm tra",
//     );
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text("Đã lưu file: ${file.path}")),
//     );
//   }

//   Future<void> loadQuiz() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getInt("userId");

//       final res = await http.get(
//         Uri.parse('$baseUrl/giangvien/quiz/${widget.idKhoaHoc}'),
//         headers: {"x-user-id": userId.toString()},
//       );

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);

//         setState(() {
//           quizzes = data['data'] ?? [];

//           if (quizzes.isNotEmpty) {
//             selectedQuiz = quizzes[0]['idQuiz'];
//           }
//         });

//         if (selectedQuiz != null) {
//           loadDiem(selectedQuiz!);
//         }
//       }
//     } catch (e) {
//       debugPrint("Lỗi load quiz: $e");
//     }
//   }

//   Future<void> loadDiem(int idQuiz) async {
//     setState(() => isLoading = true);

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final userId = prefs.getInt("userId");

//       final res = await http.get(
//         Uri.parse('$baseUrl/giangvien/quiz/diemhv/$idQuiz'),
//         headers: {"x-user-id": userId.toString()},
//       );

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final newList = data['data'] ?? [];
//         int _daLam = 0;
//         int _chuaLam = 0;
//         int _trenTB = 0;
//         int _duoiTB = 0;

//         for (var item in newList) {
//           final diem = item['diemSo'];

//           if (diem == null) {
//             _chuaLam++;
//           } else {
//             _daLam++;

//             if (diem >= 5) {
//               _trenTB++;
//             } else {
//               _duoiTB++;
//             }
//           }
//         }

//         setState(() {
//           list = newList;
//           daLam = _daLam;
//           chuaLam = _chuaLam;
//           trenTB = _trenTB;
//           duoiTB = _duoiTB;
//         });
//       }
//     } catch (e) {
//       debugPrint("Lỗi load điểm: $e");
//     } finally {
//       setState(() => isLoading = false);
//     }
//   }

//   Color getColor(diem) {
//     if (diem == null) return Colors.grey;
//     if (diem >= 8) return Colors.green;
//     if (diem >= 5) return Colors.orange;
//     return Colors.red;
//   }

//   Widget _buildStat(String label, int value, Color color) {
//     return Column(
//       children: [
//         Text(
//           "$value",
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(label),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Điểm bài kiểm tra"),
//         backgroundColor: Colors.blue,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.table_chart),
//             onPressed: () {
//               if (list.isNotEmpty) {
//                 xuatFileExcel();
//               } else {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text("Không có dữ liệu để xuất")),
//                 );
//               }
//             },
//           )
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: DropdownButtonFormField<int>(
//               value: selectedQuiz,
//               decoration: const InputDecoration(
//                 labelText: "Chọn bài kiểm tra",
//                 border: OutlineInputBorder(),
//               ),
//               items: quizzes.map<DropdownMenuItem<int>>((q) {
//                 return DropdownMenuItem(
//                   value: q['idQuiz'],
//                   child: Text(q['tenQuiz'] ?? "Quiz"),
//                 );
//               }).toList(),
//               onChanged: (value) {
//                 setState(() {
//                   selectedQuiz = value;
//                 });
//                 if (value != null) {
//                   loadDiem(value);
//                 }
//               },
//             ),
//           ),
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.blue.withOpacity(0.1),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildStat("Đã làm", daLam, Colors.green),
//                     _buildStat("Chưa làm", chuaLam, Colors.grey),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceAround,
//                   children: [
//                     _buildStat(">= 5 điểm", trenTB, Colors.blue),
//                     _buildStat("< 5 điểm", duoiTB, Colors.red),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: isLoading
//                 ? const Center(child: CircularProgressIndicator())
//                 : list.isEmpty
//                     ? const Center(child: Text("Chưa có dữ liệu"))
//                     : RefreshIndicator(
//                         onRefresh: () => loadDiem(selectedQuiz!),
//                         child: ListView.builder(
//                           itemCount: list.length,
//                           itemBuilder: (context, index) {
//                             final item = list[index];

//                             return Card(
//                               margin: const EdgeInsets.symmetric(
//                                   horizontal: 12, vertical: 6),
//                               child: ListTile(
//                                 leading: CircleAvatar(
//                                   child: Text("${index + 1}",style: TextStyle(color: Colors.white),),
//                                   backgroundColor: Colors.blue,
//                                 ),
//                                 title: Text(
//                                   item['hoTen'] ?? "",
//                                   style: const TextStyle(
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                                 subtitle: Text(item['email'] ?? ""),
//                                 trailing: Column(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Text(
//                                       item['diemSo'] != null
//                                           ? "${item['diemSo']}"
//                                           : "Chưa làm",
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.bold,
//                                         color: getColor(item['diemSo']),
//                                       ),
//                                     ),
//                                     Text(item['trangThai'] ?? ""),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//           )
//         ],
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // 🔥 kIsWeb
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

    sheet.appendRow([
      "STT",
      "Họ tên",
      "Email",
      "Điểm",
      "Trạng thái",
    ]);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã tải file xuống")),
      );
    }
    else {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/bang_diem.xlsx");
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Bảng điểm bài kiểm tra",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã lưu file: ${file.path}")),
      );
    }
  }

  Future<void> loadQuiz() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");

      final res = await http.get(
        Uri.parse('$baseUrl/giangvien/quiz/${widget.idKhoaHoc}'),
        headers: {"x-user-id": userId.toString()},
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
      final userId = prefs.getInt("userId");

      final res = await http.get(
        Uri.parse('$baseUrl/giangvien/quiz/diemhv/$idQuiz'),
        headers: {"x-user-id": userId.toString()},
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
          )
        ]
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<int>(
              value: selectedQuiz,
              decoration: const InputDecoration(
                labelText: "Chọn bài kiểm tra",
                border: OutlineInputBorder(),
              ),
              items: quizzes.map<DropdownMenuItem<int>>((q) {
                return DropdownMenuItem(
                  value: q['idQuiz'],
                  child: Text(q['tenQuiz'] ?? "Quiz"),
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
                        onRefresh: () => loadDiem(selectedQuiz!),
                        child: ListView.builder(
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    "${index + 1}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  item['hoTen'] ?? "",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(item['email'] ?? ""),
                                trailing: Column(
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
                                    Text(item['trangThai'] ?? ""),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          )
        ],
      ),
    );
  }
}