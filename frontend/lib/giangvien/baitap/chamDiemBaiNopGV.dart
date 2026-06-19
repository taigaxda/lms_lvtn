import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class Chamdiembainopgv extends StatefulWidget {
  final int idSubmission;
  const Chamdiembainopgv({super.key, required this.idSubmission});
  @override
  State<Chamdiembainopgv> createState() => _Chamdiembainopgv();
}

class _Chamdiembainopgv extends State<Chamdiembainopgv> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  final String apiUrl = '${ApiConfig.baseUrl}/giangvien/baitap';
  final TextEditingController diemController = TextEditingController();
  final TextEditingController nhanXetController = TextEditingController();
  @override
  void initState() {
    super.initState();
    getChiTiet();
  }

  Future<void> getChiTiet() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.get(
        Uri.parse('$apiUrl/chitietbt/${widget.idSubmission}'),
        headers: {"Authorization": "Bearer $token"},
      );
      final jsonData = jsonDecode(res.body);
      if (jsonData["success"]) {
        setState(() {
          data = jsonData["data"];
          isLoading = false;
          if (data!["grades"] != null) {
            diemController.text = data!["grades"]["diem"].toString();
            nhanXetController.text = data!["grades"]["nhanXet"] ?? "";
          }
        });
      }
    } catch (e) {
      debugPrint("Lỗi: $e");
    }
  }

  Future<void> chamDiem() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final res = await http.post(
        Uri.parse('$apiUrl/chamdiem/${widget.idSubmission}'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "diem": diemController.text,
          "nhanXet": nhanXetController.text,
        }),
      );
      final jsonData = jsonDecode(res.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(jsonData["message"])));

      if (jsonData["success"]) {
        getChiTiet();
        Navigator.pop(context, {
          'success': true,
          'diem': diemController.text,
          'nhanXet': nhanXetController.text,
        });
      }
    } catch (e) {
      debugPrint("Lỗi chấm điểm: $e");
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

  Future<void> _fallbackOpen(String url) async {
    final extension = url.split('.').last.toLowerCase();

    try {
      if (extension == 'doc' || extension == 'docx') {
        final viewer = "https://docs.google.com/gview?embedded=true&url=$url";

        await launchUrl(
          Uri.parse(viewer),
          mode: LaunchMode.externalApplication,
        );
        return;
      }

      await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint("Fallback cũng fail: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chấm điểm bài nộp"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
          ? const Center(child: Text("Không có dữ liệu"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Học viên: ${data!["nguoidung"]["hoTen"]}"),
                  const SizedBox(height: 8),
                  Text("Email: ${data!["nguoidung"]["email"]}"),

                  const SizedBox(height: 16),
                  if (data!["fileNop"] != null)
                    ElevatedButton(
                      onPressed: () => openFile(context, data!["fileNop"]),
                      child: const Text("Xem file nộp"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),

                  const SizedBox(height: 16),
                  if (data!["noiDung"] != null)
                    Text("Nội dung: ${data!["noiDung"]}"),

                  const SizedBox(height: 20),

                  TextField(
                    controller: diemController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Điểm (0-10)",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: nhanXetController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Nhận xét",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: chamDiem,
                      child: const Text("Chấm điểm"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
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
