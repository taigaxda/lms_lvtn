// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:frontend/api.dart';
// import 'package:chewie/chewie.dart';

// class HocBaiScreen extends StatefulWidget {
//   final int idKhoaHoc;
//   final Map<String, dynamic> baiHoc;

//   const HocBaiScreen({
//     super.key,
//     required this.idKhoaHoc,
//     required this.baiHoc,
//   });

//   @override
//   State<HocBaiScreen> createState() => _HocBaiScreenState();
// }

// class _HocBaiScreenState extends State<HocBaiScreen> {
//   VideoPlayerController? _controller;
//   ChewieController? _chewieController;
//   bool isVideo = false;
//   bool isLoading = true;
//   bool daBaoHoanThanh = false;

//   @override
//   void initState() {
//     super.initState();
//     initBaiHoc();
//   }

//   Future<void> initBaiHoc() async {
//     final videoUrl = widget.baiHoc['videoUrl'];
//     final taiLieuUrl = widget.baiHoc['taiLieuUrl'];
//     if (videoUrl != null && videoUrl != "") {
//       isVideo = true;
//       _controller = VideoPlayerController.network(videoUrl);
//       await _controller!.initialize();
//       _chewieController = ChewieController(
//         videoPlayerController: _controller!,
//         autoPlay: true,
//         looping: false,
//         allowFullScreen: true,
//         allowMuting: true,
//         allowPlaybackSpeedChanging: true,
//         showControls: true,
//         hideControlsTimer: const Duration(seconds: 3),
//         materialProgressColors: ChewieProgressColors(
//           playedColor: Colors.red,
//           handleColor: Colors.red,
//           backgroundColor: Colors.grey,
//           bufferedColor: Colors.grey.shade400,
//         ),
//       );
//       setState(() {
//         isLoading = false;
//       });
//       await hocBai("dang_hoc");
//       _controller!.addListener(() {
//         final position = _controller!.value.position;
//         final duration = _controller!.value.duration;
//         if (!daBaoHoanThanh &&
//             duration.inSeconds > 0 &&
//             position.inSeconds >= duration.inSeconds - 1) {
//           daBaoHoanThanh = true;
//           hocBai("hoan_thanh");
//         }
//       });
//     } else if (taiLieuUrl != null && taiLieuUrl != "") {
//       isVideo = false;
//       await hocBai("hoan_thanh");
//       setState(() {
//         isLoading = false;
//       });
//     } else {
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   Future<void> hocBai(String trangThai) async {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString("token");

//     await http.post(
//       Uri.parse('${ApiConfig.baseUrl}/hocvien/baihoc/hoc-bai'),
//       headers: {
//         "Content-Type": "application/json",
//         "Authorization": "Bearer $token",
//       },
//       body: json.encode({
//         "idKhoaHoc": widget.idKhoaHoc,
//         "idBaiHoc": widget.baiHoc['idBaiHoc'],
//         "trangThai": trangThai,
//       }),
//     );
//   }

// Future<void> openTaiLieu(String url) async {
//   if (url.isEmpty) return;
//   String downloadUrl = url;

//   final String extension = url.split('.').last.toLowerCase();

//   if (url.contains("upload/") &&
//       (extension == 'pdf' ||
//           extension == 'png' ||
//           extension == 'jpg' ||
//           extension == 'jpeg')) {
//     downloadUrl = url.replaceFirst("upload/", "upload/fl_attachment/");
//   }

//   final Uri uri = Uri.parse(downloadUrl);

//   try {
//     final bool launched = await launchUrl(
//       uri,
//       mode: LaunchMode.externalApplication,
//     );

//     if (!launched) {
//       debugPrint("Trình duyệt từ chối mở: $downloadUrl");
//     }
//   } catch (e) {
//     debugPrint("Lỗi mở URL: $e");
//     try {
//       await launchUrl(uri, mode: LaunchMode.platformDefault);
//     } catch (innerError) {
//       debugPrint("Mở trình duyệt nội bộ cũng thất bại: $innerError");
//     }
//   }
// }

//   @override
//   void dispose() {
//     _controller?.dispose();
//     _chewieController?.dispose();
//     super.dispose();
//   }

//   Widget buildVideo() {
//     if (_chewieController == null) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     return AspectRatio(
//       aspectRatio: _controller!.value.aspectRatio,
//       child: Chewie(controller: _chewieController!),
//     );
//   }

//   Widget buildTaiLieu() {
//     final url = widget.baiHoc['taiLieuUrl'];

//     return Center(
//       child: ElevatedButton.icon(
//         onPressed: () => openTaiLieu(url),
//         icon: const Icon(Icons.picture_as_pdf),
//         label: const Text("Mở tài liệu"),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final tenBai = widget.baiHoc['tenBaiHoc'] ?? "";
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(tenBai),
//         backgroundColor: Colors.blue,
//         iconTheme: const IconThemeData(color: Colors.white),
//         foregroundColor: Colors.white,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : Column(
//               children: [
//                 Expanded(
//                   child: SingleChildScrollView(
//                     child: Column(
//                       children: [isVideo ? buildVideo() : buildTaiLieu()],
//                     ),
//                   ),
//                 ),
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade100,
//                     border: const Border(top: BorderSide(color: Colors.grey)),
//                   ),
//                   child: SafeArea(
//                     top: false,
//                     child: Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text("Trạng thái: Đang học"),
//                         ElevatedButton(
//                           onPressed: () {
//                             Navigator.pop(context, true);
//                           },
//                           child: const Text("Xong"),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.blue,
//                             foregroundColor: Colors.white,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'package:chewie/chewie.dart';

class HocBaiScreen extends StatefulWidget {
  final int idKhoaHoc;
  final Map<String, dynamic> baiHoc;

  const HocBaiScreen({
    super.key,
    required this.idKhoaHoc,
    required this.baiHoc,
  });

  @override
  State<HocBaiScreen> createState() => _HocBaiScreenState();
}

class _HocBaiScreenState extends State<HocBaiScreen> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool isVideo = false;
  bool isLoading = true;
  bool daBaoHoanThanh = false;

  @override
  void initState() {
    super.initState();
    initBaiHoc();
  }

  Future<void> initBaiHoc() async {
    final videoUrl = widget.baiHoc['videoUrl'];
    final taiLieuUrl = widget.baiHoc['taiLieuUrl'];
    
    if (videoUrl != null && videoUrl != "") {
      isVideo = true;
      _controller = VideoPlayerController.network(videoUrl);
      await _controller!.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControls: true,
        hideControlsTimer: const Duration(seconds: 3),
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey.shade400,
        ),
      );
      
      setState(() {
        isLoading = false;
      });
      
      await hocBai("dang_hoc");
      
      _controller!.addListener(() {
        final position = _controller!.value.position;
        final duration = _controller!.value.duration;
        if (!daBaoHoanThanh &&
            duration.inSeconds > 0 &&
            position.inSeconds >= duration.inSeconds - 1) {
          daBaoHoanThanh = true;
          hocBai("hoan_thanh");
        }
      });
    } else if (taiLieuUrl != null && taiLieuUrl != "") {
      isVideo = false;
      await hocBai("dang_hoc");
      setState(() {
        isLoading = false;
      });
      // ✅ Mở tài liệu ngay khi vào bài
      openTaiLieu(taiLieuUrl);
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> hocBai(String trangThai) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/hocvien/baihoc/hoc-bai'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "idKhoaHoc": widget.idKhoaHoc,
          "idBaiHoc": widget.baiHoc['idBaiHoc'],
          "trangThai": trangThai,
        }),
      );
    } catch (e) {
      print('Lỗi học bài: $e');
    }
  }

  // ==================== XỬ LÝ MỞ TÀI LIỆU ====================
  Future<void> openTaiLieu(String url) async {
    if (url.isEmpty) return;

    // ✅ Kiểm tra nếu đã hoàn thành thì không mở lại
    if (daBaoHoanThanh) return;

    // ✅ Xử lý URL Cloudinary
    String downloadUrl = _fixCloudinaryUrl(url);
    final String extension = url.split('.').last.toLowerCase();

    // ✅ Nếu là PDF hoặc các file tài liệu
    if (_isDocumentFile(extension)) {
      // ✅ Thử mở bằng trình duyệt trước
      bool opened = await _openWithBrowser(downloadUrl);
      
      // ✅ Nếu không mở được, cho phép tải về
      if (!opened) {
        _showDownloadDialog(downloadUrl);
      }
      return;
    }

    // ✅ Các file khác: mở bằng trình duyệt
    await _openWithBrowser(downloadUrl);
  }

  // ==================== KIỂM TRA FILE TÀI LIỆU ====================
  bool _isDocumentFile(String extension) {
    final documentExtensions = [
      'pdf', 'doc', 'docx', 'ppt', 'pptx', 
      'xls', 'xlsx', 'zip', 'rar', '7z'
    ];
    return documentExtensions.contains(extension.toLowerCase());
  }

  // ==================== XỬ LÝ CLOUDINARY URL ====================
  String _fixCloudinaryUrl(String url) {
    if (url.isEmpty) return url;

    final String extension = url.split('.').last.toLowerCase();

    // ✅ Nếu là file từ Cloudinary
    if (url.contains("upload/")) {
      // ✅ Các file tài liệu cần fl_attachment để tải về
      if (_isDocumentFile(extension)) {
        return url.replaceFirst("upload/", "upload/fl_attachment/");
      }
      // ✅ Hình ảnh: thêm fl_attachment để hiển thị
      if (extension == 'png' || extension == 'jpg' || extension == 'jpeg') {
        return url.replaceFirst("upload/", "upload/fl_attachment/");
      }
    }

    return url;
  }

  // ==================== MỞ BẰNG TRÌNH DUYỆT ====================
  Future<bool> _openWithBrowser(String url) async {
    try {
      final uri = Uri.parse(url);
      
      // ✅ Thử mở bằng trình duyệt ngoài
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        print('✅ Đã mở file: $url');
        return true;
      }

      // ✅ Thử mở bằng platform default
      final bool defaultLaunched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      
      if (defaultLaunched) {
        print('✅ Đã mở file (platform default): $url');
        return true;
      }

      print('❌ Không thể mở file: $url');
      return false;
    } catch (e) {
      print('❌ Lỗi mở file: $e');
      return false;
    }
  }

  // ==================== HIỂN THỊ DIALOG TẢI FILE ====================
  void _showDownloadDialog(String url) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('📄 Tải tài liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description, size: 48, color: Colors.blue),
            const SizedBox(height: 12),
            const Text(
              'Không thể mở tài liệu tự động.\nVui lòng tải về để xem.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              url.split('/').last.split('?').first,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '⏱️ Sau khi tải về, nhấn "Đã xem xong" để hoàn thành',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // ✅ Vẫn đánh dấu hoàn thành nếu user đã xem
              _danhDauHoanThanh();
            },
            child: const Text('✅ Đã xem xong'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndOpenFile(url);
            },
            icon: const Icon(Icons.download),
            label: const Text('Tải file'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== TẢI FILE VÀ MỞ ====================
  Future<void> _downloadAndOpenFile(String url) async {
    try {
      // Hiển thị loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⏳ Đang tải file...')),
      );

      // Tải file
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final fileName = url.split('/').last.split('?').first;
        
        // Lưu vào bộ nhớ tạm
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        // Đóng loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Tải file thành công!',)),
        );
        
        // Mở file
        final result = await OpenFilex.open(file.path);
        
        if (result.type == ResultType.done) {
          print('✅ Đã mở file: $fileName');
          // ✅ Đánh dấu hoàn thành khi mở file thành công
          _danhDauHoanThanh();
        } else {
          print('❌ Không thể mở file: ${result.message}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể mở file, vui lòng thử lại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        throw Exception('Tải file thất bại');
      }
    } catch (e) {
      print('❌ Lỗi tải file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi tải file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ==================== ĐÁNH DẤU HOÀN THÀNH ====================
  Future<void> _danhDauHoanThanh() async {
    if (daBaoHoanThanh) return;
    
    daBaoHoanThanh = true;
    await hocBai("hoan_thanh");
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Đã hoàn thành bài học!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  // ==================== BUILD VIDEO ====================
  Widget buildVideo() {
    if (_chewieController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }

  // ==================== BUILD TÀI LIỆU ====================
  Widget buildTaiLieu() {
    final url = widget.baiHoc['taiLieuUrl'] ?? '';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.picture_as_pdf,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              widget.baiHoc['tenBaiHoc'] ?? '',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              daBaoHoanThanh ? '✅ Đã hoàn thành' : 'Nhấn nút bên dưới để xem tài liệu',
              style: TextStyle(
                fontSize: 14,
                color: daBaoHoanThanh ? Colors.green : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            if (!daBaoHoanThanh)
              ElevatedButton.icon(
                onPressed: () => openTaiLieu(url),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Mở tài liệu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            if (daBaoHoanThanh)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
          ],
        ),
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final tenBai = widget.baiHoc['tenBaiHoc'] ?? "";
    return Scaffold(
      appBar: AppBar(
        title: Text(tenBai),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        actions: [
          if (daBaoHoanThanh)
            const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [isVideo ? buildVideo() : buildTaiLieu()],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: const Border(top: BorderSide(color: Colors.grey)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          daBaoHoanThanh
                              ? "✅ Đã hoàn thành"
                              : "📖 Đang học",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: daBaoHoanThanh ? Colors.green : Colors.blue,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (!daBaoHoanThanh) {
                              _danhDauHoanThanh();
                            } else {
                              Navigator.pop(context, true);
                            }
                          },
                          child: Text(
                            daBaoHoanThanh ? "Thoát" : "Xong",
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: daBaoHoanThanh ? Colors.grey : Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}