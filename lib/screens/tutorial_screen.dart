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

// ==========================================
// 1️⃣ 第一層：動作教學百科 (部位分類 - 包含休息)
// ==========================================
class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  // 🌟 加入了「休息」選項
  final List<String> categories = const ['胸部', '背部', '肩部', '腿部', '手部', '核心', '有氧', '休息'];

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
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // 跳轉到該部位的動作清單
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
                    // 如果是休息選項，換個圖示感覺更貼切
                    Icon(
                        categories[index] == '休息' ? Icons.nightlight_round : Icons.fitness_center,
                        size: 40,
                        color: categories[index] == '休息' ? Colors.orangeAccent : Colors.blueAccent
                    ),
                    const SizedBox(height: 10),
                    Text(
                        categories[index],
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
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

// ==========================================
// 2️⃣ 第二層：動作清單畫面
// ==========================================
class ExerciseListScreen extends StatelessWidget {
  final String category;
  const ExerciseListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    // 假資料擴充，對應所有分類 (包含休息)
    final List<ExerciseInfo> allExercises = [
      //胸
      ExerciseInfo(name: "槓鈴上斜臥推", part: "胸部", description: "將槓鈴置於上斜椅，雙手略寬於肩，控制下放至鎖骨下方，再推起至手臂伸直，主要刺激上胸。"),
      ExerciseInfo(name: "啞鈴上斜臥推", part: "胸部", description: "坐上斜椅，雙手各持啞鈴，掌心向前，下放至胸側，再推起至啞鈴接近，訓練胸大肌上部並增加活動範圍。"),
      ExerciseInfo(name: "低到高滑輪夾胸", part: "胸部", description: "滑輪置於低位，雙手握把由下往上夾至胸前，手臂微彎，強調胸大肌上部纖維。"),
      ExerciseInfo(name: "上斜機械胸推", part: "胸部", description: "坐上斜胸推機，握把位於胸口高度，推起至手臂伸直，控制回到起始位置，主要刺激上胸。"),
      ExerciseInfo(name: "平板槓鈴握推", part: "胸部", description: "躺平板椅，雙手略寬於肩握槓鈴，下放至胸口，再推起至手臂伸直，訓練胸大肌整體。"),
      ExerciseInfo(name: "平板啞鈴握推", part: "胸部", description: "平板椅上持啞鈴，掌心向前，下放至胸側，再推起至啞鈴接近，增加胸肌伸展與收縮幅度。"),
      ExerciseInfo(name: "蝴蝶機", part: "胸部", description: "坐在蝴蝶機，雙手握把，手臂微彎，向前合攏至胸前，再控制回到起始位置，孤立訓練胸大肌。"),
      ExerciseInfo(name: "雙槓臂屈伸", part: "胸部", description: "雙手撐雙槓，身體微前傾，下放至肩膀略低於肘，再推起至手臂伸直，主要訓練胸下緣與三頭肌。"),
      ExerciseInfo(name: "高到低滑輪夾胸", part: "胸部", description: "滑輪置於高位，雙手握把由上往下夾至腹前，手臂微彎，強調胸大肌下部纖維。"),
      ExerciseInfo(name: "下斜機械胸推", part: "胸部", description: "坐下斜胸推機，握把位於胸口上方，推起至手臂伸直，控制回到起始位置，主要刺激胸大肌下部。"),

      //背
      ExerciseInfo(name: "正握槓鈴划船", part: "背部", description: "雙手正握槓鈴，腰部前傾約 45 度，保持背部平直，將槓鈴由下往上拉至腹部，再控制放下，主要訓練背闊肌與菱形肌。"),
      ExerciseInfo(name: "T-Bar Row", part: "背部", description: "站在 T-Bar 槓前，雙手握把，背部微前傾，將槓由地面拉至胸口或腹部，再控制放下，強調背闊肌厚度。"),
      ExerciseInfo(name: "寬臥坐姿划船", part: "背部", description: "坐姿拉背機，雙手寬握把手，保持胸口挺起，將把手拉至胸口，再慢慢伸直手臂，主要刺激背闊肌外側。"),
      ExerciseInfo(name: "寬握高位下拉", part: "背部", description: "坐在高位下拉機，雙手寬握槓，保持胸口挺起，將槓拉至鎖骨位置，再控制放回，訓練背闊肌展寬。"),
      ExerciseInfo(name: "單手啞鈴划船", part: "背部", description: "單手持啞鈴，另一手支撐在椅上，背部保持平直，將啞鈴由地面拉至腰側，再控制放下，強調背部單側肌群。"),
      ExerciseInfo(name: "反手槓鈴划船", part: "背部", description: "雙手反握槓鈴，腰部前傾約 45 度，保持背部平直，將槓鈴拉至腹部，再控制放下，偏重下背闊肌與肱二頭肌。"),
      ExerciseInfo(name: "窄握高位下拉", part: "背部", description: "坐在高位下拉機，雙手窄握槓，保持胸口挺起，將槓拉至胸口，再控制放回，主要刺激背闊肌中部與厚度。"),

      //肩
      ExerciseInfo(name: "站姿槓鈴肩推", part: "肩部", description: "雙手正握槓鈴於肩前，站姿收緊核心，將槓鈴推至頭頂上方，再控制放下至肩口，主要訓練前三角肌與整體肩部力量。"),
      ExerciseInfo(name: "坐姿啞鈴肩推", part: "肩部", description: "坐在椅子上，雙手各持啞鈴於肩側，掌心向前，推起至手臂伸直，再控制放下，強調肩部穩定與三角肌。"),
      ExerciseInfo(name: "前平舉", part: "肩部", description: "雙手各持啞鈴於大腿前，手臂微彎，將啞鈴抬至肩高度，再慢慢放下，主要訓練前三角肌。"),
      ExerciseInfo(name: "啞鈴飛鳥", part: "肩部", description: "雙手各持啞鈴於身側，手臂微彎，向兩側抬起至肩高度，再控制放下，主要刺激中三角肌。"),
      ExerciseInfo(name: "滑輪側平舉", part: "肩部", description: "滑輪置於低位，單手握把，手臂微彎，向側邊抬起至肩高度，再控制放下，孤立訓練中三角肌。"),
      ExerciseInfo(name: "側平舉機", part: "肩部", description: "坐在側平舉機，雙手握把，手臂微彎，向兩側抬起至肩高度，再控制放下，主要訓練中三角肌。"),
      ExerciseInfo(name: "反向夾胸肌", part: "肩部", description: "坐在反向蝴蝶機，雙手握把，手臂微彎，向後展開至肩高度，再控制回到起始位置，主要刺激後三角肌。"),
      ExerciseInfo(name: "俯身飛鳥", part: "肩部", description: "雙手各持啞鈴，身體俯身約 45 度，手臂微彎，向兩側抬起至肩高度，再控制放下，訓練後三角肌。"),
      ExerciseInfo(name: "滑輪後三角飛鳥", part: "肩部", description: "滑輪置於低位，雙手交叉握把，身體微俯身，手臂微彎，向後外側拉至肩高度，再控制回到起始位置，主要刺激後三角肌。"),

      //腿
      ExerciseInfo(name: "深蹲", part: "腿部", description: "雙腳與肩同寬，保持脊椎中立，臀部向後坐下至大腿接近平行地面，再站起，主要訓練股四頭肌、臀大肌與核心。"),
      ExerciseInfo(name: "坐姿腿屈伸", part: "腿部", description: "坐在腿屈伸機，雙腳勾住踏板，伸直膝蓋至大腿收縮，再慢慢放下，孤立訓練股四頭肌。"),
      ExerciseInfo(name: "分腿蹲", part: "腿部", description: "一腳在前一腳在後，保持上身直立，下蹲至前腿大腿接近平行，再站起，主要訓練股四頭肌與臀部。"),
      ExerciseInfo(name: "羅馬尼亞硬舉", part: "腿部", description: "雙手持槓鈴於大腿前，膝蓋微彎，臀部向後推，保持背部平直，下放至小腿中段，再站起，主要訓練臀部與腿後肌群。"),
      ExerciseInfo(name: "趴姿腿灣舉", part: "腿部", description: "趴在腿彎舉機，雙腳勾住踏板，屈膝將踏板拉向臀部，再慢慢放下，孤立訓練腿後肌群。"),
      ExerciseInfo(name: "坐姿腿灣舉", part: "腿部", description: "坐在腿彎舉機，雙腳勾住踏板，屈膝將踏板拉向大腿下方，再慢慢放下，主要刺激腿後肌群。"),
      ExerciseInfo(name: "保加利亞分腿蹲", part: "腿部", description: "後腳放在椅子或箱子上，前腳站立，下蹲至前腿大腿接近平行，再站起，強調股四頭肌與臀部。"),
      ExerciseInfo(name: "臀推", part: "腿部", description: "上背靠在椅凳，槓鈴置於髖部，屈膝腳踩地，臀部向上推至大腿與軀幹平行，再慢慢放下，主要訓練臀大肌。"),
      ExerciseInfo(name: "站姿提踵", part: "腿部", description: "站立腳尖上抬，腳跟離地至小腿收縮，再慢慢放下，訓練小腿腓腸肌。"),
      ExerciseInfo(name: "坐姿提踵", part: "腿部", description: "坐姿腳尖上抬，腳跟離地至小腿收縮，再慢慢放下，主要刺激小腿比目魚肌。"),
      ExerciseInfo(name: "腿推機踩踏板下方", part: "腿部", description: "坐在腿推機，腳放在踏板下方位置，推起至腿伸直，再控制放下，偏重股四頭肌。"),
      ExerciseInfo(name: "腿推機踩踏板中間", part: "腿部", description: "坐在腿推機，腳放在踏板中間位置，推起至腿伸直，再控制放下，均衡訓練股四頭肌與臀部。"),
      ExerciseInfo(name: "腿推機踩踏板上方", part: "腿部", description: "坐在腿推機，腳放在踏板上方位置，推起至腿伸直，再控制放下，偏重臀部與腿後肌群。"),
      ExerciseInfo(name: "腿推機腳踩寬", part: "腿部", description: "坐在腿推機，雙腳寬距放在踏板，推起至腿伸直，再控制放下，主要刺激大腿內側與臀部。"),

      //手
      ExerciseInfo(name: "W槓彎舉", part: "手部", description: "雙手反握 W 槓，手臂貼近身體，屈肘將槓舉至肩前，再慢慢放下，主要訓練肱二頭肌。"),
      ExerciseInfo(name: "啞鈴二頭彎舉", part: "手部", description: "雙手各持啞鈴，掌心向前，屈肘將啞鈴舉至肩前，再慢慢放下，訓練肱二頭肌。"),
      ExerciseInfo(name: "牧師椅二頭彎舉", part: "手部", description: "坐在牧師椅，雙手持槓或啞鈴，手臂固定在椅墊上，屈肘舉起重量，再慢慢放下，孤立訓練肱二頭肌。"),
      ExerciseInfo(name: "上斜啞鈴彎舉", part: "手部", description: "坐在上斜椅，雙手持啞鈴自然下垂，屈肘舉起至肩前，再慢慢放下，增加肱二頭肌伸展幅度。"),
      ExerciseInfo(name: "垂式彎舉", part: "手部", description: "雙手持槓或啞鈴，手臂垂直於身體前方，屈肘舉起重量，再慢慢放下，強調肱二頭肌下段。"),
      ExerciseInfo(name: "窄握握推", part: "手部", description: "躺平板椅，雙手窄握槓鈴，下放至胸口，再推起至手臂伸直，主要訓練肱三頭肌。"),
      ExerciseInfo(name: "繩索下壓", part: "手部", description: "站姿握住滑輪繩索，手肘貼近身體，向下伸直手臂，再慢慢回到起始位置，孤立訓練肱三頭肌。"),
      ExerciseInfo(name: "W槓過頭屈伸", part: "手部", description: "雙手持 W 槓於頭上，屈肘將槓放至頭後，再伸直手臂推起，主要訓練肱三頭肌長頭。"),
      ExerciseInfo(name: "手腕彎舉", part: "手部", description: "坐姿前臂放在大腿上，手掌向上持啞鈴，屈曲手腕將啞鈴抬起，再慢慢放下，訓練前臂屈肌群。"),
      ExerciseInfo(name: "反向手腕彎舉", part: "手部", description: "坐姿前臂放在大腿上，手掌向下持啞鈴，伸展手腕將啞鈴抬起，再慢慢放下，訓練前臂伸肌群。"),

      //核心
      ExerciseInfo(name: "棒式", part: "核心", description: "俯撐姿勢，前臂支撐地面，肩膀與肘關節垂直，保持身體呈一直線，收緊核心，維持姿勢，主要訓練腹橫肌與核心穩定。"),
      ExerciseInfo(name: "器械卷腹", part: "核心", description: "坐在卷腹機，雙手握把或肩部靠墊，收縮腹部將上身向前捲起，再慢慢回到起始位置，主要訓練腹直肌。"),

      //有氧
      ExerciseInfo(name: "跑步機間歇", part: "有氧", description: "在跑步機上交替進行高速度衝刺與低速度恢復，提升心肺耐力與燃脂效果。"),
      ExerciseInfo(name: "跑步機高坡度低速度", part: "有氧", description: "將跑步機調整至高坡度，低速行走，增加下肢肌群負荷並提升心肺耐力。"),
      ExerciseInfo(name: "腳踏車", part: "有氧", description: "坐姿踩動腳踏車或飛輪，保持穩定節奏，提升心肺功能並訓練腿部耐力。"),

      //休息
      ExerciseInfo(name: "肌肉恢復指南", part: "休息", description: "睡眠是肌肉生長的黃金時間！建議每天睡滿 7-8 小時，搭配滾筒放鬆緊繃筋膜。有問題隨時問教練！"),
      ExerciseInfo(name: "飲食與營養補充", part: "休息", description: "訓練後 30 分鐘內攝取優質蛋白質與碳水化合物，能有效加速恢復。不知道怎麼吃？點擊下方問教練！"),
    ];

    final List<ExerciseInfo> exercises = allExercises.where((e) => e.part == category).toList();

    return Scaffold(
      appBar: AppBar(title: Text("$category 訓練動作")),
      body: exercises.isEmpty
          ? const Center(child: Text("目前尚無動作資料", style: TextStyle(color: Colors.white54, fontSize: 16)))
          : ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(
                category == '休息' ? Icons.restaurant_menu : Icons.play_circle_outline,
                color: category == '休息' ? Colors.orangeAccent : Colors.blueAccent,
                size: 30
            ),
            title: Text(exercises[index].name, style: const TextStyle(fontSize: 18)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
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

// ==========================================
// 3️⃣ 第三層：動作詳情與 Q&A 畫面 (保留清晰的對話泡泡設計)
// ==========================================
class ExerciseDetailScreen extends StatelessWidget {
  final ExerciseInfo exercise;

  ExerciseDetailScreen({super.key, required this.exercise});

  final TextEditingController _questionController = TextEditingController();

  void _askCoach(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 25, right: 25, top: 25
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("詢問關於【${exercise.name}】", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            TextField(
              controller: _questionController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: "請描述你遇到的困難或疑問...",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;

                  final text = _questionController.text.trim();
                  if (text.isEmpty) return;

                  try {
                    await FirebaseFirestore.instance.collection('questions').add({
                      'senderUid': user.uid,
                      'exerciseName': exercise.name,
                      'content': text,
                      'timestamp': FieldValue.serverTimestamp(),
                      'isReplied': false,
                    });

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("提問已送出！"))
                      );
                    }
                    _questionController.clear();
                  } catch (e) {
                    debugPrint("寫入失敗: $e");
                  }
                },
                child: const Text("確認送出", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isRest = exercise.part == '休息'; // 判斷是否為休息類別

    return Scaffold(
      appBar: AppBar(title: Text(exercise.name)),
      body: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[900],
            // 🌟 休息分類的影片區域圖示換成床鋪或食物，更有感覺
            child: Icon(
                isRest ? Icons.local_dining : Icons.videocam,
                size: 50,
                color: Colors.white24
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(exercise.description, style: const TextStyle(fontSize: 16, height: 1.5)),
          ),

          // 🌟 Q&A 歷史紀錄區塊
          Expanded(
            child: user == null
                ? const SizedBox()
                : StreamBuilder<QuerySnapshot>(
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
                      child: Text("目前還沒有發問喔！趕快問問教練吧", style: TextStyle(color: Colors.white54))
                  );
                }

                var docs = snapshot.data!.docs;
                docs.sort((a, b) {
                  var aTime = (a.data() as Map)['timestamp'] as Timestamp?;
                  var bTime = (b.data() as Map)['timestamp'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

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
                            Text("我的提問：${data['content']}", style: const TextStyle(color: Colors.white, fontSize: 15)),
                            const Divider(color: Colors.white24, height: 20),
                            if (isReplied)
                              Text("教練回覆：${data['replyContent']}", style: const TextStyle(color: Colors.greenAccent, fontSize: 15, fontWeight: FontWeight.bold))
                            else
                              const Text("教練還在想怎麼回覆你...", style: TextStyle(color: Colors.orangeAccent, fontSize: 14)),
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
                label: const Text("詢問真人教練", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}