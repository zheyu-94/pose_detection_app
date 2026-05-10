import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:camera/camera.dart';

class PosePainter extends CustomPainter {
  // 宣告接收進來的變數
  final List<Pose> poses;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  PosePainter(this.poses, this.imageSize, this.rotation, this.cameraLensDirection);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. 準備畫筆
    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.blueAccent;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.redAccent;

    final centerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.greenAccent;

    // 這是你原本畫綠色圓點的畫筆
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.greenAccent;

    // 2. 開始畫圖
    for (final pose in poses) {
      // --- A. 先把你原本的「綠色圓點」畫出來 ---
      for (final landmark in pose.landmarks.values) {
        canvas.drawCircle(
          Offset(
            translateX(landmark.x, size, imageSize, rotation, cameraLensDirection),
            translateY(landmark.y, size, imageSize, rotation, cameraLensDirection),
          ),
          5.0, // 圓點大小
          dotPaint,
        );
      }

      // --- B. 定義畫線的小工具 ---
      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        final PoseLandmark? joint1 = pose.landmarks[type1];
        final PoseLandmark? joint2 = pose.landmarks[type2];

        if (joint1 != null && joint2 != null) {
          canvas.drawLine(
            Offset(
              translateX(joint1.x, size, imageSize, rotation, cameraLensDirection),
              translateY(joint1.y, size, imageSize, rotation, cameraLensDirection),
            ),
            Offset(
              translateX(joint2.x, size, imageSize, rotation, cameraLensDirection),
              translateY(joint2.y, size, imageSize, rotation, cameraLensDirection),
            ),
            paintType,
          );
        }
      }

      // --- C. 開始連連看 ---
      // 身體軀幹
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, centerPaint);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, centerPaint);

      // 左半身 (藍線)
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);

      // 右半身 (紅線)
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, rightPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, rightPaint);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);
      paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.poses != poses;
  }
}

double translateX(double x, Size canvasSize, Size imageSize, InputImageRotation rotation, CameraLensDirection cameraLensDirection) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
      return x * canvasSize.width / (defaultTargetPlatform == TargetPlatform.iOS ? imageSize.width : imageSize.height);
    case InputImageRotation.rotation270deg:
      return canvasSize.width - x * canvasSize.width / (defaultTargetPlatform == TargetPlatform.iOS ? imageSize.width : imageSize.height);
    default:
      return x * canvasSize.width / imageSize.width;
  }
}

double translateY(double y, Size canvasSize, Size imageSize, InputImageRotation rotation, CameraLensDirection cameraLensDirection) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      return y * canvasSize.height / (defaultTargetPlatform == TargetPlatform.iOS ? imageSize.height : imageSize.width);
    default:
      return y * canvasSize.height / imageSize.height;
  }
}