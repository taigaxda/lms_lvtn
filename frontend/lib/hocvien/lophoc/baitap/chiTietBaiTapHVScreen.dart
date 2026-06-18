import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'nopBaiTapHVScreen.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// class ChiTietBaiTapHVScreen extends StatelessWidget {
//   final Map<String, dynamic> baiTap;

//   const ChiTietBaiTapHVScreen({super.key, required this.baiTap});

//   // 🔥 MỞ FILE THÔNG MINH
//   Future<void> openFile(BuildContext context, String url) async {
//   if (url.isEmpty) return;

//   final extension = url.split('.').last.toLowerCase();

//   // 🎥 Nếu là video → popup
//   if (extension == 'mp4' || extension == 'mov' || extension == 'avi') {
//     _showVideoPopup(context, url);
//     return;
//   }

//   // 👉 phần cũ giữ nguyên
//   String finalUrl = url;

//   if (url.contains("upload/") &&
//       (extension == 'pdf' ||
//           extension == 'png' ||
//           extension == 'jpg' ||
//           extension == 'jpeg')) {
//     finalUrl = url.replaceFirst("upload/", "upload/fl_attachment/");
//   }

//   final uri = Uri.parse(finalUrl);

//   try {
//     final launched = await launchUrl(
//       uri,
//       mode: LaunchMode.externalApplication,
//     );

//     if (!launched) {
//       await _fallbackOpen(url);
//     }
//   } catch (e) {
//     debugPrint("Lỗi mở file: $e");
//     await _fallbackOpen(url);
//   }
// }
// void _showVideoPopup(BuildContext context, String url) {
//   showDialog(
//     context: context,
//     builder: (_) => Dialog(
//       insetPadding: const EdgeInsets.all(10),
//       child: AspectRatio(
//         aspectRatio: 16 / 9,
//         child: VideoPlayerWidget(url: url),
//       ),
//     ),
//   );
// }

//   // 🔥 FALLBACK
//   Future<void> _fallbackOpen(String url) async {
//     final extension = url.split('.').last.toLowerCase();

//     try {
//       // 👉 DOCX → Google Viewer
//       if (extension == 'doc' || extension == 'docx') {
//         final viewer =
//             "https://docs.google.com/gview?embedded=true&url=$url";

//         await launchUrl(
//           Uri.parse(viewer),
//           mode: LaunchMode.externalApplication,
//         );
//         return;
//       }

//       // 👉 fallback cuối → browser
//       await launchUrl(
//         Uri.parse(url),
//         mode: LaunchMode.platformDefault,
//       );
//     } catch (e) {
//       debugPrint("Fallback cũng fail: $e");
//     }
//   }

//   // 🔥 FORMAT DATE
//   String formatDate(String? date) {
//     if (date == null) return "Không có";

//     final d = DateTime.tryParse(date);
//     if (d == null) return "Không hợp lệ";

//     String twoDigits(int n) => n.toString().padLeft(2, '0');

//     return "${twoDigits(d.day)}/${twoDigits(d.month)}/${d.year} "
//         "${twoDigits(d.hour)}:${twoDigits(d.minute)}";
//   }

//   @override
//   Widget build(BuildContext context) {
//     final submissions = baiTap['submissions'] ?? [];
//     final daNop = submissions.isNotEmpty;
//     final submission = daNop ? submissions[0] : null;
//     final grade = submission?['grades'];

//     final fileDinhKem = baiTap['fileDinhKem'];
//     final fileNop = submission?['fileNop'];

//     return Scaffold(
//       appBar: AppBar(title: const Text("Chi tiết bài tập")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: ListView(
//           children: [
//             Text(
//               baiTap['tieuDe'] ?? '',
//               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),

//             const SizedBox(height: 10),

//             Text(
//               "Hạn nộp: ${formatDate(baiTap['hanNop'])}",
//               style: const TextStyle(
//                 color: Colors.red,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),

//             const SizedBox(height: 10),

