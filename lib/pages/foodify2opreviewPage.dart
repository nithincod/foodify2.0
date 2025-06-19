import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class PreviewPage extends StatefulWidget {
  final CameraDescription camera;
  final String imagePath;

  PreviewPage({required this.camera, required this.imagePath});

  @override
  _PreviewPageState createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await 
        _initializeCamera(); 
  }



   Future<void> _initializeCamera() async {
    _cameraController = CameraController(
      widget.camera,
      ResolutionPreset.max,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() => _isCameraInitialized = true);
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized) return;

    try {
      final XFile image = await _cameraController!.takePicture();
      print("📸 Captured: ${image.path}");
      await detectFood(image.path);
    } catch (e) {
      print("❌ Capture error: $e");
    }
  }

  Future<void> detectFood(String imagePath) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.5:5001/detect'),
    );

    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final decoded = json.decode(respStr);
      print("✅ Detection: $decoded");
      _showResultDialog(decoded);
    } else {
      print('❌ Detection failed: ${response.statusCode}');
    }
  }

  void _showResultDialog(dynamic result) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Detection Results"),
        content: SingleChildScrollView(
          child: Text(result.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Full-Screen Camera Preview
          _isCameraInitialized
              ? Positioned.fill(child: CameraPreview(_cameraController!))
              : Center(child: CircularProgressIndicator()),

          // Camera Framing Guide (Rounded Corners)
          Positioned.fill(
            child: CustomPaint(
              painter: RoundedFramePainter(),
            ),
          ),

          // Top Buttons & SnapFood Text
          Positioned(
            top: 40,
            left: 5,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: 40,
            right: 60,
            child: Icon(Icons.flash_on, color: Colors.white, size: 30),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 30),
          ),
          Positioned(
            top: 85,
            left: MediaQuery.of(context).size.width / 2 - 60,
            child: Row(
              children: [
                Icon(Icons.camera, color: Colors.white, size: 28),
                SizedBox(width: 10),
                Text(
                  "SnapFood",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Capture Button (Bottom Center)
          Positioned(
            bottom: 40,
            left: MediaQuery.of(context).size.width / 2 - 35,
            child: GestureDetector(
              onTap: _captureImage,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Gallery Button (Bottom Left)
          Positioned(
            bottom: 40,
            left: 30,
            child: Icon(Icons.image, color: Colors.white, size: 40),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Rounded Framing Guide
class RoundedFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final double cornerRadius = 20;
    final double cornerLength = 50;

    // Draw rounded corners
    Path path = Path()
      ..moveTo(20 + cornerRadius, 100)
      ..lineTo(20 + cornerLength, 100)
      ..moveTo(20, 100 + cornerRadius)
      ..lineTo(20, 100 + cornerLength)
      ..moveTo(size.width - 20 - cornerRadius, 100)
      ..lineTo(size.width - 20 - cornerLength, 100)
      ..moveTo(size.width - 20, 100 + cornerRadius)
      ..lineTo(size.width - 20, 100 + cornerLength)
      ..moveTo(20 + cornerRadius, size.height - 100)
      ..lineTo(20 + cornerLength, size.height - 100)
      ..moveTo(20, size.height - 100 - cornerRadius)
      ..lineTo(20, size.height - 100 - cornerLength)
      ..moveTo(size.width - 20 - cornerRadius, size.height - 100)
      ..lineTo(size.width - 20 - cornerLength, size.height - 100)
      ..moveTo(size.width - 20, size.height - 100 - cornerRadius)
      ..lineTo(size.width - 20, size.height - 100 - cornerLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
