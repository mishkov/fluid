// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:js' as js;
import 'dart:html' as html;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

enum EditStage { pickup, editing }

class _MyAppState extends State<MyApp> {
  DropzoneViewController? controller;
  bool highlighted = false;
  EditStage _stage = EditStage.pickup;

  final _cropController = CropController();

  Uint8List? _originImageBytes;
  Uint8List? _croppedImageBytes;

  var focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fluid'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _stage == EditStage.editing
              ? _originImageBytes != null
                  ? RawKeyboardListener(
                      autofocus: true,
                      focusNode: focusNode,
                      onKey: (event) {
                        if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
                          _cropController.crop();
                        }
                      },
                      child: Crop(
                        aspectRatio: 547 / 470,
                        image: _originImageBytes!,
                        controller: _cropController,
                        onCropped: (image) {
                          setState(() {
                            _croppedImageBytes = image;
                            js.context.callMethod("webSaveAs", [
                              html.Blob([_croppedImageBytes]),
                              "cropped.png",
                            ]);
                          });
                        },
                      ),
                    )
                  : const Center(
                      child: Text('_imageBytes is null!'),
                    )
              : Container(
                  color: highlighted ? Colors.red : Colors.green,
                  child: Stack(
                    children: [
                      DropzoneView(
                        operation: DragOperation.copy,
                        cursor: CursorType.grab,
                        onCreated: (ctrl) => controller = ctrl,
                        onHover: () {
                          setState(() {
                            highlighted = true;
                          });
                        },
                        onLeave: () {
                          setState(() {
                            highlighted = false;
                          });
                        },
                        onDrop: _handleFile,
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Drop something here'),
                            const Text('or'),
                            ElevatedButton(
                              onPressed: () async {
                                if (controller == null) {
                                  return;
                                }

                                final files = await controller!.pickFiles(
                                    mime: ['image/jpeg', 'image/png']);
                                await _handleFile(files.firstOrNull);
                              },
                              child: const Text('Pick file'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _handleFile(file) async {
    if (file == null) {
      return;
    }
    if (controller == null) {
      return;
    }

    setState(() {
      highlighted = false;
    });
    _originImageBytes = await controller?.getFileData(file);
    setState(() {
      _stage = EditStage.editing;
    });
  }
}
