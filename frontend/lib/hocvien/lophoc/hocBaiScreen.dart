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

  // Future<void> initBaiHoc() async {
  //   final videoUrl = widget.baiHoc['videoUrl'];
  //   final taiLieuUrl = widget.baiHoc['taiLieuUrl'];

  //   if (videoUrl != null && videoUrl != "") {
  //     isVideo = true;

  //     _controller = VideoPlayerController.network(videoUrl);

  //     await _controller!.initialize();
  //     _controller!.play();

  //     setState(() {
  //       isLoading = false;
  //     });

  //     await hocBai("dang_hoc");

  //     //lắng nghe video
  //     _controller!.addListener(() {
  //       final position = _controller!.value.position;
  //       final duration = _controller!.value.duration;

  //       if (!daBaoHoanThanh &&
  //           duration.inSeconds > 0 &&
  //           position.inSeconds >= duration.inSeconds - 1) {
  //         daBaoHoanThanh = true;
  //         hocBai("hoan_thanh");
  //       }
  //     });
  //   } else if (taiLieuUrl != null && taiLieuUrl != "") {
  //     isVideo = false;

  //     //tài liệu = mở là hoàn thành
  //     await hocBai("hoan_thanh");

  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
  Future<void> initBaiHoc() async {
  final videoUrl = widget.baiHoc['videoUrl'];
  final taiLieuUrl = widget.baiHoc['taiLieuUrl'];

  // 🎬 VIDEO
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
  }

  else if (taiLieuUrl != null && taiLieuUrl != "") {
    isVideo = false;

    // mở là tính hoàn thành luôn
    await hocBai("hoan_thanh");

    setState(() {
      isLoading = false;
    });
  }


  else {
    setState(() {
      isLoading = false;
    });
  }
}

  Future<void> hocBai(String trangThai) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");

    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/hocvien/baihoc/hoc-bai'),
      headers: {
        "Content-Type": "application/json",
        "x-user-id": userId.toString(),
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
    if (url.contains("upload/")) {
      // Thêm fl_attachment để tải về
      downloadUrl = url.replaceFirst("upload/", "upload/fl_attachment/");
    }

    final Uri uri = Uri.parse(downloadUrl);

    // Mẹo: Dùng LaunchMode.externalNonBrowserApplication nếu muốn mở thẳng app đọc file
    // Hoặc giữ nguyên externalApplication để qua trình duyệt
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void dispose() {
    // _controller?.dispose();
    // super.dispose();
    _controller?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Widget buildVideo() {
    // if (_controller == null || !_controller!.value.isInitialized) {
    //   return const Center(child: CircularProgressIndicator());
    // }

    // return Column(
    //   children: [
    //     AspectRatio(
    //       aspectRatio: _controller!.value.aspectRatio,
    //       child: VideoPlayer(_controller!),
    //     ),

    //     VideoProgressIndicator(
    //       _controller!,
    //       allowScrubbing: true,
    //       padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    //     ),

    //     Row(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         IconButton(
    //           icon: Icon(
    //             _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
    //           ),
    //           onPressed: () {
    //             setState(() {
    //               _controller!.value.isPlaying
    //                   ? _controller!.pause()
    //                   : _controller!.play();
    //             });
    //           },
    //         ),
    //       ],
    //     ),
    //   ],
    // );
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
      appBar: AppBar(title: Text(tenBai),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Phần nội dung chính có thể cuộn nếu bị tràn
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        isVideo ? buildVideo() : buildTaiLieu(),
                      ],
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
