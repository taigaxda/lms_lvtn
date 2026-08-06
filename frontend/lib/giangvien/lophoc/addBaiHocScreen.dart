// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:frontend/api.dart';
// import 'package:frontend/giangvien/menuUI/giangVienMenuBar.dart';

// class Addbaihocscreen extends StatefulWidget {
//   final int idKhoaHoc;
//   final Map<String, dynamic>? baiHoc;
//   const Addbaihocscreen({super.key, required this.idKhoaHoc, this.baiHoc});

//   @override
//   State<Addbaihocscreen> createState() => _Addbaihocscreen();
// }

// class _Addbaihocscreen extends State<Addbaihocscreen> {
//   final TextEditingController tenController = TextEditingController();
//   final TextEditingController thuTuController = TextEditingController();

//   PlatformFile? pickedFile;
//   File? selectedFile;

//   bool isLoading = false;
//   String hoTen = "";
//   String vaiTro = "";
//   bool get isEdit => widget.baiHoc != null;

//   final String apiUrl = "${ApiConfig.baseUrl}/giangvien/baihoc";

//   @override
//   void initState() {
//     super.initState();
//     loadUserInfo();
//     if (widget.baiHoc != null) {
//       tenController.text = widget.baiHoc!['tenBaiHoc'] ?? "";
//       thuTuController.text = widget.baiHoc!['thuTu']?.toString() ?? "";
//     }
//   }

//   Future<void> loadUserInfo() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       hoTen = prefs.getString("hoTen") ?? "";
//       vaiTro = prefs.getString("vaiTro") ?? "";
//     });
//   }

//   Future<void> pickFile() async {
//     final result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: [
//         'pdf',
//         'mp4',
//         'mkv',
//         'doc',
//         'docx',
//         'rar',
//         'zip',
//         'ppt',
//         'pptx',
//         'xls',
//         'xlsx',
//       ],
//       withData: true,
//     );

//     if (result != null) {
//       if (kIsWeb) {
//         pickedFile = result.files.first;
//       } else {
//         selectedFile = File(result.files.first.path!);
//       }
//       setState(() {});
//     }
//   }

//   Future<void> submit() async {
//     if (tenController.text.trim().isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Nhập tên bài học")));
//       return;
//     }

//     setState(() {
//       isLoading = true;
//     });

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final token = prefs.getString("token");
//       http.Response res;
//       int idBaiHoc;
//       if (!isEdit) {
//         res = await http.post(
//           Uri.parse(apiUrl),
//           headers: {
//             "Content-Type": "application/json",
//             "Authorization": "Bearer $token",
//           },
//           body: jsonEncode({
//             "idKhoaHoc": widget.idKhoaHoc,
//             "tenBaiHoc": tenController.text.trim(),
//             "thuTu": int.tryParse(thuTuController.text) ?? 1,
//           }),
//         );
//         if (res.statusCode != 201) {
//           throw Exception("Tạo bài học thất bại");
//         }
//         idBaiHoc = json.decode(res.body)['idBaiHoc'];
//       } else {
//         idBaiHoc = widget.baiHoc!['idBaiHoc'];
//         res = await http.put(
//           Uri.parse("$apiUrl/$idBaiHoc"),
//           headers: {
//             "Content-Type": "application/json",
//             "Authorization": "Bearer $token",
//           },
//           body: jsonEncode({
//             "tenBaiHoc": tenController.text.trim(),
//             "thuTu": int.tryParse(thuTuController.text) ?? 1,
//           }),
//         );
//         if (res.statusCode != 200) {
//           throw Exception("Cập nhật bài học thất bại");
//         }
//       }

//       if (pickedFile != null || selectedFile != null) {
//         var request = http.MultipartRequest(
//           'POST',
//           Uri.parse('$apiUrl/upload-file/$idBaiHoc'),
//         );

//         request.headers["Authorization"] = "Bearer $token";

//         if (kIsWeb && pickedFile != null) {
//           request.files.add(
//             http.MultipartFile.fromBytes(
//               'taiLieu',
//               pickedFile!.bytes!,
//               filename: pickedFile!.name,
//             ),
//           );
//         } else if (selectedFile != null) {
//           request.files.add(
//             await http.MultipartFile.fromPath('taiLieu', selectedFile!.path),
//           );
//         }

//         final uploadRes = await request.send();

