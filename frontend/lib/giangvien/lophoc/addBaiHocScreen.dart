import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/api.dart';
import 'package:frontend/giangvien/menuUI/giangVienMenuBar.dart';

class Addbaihocscreen extends StatefulWidget {
  final int idKhoaHoc;
  const Addbaihocscreen({super.key, required this.idKhoaHoc});

  @override
  State<Addbaihocscreen> createState() => _Addbaihocscreen();
}

class _Addbaihocscreen extends State<Addbaihocscreen> {
  final TextEditingController tenController = TextEditingController();
  final TextEditingController thuTuController = TextEditingController();

  PlatformFile? pickedFile;
  File? selectedFile;

  bool isLoading = false;
  String hoTen = "";
  String vaiTro = "";

  final String apiUrl = "${ApiConfig.baseUrl}/giangvien/baihoc";

  @override
  void initState() {
    super.initState();
    loadUserInfo();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'mp4',
        'mkv',
        'doc',
        'docx',
        'rar',
        'zip',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
      ],
      withData: true,
    );

    if (result != null) {
      if (kIsWeb) {
        pickedFile = result.files.first;
      } else {
        selectedFile = File(result.files.first.path!);
      }
      setState(() {});
    }
  }

  Future<void> submit() async {
    if (tenController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nhập tên bài học")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");

      final res = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId.toString(),
        },
        body: jsonEncode({
          "idKhoaHoc": widget.idKhoaHoc,
          "tenBaiHoc": tenController.text.trim(),
          "thuTu": int.tryParse(thuTuController.text) ?? 1,
        }),
      );

      if (res.statusCode != 201) {
        throw Exception("Tạo bài học thất bại");
      }

      final idBaiHoc = json.decode(res.body)['idBaiHoc'];

      if (pickedFile != null || selectedFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$apiUrl/upload-file/$idBaiHoc'),
        );

        request.headers["x-user-id"] = userId.toString();

        if (kIsWeb && pickedFile != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'taiLieu',
              pickedFile!.bytes!,
              filename: pickedFile!.name,
            ),
          );
        } else if (selectedFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath('taiLieu', selectedFile!.path),
          );
        }

        final uploadRes = await request.send();

        if (uploadRes.statusCode != 200) {
          throw Exception("Upload file thất bại");
        }
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Thêm bài học thành công")));

      Navigator.pop(context, true);
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Có lỗi xảy ra")));
    }

    setState(() => isLoading = false);
  }

  Widget filePreview() {
    if (pickedFile == null && selectedFile == null) {
      return const SizedBox();
    }

    String name = "";

    if (kIsWeb && pickedFile != null) {
      name = pickedFile!.name;
    } else if (selectedFile != null) {
      name = selectedFile!.path.split('/').last;
    }

    return ListTile(
      leading: name.endsWith('.mp4')
          ? const Icon(Icons.video_file, color: Colors.blue)
          : const Icon(Icons.picture_as_pdf, color: Colors.red),
      title: Text(name),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Thêm bài học",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: GiangVienMenuBar(hoTen: hoTen, vaiTro: vaiTro),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: tenController,
                    decoration: const InputDecoration(
                      labelText: "Tên bài học",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: thuTuController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Thứ tự",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Chọn file (video/tài liệu)"),
                  ),

                  const SizedBox(height: 10),

                  filePreview(),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: Colors.grey),
                            backgroundColor: Colors.red
                          ),
                          child: const Text(
                            "Hủy / Quay lại",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: Colors.blue
                          ),
                          child: const Text("Tạo bài học",style: TextStyle(color: Colors.white),),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
