import 'dart:math';

// 建議可以把檔名和 Class 改叫 ProBenchPressTrainer，或是保留原本名字也可以
class InclinePressTrainer {
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

  // 👇 這裡加一個 exerciseName 參數！
  void processPose({
    required double leftArmAngle,
    required double rightArmAngle,
    required double leftTuckAngle,
    required double rightTuckAngle,
    String exerciseName = "臥推", // 👈 新增這行
  }) {

    bool isLeftTuckGood = true;
    bool isRightTuckGood = true;

    if (leftArmAngle < 120.0 || rightArmAngle < 120.0) {
      isLeftTuckGood = leftTuckAngle >= 60.0 && leftTuckAngle <= 135.0;
      isRightTuckGood = rightTuckAngle >= 60.0 && rightTuckAngle <= 135.0;
    }

    if (!isLeftTuckGood || !isRightTuckGood) {
      feedback = "⚠️ 手肘微收！小心傷到肩關節！";
    }

    if (currentState == STATE_TOP) {
      // 這裡可以稍微放寬，因為有些人下放不一定能壓到 50 度
      if (leftArmAngle <= 85.0 && rightArmAngle <= 85.0) {
        currentState = STATE_BOTTOM;
        // 👇 根據動作切換碰胸提示
        if (exerciseName.contains('上斜')) {
          feedback = (isLeftTuckGood && isRightTuckGood) ? "推！感受上胸發力！" : feedback;
        } else {
          feedback = (isLeftTuckGood && isRightTuckGood) ? "碰胸了，用力推！" : feedback;
        }
      }
      else if (leftArmAngle <= 120.0 || rightArmAngle <= 120.0) {
        feedback = (isLeftTuckGood && isRightTuckGood) ? "控制下放速度..." : feedback;
      }
    }
    else if (currentState == STATE_BOTTOM) {
      if (leftArmAngle >= 150.0 && rightArmAngle >= 150.0) {
        counter++;
        currentState = STATE_TOP;
        feedback = "完成 $counter 次！推得漂亮！";
      }
      else if (leftArmAngle > 90.0 || rightArmAngle > 90.0) {
        if ((leftArmAngle - rightArmAngle).abs() > 30.0) {
          feedback = "⚠️ 左右手發力不平均！";
        } else {
          feedback = (isLeftTuckGood && isRightTuckGood) ? "繼續推！" : feedback;
        }
      }
    }
  }

  // 👇 reset 也可以根據動作動態給提示
  void reset({String exerciseName = "臥推"}) {
    counter = 0;
    currentState = STATE_TOP;
    if (exerciseName.contains('上斜')) {
      feedback = "💡 準備：將上斜板凳調整至 30~45 度";
    } else {
      feedback = "💡 準備：肩胛收緊，腳踩穩";
    }
  }
}