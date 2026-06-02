import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/api.dart';

class Cauhoigvscreen extends StatefulWidget {
  final Map quiz;
  const Cauhoigvscreen({super.key, required this.quiz});

  @override
  State<Cauhoigvscreen> createState() => _CauhoigvscreenState();
}

class _CauhoigvscreenState extends State<Cauhoigvscreen> {
  List cauHoi = [];
  bool isLoading = true;

  final String apiUrl = '${ApiConfig.baseUrl}/giangvien/quiz';
  @override
  void initState() {
    super.initState();
    fetchCauHoi();
  }

  Future<void> fetchCauHoi() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");
      final res = await http.get(
        Uri.parse('$apiUrl/${widget.quiz["idKhoaHoc"]}'),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId.toString(),
        },
      );

      final responseData = jsonDecode(res.body);

      if (responseData["success"] == true) {
        List allQuizzes = responseData["data"];
        final currentQuiz = allQuizzes.firstWhere(
          (q) => q["idQuiz"] == widget.quiz["idQuiz"],
          orElse: () => null,
        );
        if (currentQuiz != null) {
          setState(() {
            cauHoi = currentQuiz["quiz_questions"] ?? [];
          });
        }
      }
    } catch (e) {
      print("Lỗi khi tải lại câu hỏi: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteCauHoi(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("userId");
      final res = await http.delete(
        Uri.parse('$apiUrl/cauhoi/$id'),
        headers: {
          "Content-Type": "application/json",
          "x-user-id": userId.toString(),
        },
      );
      final data = jsonDecode(res.body);
      if (data["success"] == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Xóa câu hỏi thành công")));
        await fetchCauHoi();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["error"] ?? "Lỗi xoá")));
      }
    } catch (e) {
      print("Lỗi Delete: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không thể kết nối đến máy chủ")),
      );
    }
  }

  void showForm({Map? item}) {
    final qController = TextEditingController(
      text: item != null ? jsonDecode(item["cauHoi"])["question"] : "",
    );
    final aController = TextEditingController(
      text: item != null ? jsonDecode(item["cauHoi"])["A"] : "",
    );
    final bController = TextEditingController(
      text: item != null ? jsonDecode(item["cauHoi"])["B"] : "",
    );
    final cController = TextEditingController(
      text: item != null ? jsonDecode(item["cauHoi"])["C"] : "",
    );
    final dController = TextEditingController(
      text: item != null ? jsonDecode(item["cauHoi"])["D"] : "",
    );
    String dapAn = item?["dapAnDung"] ?? "A";
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(item == null ? "Thêm câu hỏi" : "Sửa câu hỏi"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: qController,
                  decoration: const InputDecoration(labelText: "Câu hỏi"),
                ),
                TextField(
                  controller: aController,
                  decoration: const InputDecoration(labelText: "Đáp án A"),
                ),
                TextField(
                  controller: bController,
                  decoration: const InputDecoration(labelText: "Đáp án B"),
                ),
                TextField(
                  controller: cController,
                  decoration: const InputDecoration(labelText: "Đáp án C"),
                ),
                TextField(
                  controller: dController,
                  decoration: const InputDecoration(labelText: "Đáp án D"),
                ),

                const SizedBox(height: 10),
                DropdownButton<String>(
                  value: dapAn,
                  items: ["A", "B", "C", "D"]
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text("Đáp án đúng: $e"),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setStateDialog(() {
                      dapAn = val!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Huỷ"),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final userId = prefs.getInt("userId");
                final body = {
                  "question": qController.text,
                  "A": aController.text,
                  "B": bController.text,
                  "C": cController.text,
                  "D": dController.text,
                  "dapAnDung": dapAn,
                };
                if (item == null) {
                  final res = await http.post(
                    Uri.parse('$apiUrl/${widget.quiz["idQuiz"]}/cauhoi'),
                    headers: {
                      "Content-Type": "application/json",
                      "x-user-id": userId.toString(),
                    },
                    body: jsonEncode(body),
                  );
                  if (jsonDecode(res.body)["success"] == true) {
                    await fetchCauHoi();
                  }
                } else {
                  final res = await http.put(
                    Uri.parse('$apiUrl/cauhoi/${item["idCauHoi"]}'),
                    headers: {
                      "Content-Type": "application/json",
                      "x-user-id": userId.toString(),
                    },
                    body: jsonEncode(body),
                  );
                  if (jsonDecode(res.body)["success"] == true) {
                    await fetchCauHoi(); // Tải lại để cập nhật nội dung
                  }
                }
                Navigator.pop(context);
              },

              child: const Text("Lưu"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz["tenQuiz"]),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: fetchCauHoi, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showForm(),
        child: const Icon(Icons.add, color: Colors.white,),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : cauHoi.isEmpty
          ? const Center(
              child: Text("Chưa có câu hỏi nào. Hãy thêm mới!"),
            )
          : RefreshIndicator(
              onRefresh: fetchCauHoi,
              child: ListView.builder(
                itemCount: cauHoi.length,
                itemBuilder: (context, index) {
                  final q = cauHoi[index];
                  final data = jsonDecode(q["cauHoi"]);

                  return Card(
                    margin: const EdgeInsets.all(10),
                    elevation: 3, // Thêm chút bóng đổ cho đẹp
                    child: ListTile(
                      title: Text(
                        "Câu ${index + 1}: ${data["question"]}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("A. ${data["A"]}"),
                            Text("B. ${data["B"]}"),
                            Text("C. ${data["C"]}"),
                            Text("D. ${data["D"]}"),
                            const Divider(),
                            Text(
                              "Đáp án đúng: ${q["dapAnDung"]}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Điểm: ${q["diemCauHoi"]}",
                              style: const TextStyle(
                                color: Colors.blueGrey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.orange),
                            onPressed: () => showForm(item: q),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteCauHoi(q["idCauHoi"]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
