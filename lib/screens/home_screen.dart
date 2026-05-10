import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'menu_planning_screen.dart';
import 'start_workout_screen.dart';
import 'profile_screen.dart';
import 'workout_history_screen.dart';
import 'weight_screen.dart';

class HomeScreen extends StatefulWidget {
  // 接收從 main.dart 傳過來的名字跟大頭貼
  final String userName;
  final String? base64Image;

  const HomeScreen({
    super.key,
    required this.userName,
    this.base64Image,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  int _totalExercises = 0;
  int _completedExercises = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  // 這裡只需要抓「今日運動進度」就好，使用者資料交給 main.dart 處理！
  Future<void> _fetchDashboardData() async {
    if (user == null) return;

    try {
      String todayStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
      var workoutDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('daily_workouts')
          .doc(todayStr)
          .get();

      if (workoutDoc.exists && workoutDoc.data()!.containsKey('exercises')) {
        List<dynamic> exercises = workoutDoc.get('exercises');
        int completed = exercises.where((ex) => ex['isCompleted'] == true).length;

        setState(() {
          _totalExercises = exercises.length;
          _completedExercises = completed;
        });
      } else {
        setState(() {
          _totalExercises = 0;
          _completedExercises = 0;
        });
      }
    } catch (e) {
      debugPrint("讀取首頁資料失敗: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : RefreshIndicator(
        onRefresh: _fetchDashboardData,
        color: Colors.blueAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 30),
              _buildTodayHeroCard(context),
              const SizedBox(height: 30),
              const Text("快捷功能", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _buildQuickActionGrid(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- 區塊 1：頂部歡迎與大頭貼 ---
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 32),
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
        const SizedBox(width: 5),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 這裡直接使用 widget.userName
              Text("早安，${widget.userName}！", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              const Text("今天準備好突破自己了嗎？", style: TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()))
                .then((_) => _fetchDashboardData());
          },
          child: CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFF1E1E1E),
            // 使用 widget.base64Image
            backgroundImage: widget.base64Image != null ? MemoryImage(base64Decode(widget.base64Image!)) : null,
            child: widget.base64Image == null ? const Icon(Icons.person, color: Colors.blueAccent) : null,
          ),
        ),
      ],
    );
  }

  // --- 區塊 2：今日任務進度卡片 ---
  Widget _buildTodayHeroCard(BuildContext context) {
    double progress = _totalExercises == 0 ? 0 : _completedExercises / _totalExercises;
    String statusText = "尚未安排菜單";
    String buttonText = "規劃今日菜單";
    Widget targetScreen = const MenuPlanningScreen();

    if (_totalExercises > 0) {
      if (_completedExercises == _totalExercises) {
        statusText = "今日菜單完美達成！";
        buttonText = "查看運動紀錄";
      } else {
        statusText = "今日進度：$_completedExercises / $_totalExercises 項";
        buttonText = "繼續訓練";
        targetScreen = const StartWorkoutScreen();
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueAccent.withAlpha(200), Colors.purpleAccent.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blueAccent.withAlpha(50), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("今日任務", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(statusText, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          if (_totalExercises > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              ),
            ),
            const SizedBox(height: 20),
          ],

          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen))
                    .then((_) => _fetchDashboardData());
              },
              child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // --- 區塊 3：快捷功能方塊 ---
  Widget _buildQuickActionGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _buildGridItem(
          title: "菜單規劃", icon: Icons.edit_document, color: Colors.blueAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuPlanningScreen())).then((_) => _fetchDashboardData()),
        ),
        _buildGridItem(
          title: "開始運動", icon: Icons.play_circle_fill, color: Colors.greenAccent[700]!,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StartWorkoutScreen())).then((_) => _fetchDashboardData()),
        ),
        _buildGridItem(
          title: "運動紀錄", icon: Icons.calendar_month, color: Colors.orangeAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutHistoryScreen())).then((_) => _fetchDashboardData()),
        ),
        _buildGridItem(
          title: "體態紀錄", icon: Icons.monitor_weight, color: Colors.purpleAccent,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WeightScreen())).then((_) => _fetchDashboardData()),
        ),
      ],
    );
  }

  Widget _buildGridItem({required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}