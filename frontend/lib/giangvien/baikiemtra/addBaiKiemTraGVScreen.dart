import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class AddBaiKiemTraGVScreen extends StatefulWidget {
  final int idKhoaHoc;
  final Map<String, dynamic>? quiz;

  const AddBaiKiemTraGVScreen({
    super.key,
    required this.idKhoaHoc,
    this.quiz,
  });

  @override
  State<AddBaiKiemTraGVScreen> createState() =>_AddBaiKiemTraGVScreenState();
}

class _AddBaiKiemTraGVScreenState extends State<AddBaiKiemTraGVScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController tenQuizController = TextEditingController();
  final TextEditingController thoiGianController = TextEditingController();
  final TextEditingController ngayDenHanController = TextEditingController();

  bool isLoading = false;

  final String apiUrl = '${ApiConfig.baseUrl}/giangvien/quiz';

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      tenQuizController.text = widget.quiz!["tenQuiz"] ?? "";
      thoiGianController.text =
          (widget.quiz!["thoiGianLamBai"] ?? "").toString();
    }
  }
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");
      final body = {
        "tenQuiz": tenQuizController.text.trim(),
        "thoiGianLamBai": int.parse(thoiGianController.text.trim()),
        "idKhoaHoc": widget.idKhoaHoc
      };
      http.Response res;
      if (widget.quiz == null) {
        res = await http.post(
          Uri.parse(apiUrl),
          headers: {
            "Content-Type": "application/json",
            "x-user-id": userId.toString(),
          },
          body: jsonEncode(body),
        );
      } else {
        res = await http.put(
          Uri.parse('$apiUrl/${widget.quiz!["idQuiz"]}'),
          headers: {
            "Content-Type": "application/json",
            "x-user-id": userId.toString(),
          },
          body: jsonEncode({
            "tenQuiz": body["tenQuiz"],
            "thoiGianLamBai": body["thoiGianLamBai"],
          }),
        );
      }
      final data = jsonDecode(res.body);
      if (data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.quiz == null
                ? "Tạo bài kiểm tra thành công"
                : "Cập nhật thành công"),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(data["error"]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.quiz != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Sửa bài kiểm tra" : "Thêm bài kiểm tra"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: tenQuizController,
                decoration: const InputDecoration(
                  labelText: "Tên bài kiểm tra",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Không được để trống";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: thoiGianController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Thời gian (phút)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Không được để trống";
                  }
                  if (int.tryParse(value) == null) {
                    return "Phải là số";
                  }
                  if (int.parse(value) <= 0) {
                    return "Phải > 0";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          isEdit ? "Cập nhật" : "Tạo bài kiểm tra",
                          style: const TextStyle(fontSize: 16,color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}