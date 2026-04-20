import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🌟 記得引入 Firestore 才能讀取資料庫
import 'screens/menu_planning_screen.dart';
import 'screens/start_workout_screen.dart';
import 'screens/training_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 健身大師',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      // 🌟 使用 StreamBuilder 監聽登入狀態
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 還在檢查狀態時，顯示載入圈圈
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 如果 snapshot 有資料，代表已登入！
          if (snapshot.hasData) {
            return const MainLayout();
          }
          // 否則退回登入畫面
          return const LoginScreen();
        },
      ),
    );
  }
}

// 🌟 App 的主要框架 (包含側邊欄 Drawer 和主畫面內容)
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final String userName = "哲宇"; // 假資料：用戶名稱
  final int streakDays = 5; // 假資料：連續登入天數

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. 頂部導覽列
      appBar: AppBar(
        title: Text('$userName, 你好!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[800],
              child: const Icon(Icons.person, color: Colors.white),
            ),
          )
        ],
      ),

      // 2. 左側抽屜選單
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E1E1E),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey[900]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const CircleAvatar(radius: 30, backgroundColor: Colors.grey, child: Icon(Icons.person, size: 35, color: Colors.white)),
                  const SizedBox(height: 10),
                  Text('$userName, 你好!', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _buildDrawerItem(Icons.list_alt, '菜單規劃', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuPlanningScreen()));
            }),
            _buildDrawerItem(Icons.play_circle_fill, '開始運動', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StartWorkoutScreen()));
            }),
            _buildDrawerItem(Icons.restaurant, '飲食規劃', () { /* 導航到飲食規劃 */ }),
            _buildDrawerItem(Icons.menu_book, '動作教學', () { /* 導航到動作教學 */ }),
            _buildDrawerItem(Icons.history, '運動紀錄', () { /* 導航到運動紀錄 */ }),
            _buildDrawerItem(Icons.monitor_weight, '體態紀錄', () { /* 導航到體態紀錄 */ }),
          ],
        ),
      ),

      // 3. 主畫面內容
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // (1) 連續登入與開始按鈕區塊
            Container(
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: Column(
                children: [
                  Text('連續登入天數: $streakDays 天', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text('加油!!!', style: TextStyle(fontSize: 18, color: Colors.amber)),
                  const SizedBox(height: 20),

                  // 🌟 大大的開始訓練按鈕 (升級版)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        // 1. 顯示讀取中的提示
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('正在尋找今日菜單...'), duration: Duration(seconds: 1)),
                        );

                        // 2. 獲取今天的日期
                        DateTime now = DateTime.now();
                        String dateString = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

                        try {
                          // 3. 呼叫 Firebase 檢查今天的菜單
                          DocumentSnapshot doc = await FirebaseFirestore.instance
                              .collection('users')
                              .doc('test_user') // 與我們菜單規劃存的 UID 一致
                              .collection('daily_workouts')
                              .doc(dateString)
                              .get();

                          // 確保畫面還存在才做跳轉 (Flutter 異步操作的最佳實踐)
                          if (context.mounted) {
                            if (doc.exists && doc.data() != null) {
                              List<dynamic> exercises = doc.get('exercises') ?? [];

                              if (exercises.isNotEmpty) {
                                // 🌟 成功找到菜單！抓取「第一個」動作名稱
                                String firstExerciseName = exercises.first['name'];

                                // 跳轉到相機畫面，並把動作名稱傳過去！
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TrainingScreen(exerciseName: firstExerciseName),
                                  ),
                                );
                              } else {
                                // 雖然有文件，但裡面沒有動作
                                _showNoWorkoutAlert(context);
                              }
                            } else {
                              // 今天完全沒有排菜單
                              _showNoWorkoutAlert(context);
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('讀取失敗: $e'), backgroundColor: Colors.red),
                            );
                          }
                        }
                      },
                      child: const Text('開始訓練', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // (2) 訓練建議區塊
            const Text('💡 訓練建議:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    "根據妳最近的運動紀錄：\n\n"
                        "1. 妳的胸部訓練量充足，建議今天可以安排「背部」或「腿部」的訓練，讓肌肉有足夠的時間恢復。\n\n"
                        "2. 上次「啞鈴二頭肌彎舉」的姿勢穩定度很高，今天可以嘗試增加 1~2 公斤的重量。\n\n"
                        "3. 記得運動前要充分熱身，並補充充足的水分喔！",
                    style: TextStyle(fontSize: 16, height: 1.6, color: Colors.white70),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 建立側邊欄選項的小工具
  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.white)),
      onTap: () {
        Navigator.pop(context); // 先關閉側邊欄
        onTap(); // 執行導航動作
      },
    );
  }

  // 🌟 如果今天沒菜單，跳出提示的小工具
  void _showNoWorkoutAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('今天還沒有安排菜單喔！請先去左側選單「菜單規劃」安排運動 💪'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }
}