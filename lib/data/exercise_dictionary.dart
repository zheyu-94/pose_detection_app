// exercise_dictionary.dart

/// 定義動作資訊的資料結構
class ExerciseInfo {
  final String name;
  final String part;
  final String description;

  ExerciseInfo({
    required this.name,
    required this.part,
    required this.description,
  });
}

class ExerciseDictionary {
  // 核心字典：改為 List<ExerciseInfo> 格式，包含部位、名稱與詳細教學
  static final List<ExerciseInfo> allExercises = [
    // --- 胸部 ---
    ExerciseInfo(name: "上斜槓鈴臥推", part: "胸部", description: "將槓鈴置於上斜椅，雙手略寬於肩，控制下放至鎖骨下方，再推起至手臂伸直，主要刺激上胸。"),
    ExerciseInfo(name: "上斜啞鈴臥推", part: "胸部", description: "坐上斜椅，雙手各持啞鈴，掌心向前，下放至胸側，再推起至啞鈴接近，訓練胸大肌上部並增加活動範圍。"),
    ExerciseInfo(name: "低到高滑輪夾胸", part: "胸部", description: "滑輪置於低位，雙手握把由下往上夾至胸前，手臂微彎，強調胸大肌上部纖維。"),
    ExerciseInfo(name: "上斜機械胸推", part: "胸部", description: "坐上斜胸推機，握把位於胸口高度，推起至手臂伸直，控制回到起始位置，主要刺激上胸。"),
    ExerciseInfo(name: "平板槓鈴臥推", part: "胸部", description: "躺平板椅，雙手略寬於肩握槓鈴，下放至胸口，再推起至手臂伸直，訓練胸大肌整體。"), // 幫你修正了「臥」推的錯字
    ExerciseInfo(name: "平板啞鈴臥推", part: "胸部", description: "平板椅上持啞鈴，掌心向前，下放至胸側，再推起至啞鈴接近，增加胸肌伸展與收縮幅度。"), // 幫你修正了「臥」推的錯字
    ExerciseInfo(name: "蝴蝶機", part: "胸部", description: "坐在蝴蝶機，雙手握把，手臂微彎，向前合攏至胸前，再控制回到起始位置，孤立訓練胸大肌。"),
    ExerciseInfo(name: "雙槓臂屈伸", part: "胸部", description: "雙手撐雙槓，身體微前傾，下放至肩膀略低於肘，再推起至手臂伸直，主要訓練胸下緣與三頭肌。"),
    ExerciseInfo(name: "高到低滑輪夾胸", part: "胸部", description: "滑輪置於高位，雙手握把由上往下夾至腹前，手臂微彎，強調胸大肌下部纖維。"),
    ExerciseInfo(name: "下斜機械胸推", part: "胸部", description: "坐下斜胸推機，握把位於胸口上方，推起至手臂伸直，控制回到起始位置，主要刺激胸大肌下部。"),

    // --- 背部 ---
    ExerciseInfo(name: "正握槓鈴划船", part: "背部", description: "雙手正握槓鈴，腰部前傾約 45 度，保持背部平直，將槓鈴由下往上拉至腹部，再控制放下，主要訓練背闊肌與菱形肌。"),
    ExerciseInfo(name: "T-Bar Row", part: "背部", description: "站在 T-Bar 槓前，雙手握把，背部微前傾，將槓由地面拉至胸口或腹部，再控制放下，強調背闊肌厚度。"),
    ExerciseInfo(name: "寬握坐姿划船", part: "背部", description: "坐姿拉背機，雙手寬握把手，保持胸口挺起，將把手拉至胸口，再慢慢伸直手臂，主要刺激背闊肌外側。"), // 幫你修正了「握」字的錯字
    ExerciseInfo(name: "寬握高位下拉", part: "背部", description: "坐在高位下拉機，雙手寬握槓，保持胸口挺起，將槓拉至鎖骨位置，再控制放回，訓練背闊肌展寬。"),
    ExerciseInfo(name: "單手啞鈴划船", part: "背部", description: "單手持啞鈴，另一手支撐在椅上，背部保持平直，將啞鈴由地面拉至腰側，再控制放下，強調背部單側肌群。"),
    ExerciseInfo(name: "反手槓鈴划船", part: "背部", description: "雙手反握槓鈴，腰部前傾約 45 度，保持背部平直，將槓鈴拉至腹部，再控制放下，偏重下背闊肌與肱二頭肌。"),
    ExerciseInfo(name: "窄握高位下拉", part: "背部", description: "坐在高位下拉機，雙手窄握槓，保持胸口挺起，將槓拉至胸口，再控制放回，主要刺激背闊肌中部與厚度。"),

    // --- 肩部 ---
    ExerciseInfo(name: "站姿槓鈴肩推", part: "肩部", description: "雙手正握槓鈴於肩前，站姿收緊核心，將槓鈴推至頭頂上方，再控制放下至肩口，主要訓練前三角肌與整體肩部力量。"),
    ExerciseInfo(name: "坐姿啞鈴肩推", part: "肩部", description: "坐在椅子上，雙手各持啞鈴於肩側，掌心向前，推起至手臂伸直，再控制放下，強調肩部穩定與三角肌。"),
    ExerciseInfo(name: "前平舉", part: "肩部", description: "雙手各持啞鈴於大腿前，手臂微彎，將啞鈴抬至肩高度，再慢慢放下，主要訓練前三角肌。"),
    ExerciseInfo(name: "啞鈴飛鳥", part: "肩部", description: "雙手各持啞鈴於身側，手臂微彎，向兩側抬起至肩高度，再控制放下，主要刺激中三角肌。"),
    ExerciseInfo(name: "滑輪側平舉", part: "肩部", description: "滑輪置於低位，單手握把，手臂微彎，向側邊抬起至肩高度，再控制放下，孤立訓練中三角肌。"),
    ExerciseInfo(name: "側平舉機", part: "肩部", description: "坐在側平舉機，雙手握把，手臂微彎，向兩側抬起至肩高度，再控制放下，主要訓練中三角肌。"),
    ExerciseInfo(name: "反向夾胸機", part: "肩部", description: "坐在反向蝴蝶機，雙手握把，手臂微彎，向後展開至肩高度，再控制回到起始位置，主要刺激後三角肌。"),
    ExerciseInfo(name: "俯身飛鳥", part: "肩部", description: "雙手各持啞鈴，身體俯身約 45 度，手臂微彎，向兩側抬起至肩高度，再控制放下，訓練後三角肌。"),
    ExerciseInfo(name: "滑輪後三角飛鳥", part: "肩部", description: "滑輪置於低位，雙手交叉握把，身體微俯身，手臂微彎，向後外側拉至肩高度，再控制回到起始位置，主要刺激後三角肌。"),

    // --- 腿部 ---
    ExerciseInfo(name: "深蹲", part: "腿部", description: "雙腳與肩同寬，保持脊椎中立，臀部向後坐下至大腿接近平行地面，再站起，主要訓練股四頭肌、臀大肌與核心。"),
    ExerciseInfo(name: "坐姿腿屈伸", part: "腿部", description: "坐在腿屈伸機，雙腳勾住踏板，伸直膝蓋至大腿收縮，再慢慢放下，孤立訓練股四頭肌。"),
    ExerciseInfo(name: "分腿蹲", part: "腿部", description: "一腳在前一腳在後，保持上身直立，下蹲至前腿大腿接近平行，再站起，主要訓練股四頭肌與臀部。"),
    ExerciseInfo(name: "羅馬尼亞硬舉", part: "腿部", description: "雙手持槓鈴於大腿前，膝蓋微彎，臀部向後推，保持背部平直，下放至小腿中段，再站起，主要訓練臀部與腿後肌群。"),
    ExerciseInfo(name: "趴姿腿彎舉", part: "腿部", description: "趴在腿彎舉機，雙腳勾住踏板，屈膝將踏板拉向臀部，再慢慢放下，孤立訓練腿後肌群。"), // 幫你修正了「彎」字的錯字
    ExerciseInfo(name: "坐姿腿彎舉", part: "腿部", description: "坐在腿彎舉機，雙腳勾住踏板，屈膝將踏板拉向大腿下方，再慢慢放下，主要刺激腿後肌群。"), // 幫你修正了「彎」字的錯字
    ExerciseInfo(name: "保加利亞分腿蹲", part: "腿部", description: "後腳放在椅子或箱子上，前腳站立，下蹲至前腿大腿接近平行，再站起，強調股四頭肌與臀部。"),
    ExerciseInfo(name: "臀推", part: "腿部", description: "上背靠在椅凳，槓鈴置於髖部，屈膝腳踩地，臀部向上推至大腿與軀幹平行，再慢慢放下，主要訓練臀大肌。"),
    ExerciseInfo(name: "站姿提踵", part: "腿部", description: "站立腳尖上抬，腳跟離地至小腿收縮，再慢慢放下，訓練小腿腓腸肌。"),
    ExerciseInfo(name: "坐姿提踵", part: "腿部", description: "坐姿腳尖上抬，腳跟離地至小腿收縮，再慢慢放下，主要刺激小腿比目魚肌。"),
    ExerciseInfo(name: "腿推機踩踏板下方", part: "腿部", description: "坐在腿推機，腳放在踏板下方位置，推起至腿伸直，再控制放下，偏重股四頭肌。"),
    ExerciseInfo(name: "腿推機踩踏板中間", part: "腿部", description: "坐在腿推機，腳放在踏板中間位置，推起至腿伸直，再控制放下，均衡訓練股四頭肌與臀部。"),
    ExerciseInfo(name: "腿推機踩踏板上方", part: "腿部", description: "坐在腿推機，腳放在踏板上方位置，推起至腿伸直，再控制放下，偏重臀部與腿後肌群。"),
    ExerciseInfo(name: "腿推機腳踩寬", part: "腿部", description: "坐在腿推機，雙腳寬距放在踏板，推起至腿伸直，再控制放下，主要刺激大腿內側與臀部。"),

    // --- 手部 ---
    ExerciseInfo(name: "W槓彎舉", part: "手部", description: "雙手反握 W 槓，手臂貼近身體，屈肘將槓舉至肩前，再慢慢放下，主要訓練肱二頭肌。"),
    ExerciseInfo(name: "啞鈴二頭彎舉", part: "手部", description: "雙手各持啞鈴，掌心向前，屈肘將啞鈴舉至肩前，再慢慢放下，訓練肱二頭肌。"),
    ExerciseInfo(name: "牧師椅二頭彎舉", part: "手部", description: "坐在牧師椅，雙手持槓或啞鈴，手臂固定在椅墊上，屈肘舉起重量，再慢慢放下，孤立訓練肱二頭肌。"),
    ExerciseInfo(name: "上斜啞鈴彎舉", part: "手部", description: "坐在上斜椅，雙手持啞鈴自然下垂，屈肘舉起至肩前，再慢慢放下，增加肱二頭肌伸展幅度。"),
    ExerciseInfo(name: "垂式彎舉", part: "手部", description: "雙手持槓或啞鈴，手臂垂直於身體前方，屈肘舉起重量，再慢慢放下，強調肱二頭肌下段。"),
    ExerciseInfo(name: "窄握臥推", part: "手部", description: "躺平板椅，雙手窄握槓鈴，下放至胸口，再推起至手臂伸直，主要訓練肱三頭肌。"), // 幫你修正了「臥」推的錯字
    ExerciseInfo(name: "繩索下壓", part: "手部", description: "站姿握住滑輪繩索，手肘貼近身體，向下伸直手臂，再慢慢回到起始位置，孤立訓練肱三頭肌。"),
    ExerciseInfo(name: "W槓過頭屈伸", part: "手部", description: "雙手持 W 槓於頭上，屈肘將槓放至頭後，再伸直手臂推起，主要訓練肱三頭肌長頭。"),
    ExerciseInfo(name: "手腕彎舉", part: "手部", description: "坐姿前臂放在大腿上，手掌向上持啞鈴，屈曲手腕將啞鈴抬起，再慢慢放下，訓練前臂屈肌群。"),
    ExerciseInfo(name: "反向手腕彎舉", part: "手部", description: "坐姿前臂放在大腿上，手掌向下持啞鈴，伸展手腕將啞鈴抬起，再慢慢放下，訓練前臂伸肌群。"),

    // --- 核心 ---
    ExerciseInfo(name: "棒式", part: "核心", description: "俯撐姿勢，前臂支撐地面，肩膀與肘關節垂直，保持身體呈一直線，收緊核心，維持姿勢，主要訓練腹橫肌與核心穩定。"),
    ExerciseInfo(name: "器械卷腹", part: "核心", description: "坐在卷腹機，雙手握把或肩部靠墊，收縮腹部將上身向前捲起，再慢慢回到起始位置，主要訓練腹直肌。"),

    // --- 有氧 ---
    ExerciseInfo(name: "跑步機間歇", part: "有氧", description: "在跑步機上交替進行高速度衝刺與低速度恢復，提升心肺耐力與燃脂效果。"),
    ExerciseInfo(name: "跑步機高坡度低速度", part: "有氧", description: "將跑步機調整至高坡度，低速行走，增加下肢肌群負荷並提升心肺耐力。"),
    ExerciseInfo(name: "腳踏車", part: "有氧", description: "坐姿踩動腳踏車或飛輪，保持穩定節奏，提升心肺功能並訓練腿部耐力。"),

    // --- 休息 ---
    ExerciseInfo(name: "肌肉恢復指南", part: "休息", description: "睡眠是肌肉生長的黃金時間！建議每天睡滿 7-8 小時，搭配滾筒放鬆緊繃筋膜。有問題隨時問教練！"),
    ExerciseInfo(name: "飲食與營養補充", part: "休息", description: "訓練後 30 分鐘內攝取優質蛋白質與碳水化合物，能有效加速恢復。不知道怎麼吃？點擊下方問教練！"),
  ];

