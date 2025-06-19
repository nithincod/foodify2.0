import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:foodify2o/pages/foodify2oFoodSearchScreen.dart';
import 'package:foodify2o/utils/searchinput.dart';
import 'package:permission_handler/permission_handler.dart';

import 'foodify2opreviewPage.dart';
import 'package:http/http.dart' as http;

import 'dart:io';

class SnapTrackPage extends StatefulWidget {
  final String appBarTitle;

  SnapTrackPage({required this.appBarTitle});

  @override
  _SnapTrackPageState createState() => _SnapTrackPageState();
}

class _SnapTrackPageState extends State<SnapTrackPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _initializeCamera();
    } else {
      print('Camera permission denied');
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (!mounted) return;
        setState(() => _isCameraInitialized = true);
      } else {
        print('No cameras available');
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
  if (_cameraController == null || !_cameraController!.value.isInitialized) {
    print('Camera is not initialized');
    return;
  }
  try {
    final XFile imageFile = await _cameraController!.takePicture();

    // Navigate to next screen with image path
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewPage(imagePath: imageFile.path, camera: _cameras![0],),
      ),
    );
  } catch (e) {
    print('Error capturing image: $e');
  }
}


  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.appBarTitle,
          style: TextStyle(
            color: Color.fromARGB(255, 80, 80, 80),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  _isCameraInitialized && _cameraController != null
                      ? Container(
                          height: MediaQuery.of(context).size.height * 0.35,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Color.fromARGB(255, 255, 255, 255),
                                width: 2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: CameraPreview(_cameraController!),
                        )
                      : Center(child: CircularProgressIndicator()),
                  Positioned(
                    bottom: 20,
                    child: GestureDetector(
                      onTap: _isCameraInitialized ? _captureImage : null,
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(137, 139, 138, 138),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                          ),
                          SizedBox(height: 6),
                          Text('Snap or Add from gallery',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              InkWell(
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => FoodSearchScreen()),
    );
    print('tapped');
  },
  child: IgnorePointer( 
    child: SearchInput(
      textController: TextEditingController(),
      hintText: 'Search for food',
    ),
  ),
),

            ],
          ),
        ),
      ),
    );
  }
}
