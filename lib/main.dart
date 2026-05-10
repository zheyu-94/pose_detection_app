import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/menu_planning_screen.dart';
import 'screens/start_workout_screen.dart';
import 'screens/training_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'package:pose_detection_app/screens/tutorial_screen.dart';
import 'screens/weight_screen.dart';
import 'screens/diet_planning_screen.dart';
import 'screens/workout_history_screen.dart';
import 'screens/home_screen.dart';

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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data != null) {
            return MainLayout(user: snapshot.data!);
          }
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
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String name = userData['name'] ?? "用戶";
        String role = userData['role'] ?? "user";
        String? base64Image = userData['photoBase64']; // 抓取資料庫中的圖片字串

        return Scaffold(
          appBar: role == 'coach'
              ? AppBar(
            title: Text('$name, 你好! (教練)'),
            actions: [
              IconButton(
                icon: const Icon(Icons.account_circle),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
              )
            ],
          )
              : null,

          // 側邊欄 (Drawer)
          drawer: Drawer(
            backgroundColor: const Color(0xFF1E1E1E),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: Colors.grey[900]),
                  accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  accountEmail: Text(userData['email'] ?? ""),
                  // 這裡換成動態顯示大頭貼
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    backgroundImage: base64Image != null ? MemoryImage(base64Decode(base64Image)) : null,
                    child: base64Image == null ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                  ),
                ),

                if (role == 'user') ...[
                  _buildDrawerItem(Icons.list_alt, '菜單規劃', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuPlanningScreen()));
                  }),
                  _buildDrawerItem(Icons.play_circle_fill, '開始運動', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StartWorkoutScreen()));
                  }),
                  _buildDrawerItem(Icons.restaurant, '飲食規劃', () {
                    if (userData['weight'] == null || userData['height'] == null || userData['age'] == null || userData['gender'] == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("請先填寫體態紀錄，AI 才能幫你精準計算專屬熱量喔！"), backgroundColor: Colors.orangeAccent));
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const WeightScreen()));
                    } else {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DietPlanningScreen()));
                    }
                  }),
                  _buildDrawerItem(Icons.menu_book, '動作教學', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TutorialScreen()));
                  }),
                  _buildDrawerItem(Icons.history, '運動紀錄', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutHistoryScreen()));
                  }),
                  _buildDrawerItem(Icons.monitor_weight, '體態紀錄', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const WeightScreen()));
                  }),
                ],

                if (role == 'coach') ...[
                  _buildDrawerItem(Icons.analytics, '學員進度追蹤', () {}),
                  _buildDrawerItem(Icons.chat_bubble, '學員訊息回覆', () {}),
                  _buildDrawerItem(Icons.assignment, '指派新菜單', () {}),
                ],

                const Divider(color: Colors.white24),

                _buildDrawerItem(Icons.settings, '帳戶設置', () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                }),
                _buildDrawerItem(Icons.logout, '登出', () async {
                  await FirebaseAuth.instance.signOut();
                }),
              ],
            ),
          ),

          // 把抓到的名字跟圖片傳給 HomeScreen
          body: role == 'coach'
              ? _buildCoachHome()
              : HomeScreen(userName: name, base64Image: base64Image),
        );
      },
    );
  }

  Widget _buildCoachHome() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('questions').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("教練後台：目前尚無學員提問 🎉", style: TextStyle(fontSize: 18)));

        final questions = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            var qDoc = questions[index];
            var data = qDoc.data() as Map<String, dynamic>;

            return Card(
              color: Colors.grey[850],
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.help_outline, color: Colors.orangeAccent, size: 30),
                title: Text("詢問動作：${data['exerciseName'] ?? '未知動作'}", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text("學員問說：${data['content'] ?? ''}", style: const TextStyle(color: Colors.white70, fontSize: 15)),
                    const SizedBox(height: 5),
                    Text("狀態：${data['isReplied'] == true ? '已回覆' : '等待教練回覆'}", style: TextStyle(color: data['isReplied'] == true ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () => _showReplyDialog(context, qDoc.id, data['content'] ?? ""),
                  child: const Text("回覆", style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReplyDialog(BuildContext context, String docId, String currentQuestion) {
    final TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("回覆學員提問"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("問題內容：\n$currentQuestion", style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 15),
            TextField(controller: replyController, maxLines: 3, decoration: const InputDecoration(hintText: "請輸入你的專業建議...", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.trim().isEmpty) return;
              await FirebaseFirestore.instance.collection('questions').doc(docId).update({
                'replyContent': replyController.text.trim(),
                'isReplied': true,
                'replyTime': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("回覆成功！")));
            },
            child: const Text("送出回覆"),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(fontSize: 16, color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}