  static String get(String exerciseName) {
    try {
      print("🔍 [字典查詢] 正在尋找動作：『$exerciseName』");

      // 1. 把兩邊的空格都清掉，避免因為多按一個空白鍵導致找不到
      String cleanInput = exerciseName.replaceAll(' ', '');

      // 2. 🌟 關鍵魔法：把字典裡的動作名稱「從長到短」排序！
      // 這樣程式會先比對 "上斜槓鈴臥推" (6個字)，如果沒中，才去比對 "上斜臥推" (4個字)
      List<ExerciseInfo> sortedList = List.from(allExercises);
      sortedList.sort((a, b) => b.name.length.compareTo(a.name.length));

      // 3. 開始比對
      final exercise = sortedList.firstWhere((e) {
        String cleanDictName = e.name.replaceAll(' ', '');

        // 只要互相包含就算成功！
        return cleanInput.contains(cleanDictName) || cleanDictName.contains(cleanInput);
      });

      print("✅ [字典查詢] 成功找到配對：『${exercise.name}』");
      return exercise.description;

    } catch (e) {
      print("❌ [字典查詢] 找不到對應的動作！輸入是：『$exerciseName』");
      return '💡 提示：保持呼吸節奏，收緊核心，動作全程控制速度。若有不適請立即停止。';
    }
  }
}