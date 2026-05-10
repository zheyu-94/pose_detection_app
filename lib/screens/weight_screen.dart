import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();

  String _selectedGender = '男';
  double _activityLevel = 1.2;
  int _selectedDays = 7; // 預設顯示 7 天內的數據

  final List<Map<String, dynamic>> _activityOptions = [
    {'label': '久坐 (不運動)', 'value': 1.2},
    {'label': '輕度 (每週 1-3 天)', 'value': 1.375},
    {'label': '中度 (每週 3-5 天)', 'value': 1.55},
    {'label': '高度 (每週 6-7 天)', 'value': 1.725},
  ];

  Future<void> _saveData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double height = double.tryParse(_heightController.text) ?? 0;
    double weight = double.tryParse(_weightController.text) ?? 0;
    int age = int.tryParse(_ageController.text) ?? 0;

    if (height == 0 || weight == 0 || age == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("請填寫完整資訊")));
      return;
    }

    double bmr = (_selectedGender == '男')
        ? (10 * weight) + (6.25 * height) - (5 * age) + 5
        : (10 * weight) + (6.25 * height) - (5 * age) - 161;
    double tdee = bmr * _activityLevel;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'height': height, 'weight': weight, 'age': age,
        'gender': _selectedGender, 'tdee': tdee.roundToDouble(),
      });

      await FirebaseFirestore.instance.collection('weight_history').add({
        'uid': user.uid,
        'weight': weight,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("紀錄成功！")));
        _weightController.clear(); // 存完清空體重欄位
      }
    } catch (e) {
      print("儲存失敗: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("體態與 TDEE 紀錄")),
      body: Column(
        children: [
          // --- 上半部：輸入區域 ---
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInputField("身高 (cm)", _heightController, Icons.height),
                  _buildInputField("體重 (kg)", _weightController, Icons.monitor_weight),
                  _buildInputField("年齡", _ageController, Icons.cake),
                  const SizedBox(height: 10),
                  _buildGenderAndActivity(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveData,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      child: const Text("更新體態並儲存紀錄", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1, color: Colors.white24),

          // --- 下半部：圖表區域 ---
          Expanded(
            flex: 5,
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Text("體重變化趨勢", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),

                // 時間區間選擇按鈕
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildTimeChip("7天", 7),
                      _buildTimeChip("15天", 15),
                      _buildTimeChip("1個月", 30),
                      _buildTimeChip("3個月", 90),
                      _buildTimeChip("半年", 180),
                    ],
                  ),
                ),

                // 讀取 Firestore 資料並畫圖
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('weight_history')
                        .where('uid', isEqualTo: user?.uid)
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text("讀取失敗: ${snapshot.error}"));
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                      var docs = snapshot.data!.docs;
                      if (docs.isEmpty) return const Center(child: Text("尚無歷史紀錄", style: TextStyle(color: Colors.white54)));

                      // 1. 根據選擇的天數過濾資料
                      DateTime cutoffDate = DateTime.now().subtract(Duration(days: _selectedDays));
                      var filteredDocs = docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        if (data['date'] == null) return false;
                        DateTime docDate = DateFormat('yyyy-MM-dd').parse(data['date']);
                        return docDate.isAfter(cutoffDate) || docDate.isAtSameMomentAs(cutoffDate);
                      }).toList();

                      if (filteredDocs.isEmpty) {
                        return Center(child: Text("這 $_selectedDays 天內沒有紀錄喔！", style: const TextStyle(color: Colors.white54)));
                      }

                      // 2. 核心修正：將同一天的數據去重，只保留最新的一筆！
                      Map<String, double> dailyWeights = {};
                      for (var doc in filteredDocs) {
                        var data = doc.data() as Map<String, dynamic>;
                        String dateStr = data['date'];

                        // 因為 Firestore 撈下來的資料已經是「由新到舊」排序
                        // 所以我們遇到的第一個 dateStr，絕對是那一天最新的一筆！
                        if (!dailyWeights.containsKey(dateStr)) {
                          dailyWeights[dateStr] = (data['weight'] as num).toDouble();
                        }
                      }

                      // 3. 準備畫圖的資料 (把時間反轉為由舊到新，圖表才會從左畫到右)
                      var sortedDates = dailyWeights.keys.toList().reversed.toList();
                      List<FlSpot> spots = [];
                      for (int i = 0; i < sortedDates.length; i++) {
                        spots.add(FlSpot(i.toDouble(), dailyWeights[sortedDates[i]]!));
                      }

                      // 4. 渲染圖表
                      return Padding(
                        padding: const EdgeInsets.only(right: 25, left: 15, top: 15, bottom: 15),
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) => Text("${value.toInt()}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: spots,
                                isCurved: true,
                                color: Colors.greenAccent,
                                barWidth: 4,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.greenAccent.withOpacity(0.2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI 組件封裝 ---
  Widget _buildTimeChip(String label, int days) {
    bool isSelected = _selectedDays == days;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _selectedDays = days);
        },
        selectedColor: Colors.blueAccent,
        backgroundColor: Colors.grey[800],
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.white54),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  Widget _buildGenderAndActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("性別："),
            Radio(value: '男', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v!)),
            const Text("男"),
            Radio(value: '女', groupValue: _selectedGender, onChanged: (v) => setState(() => _selectedGender = v!)),
            const Text("女"),
          ],
        ),
        DropdownButton<double>(
          isExpanded: true,
          value: _activityLevel,
          items: _activityOptions.map((opt) => DropdownMenuItem<double>(value: opt['value'], child: Text(opt['label']))).toList(),
          onChanged: (v) => setState(() => _activityLevel = v!),
        ),
      ],
    );
  }
}