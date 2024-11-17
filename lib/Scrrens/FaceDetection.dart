import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';

class FaceDetectionScreen extends StatefulWidget {
  @override
  _FaceDetectionScreenState createState() => _FaceDetectionScreenState();
}

class _FaceDetectionScreenState extends State<FaceDetectionScreen> {
  late FaceDetector faceDetector;
  List<Face> detectedFaces = [];
  bool isProcessing = false;
  XFile? capturedImage;

  @override
  void initState() {
    super.initState();
    final options = FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
      enableClassification: true,
    );
    faceDetector = GoogleMlKit.vision.faceDetector(options);
  }

  Future<XFile?> pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);
      return photo;
    } catch (e) {
      debugPrint("Error picking image: $e");
      return null;
    }
  }

  Future<void> detectFaces(XFile imageFile) async {
    try {
      setState(() {
        isProcessing = true;
        detectedFaces = [];
        capturedImage = imageFile;
      });

      final inputImage = InputImage.fromFilePath(imageFile.path);
      final List<Face> faces = await faceDetector.processImage(inputImage);

      setState(() {
        detectedFaces = faces;
        isProcessing = false;
      });
    } catch (e) {
      debugPrint("Error detecting faces: $e");
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (!status.isGranted) {
      debugPrint("Camera permission denied.");
    }
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Detection'),
      ),
      body: Stack(
        children: [
          if (capturedImage != null)
            Image.file(
              File(capturedImage!.path),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          CustomPaint(
            painter: FacePainter(detectedFaces),
            child: Container(),
          ),
          if (isProcessing)
            const Center(
              child: CircularProgressIndicator(),
            ),
          if (capturedImage == null)
            const Center(
              child: Text(
                'Take a photo to detect faces!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (await requestCameraPermission()) {
            final imageFile = await pickImage();
            if (imageFile != null) {
              await detectFaces(imageFile);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: const Text("Failed to pick image!")),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Camera permission is required!")),
            );
          }
        },
        child: const Icon(Icons.camera),
      ),
    );
  }

  @override
  void dispose() {
    faceDetector.close();
    super.dispose();
  }
}

class FacePainter extends CustomPainter {
  final List<Face> faces;

  FacePainter(this.faces);

  @override
  void paint(Canvas canvas, Size size) {
    final paintBox = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final paintLandmarks = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    for (Face face in faces) {
      // Draw the bounding box
      canvas.drawRect(
        Rect.fromLTRB(
          face.boundingBox.left.toDouble(),
          face.boundingBox.top.toDouble(),
          face.boundingBox.right.toDouble(),
          face.boundingBox.bottom.toDouble(),
        ),
        paintBox,
      );

      // Draw the landmarks
      if (face.landmarks[FaceLandmarkType.leftEye] != null) {
        final leftEye = face.landmarks[FaceLandmarkType.leftEye]!.position;
        canvas.drawCircle(
          Offset(leftEye.x.toDouble(), leftEye.y.toDouble()),
          4.0,
          paintLandmarks,
        );
      }
      if (face.landmarks[FaceLandmarkType.rightEye] != null) {
        final rightEye = face.landmarks[FaceLandmarkType.rightEye]!.position;
        canvas.drawCircle(
          Offset(rightEye.x.toDouble(), rightEye.y.toDouble()),
          4.0,
          paintLandmarks,
        );
      }
      if (face.landmarks[FaceLandmarkType.noseBase] != null) {
        final noseBase = face.landmarks[FaceLandmarkType.noseBase]!.position;
        canvas.drawCircle(
          Offset(noseBase.x.toDouble(), noseBase.y.toDouble()),
          4.0,
          paintLandmarks,
        );
      }
      if (face.landmarks[FaceLandmarkType.leftMouth] != null) {
        final mouthLeft = face.landmarks[FaceLandmarkType.leftMouth]!.position;
        canvas.drawCircle(
          Offset(mouthLeft.x.toDouble(), mouthLeft.y.toDouble()),
          4.0,
          paintLandmarks,
        );
      }
      if (face.landmarks[FaceLandmarkType.rightMouth] != null) { // Corrected from leftMouth to rightMouth
        final mouthRight = face.landmarks[FaceLandmarkType.rightMouth]!.position;
        canvas.drawCircle(
          Offset(mouthRight.x.toDouble(), mouthRight.y.toDouble()),
          4.0,
          paintLandmarks,
        );
      }
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.faces != faces;
  }
}


