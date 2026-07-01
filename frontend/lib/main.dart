// import 'package:flutter/material.dart';
// import 'package:frontend/admin/users/usersScreen.dart';
// import 'package:frontend/authentication/loginScreen.dart';
// import 'package:frontend/admin/classroom/classScreen.dart';
// import 'package:frontend/hocvien/hocVienScreen.dart';
// import 'package:frontend/giangvien/lopHocScreen.dart';
// import 'package:frontend/giangvien/dashBoardGiangVien.dart';
// import 'package:frontend/giangvien/lopHocLuuTruGV.dart';
// import 'package:frontend/admin/dashBoardAdminScreen.dart';
// import 'package:frontend/hocvien/lopHocLuuTruHV.dart';
// import 'package:frontend/hocvien/chuaHTHocVienScreen.dart';
// import 'package:frontend/admin/thongbao/thongBaoAdminScreen.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:webview_flutter/webview_flutter.dart';
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   // await initWebView();
//   await Firebase.initializeApp();
//   await setupFCM();
//   runApp(const MyApp());
// }
// // Future<void> initWebView() async {
  
// // }

// Future<void> setupFCM() async {
//   FirebaseMessaging messaging = FirebaseMessaging.instance;
//   await messaging.requestPermission();
//   String? token = await messaging.getToken();
//   print("FCM TOKEN: $token");
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'LMS',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const MyHomePage(),
//         '/admin': (context) => UsersScreen(),
//         '/users': (context) => UsersScreen(),
//         '/classroom': (context) => ClassScreen(),
//         '/login': (context) => Loginscreen(),
//         '/hocvien': (context) => HocVienScreen(),
//         '/giangvien': (context) => LopHocGVScreen(),
//         '/homeGiangVien': (context) => LopHocGVScreen(),
//         '/homeHocVien': (context) => HocVienScreen(),
//         '/dashboardGiangVien': (context) => DashboardGVScreen(),
//         '/lopHocDaLuuTru': (context) => LopHocLuuTruGVScreen(),
//         '/dashBoardAdmin':(context)=> DashboardAdminScreen(),
//         '/lopHocLuuTruHV': (context) => LopHocLuuTruHVScreen(),
//         '/chuaHoanThanhHV': (context) => ChuaHTHocVienScreen(),
//         '/thongbaoAd': (context) => Thongbaoadminscreen(),
//       },
//     );
//   }
// }

// class MyHomePage extends StatelessWidget {
//   const MyHomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.only(top: 80, bottom: 50),
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [Colors.deepPurple, Colors.blue],
//                 ),
//                 borderRadius: BorderRadius.vertical(
//                   bottom: Radius.circular(30),
//                 ),
//               ),
//               child: Column(
//                 children: const [
//                   Icon(Icons.school, size: 70, color: Colors.white),
//                   SizedBox(height: 16),
//                   Text(
//                     "LMS System",
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     "Hệ thống quản lý học tập hiện đại",
//                     style: TextStyle(color: Colors.white70),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 children: const [
//                   Text(
//                     "Chào mừng bạn đến với LMS",
//                     style: TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     "Quản lý khóa học, học viên và giảng viên một cách dễ dàng. "
//                     "Truy cập bài học, làm quiz và theo dõi tiến độ học tập.",
//                     textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 children: [
//                   _buildFeature(Icons.menu_book, "Quản lý khóa học"),
//                   _buildFeature(Icons.people, "Quản lý học viên"),
//                   _buildFeature(Icons.quiz, "Học tập, làm bài kiểm tra"),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 40),

//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 children: [
//                   ElevatedButton(
//                     style: ElevatedButton.styleFrom(
//                       minimumSize: const Size(double.infinity, 50),
//                       backgroundColor: Colors.deepPurple,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     onPressed: () {
//                       Navigator.pushNamed(context, '/login');
//                     },
//                     child: const Text(
//                       "Đăng nhập",
//                       style: TextStyle(fontSize: 16, color: Colors.white),
//                     ),
//                   ),

//                   const SizedBox(height: 10),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFeature(IconData icon, String text) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Row(
//         children: [
//           Icon(icon, color: Colors.deepPurple),
//           const SizedBox(width: 12),
//           Text(text),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:frontend/admin/users/usersScreen.dart';
import 'package:frontend/authentication/loginScreen.dart';
import 'package:frontend/admin/classroom/classScreen.dart';
import 'package:frontend/hocvien/hocVienScreen.dart';
import 'package:frontend/giangvien/lopHocScreen.dart';
import 'package:frontend/giangvien/dashBoardGiangVien.dart';
import 'package:frontend/giangvien/lopHocLuuTruGV.dart';
import 'package:frontend/admin/dashBoardAdminScreen.dart';
import 'package:frontend/hocvien/lopHocLuuTruHV.dart';
import 'package:frontend/hocvien/chuaHTHocVienScreen.dart';
import 'package:frontend/admin/thongbao/thongBaoAdminScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend/api.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Khởi tạo Firebase
  await Firebase.initializeApp();
  
  // ✅ Đăng ký FCM và lắng nghe thông báo
  await setupFCM();
  
  runApp(const MyApp());
}

