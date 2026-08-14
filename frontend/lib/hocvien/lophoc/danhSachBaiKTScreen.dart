// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:frontend/hocvien/lophoc/lamBaiKTScreen.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:frontend/api.dart';

// class Danhsachbaiktscreen extends StatefulWidget {
//   final int idKhoaHoc;

//   const Danhsachbaiktscreen({super.key, required this.idKhoaHoc});

//   @override
//   State<Danhsachbaiktscreen> createState() => _DanhsachbaiktscreenState();
// }

// class _DanhsachbaiktscreenState extends State<Danhsachbaiktscreen> {
//   List quizzes = [];
//   bool isLoading = true;

//   final String apiUrl = '${ApiConfig.baseUrl}/hocvien';

//   @override
//   void initState() {
//     super.initState();
//     loadQuiz();
//   }

//   Future<void> loadQuiz() async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("token");

//     final res = await http.get(
//       Uri.parse('$apiUrl/quiz/dsquiz/${widget.idKhoaHoc}'),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token",
//       },
//     );
//     if (res.statusCode == 200) {
//       quizzes = json.decode(res.body)['data'];
//     }
//     setState(() => isLoading = false);
//   }

//   Future<void> openLamBaiKTScreen(Map q) async {
//     if (q['daLam']) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Đã làm rồi")));
//       return;
//     }
//     if (q['ngayDenHan'] != null) {
//       DateTime ngayHienTai = DateTime.now();
//       DateTime denHan = DateTime.parse(q['ngayDenHan']);
//       if (ngayHienTai.isAfter(denHan)) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Bài đã quá hạn, vui lòng liên hệ giảng viên"),
//           ),
//         );
//         return;
//       }
//     }
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => Lambaiktscreen(idQuiz: q['idQuiz'])),
//     );
//     if (result == true) {
//       await loadQuiz();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           "Bài kiểm tra",
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.blue,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),

//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.all(12),
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.purple.withOpacity(0.05),
//                       borderRadius: BorderRadius.circular(12),
//                       border: Border.all(color: Colors.purple.shade200),
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           "Thống kê bài kiểm tra",
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.purple,
//                           ),
//                         ),
//                         const SizedBox(height: 6),
//                         Text("Tổng bài kiểm tra: ${quizzes.length}"),
//                       ],
//                     ),
//                   ),
//                 ),
//                 Expanded(
//                   child: ListView.builder(
//                     itemCount: quizzes.length,
//                     itemBuilder: (context, index) {
//                       final q = quizzes[index];

//                       bool quaHan = false;
//                       if (q['ngayDenHan'] != null) {
//                         quaHan = DateTime.now().isAfter(
//                           DateTime.parse(q['ngayDenHan']),
//                         );
//                       }

//                       return Card(
//                         margin: const EdgeInsets.symmetric(
//                           horizontal: 16,
//                           vertical: 8,
//                         ),
//                         elevation: 3,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: InkWell(
//                           borderRadius: BorderRadius.circular(12),
//                           onTap: () => openLamBaiKTScreen(q),
//                           child: Padding(
//                             padding: const EdgeInsets.all(12),
//                             child: Row(
//                               children: [
//                                 Container(
//                                   padding: const EdgeInsets.all(10),
//                                   decoration: BoxDecoration(
//                                     color: quaHan
//                                         ? Colors.grey.withOpacity(0.2)
//                                         : Colors.purple.withOpacity(0.1),
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   child: Icon(
//                                     Icons.quiz,
//                                     color: quaHan ? Colors.grey : Colors.purple,
//                                   ),
//                                 ),

//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         q['tenQuiz'] ?? "",
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 15,
//                                         ),
//                                       ),

//                                       const SizedBox(height: 6),
//                                       _buildStatus(q, quaHan),

//                                       const SizedBox(height: 6),

//                                       Row(
//                                         children: [
//                                           const Icon(
//                                             Icons.timer,
//                                             size: 16,
//                                             color: Colors.grey,
//                                           ),
//                                           const SizedBox(width: 4),
//                                           Text(
//                                             "${q['thoiGianLamBai'] ?? 0} phút",
//                                           ),
//                                         ],
//                                       ),

//                                       const SizedBox(height: 6),

//                                       if (q['ngayDenHan'] != null)
//                                         Row(
//                                           children: [
//                                             const Icon(
//                                               Icons.calendar_today,
//                                               size: 16,
//                                             ),
//                                             const SizedBox(width: 4),
//                                             Text(
//                                               "Hạn: ${formatDate(q['ngayDenHan'])}",
//                                               style: TextStyle(
//                                                 fontSize: 12,
//                                                 color: quaHan
//                                                     ? Colors.red
//                                                     : Colors.black87,
//                                               ),
//                                             ),
//                                           ],
//                                         ),

//                                       const SizedBox(height: 6),

//                                       if (!q['daLam'] && !quaHan)
//                                         const Text(
//                                           "Nhấn để làm bài",
//                                           style: TextStyle(
//                                             fontSize: 12,
//                                             color: Colors.blueGrey,
//                                             fontStyle: FontStyle.italic,
//                                           ),
//                                         ),
//                                     ],
//                                   ),
//                                 ),

//                                 const Icon(Icons.arrow_forward_ios, size: 16),
//                               ],
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }

