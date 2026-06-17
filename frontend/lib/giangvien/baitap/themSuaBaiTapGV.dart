import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/api.dart';

class Themsuabaitapgv extends StatefulWidget {
  final int idKhoaHoc;
  final Map<String, dynamic>? baiTap;

  const Themsuabaitapgv({super.key, required this.idKhoaHoc, this.baiTap});

  @override
  State<Themsuabaitapgv> createState() => _ThemsuabaitapGVState();
}

class _ThemsuabaitapGVState extends State<Themsuabaitapgv> {
  final tieuDeController = TextEditingController();
  final moTaController = TextEditingController();

  DateTime? hanNop;

  PlatformFile? pickedFile;
  File? selectedFile;

  bool isLoading = false;

  bool get isEdit => widget.baiTap != null;

  final String apiUrl = "${ApiConfig.baseUrl}/giangvien/baitap";

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final data = widget.baiTap!;
      tieuDeController.text = data["tieuDe"] ?? "";
      moTaController.text = data["moTa"] ?? "";
      if (data["hanNop"] != null) {
        hanNop = DateTime.tryParse(data["hanNop"]);
      }
    }
  }

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      if (kIsWeb) {
        pickedFile = result.files.first;
      } else {
        selectedFile = File(result.files.first.path!);
      }
      setState(() {});
    }
  }

  Future<void> pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: hanNop ?? now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(hanNop ?? now),
    );

    if (pickedTime == null) return;

    final selectedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    if (selectedDateTime.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không được chọn thời gian trong quá khứ")),
      );
      return;
    }

    setState(() {
      hanNop = selectedDateTime;
    });
  }

  Future<void> submit() async {
    if (tieuDeController.text.trim().isEmpty ||
        moTaController.text.trim().isEmpty ||
        hanNop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đầy đủ thông tin")),
      );
      return;
    }
    setState(() {
      isLoading = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      http.StreamedResponse response;
      if (!isEdit) {
        var request = http.MultipartRequest(
          "POST",
          Uri.parse("$apiUrl/${widget.idKhoaHoc}"),
        );
        request.headers["Authorization"] = "Bearer $token";
        request.fields["tieuDe"] = tieuDeController.text.trim();
        request.fields["moTa"] = moTaController.text.trim();
        request.fields["hanNop"] = hanNop!.toIso8601String();
        if (pickedFile != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'fileDinhKem',
              pickedFile!.bytes!,
              filename: pickedFile!.name,
            ),
          );
        } else if (selectedFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'fileDinhKem',
              selectedFile!.path,
            ),
          );
        }

        response = await request.send();
      } else {
        int idAssignment = widget.baiTap!["idAssignment"];

        var request = http.MultipartRequest(
          "PUT",
          Uri.parse("$apiUrl/$idAssignment"),
        );

        request.headers["Authorization"] = "Bearer $token";

        request.fields["tieuDe"] = tieuDeController.text.trim();
        request.fields["moTa"] = moTaController.text.trim();
        request.fields["hanNop"] = hanNop!.toIso8601String();

        if (pickedFile != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'fileDinhKem',
              pickedFile!.bytes!,
              filename: pickedFile!.name,
            ),
          );
        } else if (selectedFile != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'fileDinhKem',
              selectedFile!.path,
            ),
          );
        }

        response = await request.send();
      }
      final resBody = await response.stream.bytesToString();
      final data = jsonDecode(resBody);

      if (data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? "Cập nhật bài tập thành công"
                  : "Thêm bài tập thành công",
            ),
          ),
        );

        Navigator.pop(context, true);
      } else {
        throw Exception(data["message"]);
      }
    } catch (e) {
      debugPrint("Lỗi: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Có lỗi xảy ra")));
    }
    setState(() {
      isLoading = false;
    });
  }

  Widget filePreview() {
    if (pickedFile == null && selectedFile == null) {
      if (isEdit && widget.baiTap?["fileDinhKem"] != null) {
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(widget.baiTap!["fileDinhKem"]),
          subtitle: const Text("File hiện tại"),
        );
      }
      return const SizedBox();
    }

    String name = "";

    if (kIsWeb && pickedFile != null) {
      name = pickedFile!.name;
    } else if (selectedFile != null) {
      name = selectedFile!.path.split('/').last;
    }

    return ListTile(
      leading: const Icon(Icons.insert_drive_file),
      title: Text(name),
    );
  }

  String formatDate() {
    if (hanNop == null) return "Chọn hạn nộp";
    return "${hanNop!.day}/${hanNop!.month}/${hanNop!.year}";
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? "Sửa bài tập" : "Thêm bài tập",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: tieuDeController,
                    decoration: const InputDecoration(
                      labelText: "Tiêu đề",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: moTaController,
                    decoration: const InputDecoration(
                      labelText: "Mô tả",
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),

                  const SizedBox(height: 15),

                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(formatDate()),
                    onTap: pickDateTime,
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    onPressed: pickFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Chọn file đính kèm"),
                  ),

                  filePreview(),

                  const SizedBox(height: 30),

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
                          onPressed: submit,
                          child: Text(isEdit ? "Cập nhật" : "Tạo"),
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
