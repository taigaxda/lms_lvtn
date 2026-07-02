import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class Lambaiktscreen extends StatefulWidget {
  final int idQuiz;

  const Lambaiktscreen({super.key, required this.idQuiz});

  @override
  State<Lambaiktscreen> createState() => _LamBaiKTScreenState();
}

class _LamBaiKTScreenState extends State<Lambaiktscreen>
    with WidgetsBindingObserver {
  // bool isLoading = true;
  // Map<String, dynamic>? quiz;
  // List questions = [];

  // Map<String, String> answers = {};

  // final String apiUrl = '${ApiConfig.baseUrl}/hocvien';

  // Timer? timer;
  // int remainingTime = 0;
  // String? errorMessage;

  // @override
  // void initState() {
  //   super.initState();
  //   loadQuiz();
  // }

  // @override
  // void dispose() {
  //   timer?.cancel();
  //   super.dispose();
  // }

  // Future<void> loadQuiz() async {
  //   try {
  //     final prefs = await SharedPreferences.getInstance();
  //     final token = prefs.getString("token");

  //     final res = await http.get(
  //       Uri.parse('$apiUrl/quiz/baikiemtra/${widget.idQuiz}'),
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Authorization": "Bearer $token",
  //       },
  //     );
  //     if (res.statusCode == 200) {
  //       final data = jsonDecode(res.body)['data'];
  //       if (data['questions'] == null || data['questions'].isEmpty) {
  //         setState(() {
  //           errorMessage =
  //               "Bài kiểm tra chưa có câu hỏi. Vui lòng quay lại sau.";
  //           isLoading = false;
  //         });
  //         return;
  //       }
  //       setState(() {
  //         quiz = data;
  //         questions = data['questions'];
  //         isLoading = false;
  //         errorMessage = null;
  //       });

  //       if (data['thoiGianLamBai'] != null) {
  //         remainingTime = data['thoiGianLamBai'] * 60;
  //         startTimer();
  //       } else {
  //         remainingTime = -1;
  //       }
  //     } else {
  //       final data = jsonDecode(res.body);
  //       setState(() {
  //         errorMessage = data['message'] ?? 'Không thể tải bài kiểm tra';
  //         isLoading = false;
  //       });
  //     }
  //   } catch (e) {
  //     setState(() {
  //       errorMessage = 'Lỗi kết nối server. Vui lòng thử lại.';
  //       isLoading = false;
  //     });
  //   }
  // }

  // void startTimer() {
  //   timer = Timer.periodic(const Duration(seconds: 1), (t) {
  //     if (remainingTime <= 0) {
  //       t.cancel();
  //       autoSubmit();
  //     } else {
  //       setState(() {
  //         remainingTime--;
  //       });
  //     }
  //   });
  // }

  // String formatTime(int seconds) {
  //   int m = seconds ~/ 60;
  //   int s = seconds % 60;
  //   return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  // }

  // Future<void> submitQuiz() async {
  //   timer?.cancel();
  //   final prefs = await SharedPreferences.getInstance();
  //   final token = prefs.getString("token");

  //   List formattedAnswers = answers.entries.map((e) {
  //     return {"idCauHoi": int.parse(e.key), "idDapAn": int.parse(e.value)};
  //   }).toList();
  //   final res = await http.post(
  //     Uri.parse('$apiUrl/quiz/${widget.idQuiz}/nopbai'),
  //     headers: {
  //       "Content-Type": "application/json",
  //       "Authorization": "Bearer $token",
  //     },
  //     body: jsonEncode({"answers": formattedAnswers}),
  //   );

  //   final data = jsonDecode(res.body);

  //   if (res.statusCode == 200) {
  //     showDialog(
  //       context: context,
  //       barrierDismissible: false,
  //       builder: (_) => AlertDialog(
  //         title: const Text("Kết quả"),
  //         content: Text("Điểm: ${data['data']['diem']}"),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               Navigator.pop(context);
  //               Navigator.pop(context, true);
  //             },
  //             child: const Text("OK"),
  //           ),
  //         ],
  //       ),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text(data['message'] ?? "Lỗi")));
  //   }
  // }

  // void autoSubmit() {
  //   submitQuiz();
  // }

  // Widget buildQuestion(Map q) {
  //   String id = q['idCauHoi'].toString();
  //   return Card(
  //     margin: const EdgeInsets.all(12),
  //     child: Padding(
  //       padding: const EdgeInsets.all(12),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text("Câu hỏi: ${q['cauHoi']}"),
  //           const SizedBox(height: 10),
  //           ...q['answers'].map<Widget>((a) {
  //             return RadioListTile(
  //               title: Text(a['noiDung']),
  //               value: a['idDapAn'].toString(),
  //               groupValue: answers[id],
  //               onChanged: (value) {
  //                 setState(() {
  //                   answers[id] = value!;
  //                 });
  //               },
  //             );
  //           }).toList(),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text(quiz?['tenQuiz'] ?? "Đang tải..."),
  //       backgroundColor: Colors.blue,
  //       iconTheme: const IconThemeData(color: Colors.white),
  //       foregroundColor: Colors.white,
  //       actions: [
  //         Padding(
  //           padding: const EdgeInsets.all(12),
  //           child: Center(
  //             child: isLoading
  //                 ? const SizedBox(
  //                     width: 20,
  //                     height: 20,
  //                     child: CircularProgressIndicator(
  //                       strokeWidth: 2,
  //                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
  //                     ),
  //                   )
  //                 : remainingTime == -1
  //                 ? const Text("Không giới hạn")
  //                 : Text(formatTime(remainingTime)),
  //           ),
  //         ),
  //       ],
  //     ),
  //     body: isLoading
  //         ? const Center(child: CircularProgressIndicator())
  //         : errorMessage !=
  //               null // ✅ Kiểm tra errorMessage
  //         ? Center(
  //             child: Padding(
  //               padding: const EdgeInsets.all(24),
  //               child: Column(
  //                 mainAxisAlignment: MainAxisAlignment.center,
  //                 children: [
  //                   Icon(
  //                     Icons.error_outline,
  //                     size: 64,
  //                     color: Colors.red.shade300,
  //                   ),
  //                   const SizedBox(height: 16),
  //                   Text(
  //                     errorMessage!,
  //                     style: const TextStyle(fontSize: 16, color: Colors.grey),
  //                     textAlign: TextAlign.center,
  //                   ),
  //                   const SizedBox(height: 24),
  //                   ElevatedButton.icon(
  //                     onPressed: () {
  //                       Navigator.pop(context);
  //                     },
  //                     icon: const Icon(Icons.arrow_back),
  //                     label: const Text("Quay lại"),
  //                     style: ElevatedButton.styleFrom(
  //                       backgroundColor: Colors.blue,
  //                       foregroundColor: Colors.white,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           )
  //         : questions.isEmpty
  //         ? const Center(
  //             child: Text(
  //               "Bài kiểm tra không có câu hỏi",
  //               style: TextStyle(fontSize: 16, color: Colors.grey),
  //             ),
  //           )
  //         : Column(
  //             children: [
  //               Expanded(
  //                 child: ListView(
  //                   padding: const EdgeInsets.only(bottom: 80),
  //                   children: questions.map((q) => buildQuestion(q)).toList(),
  //                 ),
  //               ),
  //               Container(
  //                 padding: const EdgeInsets.all(12),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white,
  //                   boxShadow: [
  //                     BoxShadow(
  //                       color: Colors.grey.withOpacity(0.2),
  //                       blurRadius: 4,
  //                       offset: const Offset(0, -2),
  //                     ),
  //                   ],
  //                 ),
  //                 child: Row(
  //                   children: [
  //                     Expanded(
  //                       child: Text(
  //                         "Đã trả lời: ${answers.length}/${questions.length}",
  //                         style: const TextStyle(
  //                           fontSize: 14,
  //                           color: Colors.grey,
  //                         ),
  //                       ),
  //                     ),
  //                     ElevatedButton(
  //                       onPressed: submitQuiz,
  //                       style: ElevatedButton.styleFrom(
  //                         minimumSize: const Size(120, 45),
  //                         backgroundColor: Colors.blue,
  //                         foregroundColor: Colors.white,
  //                         shape: RoundedRectangleBorder(
  //                           borderRadius: BorderRadius.circular(8),
  //                         ),
  //                       ),
  //                       child: const Text("Nộp bài"),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //   );
  // }
  bool isLoading = true;
  Map<String, dynamic>? quiz;
  List questions = [];
  Map<String, String> answers = {};
  final String apiUrl = '${ApiConfig.baseUrl}/hocvien';
  Timer? timer;
  int remainingTime = 0;
  String? errorMessage;
  int _soLanChuyenTab = 0;
  static const int _GIOI_HAN_CHUYEN_TAB = 3;
  bool _daCanhBao = false;
  Set<int> _cauChuaTraLoi = {};
  int _thoiGianLamBai = 0;
  Timer? _thoiGianTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    loadQuiz();
  }

  @override
  void dispose() {
    timer?.cancel();
    _thoiGianTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _soLanChuyenTab++;
      if (_soLanChuyenTab >= _GIOI_HAN_CHUYEN_TAB && !_daCanhBao) {
        _daCanhBao = true;
        _showWarningDialog();
      } else if (_soLanChuyenTab < _GIOI_HAN_CHUYEN_TAB) {
        _showToast(
          'Cảnh báo: Bạn đã chuyển tab ${_soLanChuyenTab}/$_GIOI_HAN_CHUYEN_TAB lần',
        );
      }
    }
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text(
          'Cảnh báo gian lận',
          style: TextStyle(color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bạn đã chuyển tab quá số lần cho phép!'),
            const SizedBox(height: 8),
            Text('Số lần chuyển tab: $_soLanChuyenTab / $_GIOI_HAN_CHUYEN_TAB'),
            const SizedBox(height: 8),
            const Text('Bài làm sẽ bị hủy và điểm 0.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              nopBaiDiem0();
            },
            child: const Text('Đồng ý', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> nopBaiDiem0() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.post(
        Uri.parse('$apiUrl/quiz/${widget.idQuiz}/nopbai'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "answers": [],
          "thoiGianLamBai": _thoiGianLamBai,
          "gianLan": true,
        }),
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        if (response.statusCode == 200) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => AlertDialog(
              title: const Text(
                'Bài làm bị hủy',
                style: TextStyle(color: Colors.red),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Bạn đã chuyển tab quá số lần cho phép!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const Text(
                    'Bài làm đã bị hủy và điểm 0.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Điểm',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        Text(
                          data['data']?['diem']?.toString() ?? '0',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data['message'] ?? 'Không thể lưu điểm'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi kết nối, vui lòng thử lại'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  void _startThoiGianLamBai() {
    _thoiGianTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          _thoiGianLamBai++;
        });
      }
    });
  }

  Future<void> loadQuiz() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.get(
        Uri.parse('$apiUrl/quiz/baikiemtra/${widget.idQuiz}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        if (data['questions'] == null || data['questions'].isEmpty) {
          setState(() {
            errorMessage =
                "Bài kiểm tra chưa có câu hỏi. Vui lòng quay lại sau.";
            isLoading = false;
          });
          return;
        }
        setState(() {
          quiz = data;
          questions = data['questions'];
          _cauChuaTraLoi = Set.from(questions.map((q) => q['idCauHoi'] as int));
          isLoading = false;
          errorMessage = null;
        });
        _startThoiGianLamBai();
        if (data['thoiGianLamBai'] != null) {
          remainingTime = data['thoiGianLamBai'] * 60;
          startTimer();
        } else {
          remainingTime = -1;
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          errorMessage = data['message'] ?? 'Không thể tải bài kiểm tra';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Lỗi kết nối server. Vui lòng thử lại.';
        isLoading = false;
      });
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (remainingTime <= 0) {
        t.cancel();
        tuDongNop();
      } else {
        setState(() {
          remainingTime--;
        });
      }
    });
  }

  String formatTime(int seconds) {
    if (seconds < 0) return "00:00";
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _updateAnswer(String idCauHoi, String idDapAn) {
    setState(() {
      answers[idCauHoi] = idDapAn;
      _cauChuaTraLoi.remove(int.parse(idCauHoi));
    });
  }

  List<int> _getCauChuaTraLoi() {
    return _cauChuaTraLoi.toList()..sort();
  }

  Future<void> submitQuiz() async {
    final cauChuaTraLoi = _getCauChuaTraLoi();
    if (cauChuaTraLoi.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cảnh báo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bạn chưa trả lời các câu hỏi sau:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: cauChuaTraLoi.map((id) {
                  return Chip(
                    label: Text('Câu $id'),
                    backgroundColor: Colors.orange.shade100,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Bạn có chắc chắn muốn nộp bài?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Quay lại làm'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Nộp bài'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    timer?.cancel();
    _thoiGianTimer?.cancel();

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    List formattedAnswers = answers.entries.map((e) {
      return {"idCauHoi": int.parse(e.key), "idDapAn": int.parse(e.value)};
    }).toList();

    final res = await http.post(
      Uri.parse('$apiUrl/quiz/${widget.idQuiz}/nopbai'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "answers": formattedAnswers,
        "thoiGianLamBai": _thoiGianLamBai,
      }),
    );

    final data = jsonDecode(res.body);

    if (res.statusCode == 200) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Kết quả"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data['data']['diem'] >= 5
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                  ),
                  child: Text(
                    data['data']['diem'].toString(),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: data['data']['diem'] >= 5
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data['data']['diem'] >= 5 ? 'Đạt' : 'Chưa đạt',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: data['data']['diem'] >= 5
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thời gian làm bài: ${_formatThoiGian(_thoiGianLamBai)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(data['message'] ?? "Lỗi")));
    }
  }

  String _formatThoiGian(int seconds) {
    if (seconds < 60) {
      return '$seconds giây';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes < 60) {
      return '$minutes phút ${remainingSeconds}s';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours giờ ${remainingMinutes} phút';
  }

  void tuDongNop() {
    _thoiGianTimer?.cancel();
    submitQuiz();
  }

  Widget buildQuestion(Map q) {
    String id = q['idCauHoi'].toString();
    bool daTraLoi = answers.containsKey(id);
    return Card(
      margin: const EdgeInsets.all(12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: daTraLoi ? Colors.green : Colors.orange,
          width: daTraLoi ? 2 : 3,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: daTraLoi ? Colors.green : Colors.orange,
                  radius: 14,
                  child: Text(
                    q['idCauHoi'].toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    q['cauHoi'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  daTraLoi ? Icons.check_circle : Icons.warning,
                  color: daTraLoi ? Colors.green : Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...q['answers'].map<Widget>((a) {
              return RadioListTile(
                title: Text(a['noiDung']),
                value: a['idDapAn'].toString(),
                groupValue: answers[id],
                onChanged: (value) {
                  _updateAnswer(id, value!);
                },
                activeColor: Colors.blue,
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showQuestionNavigator() {
    final cauChuaTraLoi = _getCauChuaTraLoi();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        height: 300,
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Danh sách câu hỏi',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Divider(),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  final id = q['idCauHoi'].toString();
                  final daTraLoi = answers.containsKey(id);

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: daTraLoi ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          q['idCauHoi'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (cauChuaTraLoi.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Còn ${cauChuaTraLoi.length} câu chưa trả lời',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quiz?['tenQuiz'] ?? "Đang tải..."),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view),
            onPressed: _showQuestionNavigator,
            tooltip: 'Xem danh sách câu hỏi',
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : remainingTime == -1
                  ? const Text("Không giới hạn")
                  : Text(
                      formatTime(remainingTime),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Quay lại"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : questions.isEmpty
          ? const Center(
              child: Text(
                "Bài kiểm tra không có câu hỏi",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  color: Colors.grey.shade50,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: answers.length / questions.length,
                            backgroundColor: Colors.grey.shade200,
                            color: answers.length == questions.length
                                ? Colors.green
                                : Colors.blue,
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${answers.length}/${questions.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 80),
                    children: questions.map((q) => buildQuestion(q)).toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Đã trả lời: ${answers.length}/${questions.length}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            if (_getCauChuaTraLoi().isNotEmpty)
                              Text(
                                'Còn ${_getCauChuaTraLoi().length} câu chưa làm',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                ),
                              ),
                            Text(
                              '${_formatThoiGian(_thoiGianLamBai)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: submitQuiz,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(120, 45),
                          backgroundColor: answers.length == questions.length
                              ? Colors.green
                              : Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          answers.length == questions.length
                              ? "Nộp bài"
                              : "Nộp bài",
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
