import 'dart:math';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class SquatTrainer {
  // 狀態機常數
  static const int STATE_STANDING = 0;
  static const int STATE_DESCENDING = 1;
  static const int STATE_BOTTOM = 2;
  static const int STATE_ASCENDING = 3;

  int counter = 0;
  int currentState = STATE_STANDING;
  String feedback = "準備好就開始下蹲";
  bool isBadForm = false; // 紀錄姿勢是否錯誤（背部前傾）

  // 計算三點夾角
  double calculateAngle(double ax, double ay, double bx, double by, double cx, double cy) {
    double radians = atan2(cy - by, cx - bx) - atan2(ay - by, ax - bx);
    double angle = (radians * 180.0 / pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  // 計算背部前傾角度 (相對於 Y 軸垂直線)
  double calculateTorsoAngle(double shoulderX, double shoulderY, double hipX, double hipY) {
    // 建立一個垂直點 (x 相同，y 往上)
    double verticalX = hipX;
    double verticalY = hipY - 100;
    return calculateAngle(shoulderX, shoulderY, hipX, hipY, verticalX, verticalY);
  }

  // 處理深蹲動作判斷
  void processPose({required double kneeAngle, required double torsoAngle}) {
    // 1. 防護機制：背部前傾判斷
    if (torsoAngle > 45.0) {
      isBadForm = true;
      feedback = "抬頭挺胸！背部不要過度前傾！";
      return; // 姿勢錯誤時，暫停計數狀態的更新
    } else {
      isBadForm = false;
    }

    // 2. 狀態機與計數邏輯
    if (kneeAngle > 150) {
      if (currentState == STATE_ASCENDING) {
        counter++;
        feedback = "完美！繼續保持！";
      } else if (currentState == STATE_DESCENDING) {
        feedback = "蹲低一點！大腿要平行地面";
      } else {
        feedback = "準備好就開始下蹲";
      }
      currentState = STATE_STANDING;
    }
    else if (kneeAngle < 95) {
      currentState = STATE_BOTTOM;
      feedback = "深度足夠！利用臀腿發力站起";
    }
    else if (kneeAngle <= 150 && kneeAngle >= 95) {
      if (currentState == STATE_STANDING || currentState == STATE_DESCENDING) {
        currentState = STATE_DESCENDING;
        feedback = "控制速度，慢慢下放...";
      } else if (currentState == STATE_BOTTOM || currentState == STATE_ASCENDING) {
        currentState = STATE_ASCENDING;
        feedback = "用力推！";
      }
    }
  }

  void reset() {
    counter = 0;
    currentState = STATE_STANDING;
    feedback = "準備好就開始下蹲";
    isBadForm = false;
  }
}