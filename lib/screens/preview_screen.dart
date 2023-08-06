import 'dart:io';

import 'package:flutter/material.dart';
import 'package:instantcamera/screens/captures_screen.dart';

class PreviewScreen extends StatelessWidget {
  final File imageFile;

  final List<File> imageFileList;

  const PreviewScreen({required this.imageFile, required this.imageFileList});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CapturesScreen(imageFileList: imageFileList),
                    ));
              },
              icon: const Icon(
                Icons.arrow_back,
                size: 40,
                color: Colors.white,
              )),
          Expanded(
            child: Image.file(imageFile),
          ),
        ],
      ),
    );
  }
}