// Widget _buildStatus(Map q, bool quaHan) {
//   String text;
//   Color color;

//   if (quaHan) {
//     text = "Quá hạn";
//     color = Colors.red;
//   } else if (q['daLam']) {
//     text = "Đã làm - ${q['diem'] ?? 0} điểm";
//     color = Colors.green;
//   } else {
//     text = "Chưa làm";
//     color = Colors.orange;
//   }

//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//     decoration: BoxDecoration(
//       color: color.withOpacity(0.15),
//       borderRadius: BorderRadius.circular(8),
//     ),
//     child: Text(
//       text,
//       style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
//     ),
//   );
// }

// String formatDate(String dateStr) {
//   DateTime dt = DateTime.parse(dateStr);
//   return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/hocvien/lophoc/lamBaiKTScreen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class Danhsachbaiktscreen extends StatefulWidget {
  final int idKhoaHoc;

  const Danhsachbaiktscreen({super.key, required this.idKhoaHoc});

  @override
  State<Danhsachbaiktscreen> createState() => _DanhsachbaiktscreenState();
}

class _DanhsachbaiktscreenState extends State<Danhsachbaiktscreen> {
  List quizzes = [];
  bool isLoading = true;

  final String apiUrl = '${ApiConfig.baseUrl}/hocvien';

  @override
  void initState() {
    super.initState();
    loadQuiz();
  }

  Future<void> loadQuiz() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final res = await http.get(
      Uri.parse('$apiUrl/quiz/dsquiz/${widget.idKhoaHoc}'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );
    if (res.statusCode == 200) {
      quizzes = json.decode(res.body)['data'];
    }
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  // Hàm kiểm tra Quá Hạn chính xác khi Backend ĐÃ CỘNG GIỜ THỦ CÔNG
  bool checkQuaHan(String? ngayDenHan) {
    if (ngayDenHan == null || ngayDenHan.isEmpty) return false;

    try {
      // 1. Thay khoảng trắng thành 'T' để DateTime.parse không bị crash
      String cleanStr = ngayDenHan.trim().replaceAll(" ", "T");

      // 2. Xóa chữ 'Z' nếu có (Z ép Flutter hiểu là UTC làm bị cộng lố 7 tiếng)
      if (cleanStr.endsWith("Z")) {
        cleanStr = cleanStr.substring(0, cleanStr.length - 1);
      }

      // 3. Parse ngày hạn nộp
      DateTime dt = DateTime.parse(cleanStr);
      DateTime denHanReal = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);

      // 4. Lấy giờ hiện tại của điện thoại
      DateTime now = DateTime.now();
      DateTime nowReal = DateTime(now.year, now.month, now.day, now.hour, now.minute, now.second);

      return nowReal.isAfter(denHanReal);
    } catch (e) {
      debugPrint("Lỗi parse ngày: $e");
      return false;
    }
  }

  Future<void> openLamBaiKTScreen(Map q) async {
    if (q['daLam'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã làm rồi")));
      return;
    }

    if (q['ngayDenHan'] != null && checkQuaHan(q['ngayDenHan'])) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bài đã quá hạn, vui lòng liên hệ giảng viên"),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => Lambaiktscreen(idQuiz: q['idQuiz'])),
    );
    if (result == true) {
      await loadQuiz();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bài kiểm tra",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Thống kê bài kiểm tra",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text("Tổng bài kiểm tra: ${quizzes.length}"),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      final q = quizzes[index];

                      // Gọi hàm check quaHan an toàn
                      bool quaHan = checkQuaHan(q['ngayDenHan']);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => openLamBaiKTScreen(q),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: quaHan
                                        ? Colors.grey.withOpacity(0.2)
                                        : Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.quiz,
                                    color: quaHan ? Colors.grey : Colors.purple,
                                  ),
                                ),

                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        q['tenQuiz'] ?? "",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),

                                      const SizedBox(height: 6),
                                      _buildStatus(q, quaHan),

                                      const SizedBox(height: 6),

                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.timer,
                                            size: 16,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${q['thoiGianLamBai'] ?? 0} phút",
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 6),

                                      if (q['ngayDenHan'] != null)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Hạn: ${formatDate(q['ngayDenHan'])}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: quaHan
                                                    ? Colors.red
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),

                                      const SizedBox(height: 6),

                                      if (q['daLam'] != true && !quaHan)
                                        const Text(
                                          "Nhấn để làm bài",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blueGrey,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
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

Widget _buildStatus(Map q, bool quaHan) {
  String text;
  Color color;

  // Ưu tiên check đã làm trước, rồi mới đến quá hạn
  if (q['daLam'] == true) {
    text = "Đã làm - ${q['diem'] ?? 0} điểm";
    color = Colors.green;
  } else if (quaHan) {
    text = "Quá hạn";
    color = Colors.red;
  } else {
    text = "Chưa làm";
    color = Colors.orange;
  }

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );
}

String formatDate(String dateStr) {
  try {
    String cleanStr = dateStr.trim().replaceAll(" ", "T");
    if (cleanStr.endsWith("Z")) {
      cleanStr = cleanStr.substring(0, cleanStr.length - 1);
    }
    DateTime dt = DateTime.parse(cleanStr);
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  } catch (_) {
    return dateStr;
  }
}