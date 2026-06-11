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
      final token = prefs.getString("token");
      final res = await http.get(
        Uri.parse('$apiUrl/${widget.quiz["idKhoaHoc"]}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
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
            cauHoi = currentQuiz["questions"] ?? [];
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
      final token = prefs.getString("token");
      final res = await http.delete(
        Uri.parse('$apiUrl/cauhoi/$id'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
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
    final qController = TextEditingController(text: item?["cauHoi"] ?? "");
    List<TextEditingController> controllers = [];
    List<bool> isCorrect = [];
    if (item != null) {
      final answers = item["answers"] ?? [];
      for (var a in answers) {
        controllers.add(TextEditingController(text: a["noiDung"]));
        isCorrect.add(a["laDung"]);
      }
    } else {
      for (int i = 0; i < 4; i++) {
        controllers.add(TextEditingController());
        isCorrect.add(i == 0);
      }
    }
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
                const SizedBox(height: 10),
                ...List.generate(controllers.length, (i) {
                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controllers[i],
                          decoration: InputDecoration(
                            labelText: "Đáp án ${i + 1}",
                          ),
                        ),
                      ),
                      Radio<bool>(
                        value: true,
                        groupValue: isCorrect[i],
                        onChanged: (value) {
                          setStateDialog(() {
                            for (int j = 0; j < isCorrect.length; j++) {
                              isCorrect[j] = false;
                            }
                            isCorrect[i] = true;
                          });
                        },
                      ),
                    ],
                  );
                }),
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
                final token = prefs.getString("token");
                final answers = List.generate(controllers.length, (i) {
                  return {
                    if (item != null && i < item["answers"].length)
                      "idDapAn": item["answers"][i]["idDapAn"],
                    "noiDung": controllers[i].text,
                    "laDung": isCorrect[i],
                  };
                });
                http.Response res;
                if (item == null) {
                  final body = {
                    "questions": [
                      {"cauHoi": qController.text, "answers": answers},
                    ],
                  };
                  res = await http.post(
                    Uri.parse('$apiUrl/${widget.quiz["idQuiz"]}/cauhoi'),
                    headers: {
                      "Content-Type": "application/json",
                      "Authorization": "Bearer $token",
                    },
                    body: jsonEncode(body),
                  );
                } else {
                  final body = {"cauHoi": qController.text, "answers": answers};
                  res = await http.put(
                    Uri.parse('$apiUrl/cauhoi/${item["idCauHoi"]}'),
                    headers: {
                      "Content-Type": "application/json",
                      "Authorization": "Bearer $token",
                    },
                    body: jsonEncode(body),
                  );
                }
                final data = jsonDecode(res.body);
                if (res.statusCode == 200 && data["success"] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Lưu thành công")),
                  );
                  await fetchCauHoi();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(data["error"] ?? "Có lỗi xảy ra")),
                  );
                }
                await fetchCauHoi();
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
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cauHoi.isEmpty
          ? const Center(child: Text("Chưa có câu hỏi nào. Hãy thêm mới!"))
          : RefreshIndicator(
              onRefresh: fetchCauHoi,
              child: ListView.builder(
                itemCount: cauHoi.length,
                itemBuilder: (context, index) {
                  final q = cauHoi[index];
                  final answers = q["answers"] ?? [];

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(
                        "Câu ${index + 1}: ${q["cauHoi"]}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...answers.map<Widget>((a) {
                            return Text(
                              "- ${a["noiDung"]}",
                              style: TextStyle(
                                color: a["laDung"]
                                    ? Colors.green
                                    : Colors.black,
                                fontWeight: a["laDung"]
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            );
                          }).toList(),
                        ],
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
