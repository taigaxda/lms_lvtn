import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class Themsuathongbaoadminscreen extends StatefulWidget {
  final int? idThongBao;
  final int? idKhoaHoc;
  const Themsuathongbaoadminscreen({super.key, this.idThongBao, this.idKhoaHoc});
  @override
  State<Themsuathongbaoadminscreen> createState() =>
      _ThemSuaThongBaoGVScreenState();
}

class _ThemSuaThongBaoGVScreenState extends State<Themsuathongbaoadminscreen> {
  final TextEditingController tieuDeCtrl = TextEditingController();
  final TextEditingController noiDungCtrl = TextEditingController();

  bool isLoading = false;
  bool isEdit = false;

  final String apiUrl = "${ApiConfig.baseUrl}/admin/thongbao";
  @override
  void initState() {
    super.initState();

    if (widget.idThongBao != null) {
      isEdit = true;
      getChiTiet();
    }
  }

  Future<void> getChiTiet() async {
    try {
      setState(() => isLoading = true);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      final res = await http.get(
        Uri.parse("$apiUrl/chitiet/${widget.idThongBao}"),
        headers: {"Authorization": "Bearer $token"},
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success']) {
        tieuDeCtrl.text = data['data']['tieuDe'] ?? "";
        noiDungCtrl.text = data['data']['noiDung'] ?? "";
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> submit() async {
    final tieuDe = tieuDeCtrl.text.trim();
    final noiDung = noiDungCtrl.text.trim();

    if (tieuDe.isEmpty || noiDung.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đầy đủ")));
      return;
    }
    try {
      setState(() {
        isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");

      http.Response res;
      if (isEdit) {
        res = await http.put(
          Uri.parse("$apiUrl/${widget.idThongBao}"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({"tieuDe": tieuDe, "noiDung": noiDung,"idKhoaHoc": widget.idKhoaHoc,}),
        );
      } else {
        res = await http.post(
          Uri.parse("$apiUrl"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "tieuDe": tieuDe, 
            "noiDung": noiDung,
            "idKhoaHoc": widget.idKhoaHoc
          }),
        );
      }
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201 && data['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? "Cập nhật thành công" : "Tạo thành công"),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Sửa thông báo" : "Thêm thông báo"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: tieuDeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Tiêu đề",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: noiDungCtrl,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: "Nội dung",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: submit,
                      child: Text(isEdit ? "Cập nhật" : "Tạo"),
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
