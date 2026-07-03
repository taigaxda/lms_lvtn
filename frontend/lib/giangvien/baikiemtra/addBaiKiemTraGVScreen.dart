import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class AddBaiKiemTraGVScreen extends StatefulWidget {
  final int idKhoaHoc;
  final Map<String, dynamic>? quiz;

  const AddBaiKiemTraGVScreen({super.key, required this.idKhoaHoc, this.quiz});

  @override
  State<AddBaiKiemTraGVScreen> createState() => _AddBaiKiemTraGVScreenState();
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
      // if (widget.quiz!["thoiGianLamBai"] != null) {
      //   thoiGianController.text = widget.quiz!["thoiGianLamBai"].toString();
      // }
      // if (widget.quiz!["ngayDenHan"] != null) {
      //   ngayDenHanController.text = widget.quiz!["ngayDenHan"].toString();
      // }
      final thoiGian = widget.quiz!["thoiGianLamBai"];
      if (thoiGian != null) {
        thoiGianController.text = thoiGian.toString();
      } else {
        thoiGianController.clear();
      }
      final ngayDenHan = widget.quiz!["ngayDenHan"];
      if (ngayDenHan != null) {
        ngayDenHanController.text = ngayDenHan.toString();
      } else {
        ngayDenHanController.clear();
      }
    }
  }

  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      final thoiGianText = thoiGianController.text.trim();
      final thoiGianLamBai = thoiGianText.isEmpty
          ? null
          : int.parse(thoiGianText);
      final body = {
        "tenQuiz": tenQuizController.text.trim(),
        "thoiGianLamBai": thoiGianLamBai,
        "ngayDenHan": ngayDenHanController.text.trim().isEmpty
            ? null
            : ngayDenHanController.text.trim(),
        "idKhoaHoc": widget.idKhoaHoc,
      };
      http.Response res;
      if (widget.quiz == null) {
        res = await http.post(
          Uri.parse(apiUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(body),
        );
      } else {
        res = await http.put(
          Uri.parse('$apiUrl/${widget.quiz!["idQuiz"]}'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "tenQuiz": body["tenQuiz"],
            "thoiGianLamBai": body["thoiGianLamBai"],
            "ngayDenHan": body["ngayDenHan"],
          }),
        );
      }
      final data = jsonDecode(res.body);
      if (data["success"]) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.quiz == null
                  ? "Tạo bài kiểm tra thành công"
                  : "Cập nhật thành công",
            ),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(data["error"]);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickDateTime() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
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
        const SnackBar(
          content: Text("Không được chọn thời gian trong quá khứ"),
        ),
      );
      return;
    }

    setState(() {
      ngayDenHanController.text = selectedDateTime.toIso8601String();
    });
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
                    return null;
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
              const SizedBox(height: 16),
              TextFormField(
                controller: ngayDenHanController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: "Ngày đến hạn (có thể bỏ trống nếu là bài ôn tập)",
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ngayDenHanController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              ngayDenHanController.clear();
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: pickDateTime,
                      ),
                    ],
                  ),
                ),
                onTap: pickDateTime,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEdit ? "Cập nhật" : "Tạo bài kiểm tra",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
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