//         if (uploadRes.statusCode != 200) {
//           throw Exception("Upload file thất bại");
//         }
//       }

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             isEdit ? "Cập nhật bài học thành công" : "Thêm bài học thành công",
//           ),
//         ),
//       );

//       Navigator.pop(context, true);
//     } catch (e) {
//       print(e);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Có lỗi xảy ra")));
//     }

//     setState(() {
//       isLoading = false;
//     });
//   }

//   Widget filePreview() {
//     if (isEdit && pickedFile == null && selectedFile == null) {
//       final fileCu = widget.baiHoc!['taiLieu'];

//       if (fileCu != null) {
//         return ListTile(
//           leading: const Icon(Icons.insert_drive_file),
//           title: Text(fileCu),
//           subtitle: const Text("File hiện tại"),
//         );
//       }
//     }
//     if (pickedFile == null && selectedFile == null) {
//       return const SizedBox();
//     }

//     String name = "";

//     if (kIsWeb && pickedFile != null) {
//       name = pickedFile!.name;
//     } else if (selectedFile != null) {
//       name = selectedFile!.path.split('/').last;
//     }

//     return ListTile(
//       leading: name.endsWith('.mp4')
//           ? const Icon(Icons.video_file, color: Colors.blue)
//           : const Icon(Icons.picture_as_pdf, color: Colors.red),
//       title: Text(name),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           isEdit ? "Sửa bài học" : "Thêm bài học",
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: Colors.blue,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       drawer: GiangVienMenuBar(hoTen: hoTen, vaiTro: vaiTro),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 children: [
//                   TextField(
//                     controller: tenController,
//                     decoration: const InputDecoration(
//                       labelText: "Tên bài học",
//                       border: OutlineInputBorder(),
//                     ),
//                   ),

//                   const SizedBox(height: 15),

//                   TextField(
//                     controller: thuTuController,
//                     keyboardType: TextInputType.number,
//                     decoration: const InputDecoration(
//                       labelText: "Thứ tự",
//                       border: OutlineInputBorder(),
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   ElevatedButton.icon(
//                     onPressed: pickFile,
//                     icon: const Icon(Icons.upload_file),
//                     label: const Text("Chọn file (video/tài liệu)"),
//                   ),

//                   const SizedBox(height: 10),

//                   filePreview(),

//                   const SizedBox(height: 30),

//                   Row(
//                     children: [
//                       Expanded(
//                         child: OutlinedButton(
//                           onPressed: () => Navigator.pop(context),
//                           style: OutlinedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             side: const BorderSide(color: Colors.grey),
//                             backgroundColor: Colors.red,
//                           ),
//                           child: const Text(
//                             "Hủy / Quay lại",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 10),
//                       Expanded(
//                         child: ElevatedButton(
//                           onPressed: submit,
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 15),
//                             backgroundColor: Colors.blue,
//                           ),
//                           child: Text(
//                             isEdit ? "Cập nhật bài học" : "Tạo bài học",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }
// }
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
  final Map<String, dynamic>? baiHoc;
  const Addbaihocscreen({super.key, required this.idKhoaHoc, this.baiHoc});

  @override
  State<Addbaihocscreen> createState() => _Addbaihocscreen();
}

class _Addbaihocscreen extends State<Addbaihocscreen> {
  final TextEditingController tenController = TextEditingController();
  final TextEditingController thuTuController = TextEditingController();

  PlatformFile? pickedFile;
  File? selectedFile;

  bool isLoading = false;
  bool isLoadingChuongs = true;
  String hoTen = "";
  String vaiTro = "";
  
  List<Map<String, dynamic>> chuongs = [];
  int? selectedChuongId;
  int? _initialChuongId;
  
  bool get isEdit => widget.baiHoc != null;

  final String apiUrl = "${ApiConfig.baseUrl}/giangvien/baihoc";
  final String apiGiangVien = "${ApiConfig.baseUrl}/giangvien";

  @override
  void initState() {
    super.initState();
    loadUserInfo();
    
    if (widget.baiHoc != null) {
      tenController.text = widget.baiHoc!['tenBaiHoc'] ?? "";
      thuTuController.text = widget.baiHoc!['thuTu']?.toString() ?? "";
      _initialChuongId = widget.baiHoc!['idChuong'];
    }
    _loadChuongs();
  }

