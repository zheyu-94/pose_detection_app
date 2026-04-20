import 'dart:math';

class ShoulderPressTrainer {
  static const int STATE_TOP = 0;
  static const int STATE_BOTTOM = 1;

  int counter = 0;
  int currentState = STATE_TOP;

  String feedback = "💡 準備中...";

  double calculateAngle(double ax, double ay, double bx, double by, double cx, double cy) {
    double radians = atan2(cy - by, cx - bx) - atan2(ay - by, ax - bx);
    double angle = (radians * 180.0 / pi).abs();

    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  void processPose({
    required double leftArmAngle,
    required double rightArmAngle,
    required double leftTuckAngle,
    required double rightTuckAngle,
    String exerciseName = "肩推", // 👈 加入名稱判斷
  }) {

    bool isLeftTuckGood = true;
    bool isRightTuckGood = true;

    if (leftArmAngle < 120.0 || rightArmAngle < 120.0) {
      isLeftTuckGood = leftTuckAngle >= 60.0 && leftTuckAngle <= 135.0;
      isRightTuckGood = rightTuckAngle >= 60.0 && rightTuckAngle <= 135.0;
    }

    if (!isLeftTuckGood || !isRightTuckGood) {
      feedback = "⚠️ 手肘微收！不要向外打開太多！";
    }

    if (currentState == STATE_TOP) {
      // 🌟 修正點：把 50 度放寬到 85 度！
      if (leftArmAngle <= 85.0 && rightArmAngle <= 85.0) {
        currentState = STATE_BOTTOM;
        feedback = (isLeftTuckGood && isRightTuckGood) ? "下放到底了，向上推！" : feedback;
      }
      else if (leftArmAngle <= 120.0 || rightArmAngle <= 120.0) {
        feedback = (isLeftTuckGood && isRightTuckGood) ? "控制速度，繼續下放..." : feedback;
      }
    }
    else if (currentState == STATE_BOTTOM) {
      // 推到頂的判斷 (150度~160度皆可，這裡保留你的 160 度)
      if (leftArmAngle >= 160.0 && rightArmAngle >= 160.0) {
        counter++;
        currentState = STATE_TOP;
        feedback = "完成 $counter 次！做的好！";
      }
      else if (leftArmAngle > 90.0 || rightArmAngle > 90.0) {
        if ((leftArmAngle - rightArmAngle).abs() > 30.0) {
          feedback = "⚠️ 注意左右手平衡！";
        } else {
          feedback = (isLeftTuckGood && isRightTuckGood) ? "用力推！" : feedback;
        }
      }
    }
  }

  // 🌟 動態給予初始提示
  void reset({String exerciseName = "肩推"}) {
    counter = 0;
    currentState = STATE_TOP;
    if (exerciseName.contains('站姿')) {
      feedback = "💡 準備：雙腳踩穩，核心與臀部收緊防折腰";
    } else {
      feedback = "💡 準備：將板凳椅背調整至 75~90 度";
    }
  }
}