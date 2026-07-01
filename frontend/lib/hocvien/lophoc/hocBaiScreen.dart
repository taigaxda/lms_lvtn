import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
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
      await hocBai("hoan_thanh");
      setState(() {
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> hocBai(String trangThai) async {
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
  }

Future<void> openTaiLieu(String url) async {
  if (url.isEmpty) return;
  String downloadUrl = url;

  final String extension = url.split('.').last.toLowerCase();

  if (url.contains("upload/") &&
      (extension == 'pdf' ||
          extension == 'png' ||
          extension == 'jpg' ||
          extension == 'jpeg')) {
    downloadUrl = url.replaceFirst("upload/", "upload/fl_attachment/");
  }

  final Uri uri = Uri.parse(downloadUrl);

  try {
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launched) {
      debugPrint("Trình duyệt từ chối mở: $downloadUrl");
    }
  } catch (e) {
    debugPrint("Lỗi mở URL: $e");
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (innerError) {
      debugPrint("Mở trình duyệt nội bộ cũng thất bại: $innerError");
    }
  }
}

  @override
  void dispose() {
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Widget buildVideo() {
    if (_chewieController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Chewie(controller: _chewieController!),
    );
  }

  Widget buildTaiLieu() {
    final url = widget.baiHoc['taiLieuUrl'];

    return Center(
      child: ElevatedButton.icon(
        onPressed: () => openTaiLieu(url),
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("Mở tài liệu"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenBai = widget.baiHoc['tenBaiHoc'] ?? "";
    return Scaffold(
      appBar: AppBar(
        title: Text(tenBai),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
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
                        const Text("Trạng thái: Đang học"),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: const Text("Xong"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
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
// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
// import 'package:chewie/chewie.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:frontend/api.dart';

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

// class _HocBaiScreenState extends State<HocBaiScreen>
//     with WidgetsBindingObserver {
//   VideoPlayerController? _controller;
//   ChewieController? _chewieController;

//   bool isVideo = false;
//   bool isLoading = true;
//   bool daBaoHoanThanh = false;

//   int _thoiGianXem = 0;
//   Timer? _timer;
//   DateTime? _docStartTime;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     initBaiHoc();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);

//     _timer?.cancel();

//     // document: tính thời gian khi thoát
//     if (!isVideo && _docStartTime != null) {
//       final duration = DateTime.now().difference(_docStartTime!).inSeconds;
//       if (duration > 0) {
//         _guiThoiGian(duration);
//       }
//     }

//     _controller?.dispose();
//     _chewieController?.dispose();
//     super.dispose();
//   }

//   // ================= INIT =================
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
//         allowFullScreen: true,
//       );

//       setState(() => isLoading = false);

//       await hocBai("dang_hoc", 0);
//       _startTracking();

//       // check hoàn thành
//       _controller!.addListener(() {
//         final pos = _controller!.value.position;
//         final dur = _controller!.value.duration;

//         if (!daBaoHoanThanh &&
//             dur.inSeconds > 0 &&
//             pos.inSeconds >= dur.inSeconds - 1) {
//           daBaoHoanThanh = true;
//           _timer?.cancel();
//           hocBai("hoan_thanh", 0);
//         }
//       });
//     } else if (taiLieuUrl != null && taiLieuUrl != "") {
//       isVideo = false;
//       setState(() => isLoading = false);

//       await hocBai("dang_hoc", 0);
//     } else {
//       setState(() => isLoading = false);
//     }
//   }

//   // ================= TRACKING VIDEO =================
//   void _startTracking() {
//     _timer?.cancel();

//     _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
//       if (!mounted) return;

//       if (_controller != null && _controller!.value.isPlaying) {
//         _thoiGianXem += 5;
//         _guiThoiGian(5); // 👈 gửi delta
//       }
//     });
//   }

//   // ================= TRACKING DOCUMENT =================
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (isVideo) return;

//     if (state == AppLifecycleState.paused) {
//       _docStartTime = DateTime.now();
//     }

//     if (state == AppLifecycleState.resumed) {
//       if (_docStartTime != null) {
//         final duration =
//             DateTime.now().difference(_docStartTime!).inSeconds;

//         if (duration > 0) {
//           _thoiGianXem += duration;
//           _guiThoiGian(duration);
//         }

//         _docStartTime = null;
//       }
//     }
//   }

//   // ================= API =================
//   Future<void> _guiThoiGian(int delta) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("token");

//       await http.post(
//         Uri.parse('${ApiConfig.baseUrl}/hocvien/baihoc/hoc-bai'),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: json.encode({
//           "idKhoaHoc": widget.idKhoaHoc,
//           "idBaiHoc": widget.baiHoc['idBaiHoc'],
//           "trangThai": "dang_hoc",
//           "thoiGianXem": delta,
//         }),
//       );
//     } catch (e) {
//       print("❌ lỗi tracking: $e");
//     }
//   }

//   Future<void> hocBai(String trangThai, int time) async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("token");

//       await http.post(
//         Uri.parse('${ApiConfig.baseUrl}/hocvien/baihoc/hoc-bai'),
//         headers: {
//           "Content-Type": "application/json",
//           "Authorization": "Bearer $token",
//         },
//         body: json.encode({
//           "idKhoaHoc": widget.idKhoaHoc,
//           "idBaiHoc": widget.baiHoc['idBaiHoc'],
//           "trangThai": trangThai,
//           "thoiGianXem": time,
//         }),
//       );
//     } catch (e) {
//       print("❌ lỗi hocBai: $e");
//     }
//   }

//   // ================= OPEN DOC =================
//   Future<void> _openTaiLieu(String url) async {
//     final uri = Uri.parse(url);
//     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   }

//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     final ten = widget.baiHoc['tenBaiHoc'] ?? "";

//     return Scaffold(
//       appBar: AppBar(title: Text(ten)),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : isVideo
//               ? Column(
//                   children: [
//                     AspectRatio(
//                       aspectRatio: _controller!.value.aspectRatio,
//                       child: Chewie(controller: _chewieController!),
//                     ),
//                     _bottomBar()
//                   ],
//                 )
//               : Column(
//                   children: [
//                     Expanded(
//                       child: Center(
//                         child: ElevatedButton(
//                           onPressed: () =>
//                               _openTaiLieu(widget.baiHoc['taiLieuUrl']),
//                           child: const Text("Mở tài liệu"),
//                         ),
//                       ),
//                     ),
//                     _bottomBar()
//                   ],
//                 ),
//     );
//   }

//   Widget _bottomBar() {
//     return Padding(
//       padding: const EdgeInsets.all(12),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text("⏱️ ${_format(_thoiGianXem)}"),
//           Row(
//             children: [
//               if (!daBaoHoanThanh)
//                 ElevatedButton(
//                   onPressed: () async {
//                     daBaoHoanThanh = true;
//                     await hocBai("hoan_thanh", 0);
//                     Navigator.pop(context, true);
//                   },
//                   child: const Text("Hoàn thành"),
//                 ),
//               const SizedBox(width: 10),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context, true),
//                 child: const Text("Thoát"),
//               )
//             ],
//           )
//         ],
//       ),
//     );
//   }

//   String _format(int s) {
//     final m = s ~/ 60;
//     final sec = s % 60;
//     return "${m}m ${sec}s";
//   }
// }