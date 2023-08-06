import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:instantcamera/screens/preview_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../main.dart';

class CameraScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;

  File? imageFilex;

  // Initial values
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;

  List<File> allFileList = [];

  final resolutionPresets = ResolutionPreset.values;

  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;

  getPermissionStatus() async {
    await Permission.camera.request();
    var status = await Permission.camera.status;

    if (status.isGranted) {
      log('Camera Permission: GRANTED');
      setState(() {
        _isCameraPermissionGranted = true;
      });
      // Set and initialize the new camera
      onNewCameraSelected(cameras[0]);
      refreshAlreadyCapturedImages();
    } else {
      log('Camera Permission: DENIED');
    }
  }

  refreshAlreadyCapturedImages() async {
    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> fileList = await directory.list().toList();
    allFileList.clear();
    List<Map<int, dynamic>> fileNames = [];

    fileList.forEach((file) {
      if (file.path.contains('.jpg') || file.path.contains('.mp4')) {
        allFileList.add(File(file.path));

        String name = file.path.split('/').last.split('.').first;
        fileNames.add({0: int.parse(name), 1: file.path.split('/').last});
      }
    });

    if (fileNames.isNotEmpty) {
      final recentFile =
          fileNames.reduce((curr, next) => curr[0] > next[0] ? curr : next);
      String recentFileName = recentFile[1];
      if (recentFileName.contains('.mp4')) {
        imageFilex = null;
      } else {
        imageFilex = File('${directory.path}/$recentFileName');
      }

      setState(() {});
    }
  }

  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;

    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      print('Error occured while taking picture: $e');
      return null;
    }
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;

    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await previousCameraController?.dispose();

    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  @override
  void initState() {
    // Hide the status bar in Android
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    getPermissionStatus();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isCameraPermissionGranted
            ? _isCameraInitialized
                ? Container(
                    width: double.infinity,
                    child: Column(
                      children: [
                        CameraPreview(
                          controller!,
                          child: LayoutBuilder(builder: (BuildContext context,
                              BoxConstraints constraints) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                            );
                          }),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            16.0,
                            8.0,
                            16.0,
                            8.0,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              //take button and recent image view row
                              Padding(
                                padding: const EdgeInsets.only(top: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    //image taking button
                                    Padding(
                                      padding: const EdgeInsets.only(left: 160),
                                      child: InkWell(
                                        onTap: () async {
                                          XFile? rawImage = await takePicture();
                                          File imageFile = File(rawImage!.path);

                                          int currentUnix = DateTime.now()
                                              .millisecondsSinceEpoch;

                                          final directory =
                                              await getApplicationDocumentsDirectory();

                                          String fileFormat =
                                              imageFile.path.split('.').last;

                                          print(fileFormat);

                                          await imageFile.copy(
                                            '${directory.path}/$currentUnix.$fileFormat',
                                          );
                                          refreshAlreadyCapturedImages();
                                        },
                                        child: Container(
                                          width: 80,
                                          height: 80,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera,
                                            color: Colors.white,
                                            size: 87,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // right side gallery viewer
                                    InkWell(
                                      onTap: imageFilex != null
                                          ? () async {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      PreviewScreen(
                                                          imageFile:
                                                              imageFilex!,
                                                          imageFileList:
                                                              allFileList),
                                                ),
                                              );
                                            }
                                          : null,
                                      child: Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          image: imageFilex != null
                                              ? DecorationImage(
                                                  image: FileImage(imageFilex!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(
                    child: Text(
                      'LOADING',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(),
                  const Text(
                    'Permission denied',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      getPermissionStatus();
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Give permission',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
