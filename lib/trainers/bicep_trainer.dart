import 'dart:math';

class BicepTrainer {
  // 狀態機常數 [cite: 27, 62]
  static const int STATE_RELAX = 0;
  static const int STATE_EFFORT = 1;

  int counter = 0;
  int currentState = STATE_RELAX;
  String feedback = "準備開始";

  // 計算角度的核心邏輯 [cite: 25]
  double calculateAngle(double ax, double ay, double bx, double by, double cx, double cy) {
    // 使用 atan2 進行幾何運算 [cite: 25]
    double radians = atan2(cy - by, cx - bx) - atan2(ay - by, ax - bx);
    double angle = (radians * 180.0 / pi).abs();

    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  // 處理動作判斷與計數 [cite: 27, 28, 54]
  void processPose(double angle) {
    if (currentState == STATE_RELAX) {
      // 偵測到彎曲（出力）：角度小於 45 度 [cite: 27]
      if (angle < 45.0) {
        currentState = STATE_EFFORT;
        feedback = "很好，請伸直";
      }
    } else if (currentState == STATE_EFFORT) {
      // 偵測到伸直（放鬆）：角度大於 160 度 [cite: 27]
      if (angle > 160.0) {
        counter++;
        currentState = STATE_RELAX;
        feedback = "完成 1 次！";
      } else if (angle < 100.0) {
        // 防止半程動作的提示邏輯 [cite: 28, 54]
        feedback = "請完全伸直再做下一次";
      }
    }
  }

  void reset() {
    counter = 0;
    currentState = STATE_RELAX;
  }
}