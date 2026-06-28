import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/api.dart';
import 'socketService.dart';

class Chitietgroupscreen extends StatefulWidget{
  final int groupId;
  final String tenNhom;
   const Chitietgroupscreen({
    super.key,
    required this.groupId,
    required this.tenNhom,
  });
  @override
  State<Chitietgroupscreen> createState() => _Chitietgroupscreen();
}
class _Chitietgroupscreen extends State<Chitietgroupscreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String apiUrl = '${ApiConfig.baseUrl}/messages';
  List<Map<String, dynamic>> messages = [];
  bool isLoading = true;
  bool isSending = false;
  bool hasMore = true;
  int currentPage = 1;
  final int limit = 20;
  int userId = 0;
  String userName = '';
  File? _selectedFile;
  bool isUploading = false;
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}