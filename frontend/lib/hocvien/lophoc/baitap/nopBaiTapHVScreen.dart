import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/api.dart';

class Nopbaitaphvscreen extends StatefulWidget {
  final int idAssignment;
  final Map<String, dynamic>? submission;
  final DateTime? hanNop;

  const Nopbaitaphvscreen({
    super.key,
    required this.idAssignment,
    this.submission,
    this.hanNop,
  });

  @override
  State<Nopbaitaphvscreen> createState() => _NopbaitaphvscreenState();
}

class _NopbaitaphvscreenState extends State<Nopbaitaphvscreen> {
  final noiDungController = TextEditingController();

  PlatformFile? pickedFile;
  File? selectedFile;

  bool isLoading = false;

  final String apiUrl = "${ApiConfig.baseUrl}/hocvien/baitap";

  bool get isEdit => widget.submission != null;

  bool get isExpired {
    if (widget.hanNop == null) return false;
    return DateTime.now().isAfter(widget.hanNop!);
  }

  @override
  void initState() {
    super.initState();

    if (isEdit) {
      noiDungController.text =
          widget.submission!["noiDung"] ?? "";
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result != null) {
      setState(() {
        if (kIsWeb) {
          pickedFile = result.files.first;
        } else {
          selectedFile = File(result.files.first.path!);
        }
      });
    }
  }

  Future<void> submit() async {
    if (pickedFile == null && selectedFile == null && !isEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phải chọn file để nộp bài")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("${apiUrl}/${widget.idAssignment}/nopbai"),
      );

      request.headers["Authorization"] = "Bearer $token";

      if (noiDungController.text.trim().isNotEmpty) {
        request.fields["noiDung"] = noiDungController.text.trim();
      }

      if (pickedFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'fileNop',
            pickedFile!.bytes!,
            filename: pickedFile!.name,
          ),
        );
      } else if (selectedFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'fileNop',
            selectedFile!.path,
          ),
        );
      }

      final response = await request.send();
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);

      if (data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? "Cập nhật bài nộp thành công" : "Nộp bài thành công",
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception(data["message"]);
      }
    } catch (e) {
      debugPrint("Lỗi nộp bài: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nộp bài thất bại")),
      );
    }

    setState(() => isLoading = false);
  }

  // Widget filePreview() {
  //   if (pickedFile == null && selectedFile == null) {
  //     return const Text(
  //       "Chưa chọn file mới",
  //       style: TextStyle(color: Colors.grey),
  //     );
  //   }

  //   String name = "";

  //   if (kIsWeb && pickedFile != null) {
  //     name = pickedFile!.name;
  //   } else if (selectedFile != null) {
  //     name = selectedFile!.path.split('/').last;
  //   }

  //   return ListTile(
  //     leading: const Icon(Icons.insert_drive_file),
  //     title: Text(name),
  //   );
  // }
    // ================= FILE PREVIEW =================
  Widget filePreview() {
    // Nếu đã chọn file mới
    if (pickedFile != null || selectedFile != null) {
      String name = "";
      
      if (kIsWeb && pickedFile != null) {
        name = pickedFile!.name;
      } else if (selectedFile != null) {
        name = selectedFile!.path.split('/').last;
      }

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.insert_drive_file, color: Colors.green),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (pickedFile != null && pickedFile!.size > 0)
                    Text(
                      "${(pickedFile!.size / 1024).toStringAsFixed(2)} KB",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  pickedFile = null;
                  selectedFile = null;
                });
              },
            ),
          ],
        ),
      );
    }
    if (isEdit && widget.submission?["fileNop"] != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "File đã nộp trước đó:",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    widget.submission!["fileNop"].toString().split('/').last,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey),
          SizedBox(width: 10),
          Text(
            "Chưa chọn file",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }


  Widget oldSubmissionPreview() {
    if (!isEdit) return const SizedBox();

    // final file = widget.submission!["fileNop"];

    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Expanded(child: Text("Bạn đã nộp bài trước đó")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Cập nhật bài nộp" : "Nộp bài"),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  oldSubmissionPreview(),

                  TextField(
                    controller: noiDungController,
                    decoration: const InputDecoration(
                      labelText: "Nội dung",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Chọn file"),
                  ),

                  const SizedBox(height: 10),

                  filePreview(),

                  const Spacer(),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Hủy"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isExpired ? null : submit,
                          child: Text(
                            isExpired
                                ? "Đã quá hạn"
                                : isEdit
                                    ? "Cập nhật bài nộp"
                                    : "Nộp bài",
                          ),
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