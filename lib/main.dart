// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:js' as js;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:dotted_border/dotted_border.dart';
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
              : Uploader(
                  onUpload: (file) {
                    setState(() {
                      _originImageBytes = file;
                    });
                  },
                ),
        ),
      ),
    );
  }
}

class Uploader extends StatefulWidget {
  const Uploader({
    Key? key,
    required this.onUpload,
  }) : super(key: key);

  final void Function(Uint8List file) onUpload;

  @override
  State<Uploader> createState() => _UploaderState();
}

class _UploaderState extends State<Uploader> {
  DropzoneViewController? controller;
  bool highlighted = false;

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
    final bytes = await controller?.getFileData(file);
    if (bytes != null) {
      widget.onUpload(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = 5.0;
    const borderPadding = 8.0;

    return Container(
      decoration: BoxDecoration(
        color: highlighted ? Colors.amber : Colors.green,
        borderRadius: BorderRadius.circular(borderRadius + borderPadding),
      ),
      child: DottedBorder(
        color: Colors.white,
        strokeWidth: 3,
        padding: const EdgeInsets.all(borderPadding),
        borderType: BorderType.RRect,
        borderPadding: const EdgeInsets.all(borderPadding),
        radius: const Radius.circular(borderRadius),
        dashPattern: const [12, 8],
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
                  const Icon(
                    Icons.upload_file,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Drop something here',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    'or',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (controller == null) {
                        return;
                      }

                      final files = await controller!
                          .pickFiles(mime: ['image/jpeg', 'image/png']);
                      await _handleFile(files.firstOrNull);
                    },
                    style: ButtonStyle(
                        padding: MaterialStatePropertyAll(
                            const EdgeInsets.all(16.0))),
                    child: const Text(
                      'Choose file',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