//             Text(baiTap['moTa'] ?? 'Không có miêu tả'),

//             const SizedBox(height: 20),

//             // 🔥 FILE ĐÍNH KÈM
//             if (fileDinhKem != null && fileDinhKem.toString().isNotEmpty)
//               GestureDetector(
//                 onTap: () => openFile(context, fileDinhKem),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Row(
//                     children: [
//                       Icon(Icons.attach_file),
//                       SizedBox(width: 10),
//                       Text("Xem file đính kèm"),
//                     ],
//                   ),
//                 ),
//               )
//             else
//               const Text(
//                 "Không có file đính kèm",
//                 style: TextStyle(color: Colors.grey),
//               ),

//             const SizedBox(height: 30),

//             const Text(
//               "Trạng thái:",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),

//             const SizedBox(height: 5),

//             Text(
//               daNop ? "Đã nộp bài" : "Chưa nộp",
//               style: TextStyle(color: daNop ? Colors.green : Colors.red),
//             ),

//             const SizedBox(height: 20),

//             // 🔥 FILE NỘP
//             if (daNop && fileNop != null && fileNop.toString().isNotEmpty)
//               GestureDetector(
//                 onTap: () => openFile(context,fileDinhKem),
//                 child: Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.green.shade50,
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: const Row(
//                     children: [
//                       Icon(Icons.upload_file),
//                       SizedBox(width: 10),
//                       Text("Xem bài đã nộp"),
//                     ],
//                   ),
//                 ),
//               )
//             else if (daNop)
//               const Text(
//                 "Không có file đã nộp",
//                 style: TextStyle(color: Colors.grey),
//               ),

//             const SizedBox(height: 20),

//             // 🔥 ĐIỂM
//             if (grade != null)
//               Text(
//                 "Điểm: ${grade['diem']}",
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.orange,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// class VideoPlayerWidget extends StatefulWidget {
//   final String url;

//   const VideoPlayerWidget({super.key, required this.url});

//   @override
//   State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
// }

// class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
//   VideoPlayerController? _controller;
//   ChewieController? _chewieController;

//   @override
//   void initState() {
//     super.initState();
//     _init();
//   }

//   Future<void> _init() async {
//     _controller = VideoPlayerController.network(widget.url);
//     await _controller!.initialize();

//     _chewieController = ChewieController(
//       videoPlayerController: _controller!,
//       autoPlay: true,
//     );

//     setState(() {});
//   }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     _chewieController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_chewieController == null) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return Chewie(controller: _chewieController!);
//   }
// }


class ChiTietBaiTapHVScreen extends StatefulWidget {
  final int idAssignment;

  const ChiTietBaiTapHVScreen({super.key, required this.idAssignment});

  @override
  State<ChiTietBaiTapHVScreen> createState() => _ChiTietBaiTapHVScreenState();
}

class _ChiTietBaiTapHVScreenState extends State<ChiTietBaiTapHVScreen> {
  Map<String, dynamic>? baiTap;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAssignmentDetail();
  }

  Future<void> _fetchAssignmentDetail() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      print('=== FETCHING ASSIGNMENT DETAIL ===');
      print('idAssignment: ${widget.idAssignment}');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/hocvien/baitap/chitiet/${widget.idAssignment}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      print('Status code: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final assignment = data['data'];

        print('Found assignment: ${assignment['tieuDe']}');
        print('Submissions: ${assignment['submissions']}');

        setState(() {
          baiTap = assignment;
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = "Không tìm thấy bài tập";
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = "Lỗi server: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      print('Lỗi fetch: $e');
      setState(() {
        errorMessage = "Không thể tải dữ liệu: $e";
        isLoading = false;
      });
    }
  }

  Future<void> openFile(BuildContext context, String url) async {
    if (url.isEmpty) return;

    final extension = url.split('.').last.toLowerCase();
    if (extension == 'mp4' || extension == 'mov' || extension == 'avi') {
      _showVideoPopup(context, url);
      return;
    }

    String finalUrl = url;

    if (url.contains("upload/") &&
        (extension == 'pdf' ||
            extension == 'png' ||
            extension == 'jpg' ||
            extension == 'jpeg')) {
      finalUrl = url.replaceFirst("upload/", "upload/fl_attachment/");
    }

    final uri = Uri.parse(finalUrl);

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        await _fallbackOpen(url);
      }
    } catch (e) {
      debugPrint("Lỗi mở file: $e");
      await _fallbackOpen(url);
    }
  }

  void _showVideoPopup(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: VideoPlayerWidget(url: url),
        ),
      ),
    );
  }

  Future<void> _fallbackOpen(String url) async {
    final extension = url.split('.').last.toLowerCase();

    try {
      if (extension == 'doc' || extension == 'docx') {
        final viewer =
            "https://docs.google.com/gview?embedded=true&url=$url";

        await launchUrl(
          Uri.parse(viewer),
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      // 👉 fallback cuối → browser
      await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.platformDefault,
      );
    } catch (e) {
      debugPrint("Fallback cũng fail: $e");
    }
  }

  // ================= DATE =================
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
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chi tiết bài tập"),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chi tiết bài tập"),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchAssignmentDetail,
                child: const Text("Thử lại"),
              ),
            ],
          ),
        ),
      );
    }

    if (baiTap == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chi tiết bài tập"),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text("Không có dữ liệu")),
      );
    }

    final submissions = baiTap!['submissions'] ?? [];
    final daNop = submissions.isNotEmpty;
    final submission = daNop ? submissions[0] : null;
    final grade = submission?['grades'];

    final fileDinhKem = baiTap!['fileDinhKem'];
    final fileNop = submission?['fileNop'];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết bài tập"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              baiTap!['tieuDe'] ?? '',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),
            Text(
              "Hạn nộp: ${formatDate(baiTap!['hanNop'])}",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(baiTap!['moTa'] ?? 'Không có miêu tả'),

            const SizedBox(height: 20),

            if (fileDinhKem != null && fileDinhKem.toString().isNotEmpty)
              GestureDetector(
                onTap: () => openFile(context, fileDinhKem),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.attach_file),
                      SizedBox(width: 10),
                      Text("Xem file đính kèm"),
                    ],
                  ),
                ),
              )
            else
              const Text(
                "Không có file đính kèm",
                style: TextStyle(color: Colors.grey),
              ),

            const SizedBox(height: 30),

            const Text(
              "Trạng thái:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 5),

            Text(
              daNop ? "Đã nộp bài" : "Chưa nộp",
              style: TextStyle(
                color: daNop ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),
            if (daNop && submission != null) ...[
              const Text(
                "Bài đã nộp:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (fileNop != null && fileNop.toString().isNotEmpty)
                GestureDetector(
                  onTap: () => openFile(context, fileNop), // SỬA: fileNop chứ không phải fileDinhKem
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.upload_file),
                        SizedBox(width: 10),
                        Text("Xem bài đã nộp"),
                      ],
                    ),
                  ),
                )
              else
                const Text(
                  "Không có file đã nộp",
                  style: TextStyle(color: Colors.grey),
                ),
              
              const SizedBox(height: 8),
              
              Text(
                "Nội dung: ${submission['noiDung'] ?? 'Không có'}",
              ),
              
              const SizedBox(height: 10),
            ],

            if (grade != null)
              Text(
                "Điểm: ${grade['diem']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),

            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Nopbaitaphvscreen(
                      idAssignment: baiTap!['idAssignment'],
                      submission: submission,
                      hanNop: DateTime.tryParse(baiTap!['hanNop']),
                    ),
                  ),
                );
              },
              icon: Icon(daNop ? Icons.edit : Icons.upload),
              label: Text(daNop ? "Chỉnh sửa bài nộp" : "Nộp bài tập"),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _controller = VideoPlayerController.network(widget.url);
    await _controller!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _controller!,
      autoPlay: true,
    );

    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Chewie(controller: _chewieController!);
  }
}