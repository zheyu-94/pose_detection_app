import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🌟 記得引入 Firestore 才能讀取資料庫
import 'screens/menu_planning_screen.dart';
import 'screens/start_workout_screen.dart';
import 'screens/training_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'package:pose_detection_app/screens/tutorial_screen.dart'; // 🌟 導入你寫好的教學頁面
import 'screens/weight_screen.dart'; // 🌟 告訴 main 去哪裡找體態紀錄
import 'screens/diet_planning_screen.dart'; // 🌟 告訴 main 去哪裡找飲食規劃

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
                    if (userData['weight'] == null ||
                        userData['height'] == null ||
                        userData['age'] == null ||
                        userData['gender'] == null) {

                      // 1. 彈出貼心提示
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("請先填寫體態紀錄，AI 才能幫你精準計算專屬熱量喔！🍔"),
                          backgroundColor: Colors.orangeAccent,
                        ),
                      );

                      // 2. 直接強制把他帶到「體態紀錄」畫面
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const WeightScreen()));

                    } else {
                      // 如果資料都有了，就正常放行進入飲食規劃
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const DietPlanningScreen()));
                    }
                  }),
                  _buildDrawerItem(Icons.menu_book, '動作教學', () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TutorialScreen()));                  }),
                  _buildDrawerItem(Icons.history, '運動紀錄', () {
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryScreen()));
                  }),
                  _buildDrawerItem(Icons.monitor_weight, '體態紀錄', () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WeightScreen())
                    );                  }),
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 80, color: Colors.blueAccent),
          const SizedBox(height: 20),
          Text("歡迎回來，$name！", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("請點擊左上角選單，開始你的訓練", style: TextStyle(fontSize: 16, color: Colors.white70)),
        ],
      ),
    );
  }

  // 預留給教練的介面
  Widget _buildCoachHome() {
    return StreamBuilder<QuerySnapshot>(
      // 監聽 'questions' 集合，並依照時間排序（最新的提問在最上面）
      stream: FirebaseFirestore.instance
          .collection('questions')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        // 1. 正在讀取中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. 如果沒有資料，或資料庫裡是空的
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("教練後台：目前尚無學員提問 🎉", style: TextStyle(fontSize: 18)));
        }

        // 3. 抓到資料了！把文件轉換成列表
        final questions = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            // 取得單筆提問的資料
            var qDoc = questions[index];
            var data = qDoc.data() as Map<String, dynamic>;

            return Card(
              color: Colors.grey[850], // 深色模式的卡片顏色
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
                    Text("狀態：${data['isReplied'] == true ? '✅ 已回覆' : '⏳ 等待教練回覆'}",
                        style: TextStyle(color: data['isReplied'] == true ? Colors.green : Colors.redAccent, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  onPressed: () {
                    _showReplyDialog(
                      context,
                      qDoc.id,
                      data['content'] ?? ""
                    );
                  },
                  child: const Text("回覆", style: TextStyle(color: Colors.white)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🌟 新增：教練回覆彈窗
  void _showReplyDialog(BuildContext context, String docId, String currentQuestion) {
    final TextEditingController _replyController = TextEditingController();

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
            TextField(
              controller: _replyController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "請輸入你的專業建議...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("取消")),
          ElevatedButton(
            onPressed: () async {
              if (_replyController.text.trim().isEmpty) return;

              // 🌟 更新 Firestore 資料
              await FirebaseFirestore.instance.collection('questions').doc(docId).update({
                'replyContent': _replyController.text.trim(), // 教練回覆內容
                'isReplied': true,                            // 標記已回覆
                'replyTime': FieldValue.serverTimestamp(),    // 回覆時間
              });

              if (context.mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ 回覆成功！")));
            },
            child: const Text("送出回覆"),
          ),
        ],
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