  Future<void> loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      hoTen = prefs.getString("hoTen") ?? "";
      vaiTro = prefs.getString("vaiTro") ?? "";
    });
  }

  Future<void> _loadChuongs() async {
    setState(() => isLoadingChuongs = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      
      final response = await http.get(
        Uri.parse('$apiGiangVien/lophoc/${widget.idKhoaHoc}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final chuongData = data['data']['chuong'] ?? [];
        setState(() {
          chuongs = chuongData.cast<Map<String, dynamic>>();
          isLoadingChuongs = false;
          
          if (_initialChuongId != null) {
            final exists = chuongs.any((c) => c['idChuong'] == _initialChuongId);
            selectedChuongId = exists ? _initialChuongId : null;
          } else {
            selectedChuongId = null;
          }
        });
      } else {
        setState(() => isLoadingChuongs = false);
      }
    } catch (e) {
      print('Lỗi load chương: $e');
      setState(() => isLoadingChuongs = false);
    }
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

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token");
      http.Response res;
      int idBaiHoc;

      int finalThuTu;
      if (isEdit && thuTuController.text.trim().isEmpty) {
        finalThuTu = widget.baiHoc!['thuTu'] ?? 1;
      } else {
        finalThuTu = int.tryParse(thuTuController.text) ?? 1;
      }

      final body = {
        "idKhoaHoc": widget.idKhoaHoc,
        "tenBaiHoc": tenController.text.trim(),
        "thuTu": finalThuTu,
        "idChuong": selectedChuongId,
      };

      print('Request body: ${jsonEncode(body)}');

      if (!isEdit) {
        res = await http.post(
          Uri.parse(apiUrl),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(body),
        );
        if (res.statusCode != 201) {
          final errorData = jsonDecode(res.body);
          throw Exception(errorData['message'] ?? "Tạo bài học thất bại");
        }
        idBaiHoc = json.decode(res.body)['idBaiHoc'];
      } else {
        idBaiHoc = widget.baiHoc!['idBaiHoc'];
        
        final updateBody = {
          "tenBaiHoc": tenController.text.trim(),
          "thuTu": finalThuTu,
          "idChuong": selectedChuongId,
        };
        
        print('Update body: ${jsonEncode(updateBody)}');
        
        res = await http.put(
          Uri.parse("$apiUrl/$idBaiHoc"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode(updateBody),
        );
        
        print('Response status: ${res.statusCode}');
        print('Response body: ${res.body}');
        
        if (res.statusCode != 200) {
          final errorData = jsonDecode(res.body);
          throw Exception(errorData['message'] ?? "Cập nhật bài học thất bại");
        }
      }

      if (pickedFile != null || selectedFile != null) {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('$apiUrl/upload-file/$idBaiHoc'),
        );

        request.headers["Authorization"] = "Bearer $token";

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEdit ? "Cập nhật bài học thành công" : "Thêm bài học thành công",
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      print('Lỗi: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Có lỗi xảy ra: $e")));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget filePreview() {
    if (isEdit && pickedFile == null && selectedFile == null) {
      final fileCu = widget.baiHoc!['taiLieu'];

      if (fileCu != null) {
        return ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text(fileCu),
          subtitle: const Text("File hiện tại"),
        );
      }
    }
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
  void dispose() {
    tenController.dispose();
    thuTuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEdit ? "Sửa bài học" : "Thêm bài học",
          style: const TextStyle(color: Colors.white),
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

                  // ===== DROPDOWN CHỌN CHƯƠNG =====
                  isLoadingChuongs
                      ? const SizedBox(
                          height: 56,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : DropdownButtonFormField<int>(
                          value: selectedChuongId,
                          hint: const Text('Chọn chương (không bắt buộc)'),
                          decoration: const InputDecoration(
                            labelText: 'Chương',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.folder),
                          ),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('Không có chương'),
                            ),
                            ...chuongs.map((chuong) {
                              return DropdownMenuItem<int>(
                                value: chuong['idChuong'],
                                child: Text(chuong['tenChuong'] ?? ''),
                              );
                            }).toList(),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedChuongId = value;
                            });
                          },
                        ),
                  
                  const SizedBox(height: 15),

                  TextField(
                    controller: thuTuController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Thứ tự",
                      border: OutlineInputBorder(),
                      hintText: "Để trống giữ nguyên thứ tự khi sửa",
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
                            backgroundColor: Colors.red,
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
                            backgroundColor: Colors.blue,
                          ),
                          child: Text(
                            isEdit ? "Cập nhật bài học" : "Tạo bài học",
                            style: const TextStyle(color: Colors.white),
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