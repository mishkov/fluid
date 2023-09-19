// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';
import 'package:pasteboard/pasteboard.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

enum EditStage { pickup, editing }

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  EditStage _stage = EditStage.pickup;

  Uint8List? _originImageBytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fluid'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _stage == EditStage.editing
            ? _originImageBytes != null
                ? Editor(
                    rawImage: _originImageBytes!,
                    onDone: (image) {
                      setState(() {
                        js.context.callMethod("webSaveAs", [
                          html.Blob([image]),
                          "cropped.png",
                        ]);
                      });
                    },
                  )
                : const Center(
                    child: Text('_imageBytes is null!'),
                  )
            : Uploader(
                onUpload: (file) {
                  setState(() {
                    _originImageBytes = file;
                    _stage = EditStage.editing;
                  });
                },
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
  StreamSubscription? _onPasteEvent;

  @override
  void initState() {
    super.initState();
    _onPasteEvent = html.document
        .getElementsByTagName('body')
        .first
        .on['paste']
        .listen((event) {
      Pasteboard.image.then(_handleImageFromClipBoard);
    });
  }

  @override
  void dispose() {
    _onPasteEvent?.cancel();
    super.dispose();
  }

  Future<void> _handleImageFromClipBoard(Uint8List? image) async {
    if (image == null) {
      return;
    }

    widget.onUpload(image);
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
                    style: const ButtonStyle(
                      padding: MaterialStatePropertyAll(EdgeInsets.all(16.0)),
                    ),
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

class Editor extends StatefulWidget {
  const Editor({
    Key? key,
    required this.rawImage,
    required this.onDone,
  }) : super(key: key);

  final Uint8List rawImage;
  final void Function(Uint8List image) onDone;

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final focusNode = FocusNode();
  final _cropController = CropController();
  Uint8List? _croppedImageBytes;

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      autofocus: true,
      focusNode: focusNode,
      onKey: (event) {
        // if (event.isKeyPressed(Paste))
        if (event.isKeyPressed(LogicalKeyboardKey.enter)) {
          _cropController.crop();
        }
      },
      child: Crop(
        aspectRatio: 547 / 470,
        image: widget.rawImage,
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
    );
  }
}
