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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("f7e868ce-5fe8-40d7-8cb2-631d5cf6326d");
  OneSignal.Notifications.requestPermission(true);
  OneSignal.Notifications.clearAll();
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    print('Nhận thông báo khi app đang mở: ${event.notification.title}');
  });
  runApp(const MyApp());
}

Future<void> setupFCM() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  String? token = await messaging.getToken();
  print("FCM TOKEN: $token");
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
        '/dashBoardAdmin':(context)=> DashboardAdminScreen(),
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
                color: Colors.blueAccent,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: const [
                  Icon(Icons.school, size: 70, color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Quản lý học tập",
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
                    "Chào mừng bạn đến với hệ thống quản lý học tập",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Quản lý lớp học, học viên và giảng viên một cách dễ dàng. "
                    "Truy cập bài học, làm bài tập, làm bài kiểm tra và theo dõi tiến độ học tập.",
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
                  _buildFeature(Icons.menu_book, "Quản lý lớp học"),
                  _buildFeature(Icons.people, "Quản lý học viên"),
                  _buildFeature(Icons.quiz, "Học tập, làm bài tập và bài kiểm tra"),
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
                      backgroundColor: Colors.blueAccent,
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
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}