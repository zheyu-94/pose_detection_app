import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🌟 記得引入 Firestore 才能讀取資料庫
import 'screens/menu_planning_screen.dart';
import 'screens/start_workout_screen.dart';
import 'screens/training_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // 如果 snapshot 有資料，代表已登入！
          if (snapshot.hasData && snapshot.data != null) {
            return MainLayout(user: snapshot.data!);
          }
          // 否則退回登入畫面
          return const LoginScreen();
        },
      ),
    );
  }
}



class MainLayout extends StatefulWidget {
  final User user;
  const MainLayout({super.key, required this.user});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  // 刪除假資料變數，改用 Stream 或 Future 讀取

  @override
  Widget build(BuildContext context) {
    // 使用 StreamBuilder 監聽目前使用者的 Firestore 文件
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String name = userData['name'] ?? "用戶";
        String role = userData['role'] ?? "user";

        // 如果是教練，我們可以在這裡 return 一個不同的 UI 或者是教練專用的 Drawer
        return Scaffold(
          appBar: AppBar(
            title: Text('$name, 你好! (${role == 'coach' ? '教練' : '學員'})'),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
              )
            ],
          ),
          drawer: Drawer(
            backgroundColor: const Color(0xFF1E1E1E),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 側邊欄頭部：顯示姓名與 Email
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: Colors.grey[900]),
                  accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  accountEmail: Text(userData['email'] ?? ""),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                ),

                // --- 🌸 學員專屬功能區 ---
                if (role == 'user') ...[
                  _buildDrawerItem(Icons.list_alt, '菜單規劃', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuPlanningScreen()));
                  }),
                  _buildDrawerItem(Icons.play_circle_fill, '開始運動', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StartWorkoutScreen()));
                  }),
                  _buildDrawerItem(Icons.restaurant, '飲食規劃', () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => const DietPlanningScreen()));
                  }),
                  _buildDrawerItem(Icons.menu_book, '動作教學', () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => const TutorialScreen()));
                  }),
                  _buildDrawerItem(Icons.history, '運動紀錄', () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                  }),
                  _buildDrawerItem(Icons.monitor_weight, '體態紀錄', () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => const WeightScreen()));
                  }),
                ],

                // --- 👔 教練專屬功能區 ---
                if (role == 'coach') ...[
                  _buildDrawerItem(Icons.analytics, '學員進度追蹤', () {
                    // 導向教練管理頁面
                  }),
                  _buildDrawerItem(Icons.chat_bubble, '學員訊息回覆', () {
                    // 導向對話清單
                  }),
                  _buildDrawerItem(Icons.assignment, '指派新菜單', () {
                    // 導向指派頁面
                  }),
                ],

                const Divider(color: Colors.white24),

                // 共通功能
                _buildDrawerItem(Icons.settings, '帳戶設置', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                }),
                _buildDrawerItem(Icons.logout, '登出', () async {
                  await FirebaseAuth.instance.signOut();
                }),
              ],
            ),
          ),
          body: role == 'coach' ? _buildCoachHome() : _buildUserHome(name), // 根據身分切換主畫面
        );
      },
    );
  }

  Widget _buildUserHome(String name) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      // ... 放置原本的訓練建議與開始按鈕代碼 ...
    );
  }

  // 預留給教練的介面
  Widget _buildCoachHome() {
    return const Center(child: Text("教練後台：目前尚無學員提問", style: TextStyle(fontSize: 18)));
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