import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 動作模型
class ExerciseInfo {
  final String name;
  final String part;
  final String description;

  ExerciseInfo({required this.name, required this.part, required this.description});
}

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  // 假資料：之後你可以搬到 Firestore
  final List<String> categories = const ['胸部', '背部', '腿部', '肩部', '核心'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text("動作教學百科")),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 一列兩個
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.2,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                // 跳轉到該部位的動作清单
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ExerciseListScreen(category: categories[index]),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.fitness_center, size: 40, color: Colors.blueAccent),
                    const SizedBox(height: 10),
                    Text(
                        categories[index],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold) // 這裡預設是黑字
                    ),                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// 第二層：動作清單畫面
class ExerciseListScreen extends StatelessWidget {
  final String category;
  const ExerciseListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // 這裡根據部位過濾動作（範例）
    final List<ExerciseInfo> exercises = [
      ExerciseInfo(name: "槓鈴臥推", part: "胸部", description: "這是一個訓練胸大肌的經典動作..."),
      ExerciseInfo(name: "啞鈴飛鳥", part: "胸部", description: "專注於胸肌的拉伸與收縮..."),
    ].where((e) => e.part == category).toList();

    return Scaffold(
      appBar: AppBar(title: Text("$category 訓練動作")),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.play_circle_outline, color: Colors.blueAccent),
            title: Text(exercises[index].name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseDetailScreen(exercise: exercises[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// 第三層：動作詳情畫面
// 第三層：動作詳情畫面
// 第三層：動作詳情畫面
class ExerciseDetailScreen extends StatelessWidget {
  final ExerciseInfo exercise;

  ExerciseDetailScreen({super.key, required this.exercise});

  final TextEditingController _questionController = TextEditingController();

  void _askCoach(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 讓鍵盤彈出時不會擋住
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, // 自動避開鍵盤
            left: 25, right: 25, top: 25
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("詢問關於【${exercise.name}】"),
            TextField(controller: _questionController, maxLines: 3),
            ElevatedButton(
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null) return;

                final text = _questionController.text.trim();
                if (text.isEmpty) return;

                try {
                  await FirebaseFirestore.instance.collection('questions').add({
                    'senderUid': user.uid,         // 誰問的
                    'exerciseName': exercise.name, // 問哪招
                    'content': text,               // 問什麼
                    'timestamp': FieldValue.serverTimestamp(),
                    'isReplied': false,            // 教練回了嗎？
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("🚀 提問已送出！"))
                    );
                  }
                  _questionController.clear();
                } catch (e) {
                  print("❌ 寫入失敗: $e");
                }
              },
              child: const Text("確認送出"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // 🌟 取得當前學員身分

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[900],
            child: const Icon(Icons.videocam, size: 50, color: Colors.white24),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(exercise.description, style: const TextStyle(fontSize: 16, height: 1.5)),
          ),

          // 🌟 新增：學員的專屬 Q&A 歷史紀錄區塊
          Expanded(
            child: user == null
                ? const SizedBox() // 如果沒登入就不顯示
                : StreamBuilder<QuerySnapshot>(
              // 1. 條件過濾：只抓「這個學員」問「這個動作」的問題
              stream: FirebaseFirestore.instance
                  .collection('questions')
                  .where('senderUid', isEqualTo: user.uid)
                  .where('exerciseName', isEqualTo: exercise.name)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("目前還沒有發問喔！趕快問問教練吧 💪", style: TextStyle(color: Colors.white54))
                  );
                }

                // 2. 本地端排序 (避免 Firestore 要求建立複合索引而報錯)
                var docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  var aData = a.data() as Map<String, dynamic>;
                  var bData = b.data() as Map<String, dynamic>;
                  var aTime = aData['timestamp'] as Timestamp?;
                  var bTime = bData['timestamp'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime); // 新的時間排在上面
                });

                // 3. 畫出對話泡泡卡片
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isReplied = data['isReplied'] == true;

                    return Card(
                      color: Colors.grey[850],
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("🙋 我的提問：${data['content']}", style: const TextStyle(color: Colors.white, fontSize: 15)),
                            const Divider(color: Colors.white24, height: 20),
                            // 🌟 根據教練是否回覆，顯示不同的字與顏色
                            if (isReplied)
                              Text("🧑‍🏫 教練回覆：${data['replyContent']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 15, fontWeight: FontWeight.bold))
                            else
                              const Text("⏳ 教練還在想怎麼回覆你...", style: TextStyle(color: Colors.orangeAccent, fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 詢問教練按鈕
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
                onPressed: () => _askCoach(context),
                icon: const Icon(Icons.chat, color: Colors.black),
                label: const Text("💬 詢問真人教練", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}