// ==================== CẤU HÌNH FCM ====================
Future<void> setupFCM() async {
  try {
    // 1. Yêu cầu quyền thông báo
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    print('🔔 Permission status: ${settings.authorizationStatus}');
    
    // 2. Lấy FCM token
    String? token = await messaging.getToken();
    print("📱 FCM TOKEN: $token");
    
    // 3. Lưu token lên server khi đăng nhập (gọi sau khi login)
    // Token sẽ được lưu trong hàm đăng nhập
    
    // 4. Lắng nghe thông báo khi app đang mở (foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Received notification (foreground): ${message.notification?.title}');
      _showLocalNotification(message);
    });
    
    // 5. Lắng nghe khi app ở background và user click vào thông báo
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📩 Opened notification: ${message.data}');
      _handleNotificationTap(message);
    });
    
    // 6. Lấy token khi refresh
    messaging.onTokenRefresh.listen((newToken) {
      print('🔄 FCM token refreshed: $newToken');
      _updateFCMToken(newToken);
    });
    
  } catch (e) {
    print('❌ FCM setup error: $e');
  }
}

// ==================== GỬI TOKEN LÊN SERVER ====================
Future<void> _updateFCMToken(String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final authToken = prefs.getString('token');
    
    if (userId == null || authToken == null) return;
    
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/luu-fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'idNguoiDung': userId,
        'token': token,
      }),
    );
    print('✅ FCM token updated on server');
  } catch (e) {
    print('❌ Error updating FCM token: $e');
  }
}

// ==================== HIỂN THỊ THÔNG BÁO TRONG APP ====================
void _showLocalNotification(RemoteMessage message) {
  // TODO: Hiển thị thông báo dạng SnackBar hoặc Dialog
  // Có thể dùng flutter_local_notifications để hiển thị đẹp hơn
  
  // Ví dụ đơn giản: hiển thị SnackBar (cần context)
  // ScaffoldMessenger.of(context).showSnackBar(
  //   SnackBar(
  //     content: Text(message.notification?.title ?? 'Thông báo mới'),
  //     backgroundColor: Colors.blue,
  //   ),
  // );
}

// ==================== XỬ LÝ KHI CLICK THÔNG BÁO ====================
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  final type = data['type'];
  
  print('📩 Notification type: $type');
  print('📩 Notification data: $data');
  
  // TODO: Điều hướng đến màn hình tương ứng dựa trên type
  // Ví dụ:
  // - type = 'message' → Mở chat
  // - type = 'new_topic' → Mở chủ đề
  // - type = 'announcement' → Mở thông báo
}

// ==================== GỌI KHI ĐĂNG NHẬP THÀNH CÔNG ====================
// Hàm này sẽ được gọi trong LoginScreen sau khi đăng nhập thành công
Future<void> registerFCMTokenAfterLogin(int userId, String token) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final authToken = prefs.getString('token');
    
    if (authToken == null) return;
    
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken == null) return;
    
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/luu-fcm-token'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'idNguoiDung': userId,
        'token': fcmToken,
      }),
    );
    print('✅ FCM token registered after login');
  } catch (e) {
    print('❌ Error registering FCM token: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(),
        '/admin': (context) => UsersScreen(),
        '/users': (context) => UsersScreen(),
        '/classroom': (context) => ClassScreen(),
        '/login': (context) => Loginscreen(),
        '/hocvien': (context) => HocVienScreen(),
        '/giangvien': (context) => LopHocGVScreen(),
        '/homeGiangVien': (context) => LopHocGVScreen(),
        '/homeHocVien': (context) => HocVienScreen(),
        '/dashboardGiangVien': (context) => DashboardGVScreen(),
        '/lopHocDaLuuTru': (context) => LopHocLuuTruGVScreen(),
        '/dashBoardAdmin': (context) => DashboardAdminScreen(),
        '/lopHocLuuTruHV': (context) => LopHocLuuTruHVScreen(),
        '/chuaHoanThanhHV': (context) => ChuaHTHocVienScreen(),
        '/thongbaoAd': (context) => Thongbaoadminscreen(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 50),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.blue],
                ),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: const [
                  Icon(Icons.school, size: 70, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "LMS System",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Hệ thống quản lý học tập hiện đại",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: const [
                  Text(
                    "Chào mừng bạn đến với LMS",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Quản lý khóa học, học viên và giảng viên một cách dễ dàng. "
                    "Truy cập bài học, làm quiz và theo dõi tiến độ học tập.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildFeature(Icons.menu_book, "Quản lý khóa học"),
                  _buildFeature(Icons.people, "Quản lý học viên"),
                  _buildFeature(Icons.quiz, "Học tập, làm bài kiểm tra"),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      "Đăng nhập",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}