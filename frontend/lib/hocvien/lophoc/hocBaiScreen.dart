import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:async';
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
  Timer? _trackingTimer;
  int _tongThoiGianDaHoc = 0;
  static const int _INTERVAL_GUI = 5;

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

      _startTracking();

      _controller!.addListener(() {
        final position = _controller!.value.position;
        final duration = _controller!.value.duration;

        if (!daBaoHoanThanh &&
            duration.inSeconds > 0 &&
            position.inSeconds >= duration.inSeconds - 1) {
          daBaoHoanThanh = true;
          _stopTracking();
          _callHocBai("hoan_thanh", 0);
        }
      });
    } else if (taiLieuUrl != null && taiLieuUrl != "") {
      isVideo = false;
      setState(() {
        isLoading = false;
      });
      _startTracking();
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: _INTERVAL_GUI), (
      timer,
    ) async {
      await _callHocBai("dang_hoc", _INTERVAL_GUI);
      setState(() {
        _tongThoiGianDaHoc += _INTERVAL_GUI;
      });
    });
  }

  void _stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  Future<void> _callHocBai(String trangThai, int thoiGianHoc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/hocvien/baihoc/hoc-bai'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "idKhoaHoc": widget.idKhoaHoc,
          "idBaiHoc": widget.baiHoc['idBaiHoc'],
          "trangThai": trangThai,
          "thoiGianHoc": thoiGianHoc,
        }),
      );

      if (response.statusCode != 200) {
        debugPrint("Lỗi cập nhật: ${response.body}");
      }
    } catch (e) {
      debugPrint("Lỗi cập nhật tiến độ: $e");
    }
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
    _stopTracking();
    if (!isVideo && !daBaoHoanThanh && _tongThoiGianDaHoc > 0) {
      _callHocBai("hoan_thanh", 0);
    }
    if (isVideo && !daBaoHoanThanh && _tongThoiGianDaHoc > 0) {
      _callHocBai("dang_hoc", 0);
    }

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.picture_as_pdf, size: 80, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text(
            "Tài liệu bài học",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            url.split('/').last,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => openTaiLieu(url),
            icon: const Icon(Icons.download),
            label: const Text("Tải tài liệu"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                "Đã học: ${_tongThoiGianDaHoc ~/ 60} phút ${_tongThoiGianDaHoc % 60} giây",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ],
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
                        Text(
                          isVideo
                              ? "Trạng thái: Đang học"
                              : "Trạng thái: ${daBaoHoanThanh ? 'Hoàn thành' : 'Đang học'}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _stopTracking();
                            if (!isVideo && !daBaoHoanThanh) {
                              _callHocBai("hoan_thanh", 0);
                              setState(() {
                                daBaoHoanThanh = true;
                              });
                            }
                            else if (isVideo &&
                                _tongThoiGianDaHoc > 0 &&
                                !daBaoHoanThanh) {
                              _callHocBai("dang_hoc", 0);
                            }

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
